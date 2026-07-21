// SPDX-License-Identifier: MPL-2.0

use std::time::Duration;

use futures_util::SinkExt;
use prost::Message;
use roammand_host_agent::{
    SignalingClientError, SignalingEvent, SignalingOutbox, SignalingProtocol,
    WebSocketSignalingTransport, validate_signaling_endpoint,
};
use roammand_protocol::{
    protocol_limits::{MAX_OPAQUE_SIGNALING_ENVELOPE_BYTES, MAX_SIGNALING_SERVICE_FRAME_BYTES},
    roammand::v1::{
        ErrorCode, HeartbeatAcknowledged, PairingRendezvousClosed, PairingRendezvousCompletion,
        PairingRendezvousCreated, PairingRendezvousJoined, PairingRendezvousKind, ProtocolVersion,
        RegistrationAccepted, RoutedPairingEnvelope, RoutedSessionEnvelope, SignalingServerFrame,
        UnifiedError, signaling_client_frame, signaling_server_frame,
    },
};
use tokio::{io::AsyncWriteExt, net::TcpListener, time::timeout};
use tokio_tungstenite::{
    accept_hdr_async,
    tungstenite::{
        Message as WebSocketMessage,
        handshake::server::{ErrorResponse, Request, Response},
        http::{HeaderValue, header::SEC_WEBSOCKET_PROTOCOL},
        protocol::frame::{
            Frame,
            coding::{Data as WebSocketData, OpCode},
        },
    },
};

const DEVICE_ID: [u8; 32] = [0x31; 32];
const PEER_ID: [u8; 32] = [0x41; 32];
const RENDEZVOUS_ID: [u8; 16] = [0x51; 16];
const TRANSPORT_TEST_TIMEOUT: Duration = Duration::from_secs(2);
const SIGNALING_WEBSOCKET_SUBPROTOCOL: &str = "roammand-signaling.v1.protobuf";
const WEBSOCKET_FINAL_BINARY_FRAME: u8 = 0x82;
const WEBSOCKET_64_BIT_PAYLOAD_LENGTH: u8 = 0x7f;

#[test]
fn registers_relays_heartbeats_and_routes_only_binary_protobuf() {
    let mut protocol = SignalingProtocol::new(DEVICE_ID.to_vec()).expect("device ID must be valid");
    let registration = protocol
        .registration("register-1")
        .expect("registration must encode");
    let Some(signaling_client_frame::Payload::Register(register)) = registration.payload else {
        panic!("expected registration payload");
    };
    assert_eq!(register.device_id, DEVICE_ID);

    let registered = server_frame(
        "register-1",
        signaling_server_frame::Payload::Registered(RegistrationAccepted {
            device_id: DEVICE_ID.to_vec(),
            presence_expires_at_unix_ms: 2_000,
        }),
    );
    assert_eq!(
        protocol
            .handle_binary(&registered.encode_to_vec())
            .expect("registration response must decode"),
        SignalingEvent::Registered {
            presence_expires_at_unix_ms: 2_000
        }
    );

    let relayed = protocol
        .relay_session(PEER_ID.to_vec(), vec![0x51; 128], "relay-1")
        .expect("ready client must relay");
    let Some(signaling_client_frame::Payload::RelaySession(relay)) = relayed.payload else {
        panic!("expected relay payload");
    };
    assert_eq!(relay.recipient_device_id, PEER_ID);
    assert_eq!(relay.opaque_envelope.len(), 128);
    assert!(protocol.heartbeat("heartbeat-1").is_ok());
    assert_eq!(
        protocol.heartbeat("heartbeat-while-pending"),
        Err(SignalingClientError::InvalidState)
    );

    let routed = server_frame(
        "",
        signaling_server_frame::Payload::RoutedSession(RoutedSessionEnvelope {
            sender_device_id: PEER_ID.to_vec(),
            opaque_envelope: vec![0x61; 64],
        }),
    );
    assert_eq!(
        protocol
            .handle_binary(&routed.encode_to_vec())
            .expect("routed session must decode"),
        SignalingEvent::RoutedSession {
            sender_device_id: PEER_ID.to_vec(),
            opaque_envelope: vec![0x61; 64],
        }
    );

    let heartbeat = server_frame(
        "heartbeat-1",
        signaling_server_frame::Payload::HeartbeatAcknowledged(HeartbeatAcknowledged {
            server_time_unix_ms: 2_100,
            presence_expires_at_unix_ms: 3_000,
        }),
    );
    assert!(matches!(
        protocol.handle_binary(&heartbeat.encode_to_vec()),
        Ok(SignalingEvent::HeartbeatAcknowledged { .. })
    ));
    assert!(protocol.heartbeat("heartbeat-2").is_ok());
}

