// SPDX-License-Identifier: MPL-2.0

use roammand_ipc::{
    AuthChannel, IpcToken, ProtocolError, ServerProtocol, channel_client_proof,
    channel_server_proof, client_proof, server_proof,
};
use roammand_protocol::roammand::v1::{
    GetHostStatusRequest, LocalIpcAuthenticate, LocalIpcClientFrame, ProtocolVersion,
    local_ipc_client_frame,
};

const TOKEN: [u8; 32] = [0x44; 32];
const INSTANCE: [u8; 16] = [0x11; 16];
const SERVER_NONCE: [u8; 32] = [0x22; 32];
const CLIENT_NONCE: [u8; 32] = [0x33; 32];

#[test]
fn hmac_proofs_match_the_independent_golden_vector() {
    let token = IpcToken::new(TOKEN);
    assert_eq!(
        hex::encode(client_proof(
            &token,
            &INSTANCE,
            &SERVER_NONCE,
            &CLIENT_NONCE,
        )),
        "b362a581a76378a685e36618aa554e10999c30f4255129b3a38bcbbf5bf8e53c"
    );
    assert_eq!(
        hex::encode(server_proof(
            &token,
            &INSTANCE,
            &SERVER_NONCE,
            &CLIENT_NONCE,
        )),
        "b6745f5b541d1f60c8a26e0d5775aef30611f1a4934186496825b5040428dcd7"
    );
    assert_eq!(format!("{token:?}"), "IpcToken([REDACTED])");
}

#[test]
fn privileged_channels_are_domain_separated_from_each_other_and_flutter_ipc() {
    let token = IpcToken::new(TOKEN);
    let flutter = channel_client_proof(
        &token,
        AuthChannel::FlutterHost,
        &INSTANCE,
        &SERVER_NONCE,
        &CLIENT_NONCE,
    );
    let bridge_host = channel_client_proof(
        &token,
        AuthChannel::PrivilegedHost,
        &INSTANCE,
        &SERVER_NONCE,
        &CLIENT_NONCE,
    );
    let bridge_helper = channel_client_proof(
        &token,
        AuthChannel::PrivilegedHelper,
        &INSTANCE,
        &SERVER_NONCE,
        &CLIENT_NONCE,
    );

    assert_eq!(
        flutter,
        client_proof(&token, &INSTANCE, &SERVER_NONCE, &CLIENT_NONCE)
    );
    assert_ne!(flutter, bridge_host);
    assert_ne!(bridge_host, bridge_helper);
    assert_ne!(
        bridge_host,
        channel_server_proof(
            &token,
            AuthChannel::PrivilegedHost,
            &INSTANCE,
            &SERVER_NONCE,
            &CLIENT_NONCE,
        )
    );
}

#[test]
fn performs_mutually_authenticated_handshake() {
    let token = IpcToken::new(TOKEN);
    let proof = client_proof(&token, &INSTANCE, &SERVER_NONCE, &CLIENT_NONCE);
    let mut server = ServerProtocol::new(IpcToken::new(TOKEN), INSTANCE, SERVER_NONCE);
    let challenge = server.challenge();
    assert_eq!(challenge.agent_instance_id, INSTANCE);
    assert_eq!(challenge.server_nonce, SERVER_NONCE);

    let authenticated = server
        .authenticate(&authentication_frame(CLIENT_NONCE, proof))
        .expect("correct proof must authenticate");
    assert_eq!(
        authenticated.server_proof,
        server_proof(
            &IpcToken::new(TOKEN),
            &INSTANCE,
            &SERVER_NONCE,
            &CLIENT_NONCE,
        )
    );
    assert!(server.is_authenticated());
    assert_eq!(
        server.authenticate(&authentication_frame(CLIENT_NONCE, proof)),
        Err(ProtocolError::AlreadyAuthenticated)
    );
}

#[test]
fn wrong_token_context_and_cross_connection_replay_are_rejected() {
    let proof = client_proof(
        &IpcToken::new(TOKEN),
        &INSTANCE,
        &SERVER_NONCE,
        &CLIENT_NONCE,
    );
    let mutations = [
        (IpcToken::new([0x45; 32]), INSTANCE, SERVER_NONCE),
        (IpcToken::new(TOKEN), [0x12; 16], SERVER_NONCE),
        (IpcToken::new(TOKEN), INSTANCE, [0x23; 32]),
    ];
    for (token, instance, nonce) in mutations {
        let mut server = ServerProtocol::new(token, instance, nonce);
        assert_eq!(
            server.authenticate(&authentication_frame(CLIENT_NONCE, proof)),
            Err(ProtocolError::AuthenticationFailed)
        );
    }

    let mut changed_client = ServerProtocol::new(IpcToken::new(TOKEN), INSTANCE, SERVER_NONCE);
    assert_eq!(
        changed_client.authenticate(&authentication_frame([0x34; 32], proof)),
        Err(ProtocolError::AuthenticationFailed)
    );
}

