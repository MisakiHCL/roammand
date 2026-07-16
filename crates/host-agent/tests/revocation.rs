// SPDX-License-Identifier: MPL-2.0

use std::sync::Arc;

use roammand_host_agent::{AuthorizationRegistry, HostIdentity, HostService, MemoryGrantStore};
use roammand_host_platform::MemorySecretStore;
use roammand_protocol::{
    identity_derivation::derive_device_id_v1,
    roammand::v1::{
        DeviceIdentity, DevicePlatform, EmergencyStopRemoteSessionRequest,
        ListControllerGrantsRequest, LocalIpcClientFrame, ProtocolVersion, PublicKeyAlgorithm,
        RevokeControllerGrantRequest, SessionPermission, local_ipc_client_frame,
        local_ipc_server_frame,
    },
};
use tokio::sync::broadcast::error::TryRecvError;

#[test]
fn revocation_persists_then_terminates_matching_sessions_and_broadcasts() {
    let fixture = fixture();
    let mut events = fixture.service.subscribe_session_terminations();
    fixture
        .service
        .register_active_session(vec![0x11; 16], fixture.controller.device_id.clone())
        .expect("first matching session must register");
    fixture
        .service
        .register_active_session(vec![0x12; 16], fixture.controller.device_id.clone())
        .expect("second matching session must register");
    fixture
        .service
        .register_active_session(vec![0x13; 16], fixture.other_controller.device_id.clone())
        .expect("other session must register");

    let response = fixture.service.handle_frame(
        &frame(
            "revoke-1",
            local_ipc_client_frame::Payload::RevokeControllerGrant(RevokeControllerGrantRequest {
                grant_id: fixture.grant_id.clone(),
            }),
        ),
        200,
    );
    let Some(local_ipc_server_frame::Payload::ControllerGrantRevoked(revoked)) = response.payload
    else {
        panic!("expected ControllerGrantRevoked response");
    };
    assert_eq!(revoked.grant_id, fixture.grant_id);
    assert_eq!(revoked.terminated_session_count, 2);
    assert_eq!(fixture.service.active_session_count(), 1);
    assert!(list_grants(&fixture.service).is_empty());

    let mut received = [
        events.try_recv().expect("first termination must broadcast"),
        events
            .try_recv()
            .expect("second termination must broadcast"),
    ];
    received.sort_by(|left, right| left.session_id.cmp(&right.session_id));
    assert_eq!(received[0].session_id, vec![0x11; 16]);
    assert_eq!(received[1].session_id, vec![0x12; 16]);
    assert!(
        received
            .iter()
            .all(|event| event.controller_device_id == fixture.controller.device_id)
    );
    assert!(matches!(events.try_recv(), Err(TryRecvError::Empty)));
}

#[test]
fn persistence_failure_keeps_grant_sessions_and_event_stream_unchanged() {
    let fixture = fixture();
    let mut events = fixture.service.subscribe_session_terminations();
    fixture
        .service
        .register_active_session(vec![0x21; 16], fixture.controller.device_id.clone())
        .expect("session must register");
    fixture.store.fail_next_persist();

    let response = fixture.service.handle_frame(
        &frame(
            "revoke-fails",
            local_ipc_client_frame::Payload::RevokeControllerGrant(RevokeControllerGrantRequest {
                grant_id: fixture.grant_id,
            }),
        ),
        200,
    );
    assert!(matches!(
        response.payload,
        Some(local_ipc_server_frame::Payload::Error(_))
    ));
    assert_eq!(fixture.service.active_session_count(), 1);
    assert_eq!(list_grants(&fixture.service).len(), 1);
    assert!(matches!(events.try_recv(), Err(TryRecvError::Empty)));
}

#[test]
fn repeated_revocation_returns_stable_error_without_extra_events() {
    let fixture = fixture();
    let mut events = fixture.service.subscribe_session_terminations();
    let request = frame(
        "revoke",
        local_ipc_client_frame::Payload::RevokeControllerGrant(RevokeControllerGrantRequest {
            grant_id: fixture.grant_id,
        }),
    );
    let first = fixture.service.handle_frame(&request, 200);
    assert!(matches!(
        first.payload,
        Some(local_ipc_server_frame::Payload::ControllerGrantRevoked(_))
    ));
    let second = fixture.service.handle_frame(&request, 300);
    assert!(matches!(
        second.payload,
        Some(local_ipc_server_frame::Payload::Error(_))
    ));
    assert!(matches!(events.try_recv(), Err(TryRecvError::Empty)));
}

