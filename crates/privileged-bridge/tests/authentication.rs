// SPDX-License-Identifier: MPL-2.0

use roammand_ipc::{AuthChannel, IpcToken, channel_client_proof};
use roammand_privileged_bridge::auth::{
    AuthenticationError, BridgeAuthenticator, BridgeRole, NonceReplayGuard,
};

const SECRET: [u8; 32] = [0x41; 32];
const INSTANCE: [u8; 16] = [0x42; 16];
const SERVER_NONCE: [u8; 32] = [0x43; 32];
const CLIENT_NONCE: [u8; 32] = [0x44; 32];

#[test]
fn host_and_helper_use_distinct_mutual_authentication_contexts() {
    let host_proof = proof(
        BridgeRole::HostAgent,
        SECRET,
        INSTANCE,
        SERVER_NONCE,
        CLIENT_NONCE,
    );
    let helper_proof = proof(
        BridgeRole::SessionHelper,
        SECRET,
        INSTANCE,
        SERVER_NONCE,
        CLIENT_NONCE,
    );
    assert_ne!(host_proof, helper_proof);

    let mut guard = NonceReplayGuard::new(32).expect("guard");
    let mut server = BridgeAuthenticator::new(
        BridgeRole::HostAgent,
        IpcToken::new(SECRET),
        INSTANCE,
        SERVER_NONCE,
    );
    let server_proof = server
        .authenticate(&CLIENT_NONCE, &host_proof, &mut guard)
        .expect("host proof");
    assert_ne!(server_proof, host_proof);
    assert!(server.is_authenticated());
}

#[test]
fn rejects_cross_protocol_wrong_secret_instance_reflection_and_replay() {
    let host_proof = proof(
        BridgeRole::HostAgent,
        SECRET,
        INSTANCE,
        SERVER_NONCE,
        CLIENT_NONCE,
    );
    let flutter_proof = channel_client_proof(
        &IpcToken::new(SECRET),
        AuthChannel::FlutterHost,
        &INSTANCE,
        &SERVER_NONCE,
        &CLIENT_NONCE,
    );
    let cases = [
        (BridgeRole::SessionHelper, SECRET, INSTANCE, flutter_proof),
        (BridgeRole::SessionHelper, SECRET, INSTANCE, host_proof),
        (BridgeRole::HostAgent, [0x45; 32], INSTANCE, host_proof),
        (BridgeRole::HostAgent, SECRET, [0x46; 16], host_proof),
    ];
    for (role, secret, instance, candidate) in cases {
        let mut server =
            BridgeAuthenticator::new(role, IpcToken::new(secret), instance, SERVER_NONCE);
        let mut guard = NonceReplayGuard::new(32).expect("guard");
        assert_eq!(
            server.authenticate(&CLIENT_NONCE, &candidate, &mut guard),
            Err(AuthenticationError::AuthenticationFailed)
        );
    }

    let mut guard = NonceReplayGuard::new(32).expect("guard");
    let mut first = BridgeAuthenticator::new(
        BridgeRole::HostAgent,
        IpcToken::new(SECRET),
        INSTANCE,
        SERVER_NONCE,
    );
    first
        .authenticate(&CLIENT_NONCE, &host_proof, &mut guard)
        .expect("first use");
    let mut replay = BridgeAuthenticator::new(
        BridgeRole::HostAgent,
        IpcToken::new(SECRET),
        INSTANCE,
        SERVER_NONCE,
    );
    assert_eq!(
        replay.authenticate(&CLIENT_NONCE, &host_proof, &mut guard),
        Err(AuthenticationError::NonceReused)
    );
}

#[test]
fn rejects_reflected_nonces_malformed_lengths_and_repeat_authentication() {
    let host_proof = proof(
        BridgeRole::HostAgent,
        SECRET,
        INSTANCE,
        SERVER_NONCE,
        CLIENT_NONCE,
    );
    let mut guard = NonceReplayGuard::new(32).expect("guard");
    let mut server = BridgeAuthenticator::new(
        BridgeRole::HostAgent,
        IpcToken::new(SECRET),
        INSTANCE,
        SERVER_NONCE,
    );
    assert_eq!(
        server.authenticate(&SERVER_NONCE, &[0; 32], &mut guard),
        Err(AuthenticationError::ReflectedNonce)
    );
    assert_eq!(
        server.authenticate(&CLIENT_NONCE[..31], &host_proof, &mut guard),
        Err(AuthenticationError::InvalidLength)
    );
    assert_eq!(
        server.authenticate(&CLIENT_NONCE, &host_proof[..31], &mut guard),
        Err(AuthenticationError::InvalidLength)
    );
    server
        .authenticate(&CLIENT_NONCE, &host_proof, &mut guard)
        .expect("authenticate");
    assert_eq!(
        server.authenticate(&CLIENT_NONCE, &host_proof, &mut guard),
        Err(AuthenticationError::AlreadyAuthenticated)
    );
    assert_eq!(
        format!("{server:?}"),
        "BridgeAuthenticator { role: HostAgent, authenticated: true }"
    );
}

#[test]
fn replay_cache_evicts_oldest_nonce_without_blocking_new_connections() {
    const CAPACITY: usize = 2;

    let mut guard = NonceReplayGuard::new(CAPACITY).expect("guard");
    for value in [0x44, 0x45, 0x46] {
        let client_nonce = [value; 32];
        let candidate = proof(
            BridgeRole::HostAgent,
            SECRET,
            INSTANCE,
            SERVER_NONCE,
            client_nonce,
        );
        let mut server = BridgeAuthenticator::new(
            BridgeRole::HostAgent,
            IpcToken::new(SECRET),
            INSTANCE,
            SERVER_NONCE,
        );
        server
            .authenticate(&client_nonce, &candidate, &mut guard)
            .expect("bounded cache must continue accepting fresh nonces");
    }

    for retained_value in [0x45, 0x46] {
        let retained_nonce = [retained_value; 32];
        let retained_proof = proof(
            BridgeRole::HostAgent,
            SECRET,
            INSTANCE,
            SERVER_NONCE,
            retained_nonce,
        );
        let mut replay = BridgeAuthenticator::new(
            BridgeRole::HostAgent,
            IpcToken::new(SECRET),
            INSTANCE,
            SERVER_NONCE,
        );
        assert_eq!(
            replay.authenticate(&retained_nonce, &retained_proof, &mut guard),
            Err(AuthenticationError::NonceReused)
        );
    }

    let evicted_nonce = [0x44; 32];
    let evicted_proof = proof(
        BridgeRole::HostAgent,
        SECRET,
        INSTANCE,
        SERVER_NONCE,
        evicted_nonce,
    );
    let mut next_connection = BridgeAuthenticator::new(
        BridgeRole::HostAgent,
        IpcToken::new(SECRET),
        INSTANCE,
        SERVER_NONCE,
    );
    next_connection
        .authenticate(&evicted_nonce, &evicted_proof, &mut guard)
        .expect("the oldest nonce must be evicted in FIFO order");
}

fn proof(
    role: BridgeRole,
    secret: [u8; 32],
    instance: [u8; 16],
    server_nonce: [u8; 32],
    client_nonce: [u8; 32],
) -> [u8; 32] {
    channel_client_proof(
        &IpcToken::new(secret),
        role.auth_channel(),
        &instance,
        &server_nonce,
        &client_nonce,
    )
}