#[test]
fn heartbeat_acknowledgements_must_correlate_and_are_single_flight() {
    let mut protocol = ready_protocol();
    protocol.heartbeat("heartbeat-1").expect("first heartbeat");

    let stale = server_frame(
        "heartbeat-stale",
        signaling_server_frame::Payload::HeartbeatAcknowledged(HeartbeatAcknowledged {
            server_time_unix_ms: 2_100,
            presence_expires_at_unix_ms: 3_000,
        }),
    );
    assert_eq!(
        protocol.handle_binary(&stale.encode_to_vec()),
        Err(SignalingClientError::CorrelationMismatch)
    );
    assert_eq!(
        protocol.heartbeat("heartbeat-2"),
        Err(SignalingClientError::InvalidState)
    );

    let correlated = server_frame(
        "heartbeat-1",
        signaling_server_frame::Payload::HeartbeatAcknowledged(HeartbeatAcknowledged {
            server_time_unix_ms: 2_200,
            presence_expires_at_unix_ms: 3_100,
        }),
    );
    assert!(matches!(
        protocol.handle_binary(&correlated.encode_to_vec()),
        Ok(SignalingEvent::HeartbeatAcknowledged { .. })
    ));
    assert!(protocol.heartbeat("heartbeat-2").is_ok());
}

#[test]
fn heartbeat_acknowledgements_reject_invalid_time_windows_fail_closed() {
    let mut protocol = ready_protocol();
    protocol.heartbeat("heartbeat-1").expect("first heartbeat");

    for (server_time_unix_ms, presence_expires_at_unix_ms) in
        [(0, 3_000), (2_100, 2_100), (2_100, 2_099)]
    {
        let invalid = server_frame(
            "heartbeat-1",
            signaling_server_frame::Payload::HeartbeatAcknowledged(HeartbeatAcknowledged {
                server_time_unix_ms,
                presence_expires_at_unix_ms,
            }),
        );
        assert_eq!(
            protocol.handle_binary(&invalid.encode_to_vec()),
            Err(SignalingClientError::InvalidFrame)
        );
        assert_eq!(
            protocol.heartbeat("heartbeat-while-invalid-ack-pending"),
            Err(SignalingClientError::InvalidState)
        );
    }

    let valid = server_frame(
        "heartbeat-1",
        signaling_server_frame::Payload::HeartbeatAcknowledged(HeartbeatAcknowledged {
            server_time_unix_ms: 2_100,
            presence_expires_at_unix_ms: 3_000,
        }),
    );
    assert!(matches!(
        protocol.handle_binary(&valid.encode_to_vec()),
        Ok(SignalingEvent::HeartbeatAcknowledged { .. })
    ));
    assert!(protocol.heartbeat("heartbeat-2").is_ok());
}

#[tokio::test]
async fn websocket_transport_rejects_oversized_frame_from_header() {
    let (listener, endpoint) = loopback_signaling_listener().await;
    let server = tokio::spawn(async move {
        let (stream, _) = listener.accept().await.expect("connection must arrive");
        let mut socket = accept_hdr_async(stream, select_signaling_subprotocol)
            .await
            .expect("WebSocket handshake must complete");
        let declared_payload_bytes =
            u64::try_from(MAX_SIGNALING_SERVICE_FRAME_BYTES + 1).expect("protocol cap fits u64");
        let mut frame_header = [0_u8; 10];
        frame_header[0] = WEBSOCKET_FINAL_BINARY_FRAME;
        frame_header[1] = WEBSOCKET_64_BIT_PAYLOAD_LENGTH;
        frame_header[2..].copy_from_slice(&declared_payload_bytes.to_be_bytes());
        socket
            .get_mut()
            .write_all(&frame_header)
            .await
            .expect("oversized frame header must be sent");
    });

    let mut transport = timeout(
        TRANSPORT_TEST_TIMEOUT,
        WebSocketSignalingTransport::connect(&endpoint),
    )
    .await
    .expect("client connection must not time out")
    .expect("client connection must succeed");
    assert_eq!(
        timeout(TRANSPORT_TEST_TIMEOUT, transport.receive_binary())
            .await
            .expect("frame rejection must not wait for its payload"),
        Err(SignalingClientError::FrameTooLarge)
    );
    timeout(TRANSPORT_TEST_TIMEOUT, server)
        .await
        .expect("server must stop")
        .expect("server task must succeed");
}

