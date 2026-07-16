// SPDX-License-Identifier: MPL-2.0

use std::sync::Arc;

use ed25519_dalek::SigningKey;
use roammand_host_agent::{AuthorizationError, AuthorizationRegistry, MemoryGrantStore};
use roammand_protocol::{
    identity_derivation::derive_device_id_v1,
    roammand::v1::{DeviceIdentity, DevicePlatform, PublicKeyAlgorithm, SessionPermission},
};

#[test]
fn creates_a_persistent_one_way_controller_to_host_grant() {
    let store = Arc::new(MemoryGrantStore::new());
    let host_device_id = vec![0x91; 32];
    let mut registry = AuthorizationRegistry::load(host_device_id.clone(), store)
        .expect("empty registry must load");
    let controller = controller(1, "Phone", DevicePlatform::Ios);

    let created = registry
        .create_controller_grant(
            controller.clone(),
            &[SessionPermission::ViewScreen],
            1_700_000_000_000,
        )
        .expect("grant must be created");

    let grant = created
        .grant
        .as_ref()
        .expect("created view must contain grant");
    assert_eq!(grant.grant_id.len(), 16);
    assert_eq!(grant.host_device_id, host_device_id);
    assert_eq!(grant.controller.as_ref(), Some(&controller));
    assert_eq!(grant.permissions, [SessionPermission::ViewScreen as i32]);
    assert_eq!(grant.created_at_unix_ms, 1_700_000_000_000);
    assert_eq!(created.last_successful_connection_at_unix_ms, 0);
    assert_eq!(registry.list_controller_grants(), [created]);
}

#[test]
fn identical_create_is_idempotent_but_conflicting_update_is_rejected() {
    let store = Arc::new(MemoryGrantStore::new());
    let mut registry =
        AuthorizationRegistry::load(vec![0x92; 32], store).expect("empty registry must load");
    let controller = controller(2, "Laptop", DevicePlatform::Windows);
    let first = registry
        .create_controller_grant(controller.clone(), &[SessionPermission::ViewScreen], 100)
        .expect("first grant must be created");

    let duplicate = registry
        .create_controller_grant(controller.clone(), &[SessionPermission::ViewScreen], 200)
        .expect("identical grant must be idempotent");
    assert_eq!(duplicate, first);

    assert!(matches!(
        registry.create_controller_grant(
            controller,
            &[
                SessionPermission::ControlInput,
                SessionPermission::ViewScreen,
            ],
            300,
        ),
        Err(AuthorizationError::GrantConflict)
    ));
    assert_eq!(registry.list_controller_grants(), [first]);
}

#[test]
fn rejects_invalid_identity_direction_and_permission_sets() {
    let store = Arc::new(MemoryGrantStore::new());
    let host_public_key = SigningKey::from_bytes(&[0x31; 32])
        .verifying_key()
        .to_bytes();
    let host_device_id = derive_device_id_v1(&host_public_key)
        .expect("host public key must derive")
        .to_vec();
    let mut registry = AuthorizationRegistry::load(host_device_id.clone(), store)
        .expect("empty registry must load");

    let mut wrong_device_id = controller(3, "Phone", DevicePlatform::Android);
    wrong_device_id.device_id[0] ^= 0x80;
    assert_invalid_controller(&mut registry, wrong_device_id);

    let mut wrong_algorithm = controller(4, "Phone", DevicePlatform::Android);
    wrong_algorithm.public_key_algorithm = PublicKeyAlgorithm::Unspecified as i32;
    assert_invalid_controller(&mut registry, wrong_algorithm);

    let mut wrong_platform = controller(5, "Phone", DevicePlatform::Android);
    wrong_platform.platform = DevicePlatform::Unspecified as i32;
    assert_invalid_controller(&mut registry, wrong_platform);

    let mut long_name = controller(6, "Phone", DevicePlatform::Android);
    long_name.display_name = "x".repeat(129);
    assert_invalid_controller(&mut registry, long_name);

    let self_controller = DeviceIdentity {
        device_id: host_device_id,
        public_key_algorithm: PublicKeyAlgorithm::Ed25519 as i32,
        public_key: host_public_key.to_vec(),
        display_name: "Same Host".to_owned(),
        platform: DevicePlatform::Macos as i32,
    };
    assert!(matches!(
        registry.create_controller_grant(self_controller, &[SessionPermission::ViewScreen], 1,),
        Err(AuthorizationError::SelfGrant)
    ));

    let valid = controller(7, "Phone", DevicePlatform::Ios);
    for permissions in [
        vec![],
        vec![SessionPermission::Unspecified],
        vec![SessionPermission::ViewScreen, SessionPermission::ViewScreen],
        vec![SessionPermission::ControlInput],
    ] {
        assert!(matches!(
            registry.create_controller_grant(valid.clone(), &permissions, 1),
            Err(AuthorizationError::InvalidPermissions)
        ));
    }
}

