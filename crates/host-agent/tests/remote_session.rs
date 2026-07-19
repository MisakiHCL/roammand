// SPDX-License-Identifier: MPL-2.0

use std::sync::{Arc, Mutex};

use ed25519_dalek::{Signature, Signer, SigningKey, Verifier, VerifyingKey};
use prost::Message;
use roammand_host_agent::{
    AuthorizationRegistry, HostIdentity, HostService, MemoryGrantStore, RemoteIceServerConfig,
    RemotePeerEvent, RemotePeerEventSource, RemoteRuntimeConfig, RemoteSessionContext,
    RemoteSessionCoordinator, RemoteSessionError, RemoteSessionFactory, RemoteSessionParts,
    encode_session_answer_transcript, encode_session_offer_transcript,
    encode_session_reconnect_transcript,
};
use roammand_host_platform::MemorySecretStore;
use roammand_host_webrtc::{
    HostWebRtcError, IceTransportPolicy, PeerAnswer, PeerBackend, PeerIceCandidate,
    RemoteInputSink, SessionConfig,
};
use roammand_protocol::{
    canonical_transcript::sha256,
    identity_derivation::derive_device_id_v1,
    roammand::v1::{
        DeviceIdentity, DevicePlatform, EmergencyStopRemoteSessionRequest, ErrorCode,
        GetRemoteSessionStatusRequest, IceCandidate, LocalIpcClientFrame, ProtocolVersion,
        PublicKeyAlgorithm, ReliableInputEnvelope, RevokeControllerGrantRequest,
        SessionAuthentication, SessionControlAction, SessionControlEvent, SessionDescriptionType,
        SessionOfferAuthentication, SessionPermission, SessionReconnectAuthentication,
        SessionState, SessionStatus, SignalingEnvelope, WebRtcNegotiation,
        WebRtcSessionDescription, local_ipc_client_frame, local_ipc_server_frame,
        reliable_input_envelope, session_authentication, signaling_envelope, web_rtc_negotiation,
    },
    validation::decode_and_validate_signaling_envelope,
};

const NOW_UNIX_MS: u64 = 1_900_000_000_000;
const OFFER_SDP: &str = "v=0\r\na=fingerprint:sha-256 AA:BB\r\n";
const ANSWER_SDP: &str = "v=0\r\na=fingerprint:sha-256 CC:DD\r\n";

#[test]
fn remote_runtime_configuration_is_explicit_and_redacted() {
    let stun = RemoteIceServerConfig::new(
        vec!["stun:stun.example.test:3478".to_owned()],
        String::new(),
        String::new(),
    )
    .expect("STUN server must validate without credentials");
    let server = RemoteIceServerConfig::new(
        vec!["turns:turn.example.test:5349".to_owned()],
        "turn-user".to_owned(),
        "turn-password".to_owned(),
    )
    .expect("TURN server must validate");
    let config = RemoteRuntimeConfig::new(
        "wss://signal.example.test/ws?access_token=secret".to_owned(),
        IceTransportPolicy::Relay,
        vec![stun.clone(), server],
    )
    .expect("remote runtime config must validate");

    let debug = format!("{config:?}");
    for secret in ["access_token", "secret", "turn-user", "turn-password"] {
        assert!(!debug.contains(secret));
    }
    assert!(
        RemoteRuntimeConfig::new(
            "wss://signal.example.test/ws".to_owned(),
            IceTransportPolicy::Relay,
            vec![stun],
        )
        .is_err()
    );
    assert!(
        RemoteRuntimeConfig::new(
            "ws://signal.example.test/ws".to_owned(),
            IceTransportPolicy::All,
            Vec::new(),
        )
        .is_err()
    );
    assert!(
        RemoteIceServerConfig::new(
            vec!["stun:stun.example.test:3478".to_owned()],
            "unexpected-user".to_owned(),
            "unexpected-password".to_owned(),
        )
        .is_err()
    );
    assert!(
        RemoteIceServerConfig::new(
            vec![
                "stun:stun.example.test:3478".to_owned(),
                "turn:turn.example.test:3478".to_owned(),
            ],
            "turn-user".to_owned(),
            "turn-password".to_owned(),
        )
        .is_err()
    );
}

#[test]
fn authenticates_before_peer_creation_and_drains_bounded_ice() {
    let mut fixture = Fixture::new();

    assert!(
        fixture
            .route(&candidate_envelope(&fixture), NOW_UNIX_MS)
            .is_empty()
    );
    assert!(fixture.operations().is_empty());
    assert!(
        fixture
            .route(&authentication_envelope(&fixture), NOW_UNIX_MS)
            .is_empty()
    );
    assert!(fixture.operations().is_empty());
    let outbound = fixture.route(&description_envelope(&fixture), NOW_UNIX_MS);

    assert_eq!(fixture.operations(), vec!["peer-start", "peer-candidate"]);
    assert_eq!(outbound.len(), 2);
    let outbound_debug = format!("{outbound:?}");
    assert!(!outbound_debug.contains(OFFER_SDP));
    assert!(!outbound_debug.contains(ANSWER_SDP));
    let answer_auth = outbound
        .iter()
        .find_map(|outbound| match decode(&outbound.opaque_envelope).payload {
            Some(signaling_envelope::Payload::SessionAuthentication(authentication)) => {
                match authentication.payload {
                    Some(session_authentication::Payload::Answer(answer)) => Some(answer),
                    _ => None,
                }
            }
            _ => None,
        })
        .expect("Host must return signed answer authentication");
    assert_eq!(answer_auth.answer_sha256, sha256(ANSWER_SDP.as_bytes()));
    assert_eq!(answer_auth.signature.len(), 64);
    let host_public_key: [u8; 32] = fixture
        .host_identity()
        .public_key
        .as_slice()
        .try_into()
        .expect("Host public key length");
    VerifyingKey::from_bytes(&host_public_key)
        .expect("Host public key must be valid")
        .verify(
            &encode_session_answer_transcript(&answer_auth).expect("answer transcript must encode"),
            &Signature::try_from(answer_auth.signature.as_slice())
                .expect("answer signature length"),
        )
        .expect("Host answer signature must verify");
    assert_eq!(fixture.status_state(), SessionState::Connecting);

    fixture
        .coordinator
        .handle_peer_event(RemotePeerEvent::Connected, NOW_UNIX_MS)
        .expect("connected event must apply");
    assert_eq!(fixture.status_state(), SessionState::Connected);
}