#[tokio::test]
async fn websocket_transport_rejects_fragmented_oversized_message_fail_closed() {
    let (listener, endpoint) = loopback_signaling_listener().await;
    let first_fragment_bytes = MAX_SIGNALING_SERVICE_FRAME_BYTES / 2;
    let final_fragment_bytes = MAX_SIGNALING_SERVICE_FRAME_BYTES - first_fragment_bytes + 1;
    let valid_follow_up = vec![0x51; 16];
    let server = tokio::spawn(async move {
        let (stream, _) = listener.accept().await.expect("connection must arrive");
        let mut socket = accept_hdr_async(stream, select_signaling_subprotocol)
            .await
            .expect("WebSocket handshake must complete");
        socket
            .send(WebSocketMessage::Frame(Frame::message(
                vec![0_u8; first_fragment_bytes],
                OpCode::Data(WebSocketData::Binary),
                false,
            )))
            .await
            .expect("first message fragment must be sent");
        socket
            .send(WebSocketMessage::Frame(Frame::message(
                vec![0_u8; final_fragment_bytes],
                OpCode::Data(WebSocketData::Continue),
                true,
            )))
            .await
            .expect("final message fragment must be sent");
        let _ = socket
            .send(WebSocketMessage::Binary(valid_follow_up.into()))
            .await;
    });

    let mut transport = timeout(
        TRANSPORT_TEST_TIMEOUT,
        WebSocketSignalingTransport::connect(&endpoint),
    )
    .await
    .expect("client connection must not time out")
    .expect("client connection must succeed");
    assert_eq!(
        timeout(TRANSPORT_TEST_TIMEOUT, transport.receive_binary())
            .await
            .expect("message rejection must not time out"),
        Err(SignalingClientError::FrameTooLarge)
    );
    let follow_up = timeout(TRANSPORT_TEST_TIMEOUT, transport.receive_binary())
        .await
        .expect("fail-closed follow-up must not time out");
    assert!(
        follow_up.is_err(),
        "transport accepted a follow-up after rejecting an oversized message"
    );
    timeout(TRANSPORT_TEST_TIMEOUT, server)
        .await
        .expect("server must stop")
        .expect("server task must succeed");
}

async fn loopback_signaling_listener() -> (TcpListener, String) {
    let listener = TcpListener::bind("127.0.0.1:0")
        .await
        .expect("loopback signaling listener must bind");
    let endpoint = format!(
        "ws://{}/session",
        listener.local_addr().expect("listener address must exist")
    );
    (listener, endpoint)
}

#[allow(clippy::result_large_err, clippy::unnecessary_wraps)]
fn select_signaling_subprotocol(
    _request: &Request,
    mut response: Response,
) -> Result<Response, ErrorResponse> {
    response.headers_mut().insert(
        SEC_WEBSOCKET_PROTOCOL,
        HeaderValue::from_static(SIGNALING_WEBSOCKET_SUBPROTOCOL),
    );
    Ok(response)
}