#[test]
fn local_emergency_stop_is_idempotent_and_preserves_permanent_grants() {
    let fixture = fixture();
    let mut events = fixture.service.subscribe_session_terminations();
    fixture
        .service
        .register_active_session(vec![0x31; 16], fixture.controller.device_id.clone())
        .expect("first session");
    fixture
        .service
        .register_active_session(vec![0x32; 16], fixture.other_controller.device_id.clone())
        .expect("second session");
    let request = frame(
        "emergency-stop",
        local_ipc_client_frame::Payload::EmergencyStopRemoteSession(
            EmergencyStopRemoteSessionRequest {},
        ),
    );

    let response = fixture.service.handle_frame(&request, 200);
    let Some(local_ipc_server_frame::Payload::EmergencyStopRemoteSessionResult(result)) =
        response.payload
    else {
        panic!("expected emergency-stop result");
    };
    assert_eq!(result.terminated_session_count, 2);
    assert_eq!(fixture.service.active_session_count(), 0);
    assert_eq!(list_grants(&fixture.service).len(), 1);
    for _ in 0..2 {
        let event = events.try_recv().expect("termination event");
        assert_eq!(
            event.reason,
            roammand_protocol::roammand::v1::ErrorCode::LocalEmergencyStop as i32
        );
    }

    let repeated = fixture.service.handle_frame(&request, 201);
    let Some(local_ipc_server_frame::Payload::EmergencyStopRemoteSessionResult(result)) =
        repeated.payload
    else {
        panic!("expected idempotent emergency-stop result");
    };
    assert_eq!(result.terminated_session_count, 0);
    assert_eq!(list_grants(&fixture.service).len(), 1);
}

struct Fixture {
    service: HostService,
    store: Arc<MemoryGrantStore>,
    controller: DeviceIdentity,
    other_controller: DeviceIdentity,
    grant_id: Vec<u8>,
}

fn fixture() -> Fixture {
    let identity =
        HostIdentity::load_or_create(&MemorySecretStore::new(), "Host", DevicePlatform::Macos)
            .expect("identity must load");
    let store = Arc::new(MemoryGrantStore::new());
    let mut registry =
        AuthorizationRegistry::load(identity.device_identity().device_id.clone(), store.clone())
            .expect("registry must load");
    let controller = make_controller(0x71);
    let other_controller = make_controller(0x72);
    let grant = registry
        .create_controller_grant(controller.clone(), &[SessionPermission::ViewScreen], 100)
        .expect("grant must be created");
    let grant_id = grant.grant.expect("grant must exist").grant_id;
    Fixture {
        service: HostService::new(identity, registry, [0x51; 16], 10),
        store,
        controller,
        other_controller,
        grant_id,
    }
}

fn make_controller(seed_byte: u8) -> DeviceIdentity {
    let public_key = ed25519_dalek::SigningKey::from_bytes(&[seed_byte; 32])
        .verifying_key()
        .to_bytes();
    DeviceIdentity {
        device_id: derive_device_id_v1(&public_key)
            .expect("controller ID must derive")
            .to_vec(),
        public_key_algorithm: PublicKeyAlgorithm::Ed25519 as i32,
        public_key: public_key.to_vec(),
        display_name: "Controller".to_owned(),
        platform: DevicePlatform::Ios as i32,
    }
}

fn frame(request_id: &str, payload: local_ipc_client_frame::Payload) -> LocalIpcClientFrame {
    LocalIpcClientFrame {
        protocol_version: Some(ProtocolVersion { major: 1, minor: 0 }),
        request_id: request_id.to_owned(),
        payload: Some(payload),
    }
}

fn list_grants(service: &HostService) -> Vec<roammand_protocol::roammand::v1::ControllerGrantView> {
    let response = service.handle_frame(
        &frame(
            "list",
            local_ipc_client_frame::Payload::ListControllerGrants(ListControllerGrantsRequest {}),
        ),
        400,
    );
    let Some(local_ipc_server_frame::Payload::ControllerGrantList(list)) = response.payload else {
        panic!("expected grant list response");
    };
    list.grants
}