#[test]
fn rejects_business_requests_before_auth_and_malformed_authentication() {
    let mut server = ServerProtocol::new(IpcToken::new(TOKEN), INSTANCE, SERVER_NONCE);
    assert_eq!(
        server.begin_request(&status_frame("status-1")),
        Err(ProtocolError::AuthenticationRequired)
    );

    let mut missing_payload = valid_frame("auth-1");
    assert_eq!(
        server.authenticate(&missing_payload),
        Err(ProtocolError::MissingPayload)
    );
    missing_payload.payload = Some(local_ipc_client_frame::Payload::Authenticate(
        LocalIpcAuthenticate {
            client_nonce: vec![0; 31],
            client_proof: vec![0; 32],
        },
    ));
    assert_eq!(
        server.authenticate(&missing_payload),
        Err(ProtocolError::InvalidAuthenticationLength)
    );
}

#[test]
fn authenticated_requests_validate_version_id_payload_duplicates_and_limit() {
    let mut server = authenticated_server();
    let mut unknown_version = status_frame("status-version");
    unknown_version.protocol_version = Some(ProtocolVersion { major: 2, minor: 0 });
    assert_eq!(
        server.begin_request(&unknown_version),
        Err(ProtocolError::UnsupportedVersion)
    );
    assert_eq!(
        server.begin_request(&status_frame("")),
        Err(ProtocolError::InvalidRequestId)
    );
    assert_eq!(
        server.begin_request(&status_frame(&"x".repeat(65))),
        Err(ProtocolError::InvalidRequestId)
    );
    assert_eq!(
        server.begin_request(&valid_frame("missing-payload")),
        Err(ProtocolError::MissingPayload)
    );

    server
        .begin_request(&status_frame("duplicate"))
        .expect("first request ID must be accepted");
    assert_eq!(
        server.begin_request(&status_frame("duplicate")),
        Err(ProtocolError::DuplicateRequestId)
    );
    server.complete_request("duplicate");
    server
        .begin_request(&status_frame("duplicate"))
        .expect("completed request ID can be reused");

    let mut limited = authenticated_server();
    for index in 0..32 {
        limited
            .begin_request(&status_frame(&format!("pending-{index}")))
            .expect("request within pending limit must succeed");
    }
    assert_eq!(
        limited.begin_request(&status_frame("pending-overflow")),
        Err(ProtocolError::PendingRequestLimit)
    );
}

fn authenticated_server() -> ServerProtocol {
    let proof = client_proof(
        &IpcToken::new(TOKEN),
        &INSTANCE,
        &SERVER_NONCE,
        &CLIENT_NONCE,
    );
    let mut server = ServerProtocol::new(IpcToken::new(TOKEN), INSTANCE, SERVER_NONCE);
    server
        .authenticate(&authentication_frame(CLIENT_NONCE, proof))
        .expect("fixture must authenticate");
    server
}

fn authentication_frame(client_nonce: [u8; 32], proof: [u8; 32]) -> LocalIpcClientFrame {
    LocalIpcClientFrame {
        payload: Some(local_ipc_client_frame::Payload::Authenticate(
            LocalIpcAuthenticate {
                client_nonce: client_nonce.to_vec(),
                client_proof: proof.to_vec(),
            },
        )),
        ..valid_frame("auth-1")
    }
}

fn status_frame(request_id: &str) -> LocalIpcClientFrame {
    LocalIpcClientFrame {
        payload: Some(local_ipc_client_frame::Payload::GetHostStatus(
            GetHostStatusRequest {},
        )),
        ..valid_frame(request_id)
    }
}

fn valid_frame(request_id: &str) -> LocalIpcClientFrame {
    LocalIpcClientFrame {
        protocol_version: Some(ProtocolVersion { major: 1, minor: 0 }),
        request_id: request_id.to_owned(),
        payload: None,
    }
}
