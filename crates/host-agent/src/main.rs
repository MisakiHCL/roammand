// SPDX-License-Identifier: MPL-2.0

use std::process::ExitCode;

use roammand_host_agent::{AgentRuntime, RuntimeError, production_config_from_env};
#[cfg(target_os = "macos")]
use roammand_host_platform::{MacOsKeychainSecretStore, ProtectedSecretStore};

const USAGE: &str =
    "Roammand Host Agent\n\nUsage:\n  roammand-host-agent serve\n  roammand-host-agent --help";
#[cfg(all(target_os = "macos", feature = "native-webrtc"))]
const MACOS_PERMISSION_STATUS_COMMAND: &str = "macos-permission-status";
#[cfg(all(target_os = "macos", feature = "native-webrtc"))]
const MACOS_REQUEST_SCREEN_RECORDING_COMMAND: &str = "macos-request-screen-recording";
#[cfg(all(target_os = "macos", feature = "native-webrtc"))]
const MACOS_REQUEST_ACCESSIBILITY_COMMAND: &str = "macos-request-accessibility";
#[cfg(all(target_os = "macos", feature = "native-webrtc"))]
const MACOS_PERMISSION_EXIT_CODE_BASE: u8 = 40;
#[cfg(target_os = "macos")]
const MACOS_DELETE_HOST_IDENTITY_COMMAND: &str = "macos-delete-host-identity";

#[tokio::main]
async fn main() -> ExitCode {
    let mut arguments = std::env::args().skip(1);
    let command = arguments.next().unwrap_or_else(|| "serve".to_owned());
    if matches!(command.as_str(), "--help" | "-h" | "help") {
        println!("{USAGE}");
        return ExitCode::SUCCESS;
    }
    #[cfg(target_os = "macos")]
    if command == MACOS_DELETE_HOST_IDENTITY_COMMAND {
        if arguments.next().is_some() {
            eprintln!("{USAGE}");
            return ExitCode::from(2);
        }
        return if MacOsKeychainSecretStore::for_host_identity()
            .delete()
            .is_ok()
        {
            ExitCode::SUCCESS
        } else {
            ExitCode::FAILURE
        };
    }
    #[cfg(all(target_os = "macos", feature = "native-webrtc"))]
    if let Some(exit_code) = macos_permission_command(&command) {
        if arguments.next().is_some() {
            eprintln!("{USAGE}");
            return ExitCode::from(2);
        }
        return ExitCode::from(exit_code);
    }
    if command != "serve" || arguments.next().is_some() {
        eprintln!("{USAGE}");
        return ExitCode::from(2);
    }

    match run().await {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("ROAMMAND_STARTUP_ERROR={}", error.startup_code());
            eprintln!("Host Agent failed: {error}");
            ExitCode::FAILURE
        }
    }
}

#[cfg(all(target_os = "macos", feature = "native-webrtc"))]
fn macos_permission_command(command: &str) -> Option<u8> {
    let status = match command {
        MACOS_PERMISSION_STATUS_COMMAND => {
            roammand_host_platform::macos_desktop_permission_status(false, false)
        }
        MACOS_REQUEST_SCREEN_RECORDING_COMMAND => {
            roammand_host_platform::macos_desktop_permission_status(true, false)
        }
        MACOS_REQUEST_ACCESSIBILITY_COMMAND => {
            roammand_host_platform::macos_desktop_permission_status(false, true)
        }
        _ => return None,
    };
    Some(MACOS_PERMISSION_EXIT_CODE_BASE + status.exit_code())
}

async fn run() -> Result<(), roammand_host_agent::RuntimeError> {
    install_tls_crypto_provider()?;
    let config = production_config_from_env()?;
    let remote_sessions_enabled = config.remote().is_some();
    let running = AgentRuntime::start(&config)?;
    let remote_state = if remote_sessions_enabled {
        "enabled"
    } else {
        "disabled"
    };
    println!("Host Agent ready (remote sessions: {remote_state})");
    running.wait_for_shutdown().await
}

fn install_tls_crypto_provider() -> Result<(), RuntimeError> {
    if rustls::crypto::CryptoProvider::get_default().is_some() {
        return Ok(());
    }
    rustls::crypto::ring::default_provider()
        .install_default()
        .map_err(|_| RuntimeError::TlsCryptoProvider)
}
