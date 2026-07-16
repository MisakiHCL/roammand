// SPDX-License-Identifier: Apache-2.0

use prost::Message;
use roammand_protocol::{
    protocol_limits::{
        AGENT_INSTANCE_ID_BYTES, LOCAL_IPC_TOKEN_BYTES, MAX_CONTROLLER_GRANTS,
        MAX_DEVICE_NAME_UTF8_BYTES, MAX_HOST_AUTHORIZATION_SNAPSHOT_BYTES,
        MAX_LOCAL_IPC_FRAME_BYTES, MAX_POINTER_FAST_ENVELOPE_BYTES,
        MAX_PRIVILEGED_BRIDGE_FRAME_BYTES, MAX_RELIABLE_INPUT_ENVELOPE_BYTES,
        MAX_SIGNALING_ENVELOPE_BYTES,
    },
    roammand::v1::{
        AcquirePrivilegedLeaseRequest, ControllerPairingHello, DeviceIdentity, DevicePlatform,
        EncryptedPairingEnvelope, GetHostStatusRequest, GetRemoteSessionStatusRequest,
        InteractiveDesktopKind, LocalIpcClientFrame, PairingDirection, PairingIdentityRole,
        PairingMessage, PointerFastEnvelope, PrivilegedBridgeClientFrame,
        PrivilegedBridgeServerFrame, PrivilegedBridgeState, PrivilegedBridgeStatusSnapshot,
        PrivilegedCommandAccepted, PrivilegedIceTransportPolicy, PrivilegedPeerConfiguration,
        PrivilegedSessionDescriptor, ProtocolVersion, PublicKeyAlgorithm, QrPairingRendezvous,
        ReliableInputEnvelope, RemoteSessionStatusSnapshot, SessionDescriptionType,
        SessionOfferSignature, SessionPermission, SessionState, SessionStatus,
        SignPairingTranscriptRequest, SignSessionOfferRequest, SignalingEnvelope,
        StartPrivilegedPeerRequest, TrustedHostBinding, TrustedHostSnapshot,
        WebRtcSessionDescription, local_ipc_client_frame, pairing_message,
        privileged_bridge_client_frame, privileged_bridge_server_frame, signaling_envelope,
    },
    validation::{
        ValidationError, decode_and_validate_pointer_fast_envelope,
        decode_and_validate_privileged_bridge_client_frame,
        decode_and_validate_privileged_bridge_server_frame,
        decode_and_validate_reliable_input_envelope, decode_and_validate_signaling_envelope,
        validate_device_identity, validate_privileged_bridge_status_snapshot,
        validate_remote_session_status_snapshot, validate_session_status,
    },
};

#[test]
fn accepts_connected_with_a_16_byte_session_id() {
    let status = SessionStatus {
        session_id: bytes(16),
        state: SessionState::Connected as i32,
        error: None,
    };

    assert_eq!(validate_session_status(&status), Ok(()));
}

#[test]
fn generated_local_ipc_frames_and_limits_are_type_safe() {
    let frame = LocalIpcClientFrame {
        protocol_version: Some(version()),
        request_id: "status-1".to_owned(),
        payload: Some(local_ipc_client_frame::Payload::GetHostStatus(
            GetHostStatusRequest {},
        )),
    };

    assert!(matches!(
        frame.payload,
        Some(local_ipc_client_frame::Payload::GetHostStatus(_))
    ));
    assert_eq!(MAX_LOCAL_IPC_FRAME_BYTES, 65_536);
    assert_eq!(LOCAL_IPC_TOKEN_BYTES, 32);
    assert_eq!(AGENT_INSTANCE_ID_BYTES, 16);
    assert_eq!(MAX_CONTROLLER_GRANTS, 256);
    assert_eq!(MAX_HOST_AUTHORIZATION_SNAPSHOT_BYTES, 1_048_576);
}