#[test]
fn rejects_wrong_state_correlation_limits_versions_and_remote_errors() {
    let mut protocol = SignalingProtocol::new(DEVICE_ID.to_vec()).expect("device ID must be valid");
    assert_eq!(
        protocol.relay_session(PEER_ID.to_vec(), vec![1], "relay-1"),
        Err(SignalingClientError::InvalidState)
    );
    protocol.registration("register-1").expect("register");

    let wrong_id = server_frame(
        "other",
        signaling_server_frame::Payload::Registered(RegistrationAccepted {
            device_id: DEVICE_ID.to_vec(),
            presence_expires_at_unix_ms: 2_000,
        }),
    );
    assert_eq!(
        protocol.handle_binary(&wrong_id.encode_to_vec()),
        Err(SignalingClientError::CorrelationMismatch)
    );
    assert_eq!(
        protocol.handle_binary(&vec![0; MAX_SIGNALING_SERVICE_FRAME_BYTES + 1]),
        Err(SignalingClientError::FrameTooLarge)
    );

    let mut wrong_version = wrong_id;
    wrong_version.request_id = "register-1".to_owned();
    wrong_version.protocol_version = Some(ProtocolVersion {
        major: 99,
        minor: 0,
    });
    assert_eq!(
        protocol.handle_binary(&wrong_version.encode_to_vec()),
        Err(SignalingClientError::ProtocolUnsupported)
    );

    let remote_error = server_frame(
        "register-1",
        signaling_server_frame::Payload::Error(UnifiedError {
            code: ErrorCode::PairingRateLimited as i32,
            message_key: "signaling.rate_limited".to_owned(),
            retryable: true,
            request_id: "register-1".to_owned(),
            details: None,
        }),
    );
    assert_eq!(
        protocol.handle_binary(&remote_error.encode_to_vec()),
        Ok(SignalingEvent::RemoteError {
            code: ErrorCode::PairingRateLimited,
            retryable: true,
        })
    );

    let oversized = vec![0; MAX_OPAQUE_SIGNALING_ENVELOPE_BYTES + 1];
    assert_eq!(
        protocol.relay_session(PEER_ID.to_vec(), oversized, "relay-2"),
        Err(SignalingClientError::OpaqueEnvelopeTooLarge)
    );
}

#[test]
fn bounds_the_outbox_and_endpoint_policy() {
    let mut outbox = SignalingOutbox::new(2).expect("positive capacity");
    outbox.try_push(vec![1]).expect("first frame");
    outbox.try_push(vec![2]).expect("second frame");
    assert_eq!(
        outbox.try_push(vec![3]),
        Err(SignalingClientError::QueueFull)
    );
    assert_eq!(outbox.pop(), Some(vec![1]));
    assert_eq!(outbox.pop(), Some(vec![2]));
    assert_eq!(outbox.pop(), None);

    assert!(validate_signaling_endpoint("wss://signal.example.test/v1/ws").is_ok());
    assert!(validate_signaling_endpoint("ws://127.0.0.1:8080/v1/ws").is_ok());
    assert!(validate_signaling_endpoint("ws://localhost:8080/v1/ws").is_ok());
    assert_eq!(
        validate_signaling_endpoint("ws://signal.example.test/v1/ws"),
        Err(SignalingClientError::InsecureEndpoint)
    );
    assert_eq!(
        validate_signaling_endpoint("wss://user:secret@signal.example.test/v1/ws"),
        Err(SignalingClientError::EndpointCredentials)
    );
}

#[test]
fn applies_the_debug_lan_opt_in_to_the_public_validator() {
    let enabled = cfg!(debug_assertions)
        && std::env::var("ROAMMAND_ALLOW_INSECURE_LAN_SIGNALING").as_deref() == Ok("true");
    let result = validate_signaling_endpoint("ws://192.168.3.168:8080/v1/ws");
    if enabled {
        assert_eq!(result, Ok(()));
    } else {
        assert_eq!(result, Err(SignalingClientError::InsecureEndpoint));
    }
}