#[test]
fn late_ice_after_peer_failure_does_not_block_the_next_attempt() {
    let mut fixture = Fixture::with_peer_start_failures(1);

    assert!(
        fixture
            .route(&authentication_envelope(&fixture), NOW_UNIX_MS)
            .is_empty()
    );
    let failed = fixture.route(&description_envelope(&fixture), NOW_UNIX_MS);
    assert_eq!(failed.len(), 1);
    let Some(signaling_envelope::Payload::Error(error)) =
        decode(&failed[0].opaque_envelope).payload
    else {
        panic!("failed peer start must return a unified error");
    };
    assert_eq!(
        ErrorCode::try_from(error.code),
        Ok(ErrorCode::CaptureFailed)
    );

    let late_candidate = candidate_envelope(&fixture);
    assert!(fixture.route(&late_candidate, NOW_UNIX_MS).is_empty());

    fixture.session_id = vec![0x93; 16];
    let retry_offer = signed_offer_with_nonce(
        &fixture.controller,
        fixture.host_identity(),
        fixture.session_id.clone(),
        OFFER_SDP,
        0x73,
    );
    assert!(
        fixture
            .route(
                &authentication_envelope_for(&fixture, retry_offer),
                NOW_UNIX_MS,
            )
            .is_empty()
    );
    let retried = fixture.route(&description_envelope(&fixture), NOW_UNIX_MS);

    assert_eq!(retried.len(), 2);
    assert_eq!(fixture.status_state(), SessionState::Connecting);
    assert!(fixture.route(&late_candidate, NOW_UNIX_MS).is_empty());
}

#[test]
fn closing_status_clears_active_session_before_a_fresh_connection() {
    let mut fixture = Fixture::new();
    fixture.connect();

    let closing = envelope(
        &fixture.controller.identity.device_id,
        fixture.host_device_id(),
        signaling_envelope::Payload::SessionStatus(SessionStatus {
            session_id: fixture.session_id.clone(),
            state: SessionState::Closing.into(),
            error: None,
        }),
    );
    assert!(fixture.route(&closing, NOW_UNIX_MS).is_empty());
    assert_eq!(
        fixture.operations(),
        vec!["peer-start", "input-release-all", "peer-close"]
    );

    fixture.session_id = vec![0x94; 16];
    let next_offer = signed_offer_with_nonce(
        &fixture.controller,
        fixture.host_identity(),
        fixture.session_id.clone(),
        OFFER_SDP,
        0x74,
    );
    assert!(
        fixture
            .route(
                &authentication_envelope_for(&fixture, next_offer),
                NOW_UNIX_MS + 1,
            )
            .is_empty()
    );
    let outbound = fixture.route(&description_envelope(&fixture), NOW_UNIX_MS + 1);
    assert_eq!(outbound.len(), 2);
}

#[test]
fn closing_status_cancels_a_pending_session_idempotently() {
    let mut fixture = Fixture::new();
    assert!(
        fixture
            .route(&authentication_envelope(&fixture), NOW_UNIX_MS)
            .is_empty()
    );
    let closing = envelope(
        &fixture.controller.identity.device_id,
        fixture.host_device_id(),
        signaling_envelope::Payload::SessionStatus(SessionStatus {
            session_id: fixture.session_id.clone(),
            state: SessionState::Closing.into(),
            error: None,
        }),
    );

    assert!(fixture.route(&closing, NOW_UNIX_MS).is_empty());
    assert!(fixture.route(&closing, NOW_UNIX_MS).is_empty());
    assert!(fixture.operations().is_empty());
}

#[test]
fn reliable_close_control_clears_the_active_session() {
    let mut fixture = Fixture::new();
    fixture.connect();
    fixture
        .coordinator
        .handle_peer_event(RemotePeerEvent::Connected, NOW_UNIX_MS)
        .expect("session must connect");
    let close = ReliableInputEnvelope {
        protocol_version: Some(ProtocolVersion { major: 1, minor: 0 }),
        session_id: fixture.session_id.clone(),
        sequence: 1,
        event: Some(reliable_input_envelope::Event::SessionControl(
            SessionControlEvent {
                action: SessionControlAction::Close.into(),
            },
        )),
    };

    assert!(
        fixture
            .coordinator
            .handle_peer_event(
                RemotePeerEvent::ReliableInput(close.encode_to_vec()),
                NOW_UNIX_MS,
            )
            .expect("reliable close must apply")
            .is_empty()
    );
    assert_eq!(fixture.status_state(), SessionState::Idle);
    assert_eq!(
        fixture.operations(),
        vec!["peer-start", "input-release-all", "peer-close"]
    );
}

