// SPDX-License-Identifier: MPL-2.0

#![cfg(unix)]

use std::{fs, os::unix::fs::FileTypeExt};

use roammand_host_platform::{LocalTransportError, UnixLocalListener};
use tempfile::tempdir;
use tokio::net::UnixStream;

const INSTANCE_ID: [u8; 16] = [0x11; 16];
const IPC_TOKEN: [u8; 32] = [0x22; 32];

#[tokio::test]
async fn binds_private_runtime_artifacts_and_accepts_the_current_user() {
    let temporary = tempdir().expect("temporary directory must be created");
    let listener = UnixLocalListener::bind(temporary.path(), INSTANCE_ID, &IPC_TOKEN)
        .expect("listener must bind");

    assert_unix_mode(temporary.path(), 0o700);
    assert_unix_mode(listener.socket_path(), 0o600);
    assert_unix_mode(listener.token_path(), 0o600);
    assert_unix_mode(listener.discovery_path(), 0o600);
    assert_eq!(
        fs::read(listener.token_path()).expect("token file must be readable"),
        IPC_TOKEN
    );
    let discovery =
        fs::read_to_string(listener.discovery_path()).expect("discovery file must be readable");
    assert!(discovery.contains("transport=unix"));
    assert!(discovery.contains("instance_id=11111111111111111111111111111111"));
    assert!(!discovery.contains(&"22".repeat(32)));

    let client = UnixStream::connect(listener.socket_path())
        .await
        .expect("current-user client must connect");
    let server = listener
        .accept()
        .await
        .expect("current-user client must be accepted");
    drop(client);
    drop(server);
}

#[tokio::test]
async fn rejects_a_peer_uid_mismatch_before_returning_the_stream() {
    let temporary = tempdir().expect("temporary directory must be created");
    let different_uid = nix::unistd::Uid::effective().as_raw().wrapping_add(1);
    let listener = UnixLocalListener::bind_with_expected_uid_for_testing(
        temporary.path(),
        INSTANCE_ID,
        &IPC_TOKEN,
        different_uid,
    )
    .expect("listener must bind");
    let _client = UnixStream::connect(listener.socket_path())
        .await
        .expect("OS connection must reach the peer gate");

    assert!(matches!(
        listener.accept().await,
        Err(LocalTransportError::PeerUserMismatch)
    ));
}

#[tokio::test]
async fn replaces_only_a_current_user_owned_stale_socket() {
    let temporary = tempdir().expect("temporary directory must be created");
    let socket_path = temporary.path().join("host-agent.sock");
    let stale =
        std::os::unix::net::UnixListener::bind(&socket_path).expect("stale socket must be created");
    drop(stale);

    let listener = UnixLocalListener::bind(temporary.path(), INSTANCE_ID, &IPC_TOKEN)
        .expect("owned stale socket must be replaced");
    assert!(
        fs::symlink_metadata(listener.socket_path())
            .expect("socket metadata must exist")
            .file_type()
            .is_socket()
    );
    drop(listener);

    fs::write(&socket_path, b"not a socket").expect("ordinary file must be created");
    assert!(matches!(
        UnixLocalListener::bind(temporary.path(), INSTANCE_ID, &IPC_TOKEN),
        Err(LocalTransportError::UnsafeStaleEndpoint)
    ));
    assert_eq!(
        fs::read(&socket_path).expect("ordinary file must remain"),
        b"not a socket"
    );
}

#[tokio::test]
async fn rejects_a_second_listener_while_the_first_is_active() {
    let temporary = tempdir().expect("temporary directory must be created");
    let first = UnixLocalListener::bind(temporary.path(), INSTANCE_ID, &IPC_TOKEN)
        .expect("first listener must bind");

    assert!(matches!(
        UnixLocalListener::bind(temporary.path(), INSTANCE_ID, &IPC_TOKEN),
        Err(LocalTransportError::EndpointAlreadyActive)
    ));

    drop(first);
}

#[tokio::test]
async fn client_disconnect_does_not_stop_listener_and_drop_cleans_runtime_files() {
    let temporary = tempdir().expect("temporary directory must be created");
    let listener = UnixLocalListener::bind(temporary.path(), INSTANCE_ID, &IPC_TOKEN)
        .expect("listener must bind");
    let socket_path = listener.socket_path().to_owned();
    let token_path = listener.token_path().to_owned();
    let discovery_path = listener.discovery_path().to_owned();

    for _ in 0..2 {
        let client = UnixStream::connect(&socket_path)
            .await
            .expect("client must connect");
        let server = listener.accept().await.expect("client must be accepted");
        drop(client);
        drop(server);
    }
    drop(listener);

    assert!(!socket_path.exists());
    assert!(!token_path.exists());
    assert!(!discovery_path.exists());
}

fn assert_unix_mode(path: &std::path::Path, expected: u32) {
    use std::os::unix::fs::PermissionsExt;

    let mode = fs::metadata(path)
        .expect("metadata must be readable")
        .permissions()
        .mode()
        & 0o777;
    assert_eq!(mode, expected, "mode for {}", path.display());
}