#[test]
fn generated_remote_session_ipc_types_are_role_specific() {
    let sign_request = LocalIpcClientFrame {
        protocol_version: Some(version()),
        request_id: "sign-offer-1".to_owned(),
        payload: Some(local_ipc_client_frame::Payload::SignSessionOffer(
            SignSessionOfferRequest {
                canonical_transcript: bytes(128),
            },
        )),
    };
    let signature = SessionOfferSignature {
        controller_device_id: bytes(32),
        controller_public_key: bytes(32),
        signature: bytes(64),
        transcript_sha256: bytes(32),
    };
    let status_request = GetRemoteSessionStatusRequest {};
    let snapshot = RemoteSessionStatusSnapshot {
        session_status: Some(SessionStatus {
            state: SessionState::Idle as i32,
            ..Default::default()
        }),
        controller_device_id: Vec::new(),
    };

    assert!(matches!(
        sign_request.payload,
        Some(local_ipc_client_frame::Payload::SignSessionOffer(_))
    ));
    assert_eq!(signature.signature.len(), 64);
    assert_eq!(status_request, GetRemoteSessionStatusRequest {});
    assert_eq!(
        snapshot.session_status.expect("session status").state,
        SessionState::Idle as i32
    );
}

#[test]
fn generated_pairing_and_host_trust_types_are_role_specific() {
    let hello = ControllerPairingHello {
        rendezvous_id: bytes(16),
        identity: Some(valid_identity()),
        ephemeral_public_key: bytes(32),
        transcript_sha256: bytes(32),
        signature: bytes(64),
    };
    let envelope = EncryptedPairingEnvelope {
        direction: PairingDirection::ControllerToHost as i32,
        sequence: 1,
        ciphertext: bytes(48),
        ..Default::default()
    };
    let request = LocalIpcClientFrame {
        protocol_version: Some(version()),
        request_id: "pairing-sign-1".to_owned(),
        payload: Some(local_ipc_client_frame::Payload::SignPairingTranscript(
            SignPairingTranscriptRequest {
                canonical_transcript: bytes(256),
                role: PairingIdentityRole::Controller as i32,
            },
        )),
    };
    let snapshot = TrustedHostSnapshot {
        protocol_version: Some(version()),
        bindings: vec![TrustedHostBinding::default()],
    };

    assert_eq!(hello.signature.len(), 64);
    assert_eq!(envelope.sequence, 1);
    assert!(matches!(
        request.payload,
        Some(local_ipc_client_frame::Payload::SignPairingTranscript(_))
    ));
    assert_eq!(snapshot.bindings.len(), 1);
}

#[test]
fn validates_remote_session_status_peer_binding() {
    let idle = RemoteSessionStatusSnapshot {
        session_status: Some(SessionStatus {
            state: SessionState::Idle as i32,
            ..Default::default()
        }),
        controller_device_id: Vec::new(),
    };
    let connected = RemoteSessionStatusSnapshot {
        session_status: Some(SessionStatus {
            session_id: bytes(16),
            state: SessionState::Connected as i32,
            error: None,
        }),
        controller_device_id: bytes(32),
    };

    assert_eq!(validate_remote_session_status_snapshot(&idle), Ok(()));
    assert_eq!(
        validate_remote_session_status_snapshot(&RemoteSessionStatusSnapshot {
            controller_device_id: bytes(32),
            ..idle
        }),
        Err(ValidationError::InvalidState)
    );
    assert_eq!(
        validate_remote_session_status_snapshot(&RemoteSessionStatusSnapshot {
            controller_device_id: bytes(31),
            ..connected
        }),
        Err(ValidationError::InvalidLength)
    );
}

#[test]
fn rejects_unknown_numeric_session_state() {
    let status = SessionStatus {
        session_id: bytes(16),
        state: 99,
        error: None,
    };

    assert_eq!(
        validate_session_status(&status),
        Err(ValidationError::InvalidEnum)
    );
}

#[test]
fn rejects_failed_without_unified_error() {
    let status = SessionStatus {
        session_id: bytes(16),
        state: SessionState::Failed as i32,
        error: None,
    };

    assert_eq!(
        validate_session_status(&status),
        Err(ValidationError::InvalidState)
    );
}

#[test]
fn rejects_active_state_without_a_16_byte_session_id() {
    let status = SessionStatus {
        state: SessionState::Connecting as i32,
        ..Default::default()
    };

    assert_eq!(
        validate_session_status(&status),
        Err(ValidationError::InvalidLength)
    );
}

#[test]
fn rejects_oversized_signaling_before_decoding() {
    assert_eq!(
        decode_and_validate_signaling_envelope(&vec![0; MAX_SIGNALING_ENVELOPE_BYTES + 1]),
        Err(ValidationError::MessageTooLarge)
    );
}

#[test]
fn rejects_a_129_byte_device_display_name() {
    let mut identity = valid_identity();
    identity.display_name = "x".repeat(129);

    assert_eq!(
        validate_device_identity(&identity),
        Err(ValidationError::InvalidUtf8Length)
    );
}