#[test]
fn verified_session_context_reaches_factory_only_after_authentication() {
    let mut fixture = Fixture::new();

    assert!(fixture.contexts().is_empty());
    assert!(
        fixture
            .route(&authentication_envelope(&fixture), NOW_UNIX_MS)
            .is_empty()
    );
    assert!(fixture.contexts().is_empty());
    let outbound = fixture.route(&description_envelope(&fixture), NOW_UNIX_MS);
    assert_eq!(outbound.len(), 2);

    let contexts = fixture.contexts();
    assert_eq!(contexts.len(), 1);
    assert_eq!(contexts[0].session_id(), fixture.session_id);
    assert_eq!(
        contexts[0].permissions(),
        &[
            SessionPermission::ViewScreen,
            SessionPermission::ControlInput
        ]
    );
    assert_eq!(contexts[0].controller_display_name(), "Remote Controller");
    let debug = format!("{:?}", contexts[0]);
    assert!(debug.contains("permission_count"));
    assert!(!debug.contains("Remote Controller"));
}

#[test]
fn keeps_first_session_and_returns_busy_to_a_second_controller() {
    let mut fixture = Fixture::new();
    fixture.connect();
    let second = ControllerFixture::new(0x52);
    fixture.grant(&second.identity);
    let second_session_id = vec![0x92; 16];
    let second_offer = signed_offer(
        &second,
        fixture.host_identity(),
        second_session_id,
        OFFER_SDP,
    );

    let outbound = fixture.route(
        &envelope(
            &second.identity.device_id,
            fixture.host_device_id(),
            signaling_envelope::Payload::SessionAuthentication(SessionAuthentication {
                payload: Some(session_authentication::Payload::Offer(second_offer)),
            }),
        ),
        NOW_UNIX_MS,
    );

    assert_eq!(fixture.operations(), vec!["peer-start"]);
    assert_eq!(outbound.len(), 1);
    let Some(signaling_envelope::Payload::Error(error)) =
        decode(&outbound[0].opaque_envelope).payload
    else {
        panic!("second Controller must receive a unified error");
    };
    assert_eq!(ErrorCode::try_from(error.code), Ok(ErrorCode::DeviceBusy));
    assert_eq!(fixture.status_state(), SessionState::Connecting);
}

#[test]
fn rejects_invalid_auth_and_pending_ice_overflow_before_peer_creation() {
    let mut invalid = Fixture::new();
    let mut authentication = authentication_envelope(&invalid);
    let Some(signaling_envelope::Payload::SessionAuthentication(authentication_payload)) =
        authentication.payload.as_mut()
    else {
        panic!("expected session authentication");
    };
    let Some(session_authentication::Payload::Offer(offer)) =
        authentication_payload.payload.as_mut()
    else {
        panic!("expected session offer");
    };
    offer.signature[0] ^= 0xff;
    assert!(invalid.route(&authentication, NOW_UNIX_MS).is_empty());
    let outbound = invalid.route(&description_envelope(&invalid), NOW_UNIX_MS);
    assert_eq!(outbound.len(), 1);
    assert!(invalid.operations().is_empty());

    let mut overflow = Fixture::new();
    let candidate = candidate_envelope(&overflow);
    for _ in 0..64 {
        assert!(overflow.route(&candidate, NOW_UNIX_MS).is_empty());
    }
    let sender = candidate.sender_device_id.clone();
    assert_eq!(
        overflow
            .coordinator
            .handle_routed(&sender, &candidate.encode_to_vec(), NOW_UNIX_MS,),
        Err(RemoteSessionError::PendingIceLimit)
    );
    assert!(overflow.operations().is_empty());
}

#[test]
fn revocation_closes_peer_and_releases_input() {
    let mut fixture = Fixture::new();
    fixture.connect();
    let mut terminations = fixture.service.subscribe_session_terminations();

    let response = fixture.service.handle_frame(
        &local_frame(local_ipc_client_frame::Payload::RevokeControllerGrant(
            RevokeControllerGrantRequest {
                grant_id: fixture.grant_id.clone(),
            },
        )),
        NOW_UNIX_MS,
    );
    assert!(matches!(
        response.payload,
        Some(local_ipc_server_frame::Payload::ControllerGrantRevoked(_))
    ));
    let termination = terminations
        .try_recv()
        .expect("revocation must broadcast termination");
    let outbound = fixture
        .coordinator
        .handle_termination(&termination, NOW_UNIX_MS)
        .expect("revocation must close the session");
    assert_eq!(outbound.len(), 1);
    let closing = decode_and_validate_signaling_envelope(&outbound[0].opaque_envelope)
        .expect("termination status must validate");
    let status = match closing.payload {
        Some(signaling_envelope::Payload::SessionStatus(status)) => status,
        _ => panic!("expected closing session status"),
    };
    assert_eq!(status.session_id, fixture.session_id);
    assert_eq!(
        SessionState::try_from(status.state),
        Ok(SessionState::Closing)
    );
    assert_eq!(
        fixture.operations(),
        vec!["peer-start", "input-release-all", "peer-close"]
    );
}