#[test]
fn creates_one_rendezvous_and_binds_the_joined_peer() {
    let mut protocol = ready_protocol();
    let create = protocol
        .create_pairing(
            RENDEZVOUS_ID.to_vec(),
            PairingRendezvousKind::Qr,
            String::new(),
            "create-1",
        )
        .expect("QR rendezvous must be created");
    let Some(signaling_client_frame::Payload::CreateRendezvous(create)) = create.payload else {
        panic!("expected create rendezvous payload");
    };
    assert_eq!(create.rendezvous_id, RENDEZVOUS_ID);
    assert_eq!(create.kind, PairingRendezvousKind::Qr as i32);
    assert!(create.pairing_code.is_empty());
    assert_eq!(
        protocol.create_pairing(
            [0x52; 16].to_vec(),
            PairingRendezvousKind::Qr,
            String::new(),
            "create-2",
        ),
        Err(SignalingClientError::InvalidState)
    );

    let created = server_frame(
        "create-1",
        signaling_server_frame::Payload::RendezvousCreated(PairingRendezvousCreated {
            rendezvous_id: RENDEZVOUS_ID.to_vec(),
            kind: PairingRendezvousKind::Qr as i32,
            expires_at_unix_ms: 120_000,
        }),
    );
    assert_eq!(
        protocol
            .handle_binary(&created.encode_to_vec())
            .expect("created response must correlate"),
        SignalingEvent::PairingCreated {
            rendezvous_id: RENDEZVOUS_ID.to_vec(),
            kind: PairingRendezvousKind::Qr,
            expires_at_unix_ms: 120_000,
        }
    );

    let joined = server_frame(
        "",
        signaling_server_frame::Payload::RendezvousJoined(PairingRendezvousJoined {
            rendezvous_id: RENDEZVOUS_ID.to_vec(),
            peer_device_id: PEER_ID.to_vec(),
            expires_at_unix_ms: 120_000,
        }),
    );
    assert_eq!(
        protocol
            .handle_binary(&joined.encode_to_vec())
            .expect("host must bind the joined peer"),
        SignalingEvent::PairingJoined {
            rendezvous_id: RENDEZVOUS_ID.to_vec(),
            peer_device_id: PEER_ID.to_vec(),
            expires_at_unix_ms: 120_000,
        }
    );
}

#[test]
fn relays_only_opaque_bytes_and_completes_the_active_pairing() {
    let mut protocol = ready_joined_protocol();
    let relay = protocol
        .relay_pairing(RENDEZVOUS_ID.to_vec(), vec![0x61; 128], "relay-pairing-1")
        .expect("joined pairing must relay opaque bytes");
    let Some(signaling_client_frame::Payload::RelayPairing(relay)) = relay.payload else {
        panic!("expected relay pairing payload");
    };
    assert_eq!(relay.rendezvous_id, RENDEZVOUS_ID);
    assert_eq!(relay.opaque_envelope, vec![0x61; 128]);

    let routed = server_frame(
        "",
        signaling_server_frame::Payload::RoutedPairing(RoutedPairingEnvelope {
            rendezvous_id: RENDEZVOUS_ID.to_vec(),
            sender_device_id: PEER_ID.to_vec(),
            opaque_envelope: vec![0x62; 64],
        }),
    );
    assert_eq!(
        protocol
            .handle_binary(&routed.encode_to_vec())
            .expect("bound peer bytes must route opaquely"),
        SignalingEvent::RoutedPairing {
            rendezvous_id: RENDEZVOUS_ID.to_vec(),
            sender_device_id: PEER_ID.to_vec(),
            opaque_envelope: vec![0x62; 64],
        }
    );

    let complete = protocol
        .complete_pairing(
            RENDEZVOUS_ID.to_vec(),
            PairingRendezvousCompletion::Succeeded,
            "complete-1",
        )
        .expect("host must complete its joined pairing");
    let Some(signaling_client_frame::Payload::CompleteRendezvous(complete)) = complete.payload
    else {
        panic!("expected complete rendezvous payload");
    };
    assert_eq!(complete.rendezvous_id, RENDEZVOUS_ID);
    assert_eq!(
        complete.completion,
        PairingRendezvousCompletion::Succeeded as i32
    );
    let closed = server_frame(
        "complete-1",
        signaling_server_frame::Payload::RendezvousClosed(PairingRendezvousClosed {
            rendezvous_id: RENDEZVOUS_ID.to_vec(),
            completion: PairingRendezvousCompletion::Succeeded as i32,
        }),
    );
    assert_eq!(
        protocol
            .handle_binary(&closed.encode_to_vec())
            .expect("completion response must correlate"),
        SignalingEvent::PairingClosed {
            rendezvous_id: RENDEZVOUS_ID.to_vec(),
            completion: PairingRendezvousCompletion::Succeeded,
        }
    );
    assert!(
        protocol
            .create_pairing(
                [0x53; 16].to_vec(),
                PairingRendezvousKind::DesktopCode,
                "ABCDEFGH".to_owned(),
                "create-3",
            )
            .is_ok()
    );
}

