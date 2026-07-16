// SPDX-License-Identifier: MPL-2.0

#![cfg(windows)]

use std::fs;

use roammand_host_platform::{
    WindowsLocalListener, same_windows_user_sid_for_testing,
    windows_current_user_dacl_sddl_for_testing,
};
use tempfile::tempdir;
use tokio::net::windows::named_pipe::ClientOptions;

const INSTANCE_ID: [u8; 16] = [0x31; 16];
const IPC_TOKEN: [u8; 32] = [0x42; 32];

#[tokio::test]
async fn named_pipe_accepts_the_current_user_and_writes_private_discovery() {
    let temporary = tempdir().expect("temporary directory must be created");
    let mut listener = WindowsLocalListener::bind(temporary.path(), INSTANCE_ID, &IPC_TOKEN)
        .expect("listener must bind");
    assert_eq!(
        fs::read(listener.token_path()).expect("token file must be readable"),
        IPC_TOKEN
    );
    let discovery =
        fs::read_to_string(listener.discovery_path()).expect("discovery file must be readable");
    assert!(discovery.contains("transport=named-pipe"));
    assert!(discovery.contains("instance_id=31313131313131313131313131313131"));
    assert!(!discovery.contains(&"42".repeat(32)));

    let client = ClientOptions::new()
        .open(listener.pipe_name())
        .expect("current-user client must open pipe");
    let server = listener
        .accept()
        .await
        .expect("current-user client must be accepted");
    drop(client);
    drop(server);
}

#[test]
fn named_pipe_dacl_contains_only_system_and_current_user_entries() {
    let sddl =
        windows_current_user_dacl_sddl_for_testing().expect("current-user SDDL must be available");
    assert!(sddl.starts_with("D:P(A;;FA;;;SY)(A;;FA;;;S-1-"));
    assert!(!sddl.contains(";;;WD)"));
    assert!(!sddl.contains(";;;BU)"));
    assert!(!sddl.contains(";;;BA)"));
}

#[test]
fn windows_peer_sid_gate_rejects_a_different_user() {
    assert!(same_windows_user_sid_for_testing(
        "S-1-5-21-1",
        "S-1-5-21-1"
    ));
    assert!(!same_windows_user_sid_for_testing(
        "S-1-5-21-1",
        "S-1-5-21-2"
    ));
}

#[tokio::test]
async fn dropping_named_pipe_listener_cleans_token_and_discovery() {
    let temporary = tempdir().expect("temporary directory must be created");
    let listener = WindowsLocalListener::bind(temporary.path(), INSTANCE_ID, &IPC_TOKEN)
        .expect("listener must bind");
    let token_path = listener.token_path().to_owned();
    let discovery_path = listener.discovery_path().to_owned();
    drop(listener);

    assert!(!token_path.exists());
    assert!(!discovery_path.exists());
}