#[test]
fn local_emergency_stop_notifies_controller_and_finishes_idle() {
    let mut fixture = Fixture::new();
    fixture.connect();
    let mut terminations = fixture.service.subscribe_session_terminations();

    let response = fixture.service.handle_frame(
        &local_frame(local_ipc_client_frame::Payload::EmergencyStopRemoteSession(
            EmergencyStopRemoteSessionRequest {},
        )),
        NOW_UNIX_MS,
    );
    let Some(local_ipc_server_frame::Payload::EmergencyStopRemoteSessionResult(result)) =
        response.payload
    else {
        panic!("expected emergency-stop result");
    };
    assert_eq!(result.terminated_session_count, 1);
    let termination = terminations
        .try_recv()
        .expect("emergency stop must broadcast termination");

    let outbound = fixture
        .coordinator
        .handle_termination(&termination, NOW_UNIX_MS)
        .expect("emergency stop must close the session");

    assert_eq!(outbound.len(), 1);
    let closing = decode_and_validate_signaling_envelope(&outbound[0].opaque_envelope)
        .expect("termination status must validate");
    assert!(matches!(
        closing.payload,
        Some(signaling_envelope::Payload::SessionStatus(SessionStatus {
            state,
            ..
        })) if SessionState::try_from(state) == Ok(SessionState::Closing)
    ));
    assert_eq!(fixture.status_state(), SessionState::Idle);
    assert_eq!(
        fixture.operations(),
        vec!["peer-start", "input-release-all", "peer-close"]
    );
}

#[test]
fn protected_indicator_stop_notifies_controller_without_reconnecting() {
    let mut fixture = Fixture::new();
    fixture.connect();

    let outbound = fixture
        .coordinator
        .handle_peer_event(RemotePeerEvent::LocalStop, NOW_UNIX_MS)
        .expect("protected stop must close the session");

    assert_eq!(outbound.len(), 1);
    let closing = decode_and_validate_signaling_envelope(&outbound[0].opaque_envelope)
        .expect("termination status must validate");
    assert!(matches!(
        closing.payload,
        Some(signaling_envelope::Payload::SessionStatus(SessionStatus {
            state,
            ..
        })) if SessionState::try_from(state) == Ok(SessionState::Closing)
    ));
    assert_eq!(fixture.status_state(), SessionState::Idle);
    assert_eq!(
        fixture.operations(),
        vec!["peer-start", "input-release-all", "peer-close"]
    );
}

#[test]
fn signaling_loss_keeps_the_host_alive_beyond_the_controller_window() {
    let mut fixture = Fixture::new();
    fixture.connect();
    fixture
        .coordinator
        .handle_peer_event(RemotePeerEvent::Connected, NOW_UNIX_MS)
        .expect("session must connect");
    fixture
        .coordinator
        .signaling_lost(NOW_UNIX_MS)
        .expect("signaling loss must enter reconnect");
    assert_eq!(fixture.status_state(), SessionState::Reconnecting);
    assert_eq!(
        fixture.operations(),
        vec!["peer-start", "input-release-all"]
    );

    fixture
        .coordinator
        .poll_peer_event(NOW_UNIX_MS + 44_999)
        .expect("reconnect window must remain open");
    assert_eq!(fixture.status_state(), SessionState::Reconnecting);
    fixture
        .coordinator
        .poll_peer_event(NOW_UNIX_MS + 45_000)
        .expect("reconnect deadline must fail closed");
    assert_eq!(fixture.status_state(), SessionState::Failed);
    assert_eq!(
        fixture.operations(),
        vec![
            "peer-start",
            "input-release-all",
            "input-release-all",
            "peer-close"
        ]
    );
}

#[test]
fn signaling_loss_with_an_input_failure_clears_only_the_active_session() {
    let mut fixture = Fixture::with_input_release_failures(1);
    fixture.connect();
    fixture
        .coordinator
        .handle_peer_event(RemotePeerEvent::Connected, NOW_UNIX_MS)
        .expect("session must connect");

    assert_eq!(
        fixture.coordinator.signaling_lost(NOW_UNIX_MS),
        Err(RemoteSessionError::Input)
    );
    assert_eq!(fixture.status_state(), SessionState::Failed);
    assert_eq!(
        fixture.operations(),
        vec![
            "peer-start",
            "input-release-all",
            "input-release-all",
            "peer-close"
        ]
    );

    fixture.session_id = vec![0x95; 16];
    let next_offer = signed_offer_with_nonce(
        &fixture.controller,
        fixture.host_identity(),
        fixture.session_id.clone(),
        OFFER_SDP,
        0x75,
    );
    assert!(
        fixture
            .route(
                &authentication_envelope_for(&fixture, next_offer),
                NOW_UNIX_MS + 1,
            )
            .is_empty()
    );
    assert_eq!(
        fixture
            .route(&description_envelope(&fixture), NOW_UNIX_MS + 1)
            .len(),
        2
    );
    assert_eq!(fixture.status_state(), SessionState::Connecting);
}

