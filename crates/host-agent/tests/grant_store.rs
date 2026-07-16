// SPDX-License-Identifier: MPL-2.0

use std::{fs, sync::Arc};

use ed25519_dalek::SigningKey;
use prost::Message;
use roammand_host_agent::{AuthorizationError, AuthorizationRegistry, FileGrantStore};
use roammand_protocol::{
    identity_derivation::derive_device_id_v1,
    roammand::v1::{
        DeviceIdentity, DevicePlatform, HostAuthorizationSnapshot, PublicKeyAlgorithm,
        SessionPermission,
    },
};
use sha2::{Digest, Sha256};
use tempfile::tempdir;

const ENVELOPE_HEADER_BYTES: usize = 42;

#[test]
fn file_store_survives_restart_with_restrictive_permissions() {
    let temporary = tempdir().expect("temporary directory must be created");
    let path = temporary.path().join("state").join("grants.bin");
    let host_device_id = vec![0x81; 32];
    let first = {
        let mut registry = AuthorizationRegistry::load(
            host_device_id.clone(),
            Arc::new(FileGrantStore::new(path.clone())),
        )
        .expect("empty file store must load");
        let controller = controller(1);
        let created = registry
            .create_controller_grant(controller.clone(), &[SessionPermission::ViewScreen], 100)
            .expect("grant must be created");
        registry
            .record_authenticated_session(&controller.device_id, 200)
            .expect("last success must persist");
        created
    };

    let registry =
        AuthorizationRegistry::load(host_device_id, Arc::new(FileGrantStore::new(path.clone())))
            .expect("persisted registry must reload");
    let reloaded = registry.list_controller_grants();
    assert_eq!(reloaded.len(), 1);
    assert_eq!(
        reloaded[0]
            .grant
            .as_ref()
            .expect("grant must exist")
            .grant_id,
        first.grant.expect("created grant must exist").grant_id
    );
    assert_eq!(reloaded[0].last_successful_connection_at_unix_ms, 200);

    #[cfg(unix)]
    assert_unix_mode(&path, 0o600);
}

#[test]
fn file_store_rejects_outer_envelope_corruption() {
    let fixture = valid_file_fixture();
    let original = fs::read(&fixture.path).expect("snapshot must be readable");

    let mut cases = Vec::new();
    let mut bad_magic = original.clone();
    bad_magic[0] ^= 0x80;
    cases.push(bad_magic);
    let mut bad_version = original.clone();
    bad_version[4..6].copy_from_slice(&2_u16.to_be_bytes());
    cases.push(bad_version);
    let mut bad_length = original.clone();
    bad_length[6..10].copy_from_slice(&u32::MAX.to_be_bytes());
    cases.push(bad_length);
    let mut bad_checksum = original.clone();
    bad_checksum[10] ^= 0x80;
    cases.push(bad_checksum);
    cases.push(original[..original.len() - 1].to_vec());
    let mut trailing = original.clone();
    trailing.push(0);
    cases.push(trailing);

    for (index, corrupted) in cases.into_iter().enumerate() {
        fs::write(&fixture.path, corrupted).expect("corruption must be written");
        assert!(
            AuthorizationRegistry::load(
                fixture.host_device_id.clone(),
                Arc::new(FileGrantStore::new(fixture.path.clone())),
            )
            .is_err(),
            "corruption case {index}"
        );
    }
}

#[test]
fn file_store_rejects_host_mismatch_duplicate_grant_and_duplicate_controller() {
    let fixture = valid_file_fixture();
    let encoded = fs::read(&fixture.path).expect("snapshot must be readable");
    let mut snapshot = decode_snapshot(&encoded);

    snapshot.host_device_id[0] ^= 0x80;
    write_snapshot(&fixture.path, &snapshot);
    assert_load_fails(&fixture);

    snapshot.host_device_id = fixture.host_device_id.clone();
    let duplicate = snapshot.grants[0].clone();
    snapshot.grants.push(duplicate.clone());
    write_snapshot(&fixture.path, &snapshot);
    assert_load_fails(&fixture);

    let mut duplicate_controller = duplicate;
    duplicate_controller
        .grant
        .as_mut()
        .expect("grant must exist")
        .grant_id = vec![0x77; 16];
    snapshot.grants[1] = duplicate_controller;
    write_snapshot(&fixture.path, &snapshot);
    assert_load_fails(&fixture);
}