#[test]
fn rejects_invalid_pairing_shape_sequence_sender_and_correlation() {
    let mut protocol = ready_protocol();
    for (kind, code) in [
        (PairingRendezvousKind::Qr, "ABCDEFGH"),
        (PairingRendezvousKind::DesktopCode, ""),
        (PairingRendezvousKind::DesktopCode, "abcdEFGH"),
        (PairingRendezvousKind::DesktopCode, "ABC1EFGH"),
    ] {
        assert_eq!(
            protocol.create_pairing(
                RENDEZVOUS_ID.to_vec(),
                kind,
                code.to_owned(),
                "invalid-create",
            ),
            Err(SignalingClientError::InvalidPairingCode)
        );
    }
    assert_eq!(
        protocol.create_pairing(
            vec![0x51; 15],
            PairingRendezvousKind::Qr,
            String::new(),
            "invalid-id",
        ),
        Err(SignalingClientError::InvalidRendezvousId)
    );

    protocol
        .create_pairing(
            RENDEZVOUS_ID.to_vec(),
            PairingRendezvousKind::DesktopCode,
            "ABCDEFGH".to_owned(),
            "create-1",
        )
        .expect("valid code must start");
    let wrong_create = server_frame(
        "other-request",
        signaling_server_frame::Payload::RendezvousCreated(PairingRendezvousCreated {
            rendezvous_id: RENDEZVOUS_ID.to_vec(),
            kind: PairingRendezvousKind::DesktopCode as i32,
            expires_at_unix_ms: 120_000,
        }),
    );
    assert_eq!(
        protocol.handle_binary(&wrong_create.encode_to_vec()),
        Err(SignalingClientError::CorrelationMismatch)
    );
    let created = server_frame(
        "create-1",
        signaling_server_frame::Payload::RendezvousCreated(PairingRendezvousCreated {
            rendezvous_id: RENDEZVOUS_ID.to_vec(),
            kind: PairingRendezvousKind::DesktopCode as i32,
            expires_at_unix_ms: 120_000,
        }),
    );
    protocol
        .handle_binary(&created.encode_to_vec())
        .expect("valid create response");
    assert_eq!(
        protocol.relay_pairing(RENDEZVOUS_ID.to_vec(), vec![1], "early-relay"),
        Err(SignalingClientError::InvalidState)
    );

    let joined = server_frame(
        "",
        signaling_server_frame::Payload::RendezvousJoined(PairingRendezvousJoined {
            rendezvous_id: RENDEZVOUS_ID.to_vec(),
            peer_device_id: PEER_ID.to_vec(),
            expires_at_unix_ms: 120_000,
        }),
    );
    protocol
        .handle_binary(&joined.encode_to_vec())
        .expect("valid join notification");
    let wrong_sender = server_frame(
        "",
        signaling_server_frame::Payload::RoutedPairing(RoutedPairingEnvelope {
            rendezvous_id: RENDEZVOUS_ID.to_vec(),
            sender_device_id: [0x42; 32].to_vec(),
            opaque_envelope: vec![1],
        }),
    );
    assert_eq!(
        protocol.handle_binary(&wrong_sender.encode_to_vec()),
        Err(SignalingClientError::UnexpectedPairingPeer)
    );
    assert_eq!(
        protocol.relay_pairing(
            RENDEZVOUS_ID.to_vec(),
            vec![0; MAX_OPAQUE_SIGNALING_ENVELOPE_BYTES + 1],
            "large-relay",
        ),
        Err(SignalingClientError::OpaqueEnvelopeTooLarge)
    );
    assert_eq!(
        protocol.complete_pairing(
            RENDEZVOUS_ID.to_vec(),
            PairingRendezvousCompletion::Expired,
            "invalid-completion",
        ),
        Err(SignalingClientError::InvalidPairingCompletion)
    );
}

#[test]
fn remote_close_and_disconnect_clear_pairing_state() {
    let mut protocol = ready_joined_protocol();
    let closed = server_frame(
        "",
        signaling_server_frame::Payload::RendezvousClosed(PairingRendezvousClosed {
            rendezvous_id: RENDEZVOUS_ID.to_vec(),
            completion: PairingRendezvousCompletion::Expired as i32,
        }),
    );
    assert!(matches!(
        protocol.handle_binary(&closed.encode_to_vec()),
        Ok(SignalingEvent::PairingClosed {
            completion: PairingRendezvousCompletion::Expired,
            ..
        })
    ));
    assert!(
        protocol
            .create_pairing(
                [0x52; 16].to_vec(),
                PairingRendezvousKind::Qr,
                String::new(),
                "create-after-close",
            )
            .is_ok()
    );

    protocol.disconnected();
    assert_eq!(
        protocol.heartbeat("heartbeat-after-disconnect"),
        Err(SignalingClientError::InvalidState)
    );
    assert!(protocol.registration("register-again").is_ok());
}