#[test]
fn authenticates_reconnect_and_reuses_the_active_peer() {
    let mut fixture = Fixture::new();
    fixture.connect();
    fixture
        .coordinator
        .handle_peer_event(RemotePeerEvent::Connected, NOW_UNIX_MS)
        .expect("session must connect");
    fixture
        .coordinator
        .handle_peer_event(RemotePeerEvent::Disconnected, NOW_UNIX_MS)
        .expect("disconnect must enter reconnect");
    assert_eq!(fixture.status_state(), SessionState::Reconnecting);

    assert!(
        fixture
            .coordinator
            .handle_peer_event(RemotePeerEvent::ReliableInput(vec![0x01]), NOW_UNIX_MS)
            .expect("input must be ignored while reconnecting")
            .is_empty()
    );
    assert_eq!(
        fixture.operations(),
        vec!["peer-start", "input-release-all"]
    );

    let reconnect_offer = signed_offer_with_nonce(
        &fixture.controller,
        fixture.host_identity(),
        fixture.session_id.clone(),
        OFFER_SDP,
        0x82,
    );
    let reconnect_envelope = authentication_envelope_for(&fixture, reconnect_offer);
    assert!(fixture.route(&reconnect_envelope, NOW_UNIX_MS).is_empty());
    let candidate = candidate_envelope(&fixture);
    assert!(fixture.route(&candidate, NOW_UNIX_MS).is_empty());
    let outbound = fixture.route(&description_envelope(&fixture), NOW_UNIX_MS);
    assert_eq!(
        fixture.operations(),
        vec![
            "peer-start",
            "input-release-all",
            "peer-restart",
            "peer-candidate"
        ]
    );
    assert_eq!(outbound.len(), 2);

    assert!(fixture.route(&candidate, NOW_UNIX_MS).is_empty());
    assert_eq!(fixture.operations().last(), Some(&"peer-candidate"));

    let reconnect = outbound
        .iter()
        .find_map(|outbound| match decode(&outbound.opaque_envelope).payload {
            Some(signaling_envelope::Payload::SessionAuthentication(authentication)) => {
                match authentication.payload {
                    Some(session_authentication::Payload::Reconnect(reconnect)) => Some(reconnect),
                    _ => None,
                }
            }
            _ => None,
        })
        .expect("Host must return signed reconnect authentication");
    assert_eq!(reconnect.reconnect_generation, 1);
    verify_reconnect_signature(&fixture, &reconnect);

    fixture
        .coordinator
        .handle_peer_event(RemotePeerEvent::Connected, NOW_UNIX_MS + 1)
        .expect("restarted peer must connect");
    assert_eq!(fixture.status_state(), SessionState::Connected);

    fixture
        .coordinator
        .handle_peer_event(RemotePeerEvent::Disconnected, NOW_UNIX_MS + 2)
        .expect("second disconnect must re-enter reconnect");
    assert!(
        fixture
            .route(&reconnect_envelope, NOW_UNIX_MS + 2)
            .is_empty()
    );
    let replay = fixture.route(&description_envelope(&fixture), NOW_UNIX_MS + 2);
    assert_eq!(replay.len(), 1);
    let Some(signaling_envelope::Payload::Error(error)) =
        decode(&replay[0].opaque_envelope).payload
    else {
        panic!("replayed reconnect must receive a unified error");
    };
    assert_eq!(
        ErrorCode::try_from(error.code),
        Ok(ErrorCode::SessionReplayed)
    );
    assert_eq!(
        fixture.operations(),
        vec![
            "peer-start",
            "input-release-all",
            "peer-restart",
            "peer-candidate",
            "peer-candidate",
            "input-release-all"
        ]
    );
}

#[test]
fn spontaneous_peer_recovery_clears_the_host_reconnect_window() {
    let mut fixture = Fixture::new();
    fixture.connect();
    fixture
        .coordinator
        .handle_peer_event(RemotePeerEvent::Connected, NOW_UNIX_MS)
        .expect("session must connect");
    fixture
        .coordinator
        .handle_peer_event(RemotePeerEvent::Disconnected, NOW_UNIX_MS + 1)
        .expect("disconnect must enter reconnect");

    fixture
        .coordinator
        .handle_peer_event(RemotePeerEvent::Connected, NOW_UNIX_MS + 2)
        .expect("the retained peer may recover without a restart offer");

    assert_eq!(fixture.status_state(), SessionState::Connected);
    assert_eq!(
        fixture.operations(),
        vec!["peer-start", "input-release-all"]
    );
    assert!(
        fixture
            .coordinator
            .poll_peer_event(NOW_UNIX_MS + 45_001)
            .expect("cleared reconnect deadline must not expire the session")
            .is_empty()
    );
    assert_eq!(fixture.status_state(), SessionState::Connected);
}

#[test]
fn privileged_route_change_freezes_input_before_authenticated_reconnect() {
    let mut fixture = Fixture::new();
    fixture.connect();
    fixture
        .coordinator
        .handle_peer_event(RemotePeerEvent::Connected, NOW_UNIX_MS)
        .expect("session must connect");

    fixture
        .coordinator
        .privileged_route_changed(NOW_UNIX_MS + 1)
        .expect("route migration must begin reconnect");

    assert_eq!(fixture.status_state(), SessionState::Reconnecting);
    assert_eq!(
        fixture.operations(),
        vec!["peer-start", "input-release-all"]
    );
    assert!(
        fixture
            .coordinator
            .handle_peer_event(RemotePeerEvent::ReliableInput(vec![0x01]), NOW_UNIX_MS + 2)
            .expect("transition input is ignored")
            .is_empty()
    );
}

