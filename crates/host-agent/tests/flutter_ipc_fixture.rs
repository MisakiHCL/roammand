// SPDX-License-Identifier: MPL-2.0

use std::sync::Arc;

use prost::Message;
use roammand_host_agent::{AuthorizationRegistry, HostIdentity, HostService, MemoryGrantStore};
use roammand_host_platform::{MemorySecretStore, ProtectedSecretStore};
use roammand_ipc::{IpcToken, ServerProtocol, client_proof};
use roammand_protocol::{
    canonical_transcript::{CanonicalTranscript, TranscriptField, TranscriptPurpose, encode},
    roammand::v1::{
        DevicePlatform, LocalIpcAuthenticate, LocalIpcClientFrame, LocalIpcServerFrame,
        PairingIdentityRole, ProtocolVersion, SignCanonicalTranscriptRequest,
        SignPairingTranscriptRequest, local_ipc_client_frame, local_ipc_server_frame,
    },
};
use serde_json::{Value, json};

const HOST_SEED: [u8; 32] = [0x42; 32];
const TOKEN: [u8; 32] = [0x44; 32];
const INSTANCE_ID: [u8; 16] = [0x11; 16];
const SERVER_NONCE: [u8; 32] = [0x22; 32];
const CLIENT_NONCE: [u8; 32] = [0x33; 32];
const DART_STATUS_REQUEST_HEX: &str = "0a040801100012087374617475732d315a00";
const FIXTURE: &str = include_str!("../../../conformance/protocol_vectors/local_ipc_v1.json");

#[test]
fn rust_emission_matches_the_shared_flutter_fixture() {
    let expected: Value = serde_json::from_str(FIXTURE).expect("fixture JSON must parse");
    assert_eq!(fixture_value(), expected);
}

#[test]
fn decodes_the_dart_status_request_and_executes_it() {
    let fixture: Value = serde_json::from_str(FIXTURE).expect("fixture JSON must parse");
    let request = LocalIpcClientFrame::decode(
        hex::decode(required_string(&fixture, "status_request_client_frame_hex"))
            .expect("fixture hex must decode")
            .as_slice(),
    )
    .expect("Dart request must decode in Rust");
    assert!(matches!(
        request.payload,
        Some(local_ipc_client_frame::Payload::GetHostStatus(_))
    ));
    let response = service().handle_frame(&request, 100);
    assert!(matches!(
        response.payload,
        Some(local_ipc_server_frame::Payload::HostStatus(_))
    ));
}