#[test]
fn file_store_rejects_oversized_snapshot_before_protobuf_decode() {
    let temporary = tempdir().expect("temporary directory must be created");
    let path = temporary.path().join("grants.bin");
    fs::write(&path, vec![0; 1_048_576 + ENVELOPE_HEADER_BYTES + 1])
        .expect("oversized snapshot must be written");

    assert!(matches!(
        AuthorizationRegistry::load(vec![0x82; 32], Arc::new(FileGrantStore::new(path)),),
        Err(AuthorizationError::Store(_))
    ));
}

struct FileFixture {
    _temporary: tempfile::TempDir,
    path: std::path::PathBuf,
    host_device_id: Vec<u8>,
}

fn valid_file_fixture() -> FileFixture {
    let temporary = tempdir().expect("temporary directory must be created");
    let path = temporary.path().join("grants.bin");
    let host_device_id = vec![0x83; 32];
    let mut registry = AuthorizationRegistry::load(
        host_device_id.clone(),
        Arc::new(FileGrantStore::new(path.clone())),
    )
    .expect("empty registry must load");
    registry
        .create_controller_grant(controller(2), &[SessionPermission::ViewScreen], 100)
        .expect("grant must be created");
    FileFixture {
        _temporary: temporary,
        path,
        host_device_id,
    }
}

fn assert_load_fails(fixture: &FileFixture) {
    assert!(
        AuthorizationRegistry::load(
            fixture.host_device_id.clone(),
            Arc::new(FileGrantStore::new(fixture.path.clone())),
        )
        .is_err()
    );
}

fn decode_snapshot(envelope: &[u8]) -> HostAuthorizationSnapshot {
    let payload_length = u32::from_be_bytes(
        envelope[6..10]
            .try_into()
            .expect("length field must contain four bytes"),
    ) as usize;
    HostAuthorizationSnapshot::decode(&envelope[ENVELOPE_HEADER_BYTES..][..payload_length])
        .expect("valid snapshot must decode")
}

fn write_snapshot(path: &std::path::Path, snapshot: &HostAuthorizationSnapshot) {
    let payload = snapshot.encode_to_vec();
    let mut envelope = Vec::with_capacity(ENVELOPE_HEADER_BYTES + payload.len());
    envelope.extend_from_slice(b"PRDG");
    envelope.extend_from_slice(&1_u16.to_be_bytes());
    envelope.extend_from_slice(
        &u32::try_from(payload.len())
            .expect("test payload length must fit")
            .to_be_bytes(),
    );
    envelope.extend_from_slice(&Sha256::digest(&payload));
    envelope.extend_from_slice(&payload);
    fs::write(path, envelope).expect("snapshot must be written");
}

fn controller(seed_byte: u8) -> DeviceIdentity {
    let public_key = SigningKey::from_bytes(&[seed_byte; 32])
        .verifying_key()
        .to_bytes();
    DeviceIdentity {
        device_id: derive_device_id_v1(&public_key)
            .expect("public key must derive")
            .to_vec(),
        public_key_algorithm: PublicKeyAlgorithm::Ed25519 as i32,
        public_key: public_key.to_vec(),
        display_name: "Controller".to_owned(),
        platform: DevicePlatform::Ios as i32,
    }
}

#[cfg(unix)]
fn assert_unix_mode(path: &std::path::Path, expected: u32) {
    use std::os::unix::fs::PermissionsExt;

    let mode = fs::metadata(path)
        .expect("metadata must be readable")
        .permissions()
        .mode()
        & 0o777;
    assert_eq!(mode, expected);
}