#[test]
fn new_coordinator_after_host_restart_accepts_a_fresh_normal_offer() {
    let mut fixture = Fixture::new();
    fixture.connect();
    fixture.restart_coordinator();

    let offer = signed_offer_with_nonce(
        &fixture.controller,
        fixture.host_identity(),
        fixture.session_id.clone(),
        OFFER_SDP,
        0x83,
    );
    assert!(
        fixture
            .route(&authentication_envelope_for(&fixture, offer), NOW_UNIX_MS)
            .is_empty()
    );
    let outbound = fixture.route(&description_envelope(&fixture), NOW_UNIX_MS);

    assert_eq!(outbound.len(), 2);
    assert!(outbound.iter().any(|outbound| {
        matches!(
            decode(&outbound.opaque_envelope).payload,
            Some(signaling_envelope::Payload::SessionAuthentication(
                SessionAuthentication {
                    payload: Some(session_authentication::Payload::Answer(_))
                }
            ))
        )
    }));
    assert_eq!(
        fixture.operations(),
        vec![
            "peer-start",
            "input-release-all",
            "peer-close",
            "peer-start"
        ]
    );
}

#[test]
fn shutdown_is_idempotent_and_local_status_is_sanitized() {
    let mut fixture = Fixture::new();
    fixture.connect();

    let snapshot = fixture.remote_status();
    assert_eq!(
        snapshot.controller_device_id,
        fixture.controller.identity.device_id
    );
    let status = snapshot.session_status.as_ref().expect("status must exist");
    assert_eq!(status.state, SessionState::Connecting as i32);
    assert_eq!(status.session_id, fixture.session_id);
    let encoded = snapshot.encode_to_vec();
    assert!(
        !encoded
            .windows(OFFER_SDP.len())
            .any(|value| value == OFFER_SDP.as_bytes())
    );

    fixture
        .coordinator
        .shutdown()
        .expect("shutdown must succeed");
    fixture
        .coordinator
        .shutdown()
        .expect("repeated shutdown must succeed");
    assert_eq!(
        fixture.operations(),
        vec!["peer-start", "input-release-all", "peer-close"]
    );
    assert_eq!(fixture.status_state(), SessionState::Idle);
}

struct Fixture {
    service: Arc<HostService>,
    coordinator: RemoteSessionCoordinator,
    controller: ControllerFixture,
    session_id: Vec<u8>,
    grant_id: Vec<u8>,
    operations: Arc<Mutex<Vec<&'static str>>>,
    contexts: Arc<Mutex<Vec<RemoteSessionContext>>>,
    peer_start_failures: Arc<Mutex<usize>>,
    input_release_failures: Arc<Mutex<usize>>,
}

impl Fixture {
    fn new() -> Self {
        Self::with_failures(0, 0)
    }

    fn with_peer_start_failures(failure_count: usize) -> Self {
        Self::with_failures(failure_count, 0)
    }

    fn with_input_release_failures(failure_count: usize) -> Self {
        Self::with_failures(0, failure_count)
    }

    fn with_failures(peer_start_failure_count: usize, input_release_failure_count: usize) -> Self {
        let identity = HostIdentity::load_or_create(
            &MemorySecretStore::new(),
            "Remote Host",
            DevicePlatform::Macos,
        )
        .expect("Host identity must load");
        let controller = ControllerFixture::new(0x51);
        let store = Arc::new(MemoryGrantStore::new());
        let mut authorization =
            AuthorizationRegistry::load(identity.device_identity().device_id.clone(), store)
                .expect("authorization must load");
        let grant = authorization
            .create_controller_grant(
                controller.identity.clone(),
                &[
                    SessionPermission::ViewScreen,
                    SessionPermission::ControlInput,
                ],
                NOW_UNIX_MS - 100,
            )
            .expect("Controller must be granted");
        let grant_id = grant.grant.expect("grant must exist").grant_id;
        let service = Arc::new(HostService::new(
            identity,
            authorization,
            [0x41; 16],
            NOW_UNIX_MS - 1000,
        ));
        let operations = Arc::new(Mutex::new(Vec::new()));
        let contexts = Arc::new(Mutex::new(Vec::new()));
        let peer_start_failures = Arc::new(Mutex::new(peer_start_failure_count));
        let input_release_failures = Arc::new(Mutex::new(input_release_failure_count));
        let factory = FakeSessionFactory {
            operations: Arc::clone(&operations),
            contexts: Arc::clone(&contexts),
            peer_start_failures: Arc::clone(&peer_start_failures),
            input_release_failures: Arc::clone(&input_release_failures),
        };
        let coordinator = RemoteSessionCoordinator::new(service.clone(), Box::new(factory))
            .expect("coordinator must initialize");
        Self {
            service,
            coordinator,
            controller,
            session_id: vec![0x91; 16],
            grant_id,
            operations,
            contexts,
            peer_start_failures,
            input_release_failures,
        }
    }

    fn host_identity(&self) -> &DeviceIdentity {
        self.service.device_identity()
    }

    fn host_device_id(&self) -> &[u8] {
        &self.host_identity().device_id
    }

    fn route(
        &mut self,
        incoming: &SignalingEnvelope,
        now_unix_ms: u64,
    ) -> Vec<roammand_host_agent::RemoteSessionOutbound> {
        let sender = incoming.sender_device_id.clone();
        self.coordinator
            .handle_routed(&sender, &incoming.encode_to_vec(), now_unix_ms)
            .expect("routed envelope must be handled")
    }

    fn connect(&mut self) {
        assert!(
            self.route(&authentication_envelope(self), NOW_UNIX_MS)
                .is_empty()
        );
        let outbound = self.route(&description_envelope(self), NOW_UNIX_MS);
        assert_eq!(outbound.len(), 2);
    }