#[test]
fn pairing_request_errors_must_correlate_and_release_active_state() {
    let mut protocol = ready_protocol();
    protocol
        .create_pairing(
            RENDEZVOUS_ID.to_vec(),
            PairingRendezvousKind::Qr,
            String::new(),
            "create-1",
        )
        .expect("create request");
    let mismatched = server_frame(
        "create-1",
        signaling_server_frame::Payload::Error(UnifiedError {
            code: ErrorCode::PairingRateLimited as i32,
            message_key: "signaling.rate_limited".to_owned(),
            retryable: true,
            request_id: "other-request".to_owned(),
            details: None,
        }),
    );
    assert_eq!(
        protocol.handle_binary(&mismatched.encode_to_vec()),
        Err(SignalingClientError::CorrelationMismatch)
    );
    assert_eq!(
        protocol.create_pairing(
            [0x52; 16].to_vec(),
            PairingRendezvousKind::Qr,
            String::new(),
            "still-active",
        ),
        Err(SignalingClientError::InvalidState)
    );

    let correlated = server_frame(
        "create-1",
        signaling_server_frame::Payload::Error(UnifiedError {
            code: ErrorCode::PairingRateLimited as i32,
            message_key: "signaling.rate_limited".to_owned(),
            retryable: true,
            request_id: "create-1".to_owned(),
            details: None,
        }),
    );
    assert!(matches!(
        protocol.handle_binary(&correlated.encode_to_vec()),
        Ok(SignalingEvent::RemoteError {
            code: ErrorCode::PairingRateLimited,
            retryable: true,
        })
    ));
    assert!(
        protocol
            .create_pairing(
                [0x52; 16].to_vec(),
                PairingRendezvousKind::Qr,
                String::new(),
                "retry-create",
            )
            .is_ok()
    );
}

fn ready_protocol() -> SignalingProtocol {
    let mut protocol = SignalingProtocol::new(DEVICE_ID.to_vec()).expect("device ID must be valid");
    protocol.registration("register-1").expect("register");
    let registered = server_frame(
        "register-1",
        signaling_server_frame::Payload::Registered(RegistrationAccepted {
            device_id: DEVICE_ID.to_vec(),
            presence_expires_at_unix_ms: 2_000,
        }),
    );
    protocol
        .handle_binary(&registered.encode_to_vec())
        .expect("register response");
    protocol
}

fn ready_joined_protocol() -> SignalingProtocol {
    let mut protocol = ready_protocol();
    protocol
        .create_pairing(
            RENDEZVOUS_ID.to_vec(),
            PairingRendezvousKind::Qr,
            String::new(),
            "create-1",
        )
        .expect("create");
    for frame in [
        server_frame(
            "create-1",
            signaling_server_frame::Payload::RendezvousCreated(PairingRendezvousCreated {
                rendezvous_id: RENDEZVOUS_ID.to_vec(),
                kind: PairingRendezvousKind::Qr as i32,
                expires_at_unix_ms: 120_000,
            }),
        ),
        server_frame(
            "",
            signaling_server_frame::Payload::RendezvousJoined(PairingRendezvousJoined {
                rendezvous_id: RENDEZVOUS_ID.to_vec(),
                peer_device_id: PEER_ID.to_vec(),
                expires_at_unix_ms: 120_000,
            }),
        ),
    ] {
        protocol
            .handle_binary(&frame.encode_to_vec())
            .expect("pairing setup response");
    }
    protocol
}

fn server_frame(
    request_id: &str,
    payload: signaling_server_frame::Payload,
) -> SignalingServerFrame {
    SignalingServerFrame {
        protocol_version: Some(ProtocolVersion { major: 1, minor: 0 }),
        request_id: request_id.to_owned(),
        payload: Some(payload),
    }
}