#[test]
fn rejects_qr_rendezvous_lifetime_above_two_minutes() {
    let envelope = SignalingEnvelope {
        payload: Some(signaling_envelope::Payload::Pairing(PairingMessage {
            payload: Some(pairing_message::Payload::QrRendezvous(
                QrPairingRendezvous {
                    rendezvous_id: bytes(16),
                    host_identity: Some(valid_identity()),
                    host_public_key_fingerprint_sha256: bytes(32),
                    host_ephemeral_public_key: bytes(32),
                    signaling_endpoint: "wss://signal.example.test".to_owned(),
                    issued_at_unix_ms: 1_000,
                    expires_at_unix_ms: 121_001,
                },
            )),
        })),
        ..valid_signaling_envelope()
    };

    assert_eq!(
        decode_and_validate_signaling_envelope(&envelope.encode_to_vec()),
        Err(ValidationError::InvalidLifetime)
    );
}

#[test]
fn rejects_oversized_reliable_input_before_decoding() {
    assert_eq!(
        decode_and_validate_reliable_input_envelope(&vec![
            0;
            MAX_RELIABLE_INPUT_ENVELOPE_BYTES + 1
        ]),
        Err(ValidationError::MessageTooLarge)
    );
}

#[test]
fn rejects_oversized_pointer_fast_input_before_decoding() {
    assert_eq!(
        decode_and_validate_pointer_fast_envelope(&vec![0; MAX_POINTER_FAST_ENVELOPE_BYTES + 1]),
        Err(ValidationError::MessageTooLarge)
    );
}

#[test]
fn rejects_signaling_and_input_envelopes_without_oneof_payloads() {
    let signaling = valid_signaling_envelope().encode_to_vec();
    let reliable = ReliableInputEnvelope {
        protocol_version: Some(version()),
        session_id: bytes(16),
        ..Default::default()
    }
    .encode_to_vec();
    let pointer_fast = PointerFastEnvelope {
        protocol_version: Some(version()),
        session_id: bytes(16),
        ..Default::default()
    }
    .encode_to_vec();

    assert_eq!(
        decode_and_validate_signaling_envelope(&signaling),
        Err(ValidationError::MissingPayload)
    );
    assert_eq!(
        decode_and_validate_reliable_input_envelope(&reliable),
        Err(ValidationError::MissingPayload)
    );
    assert_eq!(
        decode_and_validate_pointer_fast_envelope(&pointer_fast),
        Err(ValidationError::MissingPayload)
    );
}

#[test]
fn accepts_a_controlled_privileged_bridge_status() {
    let status = PrivilegedBridgeStatusSnapshot {
        state: PrivilegedBridgeState::Controlled as i32,
        interactive_session: Some(valid_privileged_session()),
        helper_connected: true,
        active_controller_display_name: "My phone".to_owned(),
        error: None,
    };

    assert_eq!(validate_privileged_bridge_status_snapshot(&status), Ok(()));
}

#[test]
fn rejects_contradictory_or_unknown_privileged_bridge_status() {
    let ready_without_helper = PrivilegedBridgeStatusSnapshot {
        state: PrivilegedBridgeState::Ready as i32,
        interactive_session: Some(valid_privileged_session()),
        ..Default::default()
    };
    let unknown = PrivilegedBridgeStatusSnapshot {
        state: 99,
        ..Default::default()
    };

    assert_eq!(
        validate_privileged_bridge_status_snapshot(&ready_without_helper),
        Err(ValidationError::InvalidState)
    );
    assert_eq!(
        validate_privileged_bridge_status_snapshot(&unknown),
        Err(ValidationError::InvalidEnum)
    );
}

#[test]
fn rejects_oversized_or_unsequenced_privileged_bridge_frames() {
    assert_eq!(
        decode_and_validate_privileged_bridge_client_frame(&vec![
            0;
            MAX_PRIVILEGED_BRIDGE_FRAME_BYTES
                + 1
        ]),
        Err(ValidationError::MessageTooLarge)
    );

    let frame = PrivilegedBridgeClientFrame {
        protocol_version: Some(version()),
        request_id: "lease-1".to_owned(),
        sequence: 0,
        payload: Some(privileged_bridge_client_frame::Payload::AcquireLease(
            AcquirePrivilegedLeaseRequest {
                session_id: bytes(16),
                generation: 1,
                permissions: vec![SessionPermission::ViewScreen as i32],
                controller_display_name: "My phone".to_owned(),
            },
        )),
    };

    assert_eq!(
        decode_and_validate_privileged_bridge_client_frame(&frame.encode_to_vec()),
        Err(ValidationError::InvalidState)
    );
}