    fn grant(&self, controller: &DeviceIdentity) {
        self.service
            .create_controller_grant_for_maintenance(
                controller.clone(),
                &[SessionPermission::ViewScreen],
                NOW_UNIX_MS,
            )
            .expect("maintenance grant must succeed");
    }

    fn operations(&self) -> Vec<&'static str> {
        self.operations.lock().expect("operations lock").clone()
    }

    fn contexts(&self) -> Vec<RemoteSessionContext> {
        self.contexts.lock().expect("contexts lock").clone()
    }

    fn restart_coordinator(&mut self) {
        self.coordinator
            .shutdown()
            .expect("old coordinator must shut down");
        self.coordinator = RemoteSessionCoordinator::new(
            Arc::clone(&self.service),
            Box::new(FakeSessionFactory {
                operations: Arc::clone(&self.operations),
                contexts: Arc::clone(&self.contexts),
                peer_start_failures: Arc::clone(&self.peer_start_failures),
                input_release_failures: Arc::clone(&self.input_release_failures),
            }),
        )
        .expect("new coordinator must initialize");
    }

    fn remote_status(&self) -> roammand_protocol::roammand::v1::RemoteSessionStatusSnapshot {
        let response = self.service.handle_frame(
            &local_frame(local_ipc_client_frame::Payload::GetRemoteSessionStatus(
                GetRemoteSessionStatusRequest {},
            )),
            NOW_UNIX_MS,
        );
        match response.payload {
            Some(local_ipc_server_frame::Payload::RemoteSessionStatus(snapshot)) => snapshot,
            _ => panic!("expected remote session status"),
        }
    }

    fn status_state(&self) -> SessionState {
        SessionState::try_from(
            self.remote_status()
                .session_status
                .expect("session status")
                .state,
        )
        .expect("known state")
    }
}

struct ControllerFixture {
    signing_key: SigningKey,
    identity: DeviceIdentity,
}

impl ControllerFixture {
    fn new(seed: u8) -> Self {
        let signing_key = SigningKey::from_bytes(&[seed; 32]);
        let public_key = signing_key.verifying_key().to_bytes();
        Self {
            signing_key,
            identity: DeviceIdentity {
                device_id: derive_device_id_v1(&public_key)
                    .expect("device ID must derive")
                    .to_vec(),
                public_key_algorithm: PublicKeyAlgorithm::Ed25519 as i32,
                public_key: public_key.to_vec(),
                display_name: "Remote Controller".to_owned(),
                platform: DevicePlatform::Macos as i32,
            },
        }
    }
}

struct FakeSessionFactory {
    operations: Arc<Mutex<Vec<&'static str>>>,
    contexts: Arc<Mutex<Vec<RemoteSessionContext>>>,
    peer_start_failures: Arc<Mutex<usize>>,
    input_release_failures: Arc<Mutex<usize>>,
}

impl RemoteSessionFactory for FakeSessionFactory {
    fn create(
        &mut self,
        _config: &SessionConfig,
        context: &RemoteSessionContext,
    ) -> Result<RemoteSessionParts, RemoteSessionError> {
        self.contexts
            .lock()
            .expect("contexts lock")
            .push(context.clone());
        Ok(RemoteSessionParts::new(
            Box::new(FakePeer {
                operations: Arc::clone(&self.operations),
                start_failures: Arc::clone(&self.peer_start_failures),
            }),
            Box::new(FakeInput {
                operations: Arc::clone(&self.operations),
                release_failures: Arc::clone(&self.input_release_failures),
            }),
            Box::new(NoPeerEvents),
        ))
    }
}

struct NoPeerEvents;

impl RemotePeerEventSource for NoPeerEvents {
    fn try_recv(&self) -> Result<Option<RemotePeerEvent>, RemoteSessionError> {
        Ok(None)
    }
}

struct FakePeer {
    operations: Arc<Mutex<Vec<&'static str>>>,
    start_failures: Arc<Mutex<usize>>,
}

impl PeerBackend for FakePeer {
    fn start(
        &mut self,
        _config: &SessionConfig,
        _offer_sdp: &str,
    ) -> Result<PeerAnswer, HostWebRtcError> {
        self.operations
            .lock()
            .expect("operations lock")
            .push("peer-start");
        let mut start_failures = self.start_failures.lock().expect("start failures lock");
        if *start_failures > 0 {
            *start_failures -= 1;
            return Err(HostWebRtcError::PeerFailure);
        }
        Ok(PeerAnswer {
            sdp: ANSWER_SDP.to_owned(),
            dtls_fingerprint_sha256: vec![0x77; 32],
        })
    }

    fn restart(
        &mut self,
        _config: &SessionConfig,
        _offer_sdp: &str,
    ) -> Result<PeerAnswer, HostWebRtcError> {
        self.operations
            .lock()
            .expect("operations lock")
            .push("peer-restart");
        Ok(PeerAnswer {
            sdp: ANSWER_SDP.to_owned(),
            dtls_fingerprint_sha256: vec![0x77; 32],
        })
    }

    fn add_remote_ice_candidate(
        &mut self,
        _candidate: &PeerIceCandidate,
    ) -> Result<(), HostWebRtcError> {
        self.operations
            .lock()
            .expect("operations lock")
            .push("peer-candidate");
        Ok(())
    }

    fn close(&mut self) -> Result<(), HostWebRtcError> {
        self.operations
            .lock()
            .expect("operations lock")
            .push("peer-close");
        Ok(())
    }
}

struct FakeInput {
    operations: Arc<Mutex<Vec<&'static str>>>,
    release_failures: Arc<Mutex<usize>>,
}

