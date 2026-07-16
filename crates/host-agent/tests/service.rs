// SPDX-License-Identifier: MPL-2.0

use std::sync::Arc;

use prost::Message;
use roammand_host_agent::{
    AuthorizationRegistry, BridgeStatusError, HostIdentity, HostService, MemoryGrantStore,
};
use roammand_host_platform::{MemorySecretStore, ProtectedSecretStore};
use roammand_protocol::{
    canonical_transcript::{CanonicalTranscript, TranscriptField, TranscriptPurpose, encode},
    roammand::v1::{
        CancelHostPairingRequest, CreateControllerGrantRequest, DeviceIdentity, DevicePlatform,
        GetHostPairingStatusRequest, GetHostStatusRequest, HostPairingState,
        InteractiveDesktopKind, ListControllerGrantsRequest, LocalIpcAuthenticate,
        LocalIpcClientFrame, PairingIdentityRole, PrivilegedBridgeState,
        PrivilegedBridgeStatusSnapshot, PrivilegedSessionDescriptor, ProtocolVersion,
        PublicKeyAlgorithm, SessionPermission, SignCanonicalTranscriptRequest,
        SignPairingTranscriptRequest, SignSessionOfferRequest, StartHostDesktopCodePairingRequest,
        StartHostQrPairingRequest, local_ipc_client_frame, local_ipc_server_frame,
    },
};

const HOST_SEED: [u8; 32] = [0x42; 32];
const INSTANCE_ID: [u8; 16] = [0x51; 16];

#[test]
fn maps_status_create_list_and_restricted_signing_dtos() {
    let service = service();
    let host = assert_default_host_status(&service);

    let controller = controller();
    let created = service.handle_frame(
        &frame(
            "create-1",
            local_ipc_client_frame::Payload::CreateControllerGrant(CreateControllerGrantRequest {
                controller: Some(controller.clone()),
                permissions: vec![SessionPermission::ViewScreen as i32],
            }),
        ),
        200,
    );
    assert!(matches!(
        created.payload,
        Some(local_ipc_server_frame::Payload::ControllerGrantCreated(_))
    ));

    let listed = service.handle_frame(
        &frame(
            "list-1",
            local_ipc_client_frame::Payload::ListControllerGrants(ListControllerGrantsRequest {}),
        ),
        300,
    );
    let local_ipc_server_frame::Payload::ControllerGrantList(list) =
        listed.payload.expect("list response must have payload")
    else {
        panic!("expected ControllerGrantList response");
    };
    assert_eq!(list.grants.len(), 1);
    assert_eq!(
        list.grants[0]
            .grant
            .as_ref()
            .and_then(|grant| grant.controller.as_ref()),
        Some(&controller)
    );

    let transcript = session_answer(&host.device_id);
    let signed = service.handle_frame(
        &frame(
            "sign-1",
            local_ipc_client_frame::Payload::SignCanonicalTranscript(
                SignCanonicalTranscriptRequest {
                    canonical_transcript: transcript.clone(),
                },
            ),
        ),
        400,
    );
    let local_ipc_server_frame::Payload::CanonicalTranscriptSignature(signature) =
        signed.payload.expect("sign response must have payload")
    else {
        panic!("expected CanonicalTranscriptSignature response");
    };
    assert_eq!(signature.host_device_id, host.device_id);
    assert_eq!(signature.host_public_key, host.public_key);
    assert_eq!(signature.signature.len(), 64);
    assert!(
        !signature
            .encode_to_vec()
            .windows(HOST_SEED.len())
            .any(|window| window == HOST_SEED)
    );

    let offer = session_offer(&host.device_id, &[0x71; 32]);
    let offer_signed = service.handle_frame(
        &frame(
            "sign-offer-1",
            local_ipc_client_frame::Payload::SignSessionOffer(SignSessionOfferRequest {
                canonical_transcript: offer,
            }),
        ),
        500,
    );
    let local_ipc_server_frame::Payload::SessionOfferSignature(signature) = offer_signed
        .payload
        .expect("offer signature response must have payload")
    else {
        panic!("expected SessionOfferSignature response");
    };
    assert_eq!(signature.controller_device_id, host.device_id);
    assert_eq!(signature.controller_public_key, host.public_key);
    assert_eq!(signature.signature.len(), 64);
}