#[test]
fn privileged_peer_start_requires_a_bounded_controller_name() {
    let mut frame = PrivilegedBridgeClientFrame {
        protocol_version: Some(version()),
        request_id: "start-1".to_owned(),
        sequence: 1,
        payload: Some(privileged_bridge_client_frame::Payload::StartPeer(
            StartPrivilegedPeerRequest {
                lease_id: bytes(16),
                generation: 1,
                configuration: Some(PrivilegedPeerConfiguration {
                    ice_transport_policy: PrivilegedIceTransportPolicy::All as i32,
                    ice_servers: Vec::new(),
                }),
                offer: Some(WebRtcSessionDescription {
                    r#type: SessionDescriptionType::Offer as i32,
                    sdp: "offer".to_owned(),
                    dtls_fingerprint_sha256: bytes(32),
                }),
                controller_display_name: "Controller".to_owned(),
            },
        )),
    };
    assert!(decode_and_validate_privileged_bridge_client_frame(&frame.encode_to_vec()).is_ok());
    match frame.payload.as_mut() {
        Some(privileged_bridge_client_frame::Payload::StartPeer(start)) => {
            start.controller_display_name.clear();
        }
        _ => panic!("start payload"),
    }
    assert_eq!(
        decode_and_validate_privileged_bridge_client_frame(&frame.encode_to_vec()),
        Err(ValidationError::InvalidLength)
    );
    match frame.payload.as_mut() {
        Some(privileged_bridge_client_frame::Payload::StartPeer(start)) => {
            start.controller_display_name = "x".repeat(MAX_DEVICE_NAME_UTF8_BYTES + 1);
        }
        _ => panic!("start payload"),
    }
    assert_eq!(
        decode_and_validate_privileged_bridge_client_frame(&frame.encode_to_vec()),
        Err(ValidationError::InvalidUtf8Length)
    );
}

#[test]
fn validates_route_bound_privileged_command_acknowledgements() {
    let valid = PrivilegedBridgeServerFrame {
        protocol_version: Some(version()),
        request_id: "command-7".to_owned(),
        sequence: 7,
        payload: Some(privileged_bridge_server_frame::Payload::CommandAccepted(
            PrivilegedCommandAccepted {
                lease_id: bytes(16),
                generation: 3,
            },
        )),
    };
    assert_eq!(
        decode_and_validate_privileged_bridge_server_frame(&valid.encode_to_vec()),
        Ok(valid)
    );

    let stale = PrivilegedBridgeServerFrame {
        protocol_version: Some(version()),
        request_id: "command-8".to_owned(),
        sequence: 8,
        payload: Some(privileged_bridge_server_frame::Payload::CommandAccepted(
            PrivilegedCommandAccepted {
                lease_id: bytes(15),
                generation: 3,
            },
        )),
    };
    assert_eq!(
        decode_and_validate_privileged_bridge_server_frame(&stale.encode_to_vec()),
        Err(ValidationError::InvalidLength)
    );
}

const fn version() -> ProtocolVersion {
    ProtocolVersion { major: 1, minor: 0 }
}

fn valid_identity() -> DeviceIdentity {
    DeviceIdentity {
        device_id: bytes(32),
        public_key_algorithm: PublicKeyAlgorithm::Ed25519 as i32,
        public_key: bytes(32),
        display_name: "Host".to_owned(),
        platform: DevicePlatform::Macos as i32,
    }
}

fn valid_signaling_envelope() -> SignalingEnvelope {
    SignalingEnvelope {
        protocol_version: Some(version()),
        sender_device_id: bytes(32),
        recipient_device_id: bytes(32),
        request_id: "request-1".to_owned(),
        ..Default::default()
    }
}

fn valid_privileged_session() -> PrivilegedSessionDescriptor {
    PrivilegedSessionDescriptor {
        platform: DevicePlatform::Macos as i32,
        os_session_id: 501,
        desktop_kind: InteractiveDesktopKind::Normal as i32,
        generation: 1,
    }
}

fn bytes(length: usize) -> Vec<u8> {
    vec![0x11; length]
}