impl RemoteInputSink for FakeInput {
    fn release_all(&mut self) -> Result<(), HostWebRtcError> {
        self.operations
            .lock()
            .expect("operations lock")
            .push("input-release-all");
        let mut release_failures = self.release_failures.lock().expect("release failures lock");
        if *release_failures > 0 {
            *release_failures -= 1;
            return Err(HostWebRtcError::InputFailure);
        }
        Ok(())
    }
}

fn authentication_envelope(fixture: &Fixture) -> SignalingEnvelope {
    let offer = signed_offer(
        &fixture.controller,
        fixture.host_identity(),
        fixture.session_id.clone(),
        OFFER_SDP,
    );
    authentication_envelope_for(fixture, offer)
}

fn authentication_envelope_for(
    fixture: &Fixture,
    offer: SessionOfferAuthentication,
) -> SignalingEnvelope {
    envelope(
        &fixture.controller.identity.device_id,
        fixture.host_device_id(),
        signaling_envelope::Payload::SessionAuthentication(SessionAuthentication {
            payload: Some(session_authentication::Payload::Offer(offer)),
        }),
    )
}

fn description_envelope(fixture: &Fixture) -> SignalingEnvelope {
    envelope(
        &fixture.controller.identity.device_id,
        fixture.host_device_id(),
        signaling_envelope::Payload::WebrtcNegotiation(WebRtcNegotiation {
            session_id: fixture.session_id.clone(),
            payload: Some(web_rtc_negotiation::Payload::Description(
                WebRtcSessionDescription {
                    r#type: SessionDescriptionType::Offer as i32,
                    sdp: OFFER_SDP.to_owned(),
                    dtls_fingerprint_sha256: vec![0x76; 32],
                },
            )),
        }),
    )
}

fn candidate_envelope(fixture: &Fixture) -> SignalingEnvelope {
    envelope(
        &fixture.controller.identity.device_id,
        fixture.host_device_id(),
        signaling_envelope::Payload::WebrtcNegotiation(WebRtcNegotiation {
            session_id: fixture.session_id.clone(),
            payload: Some(web_rtc_negotiation::Payload::IceCandidate(IceCandidate {
                candidate: "candidate:1 1 udp 1 127.0.0.1 9000 typ host".to_owned(),
                sdp_mid: "0".to_owned(),
                sdp_m_line_index: 0,
            })),
        }),
    )
}

fn signed_offer(
    controller: &ControllerFixture,
    host: &DeviceIdentity,
    session_id: Vec<u8>,
    offer_sdp: &str,
) -> SessionOfferAuthentication {
    signed_offer_with_nonce(controller, host, session_id, offer_sdp, 0x72)
}

fn signed_offer_with_nonce(
    controller: &ControllerFixture,
    host: &DeviceIdentity,
    session_id: Vec<u8>,
    offer_sdp: &str,
    nonce_byte: u8,
) -> SessionOfferAuthentication {
    let mut offer = SessionOfferAuthentication {
        controller_device_id: controller.identity.device_id.clone(),
        host_device_id: host.device_id.clone(),
        session_id,
        nonce: vec![nonce_byte; 32],
        issued_at_unix_ms: NOW_UNIX_MS - 5000,
        expires_at_unix_ms: NOW_UNIX_MS + 5000,
        requested_permissions: vec![
            SessionPermission::ViewScreen as i32,
            SessionPermission::ControlInput as i32,
        ],
        offer_sha256: sha256(offer_sdp.as_bytes()).to_vec(),
        controller_dtls_fingerprint_sha256: vec![0x76; 32],
        signature: vec![0; 64],
    };
    let transcript = encode_session_offer_transcript(&offer).expect("offer must encode");
    offer.signature = controller.signing_key.sign(&transcript).to_bytes().to_vec();
    offer
}

fn verify_reconnect_signature(fixture: &Fixture, reconnect: &SessionReconnectAuthentication) {
    let host_public_key: [u8; 32] = fixture
        .host_identity()
        .public_key
        .as_slice()
        .try_into()
        .expect("Host public key length");
    VerifyingKey::from_bytes(&host_public_key)
        .expect("Host public key must be valid")
        .verify(
            &encode_session_reconnect_transcript(reconnect)
                .expect("reconnect transcript must encode"),
            &Signature::try_from(reconnect.signature.as_slice())
                .expect("reconnect signature length"),
        )
        .expect("Host reconnect signature must verify");
}

fn envelope(
    sender: &[u8],
    recipient: &[u8],
    payload: signaling_envelope::Payload,
) -> SignalingEnvelope {
    SignalingEnvelope {
        protocol_version: Some(ProtocolVersion { major: 1, minor: 0 }),
        sender_device_id: sender.to_vec(),
        recipient_device_id: recipient.to_vec(),
        request_id: "remote-session-1".to_owned(),
        sent_at_unix_ms: NOW_UNIX_MS,
        payload: Some(payload),
    }
}

fn decode(encoded: &[u8]) -> SignalingEnvelope {
    SignalingEnvelope::decode(encoded).expect("outbound envelope must decode")
}

fn local_frame(payload: local_ipc_client_frame::Payload) -> LocalIpcClientFrame {
    LocalIpcClientFrame {
        protocol_version: Some(ProtocolVersion { major: 1, minor: 0 }),
        request_id: "local-status-1".to_owned(),
        payload: Some(payload),
    }
}
