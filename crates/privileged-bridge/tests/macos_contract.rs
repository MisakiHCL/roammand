// SPDX-License-Identifier: MPL-2.0

#![cfg(target_family = "unix")]

use std::{
    fs,
    os::unix::fs::{MetadataExt, PermissionsExt},
};

use roammand_privileged_bridge::macos::{
    ComponentRole, DaemonCapability, InstallManifest, MacAgentAction, MacAgentRoute,
    MacAgentRouter, MacOsVersion, MacPeerPlacement, SecureSocketConfig, SessionType, TrustError,
    bind_secure_socket, validate_component_role,
};

#[test]
fn supports_only_macos_14_4_or_newer_and_explicit_launchd_roles() {
    assert!(MacOsVersion::new(14, 4, 0).is_supported());
    assert!(MacOsVersion::new(15, 0, 0).is_supported());
    assert!(!MacOsVersion::new(14, 3, 9).is_supported());

    assert!(validate_component_role(ComponentRole::Daemon, 0, SessionType::Background).is_ok());
    assert!(validate_component_role(ComponentRole::HostAgent, 501, SessionType::Aqua).is_ok());
    assert!(validate_component_role(ComponentRole::SessionAgent, 501, SessionType::Aqua).is_ok());
    assert!(
        validate_component_role(ComponentRole::SessionAgent, 0, SessionType::LoginWindow).is_ok()
    );
    for invalid in [
        (ComponentRole::Daemon, 501, SessionType::Background),
        (ComponentRole::Daemon, 0, SessionType::Aqua),
        (ComponentRole::HostAgent, 0, SessionType::Aqua),
        (ComponentRole::HostAgent, 501, SessionType::LoginWindow),
        (ComponentRole::SessionAgent, 501, SessionType::Background),
        (ComponentRole::SessionAgent, 501, SessionType::Unknown),
    ] {
        assert_eq!(
            validate_component_role(invalid.0, invalid.1, invalid.2),
            Err(TrustError::RoleRejected)
        );
    }
    assert_eq!(
        DaemonCapability::all(),
        &[
            DaemonCapability::ObserveSessions,
            DaemonCapability::RouteFrames
        ]
    );
}

#[test]
fn manifest_is_bounded_exact_versioned_and_rejects_unknown_or_duplicate_entries() {
    let host_hash = "11".repeat(32);
    let helper_hash = "22".repeat(32);
    let valid =
        format!("version=1\nhost_agent_sha256={host_hash}\nsession_agent_sha256={helper_hash}\n");
    let manifest = InstallManifest::parse(valid.as_bytes()).expect("manifest");
    assert_eq!(manifest.host_agent_sha256(), [0x11; 32]);
    assert_eq!(manifest.session_agent_sha256(), [0x22; 32]);

    for invalid in [
        valid.replace("version=1", "version=2"),
        format!("{valid}unknown=value\n"),
        format!("{valid}host_agent_sha256={host_hash}\n"),
        "version=1\n".to_owned(),
        "x".repeat(4097),
    ] {
        assert!(InstallManifest::parse(invalid.as_bytes()).is_err());
    }
}

#[test]
fn unix_socket_rejects_symlinks_mutable_parents_and_sets_private_mode() {
    let directory = tempfile::tempdir().expect("tempdir");
    let owner = fs::metadata(directory.path()).expect("metadata").uid();
    fs::set_permissions(directory.path(), fs::Permissions::from_mode(0o700)).expect("permissions");
    let socket_path = directory.path().join("bridge.sock");
    let config = SecureSocketConfig {
        socket_path: socket_path.clone(),
        expected_parent_owner: owner,
    };
    assert!(!format!("{config:?}").contains(socket_path.to_string_lossy().as_ref()));
    let socket = bind_secure_socket(&config).expect("secure socket");
    assert_eq!(
        fs::metadata(&socket_path).expect("socket metadata").mode() & 0o777,
        0o600
    );
    drop(socket);
    fs::remove_file(&socket_path).expect("remove socket");

    fs::set_permissions(directory.path(), fs::Permissions::from_mode(0o777))
        .expect("mutable permissions");
    assert_eq!(
        bind_secure_socket(&SecureSocketConfig {
            socket_path: socket_path.clone(),
            expected_parent_owner: owner,
        })
        .expect_err("mutable parent must reject"),
        TrustError::MutableParent
    );

    fs::set_permissions(directory.path(), fs::Permissions::from_mode(0o700))
        .expect("restore permissions");
    let target = directory.path().join("target");
    fs::write(&target, b"not a socket").expect("target");
    std::os::unix::fs::symlink(&target, &socket_path).expect("symlink");
    assert_eq!(
        bind_secure_socket(&SecureSocketConfig {
            socket_path,
            expected_parent_owner: owner,
        })
        .expect_err("symlink must reject"),
        TrustError::SymlinkRejected
    );
}

#[test]
fn route_change_waits_for_release_ack_or_timeout_before_publish() {
    let aqua = MacAgentRoute {
        placement: MacPeerPlacement::Aqua { uid: 501 },
        os_session_id: 7,
        generation: 1,
    };
    let login = MacAgentRoute {
        placement: MacPeerPlacement::LoginWindow,
        os_session_id: 7,
        generation: 2,
    };
    let mut router = MacAgentRouter::new();
    assert_eq!(
        router.begin_route(aqua, 1_000).expect("initial route"),
        vec![MacAgentAction::PublishAgent(aqua)]
    );
    assert_eq!(
        router.begin_route(login, 1_100).expect("transition"),
        vec![
            MacAgentAction::FreezeInput,
            MacAgentAction::ReleaseAllInput,
            MacAgentAction::ClosePeer,
        ]
    );
    assert_eq!(router.current(), Some(aqua));
    assert_eq!(router.pending(), Some(login));
    assert!(
        router
            .poll_release_timeout(1_100)
            .expect("not timed out")
            .is_empty()
    );
    assert_eq!(
        router.acknowledge_release(1).expect("release ack"),
        vec![
            MacAgentAction::StopAgent,
            MacAgentAction::PublishAgent(login),
        ]
    );
    assert_eq!(router.current(), Some(login));

    let next_aqua = MacAgentRoute {
        generation: 3,
        ..aqua
    };
    router.begin_route(next_aqua, 2_000).expect("unlock");
    assert!(
        router
            .poll_release_timeout(2_999)
            .expect("before timeout")
            .is_empty()
    );
    assert_eq!(
        router.poll_release_timeout(3_000).expect("timeout"),
        vec![
            MacAgentAction::StopAgent,
            MacAgentAction::PublishAgent(next_aqua),
        ]
    );
}

#[test]
fn route_teardown_is_fail_closed_and_stale_events_are_rejected() {
    let route = MacAgentRoute {
        placement: MacPeerPlacement::Aqua { uid: 501 },
        os_session_id: 9,
        generation: 4,
    };
    let mut router = MacAgentRouter::new();
    router.begin_route(route, 100).expect("route");
    assert!(
        router
            .begin_route(route, 101)
            .expect("duplicate")
            .is_empty()
    );
    assert!(router.acknowledge_release(3).is_err());
    assert_eq!(
        router.disconnect_host(),
        vec![
            MacAgentAction::FreezeInput,
            MacAgentAction::ReleaseAllInput,
            MacAgentAction::ClosePeer,
            MacAgentAction::StopAgent,
            MacAgentAction::ClearRoute,
        ]
    );
    assert_eq!(router.current(), None);
    assert!(router.disconnect_host().is_empty());
}