fn assert_default_host_status(service: &HostService) -> DeviceIdentity {
    let status = service.handle_frame(
        &frame(
            "status-1",
            local_ipc_client_frame::Payload::GetHostStatus(GetHostStatusRequest {}),
        ),
        100,
    );
    let local_ipc_server_frame::Payload::HostStatus(status) =
        status.payload.expect("status response must have payload")
    else {
        panic!("expected HostStatus response");
    };
    assert_eq!(status.agent_instance_id, INSTANCE_ID);
    assert_eq!(status.agent_started_at_unix_ms, 10);
    assert_eq!(status.controller_grant_count, 0);
    assert_eq!(
        status
            .privileged_bridge
            .as_ref()
            .expect("bridge status")
            .state,
        PrivilegedBridgeState::UserSessionOnly as i32
    );
    status
        .identity
        .expect("status must contain public identity")
}

#[test]
fn publishes_monotonic_sanitized_privileged_bridge_status() {
    let service = service();
    let controller = controller();
    service
        .create_controller_grant_for_maintenance(
            controller.clone(),
            &[
                SessionPermission::ViewScreen,
                SessionPermission::ControlInput,
            ],
            100,
        )
        .expect("grant");
    let bridge_snapshot = PrivilegedBridgeStatusSnapshot {
        state: PrivilegedBridgeState::Controlled as i32,
        interactive_session: Some(privileged_session(2)),
        helper_connected: true,
        active_controller_display_name: String::new(),
        error: None,
    };
    service
        .update_privileged_bridge_status(bridge_snapshot, Some(&controller.device_id))
        .expect("controlled status");

    let response = service.handle_frame(
        &frame(
            "status-controlled",
            local_ipc_client_frame::Payload::GetHostStatus(GetHostStatusRequest {}),
        ),
        200,
    );
    let Some(local_ipc_server_frame::Payload::HostStatus(status)) = response.payload else {
        panic!("expected host status");
    };
    let bridge = status.privileged_bridge.expect("bridge status");
    assert_eq!(bridge.active_controller_display_name, "Controller");
    let encoded = bridge.encode_to_vec();
    assert!(!String::from_utf8_lossy(&encoded).contains("/Users/"));

    assert_eq!(
        service.update_privileged_bridge_status(
            PrivilegedBridgeStatusSnapshot {
                state: PrivilegedBridgeState::Ready as i32,
                interactive_session: Some(privileged_session(1)),
                helper_connected: true,
                ..Default::default()
            },
            None,
        ),
        Err(BridgeStatusError::StaleGeneration)
    );
}

#[test]
fn maps_role_bound_pairing_signature_dto() {
    let service = service();
    let host = service.device_identity().clone();
    let pairing = pairing_transcript(&host.device_id, &[0x72; 32]);
    let pairing_signed = service.handle_frame(
        &frame(
            "sign-pairing-1",
            local_ipc_client_frame::Payload::SignPairingTranscript(SignPairingTranscriptRequest {
                canonical_transcript: pairing,
                role: PairingIdentityRole::Controller as i32,
            }),
        ),
        600,
    );
    let local_ipc_server_frame::Payload::PairingTranscriptSignature(signature) = pairing_signed
        .payload
        .expect("pairing signature response must have payload")
    else {
        panic!("expected PairingTranscriptSignature response");
    };
    assert_eq!(signature.role, PairingIdentityRole::Controller as i32);
    assert_eq!(signature.signer_device_id, host.device_id);
    assert_eq!(signature.signer_public_key, host.public_key);
    assert_eq!(signature.signature.len(), 64);
}

