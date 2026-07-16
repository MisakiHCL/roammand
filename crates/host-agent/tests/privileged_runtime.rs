// SPDX-License-Identifier: MPL-2.0

#![cfg(unix)]

use std::{
    fs,
    path::Path,
    sync::{
        Arc,
        atomic::{AtomicBool, Ordering},
    },
    thread,
    time::Duration,
};

use roammand_host_agent::{
    AgentRuntime, AgentRuntimeConfig, PrivilegedBridgeRuntimeConfig, RuntimeError,
};
use roammand_host_platform::{MemorySecretStore, RuntimePaths};
use roammand_privileged_bridge::{
    helper::{HelperBackend, HelperProtocolError},
    installed::installed_file_sha256,
    proxy::ProxyEvent,
    runtime::{BrokerRuntimeConfig, HelperClientConfig, run_unix_broker, run_unix_helper},
};
use roammand_protocol::roammand::v1::{
    DevicePlatform, IceCandidate, InteractiveDesktopKind, PrivilegedInputCommand,
    PrivilegedPeerConfiguration, PrivilegedSessionDescriptor, WebRtcSessionDescription,
};
use tempfile::TempDir;

const TOKEN: [u8; 32] = [0x11; 32];
const HOST_HASH: [u8; 32] = [0x21; 32];

struct IdleBackend;

impl HelperBackend for IdleBackend {
    fn start(
        &mut self,
        _configuration: &PrivilegedPeerConfiguration,
        _offer: &WebRtcSessionDescription,
        _controller_display_name: &str,
    ) -> Result<roammand_host_webrtc::PeerAnswer, HelperProtocolError> {
        Err(HelperProtocolError::Backend)
    }

    fn restart(
        &mut self,
        configuration: &PrivilegedPeerConfiguration,
        offer: &WebRtcSessionDescription,
        controller_display_name: &str,
    ) -> Result<roammand_host_webrtc::PeerAnswer, HelperProtocolError> {
        self.start(configuration, offer, controller_display_name)
    }

    fn add_candidate(&mut self, _candidate: &IceCandidate) -> Result<(), HelperProtocolError> {
        Ok(())
    }

    fn input(&mut self, _input: &PrivilegedInputCommand) -> Result<(), HelperProtocolError> {
        Ok(())
    }

    fn secure_attention(&mut self) -> Result<(), HelperProtocolError> {
        Err(HelperProtocolError::Backend)
    }

    fn close(&mut self) -> Result<(), HelperProtocolError> {
        Ok(())
    }

    fn try_event(&mut self) -> Result<Option<ProxyEvent>, HelperProtocolError> {
        Ok(None)
    }

    fn fail_closed(&mut self) {}
}

#[tokio::test]
async fn installed_mode_probes_the_real_bridge_and_never_falls_back() {
    let temporary = TempDir::new().expect("temp");
    let socket_path = temporary.path().join("bridge.sock");
    let executable_hash = installed_file_sha256(&std::env::current_exe().expect("current exe"))
        .expect("executable hash");
    let shutdown = Arc::new(AtomicBool::new(false));
    let broker_shutdown = Arc::clone(&shutdown);
    let broker_path = socket_path.clone();
    let broker = thread::spawn(move || {
        run_unix_broker(
            &broker_path,
            BrokerRuntimeConfig::new(TOKEN, [0x61; 16], executable_hash, executable_hash, 501)
                .expect("broker config"),
            broker_shutdown.as_ref(),
            Duration::from_millis(200),
        )
    });
    wait_for_path(&socket_path);
    let helper_shutdown = Arc::clone(&shutdown);
    let helper_path = socket_path.clone();
    let helper = thread::spawn(move || {
        run_unix_helper(
            &helper_path,
            HelperClientConfig::new(
                TOKEN,
                executable_hash,
                PrivilegedSessionDescriptor {
                    platform: DevicePlatform::Macos as i32,
                    os_session_id: 501,
                    desktop_kind: InteractiveDesktopKind::Normal as i32,
                    generation: 7,
                },
            )
            .expect("helper config"),
            Box::new(IdleBackend),
            helper_shutdown.as_ref(),
            Duration::from_millis(200),
        )
    });

    let paths = RuntimePaths::from_roots(
        temporary.path().join("data"),
        temporary.path().join("runtime"),
    );
    let config = AgentRuntimeConfig::new(paths, "Host".to_owned(), DevicePlatform::Macos)
        .with_privileged_bridge(
            PrivilegedBridgeRuntimeConfig::new(socket_path, TOKEN, executable_hash, 501)
                .expect("bridge config"),
        );
    let store = MemorySecretStore::new();
    let running = retry_start(&config, &store);
    running.shutdown().await.expect("Host shutdown");

    shutdown.store(true, Ordering::Relaxed);
    assert!(helper.join().expect("helper join").is_ok());
    assert!(broker.join().expect("broker join").is_ok());

    let missing = AgentRuntimeConfig::new(
        RuntimePaths::from_roots(
            temporary.path().join("missing-data"),
            temporary.path().join("missing-runtime"),
        ),
        "Host".to_owned(),
        DevicePlatform::Macos,
    )
    .with_privileged_bridge(
        PrivilegedBridgeRuntimeConfig::new(
            temporary.path().join("missing.sock"),
            TOKEN,
            HOST_HASH,
            501,
        )
        .expect("missing bridge config"),
    );
    assert_eq!(
        AgentRuntime::start_with_store(&missing, &MemorySecretStore::new())
            .expect_err("installed mode must fail closed"),
        RuntimeError::PrivilegedBridgeUnavailable
    );
}

#[test]
fn installed_client_configuration_is_loaded_from_exact_files_and_redacted() {
    let temporary = TempDir::new().expect("temp");
    let secret = temporary.path().join("secret.bin");
    let owner = temporary.path().join("owner-id");
    let executable = temporary.path().join("host-agent");
    fs::write(&secret, TOKEN).expect("secret");
    fs::write(&owner, b"501\n").expect("owner");
    fs::write(&executable, b"host executable").expect("executable");

    let config = PrivilegedBridgeRuntimeConfig::load_installed(
        temporary.path().join("bridge.sock"),
        &secret,
        &owner,
        &executable,
    )
    .expect("installed config");
    assert_eq!(
        format!("{config:?}"),
        "PrivilegedBridgeRuntimeConfig([REDACTED])"
    );
    fs::write(&secret, [0_u8; 32]).expect("invalid secret");
    assert!(
        PrivilegedBridgeRuntimeConfig::load_installed(
            temporary.path().join("bridge.sock"),
            &secret,
            &owner,
            &executable,
        )
        .is_err()
    );
}

fn retry_start(
    config: &AgentRuntimeConfig,
    store: &MemorySecretStore,
) -> roammand_host_agent::RunningAgent {
    for _ in 0..100 {
        match AgentRuntime::start_with_store(config, store) {
            Ok(running) => return running,
            Err(RuntimeError::PrivilegedBridgeUnavailable) => {
                thread::sleep(Duration::from_millis(10));
            }
            Err(error) => panic!("Host start failed: {error:?}"),
        }
    }
    panic!("installed bridge did not become ready");
}

fn wait_for_path(path: &Path) {
    for _ in 0..100 {
        if path.exists() {
            return;
        }
        thread::sleep(Duration::from_millis(10));
    }
    panic!("broker path was not created");
}