#[test]
fn failed_persistence_does_not_change_memory_or_last_success() {
    let store = Arc::new(MemoryGrantStore::new());
    let mut registry = AuthorizationRegistry::load(vec![0x93; 32], store.clone())
        .expect("empty registry must load");
    let first_controller = controller(8, "Phone", DevicePlatform::Ios);
    let first = registry
        .create_controller_grant(
            first_controller.clone(),
            &[SessionPermission::ViewScreen],
            100,
        )
        .expect("grant must be created");

    store.fail_next_persist();
    assert!(matches!(
        registry.record_authenticated_session(&first_controller.device_id, 200),
        Err(AuthorizationError::Store(_))
    ));
    assert_eq!(
        registry.list_controller_grants().as_slice(),
        std::slice::from_ref(&first)
    );

    store.fail_next_persist();
    let other = controller(9, "Other", DevicePlatform::Android);
    assert!(matches!(
        registry.create_controller_grant(other, &[SessionPermission::ViewScreen], 300,),
        Err(AuthorizationError::Store(_))
    ));
    assert_eq!(registry.list_controller_grants(), [first]);
}

#[test]
fn authenticated_session_time_is_monotonic_and_not_publicly_inferred() {
    let store = Arc::new(MemoryGrantStore::new());
    let mut registry =
        AuthorizationRegistry::load(vec![0x94; 32], store).expect("empty registry must load");
    let controller = controller(10, "Phone", DevicePlatform::Ios);
    registry
        .create_controller_grant(controller.clone(), &[SessionPermission::ViewScreen], 100)
        .expect("grant must be created");

    registry
        .record_authenticated_session(&controller.device_id, 300)
        .expect("successful authentication must update time");
    registry
        .record_authenticated_session(&controller.device_id, 200)
        .expect("older success must be idempotent");
    assert_eq!(
        registry.list_controller_grants()[0].last_successful_connection_at_unix_ms,
        300
    );
}

#[test]
fn rejects_more_than_256_controller_grants() {
    let store = Arc::new(MemoryGrantStore::new());
    let mut registry =
        AuthorizationRegistry::load(vec![0x95; 32], store).expect("empty registry must load");

    for index in 0..256_u16 {
        registry
            .create_controller_grant(
                controller_index(index),
                &[SessionPermission::ViewScreen],
                u64::from(index) + 1,
            )
            .expect("grant within the limit must succeed");
    }
    assert!(matches!(
        registry.create_controller_grant(
            controller_index(256),
            &[SessionPermission::ViewScreen],
            300,
        ),
        Err(AuthorizationError::GrantLimit)
    ));
}

fn assert_invalid_controller(registry: &mut AuthorizationRegistry, invalid: DeviceIdentity) {
    assert!(matches!(
        registry.create_controller_grant(invalid, &[SessionPermission::ViewScreen], 1,),
        Err(AuthorizationError::InvalidController)
    ));
}

fn controller(seed_byte: u8, name: &str, platform: DevicePlatform) -> DeviceIdentity {
    let public_key = SigningKey::from_bytes(&[seed_byte; 32])
        .verifying_key()
        .to_bytes();
    DeviceIdentity {
        device_id: derive_device_id_v1(&public_key)
            .expect("public key must derive")
            .to_vec(),
        public_key_algorithm: PublicKeyAlgorithm::Ed25519 as i32,
        public_key: public_key.to_vec(),
        display_name: name.to_owned(),
        platform: platform as i32,
    }
}

fn controller_index(index: u16) -> DeviceIdentity {
    let mut seed = [0_u8; 32];
    seed[..2].copy_from_slice(&index.to_be_bytes());
    let public_key = SigningKey::from_bytes(&seed).verifying_key().to_bytes();
    DeviceIdentity {
        device_id: derive_device_id_v1(&public_key)
            .expect("public key must derive")
            .to_vec(),
        public_key_algorithm: PublicKeyAlgorithm::Ed25519 as i32,
        public_key: public_key.to_vec(),
        display_name: format!("Controller {index}"),
        platform: DevicePlatform::Ios as i32,
    }
}