#[test]
fn maps_pairing_start_status_stale_cancel_and_retry_with_monotonic_events() {
    let service = service();
    service
        .pairing_signaling_connected()
        .expect("test signaling must connect");
    let mut events = service.subscribe_host_pairing_states();
    let started = service.handle_frame(
        &frame(
            "start-qr",
            local_ipc_client_frame::Payload::StartHostQrPairing(StartHostQrPairingRequest {
                signaling_endpoint: "wss://signal.example.test/v1/ws".to_owned(),
            }),
        ),
        1_000,
    );
    let started = pairing_status(started);
    assert_eq!(started.state, HostPairingState::Creating as i32);
    let invitation = started.invitation.as_ref().expect("QR invitation");
    assert_eq!(invitation.expires_at_unix_ms, 121_000);
    assert!(invitation.pairing_code.is_empty());
    let event = events.try_recv().expect("start event must publish");
    assert_eq!(event.revision, started.revision);

    let refreshed = service.handle_frame(
        &frame(
            "get-pairing",
            local_ipc_client_frame::Payload::GetHostPairingStatus(GetHostPairingStatusRequest {}),
        ),
        1_001,
    );
    assert_eq!(pairing_status(refreshed).revision, started.revision);

    let stale_cancel = service.handle_frame(
        &frame(
            "stale-cancel",
            local_ipc_client_frame::Payload::CancelHostPairing(CancelHostPairingRequest {
                rendezvous_id: vec![0x99; 16],
            }),
        ),
        1_002,
    );
    assert_error(&stale_cancel, "stale-cancel");

    let cancelled = service.handle_frame(
        &frame(
            "cancel-pairing",
            local_ipc_client_frame::Payload::CancelHostPairing(CancelHostPairingRequest {
                rendezvous_id: invitation.rendezvous_id.clone(),
            }),
        ),
        1_003,
    );
    let cancelled = pairing_status(cancelled);
    assert_eq!(cancelled.state, HostPairingState::Cancelled as i32);
    assert!(cancelled.revision > started.revision);

    let retried = service.handle_frame(
        &frame(
            "start-code",
            local_ipc_client_frame::Payload::StartHostDesktopCodePairing(
                StartHostDesktopCodePairingRequest {
                    signaling_endpoint: "wss://signal.example.test/v1/ws".to_owned(),
                },
            ),
        ),
        2_000,
    );
    let retried = pairing_status(retried);
    assert_eq!(retried.state, HostPairingState::Creating as i32);
    assert!(retried.revision > cancelled.revision);
    assert_eq!(
        retried
            .invitation
            .as_ref()
            .expect("desktop invitation")
            .pairing_code
            .len(),
        8
    );
}

#[test]
fn rejects_illegal_enums_arbitrary_signing_and_auth_payload_as_unified_errors() {
    let service = service();
    let invalid_permissions = service.handle_frame(
        &frame(
            "bad-permissions",
            local_ipc_client_frame::Payload::CreateControllerGrant(CreateControllerGrantRequest {
                controller: Some(controller()),
                permissions: vec![99],
            }),
        ),
        100,
    );
    assert_error(&invalid_permissions, "bad-permissions");

    let arbitrary_sign = service.handle_frame(
        &frame(
            "bad-sign",
            local_ipc_client_frame::Payload::SignCanonicalTranscript(
                SignCanonicalTranscriptRequest {
                    canonical_transcript: b"arbitrary bytes".to_vec(),
                },
            ),
        ),
        100,
    );
    assert_error(&arbitrary_sign, "bad-sign");

    let invalid_pairing_role = service.handle_frame(
        &frame(
            "bad-pairing-role",
            local_ipc_client_frame::Payload::SignPairingTranscript(SignPairingTranscriptRequest {
                canonical_transcript: pairing_transcript(&[0x61; 32], &[0x62; 32]),
                role: 99,
            }),
        ),
        100,
    );
    assert_error(&invalid_pairing_role, "bad-pairing-role");

    let authenticate = service.handle_frame(
        &frame(
            "auth-again",
            local_ipc_client_frame::Payload::Authenticate(LocalIpcAuthenticate::default()),
        ),
        100,
    );
    assert_error(&authenticate, "auth-again");
}

#[test]
fn error_responses_do_not_expose_seed_path_or_internal_error_text() {
    let service = service();
    let response = service.handle_frame(
        &frame(
            "bad-sign",
            local_ipc_client_frame::Payload::SignCanonicalTranscript(
                SignCanonicalTranscriptRequest {
                    canonical_transcript: vec![0x42; 4097],
                },
            ),
        ),
        100,
    );
    let encoded = response.encode_to_vec();
    assert!(
        !encoded
            .windows(HOST_SEED.len())
            .any(|window| window == HOST_SEED)
    );
    let debug = format!("{response:?}");
    assert!(!debug.contains(env!("CARGO_MANIFEST_DIR")));
    assert!(!debug.contains("InvalidTranscript"));
    assert!(!debug.contains("private"));
}