fn fixture_value() -> Value {
    let mut protocol = ServerProtocol::new(IpcToken::new(TOKEN), INSTANCE_ID, SERVER_NONCE);
    let challenge_frame = LocalIpcServerFrame {
        protocol_version: Some(version()),
        request_id: String::new(),
        payload: Some(local_ipc_server_frame::Payload::Challenge(
            protocol.challenge(),
        )),
    };
    let authentication_frame = LocalIpcClientFrame {
        protocol_version: Some(version()),
        request_id: "authenticate".to_owned(),
        payload: Some(local_ipc_client_frame::Payload::Authenticate(
            LocalIpcAuthenticate {
                client_nonce: CLIENT_NONCE.to_vec(),
                client_proof: client_proof(
                    &IpcToken::new(TOKEN),
                    &INSTANCE_ID,
                    &SERVER_NONCE,
                    &CLIENT_NONCE,
                )
                .to_vec(),
            },
        )),
    };
    let authenticated = protocol
        .authenticate(&authentication_frame)
        .expect("fixture proof must authenticate");
    let authenticated_frame = LocalIpcServerFrame {
        protocol_version: Some(version()),
        request_id: authentication_frame.request_id.clone(),
        payload: Some(local_ipc_server_frame::Payload::Authenticated(
            authenticated.clone(),
        )),
    };
    let status_request = LocalIpcClientFrame::decode(
        hex::decode(DART_STATUS_REQUEST_HEX)
            .expect("Dart fixture hex must decode")
            .as_slice(),
    )
    .expect("Dart fixture request must decode");
    let service = service();
    let status_response = service.handle_frame(&status_request, 100);
    let host_device_id = match status_response
        .payload
        .as_ref()
        .expect("status response must contain payload")
    {
        local_ipc_server_frame::Payload::HostStatus(status) => status
            .identity
            .as_ref()
            .expect("status must contain identity")
            .device_id
            .clone(),
        _ => panic!("expected status response"),
    };
    let sign_request = LocalIpcClientFrame {
        protocol_version: Some(version()),
        request_id: "sign-1".to_owned(),
        payload: Some(local_ipc_client_frame::Payload::SignCanonicalTranscript(
            SignCanonicalTranscriptRequest {
                canonical_transcript: session_answer(&host_device_id),
            },
        )),
    };
    let sign_response = service.handle_frame(&sign_request, 100);
    let pairing_sign_request = LocalIpcClientFrame {
        protocol_version: Some(version()),
        request_id: "pairing-sign-1".to_owned(),
        payload: Some(local_ipc_client_frame::Payload::SignPairingTranscript(
            SignPairingTranscriptRequest {
                canonical_transcript: pairing_transcript(&[0x71; 32], &host_device_id),
                role: PairingIdentityRole::Host as i32,
            },
        )),
    };
    let pairing_sign_response = service.handle_frame(&pairing_sign_request, 100);

    json!({
        "spdx_license_identifier": "Apache-2.0",
        "fixture_version": 1,
        "token_hex": hex::encode(TOKEN),
        "agent_instance_id_hex": hex::encode(INSTANCE_ID),
        "server_nonce_hex": hex::encode(SERVER_NONCE),
        "client_nonce_hex": hex::encode(CLIENT_NONCE),
        "client_proof_hex": hex::encode(client_proof(
            &IpcToken::new(TOKEN),
            &INSTANCE_ID,
            &SERVER_NONCE,
            &CLIENT_NONCE,
        )),
        "server_proof_hex": hex::encode(authenticated.server_proof),
        "challenge_server_frame_hex": hex::encode(challenge_frame.encode_to_vec()),
        "authenticate_client_frame_hex": hex::encode(authentication_frame.encode_to_vec()),
        "authenticated_server_frame_hex": hex::encode(authenticated_frame.encode_to_vec()),
        "status_request_client_frame_hex": DART_STATUS_REQUEST_HEX,
        "status_response_server_frame_hex": hex::encode(status_response.encode_to_vec()),
        "sign_request_client_frame_hex": hex::encode(sign_request.encode_to_vec()),
        "sign_response_server_frame_hex": hex::encode(sign_response.encode_to_vec()),
        "pairing_sign_request_client_frame_hex": hex::encode(pairing_sign_request.encode_to_vec()),
        "pairing_sign_response_server_frame_hex": hex::encode(pairing_sign_response.encode_to_vec()),
    })
}

fn service() -> HostService {
    let secret_store = MemorySecretStore::new();
    secret_store
        .store(&HOST_SEED)
        .expect("test seed must be stored");
    let identity =
        HostIdentity::load_or_create(&secret_store, "Fixture Host", DevicePlatform::Macos)
            .expect("fixture identity must load");
    let authorization = AuthorizationRegistry::load(
        identity.device_identity().device_id.clone(),
        Arc::new(MemoryGrantStore::new()),
    )
    .expect("fixture authorization must load");
    HostService::new(identity, authorization, INSTANCE_ID, 10)
}

fn session_answer(host_device_id: &[u8]) -> Vec<u8> {
    let fields = [1_u16, 2, 8, 9, 10, 11, 12, 13, 14, 15, 16]
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
    .expect("fixture transcript must encode")
}

fn pairing_transcript(controller_device_id: &[u8], host_device_id: &[u8]) -> Vec<u8> {
    let fields = [1_u16, 2, 3, 4, 5, 6, 7]
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
    .expect("fixture pairing transcript must encode")
}

const fn field_length(tag: u16) -> usize {
    match tag {
        3 | 8 => 16,
        10 | 11 => 8,
        12 => 4,
        _ => 32,
    }
}

const fn version() -> ProtocolVersion {
    ProtocolVersion { major: 1, minor: 0 }
}

fn required_string<'a>(fixture: &'a Value, key: &str) -> &'a str {
    fixture[key].as_str().expect("fixture field must be text")
}
