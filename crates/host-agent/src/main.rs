// SPDX-License-Identifier: MPL-2.0

use std::process::ExitCode;

use roammand_host_agent::{AgentRuntime, RuntimeError, production_config_from_env};

const USAGE: &str =
    "Roammand Host Agent\n\nUsage:\n  roammand-host-agent serve\n  roammand-host-agent --help";

#[tokio::main]
async fn main() -> ExitCode {
    let mut arguments = std::env::args().skip(1);
    let command = arguments.next().unwrap_or_else(|| "serve".to_owned());
    if matches!(command.as_str(), "--help" | "-h" | "help") {
        println!("{USAGE}");
        return ExitCode::SUCCESS;
    }
    if command != "serve" || arguments.next().is_some() {
        eprintln!("{USAGE}");
        return ExitCode::from(2);
    }

    match run().await {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("Host Agent failed: {error}");
            ExitCode::FAILURE
        }
    }
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