fn service() -> HostService {
    let secret_store = MemorySecretStore::new();
    secret_store
        .store(&HOST_SEED)
        .expect("test seed must be stored");
    let identity = HostIdentity::load_or_create(&secret_store, "Host", DevicePlatform::Macos)
        .expect("identity must load");
    let registry = AuthorizationRegistry::load(
        identity.device_identity().device_id.clone(),
        Arc::new(MemoryGrantStore::new()),
    )
    .expect("registry must load");
    HostService::new(identity, registry, INSTANCE_ID, 10)
}

fn frame(request_id: &str, payload: local_ipc_client_frame::Payload) -> LocalIpcClientFrame {
    LocalIpcClientFrame {
        protocol_version: Some(ProtocolVersion { major: 1, minor: 0 }),
        request_id: request_id.to_owned(),
        payload: Some(payload),
    }
}

fn controller() -> DeviceIdentity {
    let public_key = ed25519_dalek::SigningKey::from_bytes(&[0x61; 32])
        .verifying_key()
        .to_bytes();
    DeviceIdentity {
        device_id: roammand_protocol::identity_derivation::derive_device_id_v1(&public_key)
            .expect("controller ID must derive")
            .to_vec(),
        public_key_algorithm: PublicKeyAlgorithm::Ed25519 as i32,
        public_key: public_key.to_vec(),
        display_name: "Controller".to_owned(),
        platform: DevicePlatform::Ios as i32,
    }
}

fn privileged_session(generation: u64) -> PrivilegedSessionDescriptor {
    PrivilegedSessionDescriptor {
        platform: DevicePlatform::Macos as i32,
        os_session_id: 501,
        desktop_kind: InteractiveDesktopKind::Normal as i32,
        generation,
    }
}

fn session_answer(host_device_id: &[u8]) -> Vec<u8> {
    let tags = [1_u16, 2, 8, 9, 10, 11, 12, 13, 14, 15, 16];
    let fields = tags
        .into_iter()
        .map(|tag| TranscriptField {
            tag,
            value: if tag == 2 {
                host_device_id.to_vec()
            } else {
                vec![u8::try_from(tag).expect("tag fits"); field_length(tag)]
            },
        })
        .collect();
    encode(&CanonicalTranscript {
        purpose: TranscriptPurpose::SessionAnswer,
        fields,
    })
    .expect("answer transcript must encode")
}

fn session_offer(controller_device_id: &[u8], host_device_id: &[u8]) -> Vec<u8> {
    let tags = [1_u16, 2, 8, 9, 10, 11, 12, 13, 14];
    let fields = tags
        .into_iter()
        .map(|tag| TranscriptField {
            tag,
            value: match tag {
                1 => controller_device_id.to_vec(),
                2 => host_device_id.to_vec(),
                _ => vec![u8::try_from(tag).expect("tag fits"); field_length(tag)],
            },
        })
        .collect();
    encode(&CanonicalTranscript {
        purpose: TranscriptPurpose::SessionOffer,
        fields,
    })
    .expect("offer transcript must encode")
}

fn pairing_transcript(controller_device_id: &[u8], host_device_id: &[u8]) -> Vec<u8> {
    let tags = [1_u16, 2, 3, 4, 5, 6, 7];
    let fields = tags
        .into_iter()
        .map(|tag| TranscriptField {
            tag,
            value: match tag {
                1 => controller_device_id.to_vec(),
                2 => host_device_id.to_vec(),
                _ => vec![u8::try_from(tag).expect("tag fits"); field_length(tag)],
            },
        })
        .collect();
    encode(&CanonicalTranscript {
        purpose: TranscriptPurpose::PairingSas,
        fields,
    })
    .expect("pairing transcript must encode")
}

const fn field_length(tag: u16) -> usize {
    match tag {
        3 | 8 => 16,
        10 | 11 => 8,
        12 => 4,
        _ => 32,
    }
}

fn assert_error(response: &roammand_protocol::roammand::v1::LocalIpcServerFrame, request_id: &str) {
    let Some(local_ipc_server_frame::Payload::Error(error)) = response.payload.as_ref() else {
        panic!("expected UnifiedError response");
    };
    assert_eq!(response.request_id, request_id);
    assert_eq!(error.request_id, request_id);
    assert!(!error.message_key.is_empty());
}

fn pairing_status(
    response: roammand_protocol::roammand::v1::LocalIpcServerFrame,
) -> roammand_protocol::roammand::v1::HostPairingStatusSnapshot {
    let Some(local_ipc_server_frame::Payload::HostPairingStatus(status)) = response.payload else {
        panic!("expected HostPairingStatus response");
    };
    status
}
