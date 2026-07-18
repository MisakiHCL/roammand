// SPDX-License-Identifier: MPL-2.0

use std::{
    collections::VecDeque,
    env, fmt,
    sync::Arc,
    time::{Duration, SystemTime, UNIX_EPOCH},
};

#[cfg(any(target_os = "macos", windows))]
use std::path::{Path, PathBuf};

#[cfg(target_os = "macos")]
use roammand_privileged_bridge::installed::{
    MACOS_BRIDGE_SOCKET_PATH, MACOS_HOST_AGENT_PATH, MACOS_INSTALL_SECRET_PATH, MACOS_OWNER_ID_PATH,
};

#[cfg(windows)]
use roammand_privileged_bridge::{
    installed::{
        WINDOWS_HOST_AGENT_PATH, WINDOWS_INSTALL_SECRET_PATH, installed_file_sha256,
        read_install_secret,
    },
    windows::BRIDGE_PIPE_NAME,
    windows_runtime::current_process_session_id,
};

use prost::Message;
#[cfg(unix)]
use roammand_host_platform::UnixLocalListener;
#[cfg(windows)]
use roammand_host_platform::WindowsLocalListener;
use roammand_host_platform::{
    LocalTransportError, ProtectedSecretStore, RuntimePaths, host_identity_secret_store,
};
use roammand_ipc::{FrameDecoder, IpcToken, ProtocolError, ServerProtocol, encode_frame};
use roammand_protocol::roammand::v1::{
    ErrorCode, HostPairingStateChangedEvent, HostPairingStatusSnapshot, LocalIpcClientFrame,
    LocalIpcServerFrame, ProtocolVersion, SessionTerminatedEvent, UnifiedError,
    local_ipc_server_frame,
};
use thiserror::Error;
use tokio::{
    io::{AsyncRead, AsyncReadExt, AsyncWrite, AsyncWriteExt},
    sync::{Semaphore, mpsc, watch},
    task::{JoinHandle, JoinSet},
    time::timeout,
};
use zeroize::Zeroizing;

use crate::{
    AuthorizationRegistry, FileGrantStore, HostIdentity, HostService,
    PrivilegedBridgeRuntimeConfig, RemoteRuntimeConfig,
    remote_runtime::{PreparedRemote, prepare_remote, run_remote_sessions},
};

#[cfg(any(target_os = "macos", windows))]
use crate::remote_runtime::with_remote_config_from_env;

const INSTANCE_ID_BYTES: usize = 16;
const IPC_TOKEN_BYTES: usize = 32;
const NONCE_BYTES: usize = 32;
const MAX_LOCAL_CLIENTS: usize = 4;
const OUTBOUND_QUEUE_CAPACITY: usize = 32;
const READ_BUFFER_BYTES: usize = 8192;
const HANDSHAKE_TIMEOUT: Duration = Duration::from_secs(3);
const REQUEST_TIMEOUT: Duration = Duration::from_secs(5);
const GRANT_SNAPSHOT_FILE_NAME: &str = "controller-grants.bin";
#[cfg(any(target_os = "macos", windows))]
const DATA_DIR_ENV: &str = "ROAMMAND_DATA_DIR";
#[cfg(any(target_os = "macos", windows))]
const RUNTIME_DIR_ENV: &str = "ROAMMAND_RUNTIME_DIR";
const DEVICE_NAME_ENV: &str = "ROAMMAND_DEVICE_NAME";
const DEFAULT_DEVICE_NAME: &str = "Roammand Host";
#[cfg(any(target_os = "macos", windows))]
const PRODUCT_DATA_DIRECTORY: &str = "Roammand";
// Read the pre-brand location when it already exists so identities and grants survive upgrades.
#[cfg(any(target_os = "macos", windows))]
const LEGACY_PRODUCT_DATA_DIRECTORY: &str = "Personal Remote Desktop";
const PROTOCOL_MAJOR_VERSION: u32 = 1;
const PROTOCOL_MINOR_VERSION: u32 = 0;

#[derive(Clone, Eq, PartialEq)]
pub struct AgentRuntimeConfig {
    paths: RuntimePaths,
    display_name: String,
    platform: roammand_protocol::roammand::v1::DevicePlatform,
    remote: Option<RemoteRuntimeConfig>,
    privileged_bridge: Option<PrivilegedBridgeRuntimeConfig>,
}

impl AgentRuntimeConfig {
    #[must_use]
    pub const fn new(
        paths: RuntimePaths,
        display_name: String,
        platform: roammand_protocol::roammand::v1::DevicePlatform,
    ) -> Self {
        Self {
            paths,
            display_name,
            platform,
            remote: None,
            privileged_bridge: None,
        }
    }

    #[must_use]
    pub fn with_remote(mut self, remote: RemoteRuntimeConfig) -> Self {
        self.remote = Some(remote);
        self
    }

    #[must_use]
    pub const fn remote(&self) -> Option<&RemoteRuntimeConfig> {
        self.remote.as_ref()
    }

    #[must_use]
    pub fn with_privileged_bridge(
        mut self,
        privileged_bridge: PrivilegedBridgeRuntimeConfig,
    ) -> Self {
        self.privileged_bridge = Some(privileged_bridge);
        self
    }

    #[must_use]
    pub const fn privileged_bridge(&self) -> Option<&PrivilegedBridgeRuntimeConfig> {
        self.privileged_bridge.as_ref()
    }
}

impl fmt::Debug for AgentRuntimeConfig {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("AgentRuntimeConfig")
            .field("platform", &self.platform)
            .field("remote_configured", &self.remote.is_some())
            .field(
                "privileged_bridge_required",
                &self.privileged_bridge.is_some(),
            )
            .finish_non_exhaustive()
    }
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum RuntimeError {
    #[error("Host Agent is already running")]
    AlreadyRunning,
    #[error("Host Agent is unsupported on this platform")]
    UnsupportedPlatform,
    #[error("Host Agent private paths are unavailable")]
    PrivatePaths,
    #[error("Host Agent protected identity is unavailable")]
    ProtectedIdentity,
    #[error("Host Agent authorization data is unavailable")]
    AuthorizationData,
    #[error("Host Agent local transport is unavailable")]
    LocalTransport,
    #[error("Host Agent secure random generation failed")]
    RandomGeneration,
    #[error("Host Agent system clock is unavailable")]
    SystemClock,
    #[error("Host Agent local protocol failed")]
    LocalProtocol,
    #[error("Host Agent task failed")]
    Task,
    #[error("Host Agent shutdown signal is unavailable")]
    ShutdownSignal,
    #[error("Host Agent environment is unavailable")]
    Environment,
    #[error("Host Agent remote session configuration is invalid")]
    RemoteConfiguration,
    #[error("Host Agent TLS crypto provider is unavailable")]
    TlsCryptoProvider,
    #[error("Host Agent was built without native WebRTC support")]
    NativeWebRtcUnavailable,
    #[error("Host Agent remote session runtime failed")]
    RemoteSession,
    #[error("Host Agent required privileged bridge is unavailable")]
    PrivilegedBridgeUnavailable,
    #[error("Host Agent protected-session Agent is unavailable")]
    ProtectedSessionAgentUnavailable,
    #[error("Host Agent requires Screen Recording and Accessibility permission")]
    DesktopPermissionsRequired,
}

impl RuntimeError {
    /// Returns a stable, non-sensitive startup diagnostic code.
    #[must_use]
    pub const fn startup_code(self) -> &'static str {
        match self {
            Self::AlreadyRunning => "already_running",
            Self::UnsupportedPlatform => "unsupported_platform",
            Self::PrivatePaths => "private_paths_unavailable",
            Self::ProtectedIdentity => "protected_identity_unavailable",
            Self::AuthorizationData => "authorization_data_unavailable",
            Self::LocalTransport => "local_transport_unavailable",
            Self::RandomGeneration => "random_generation_failed",
            Self::SystemClock => "system_clock_unavailable",
            Self::LocalProtocol => "local_protocol_failed",
            Self::Task => "runtime_task_failed",
            Self::ShutdownSignal => "shutdown_signal_unavailable",
            Self::Environment => "environment_unavailable",
            Self::RemoteConfiguration => "remote_configuration_invalid",
            Self::TlsCryptoProvider => "tls_provider_unavailable",
            Self::NativeWebRtcUnavailable => "native_webrtc_unavailable",
            Self::RemoteSession => "remote_session_runtime_failed",
            Self::PrivilegedBridgeUnavailable => "privileged_bridge_unavailable",
            Self::ProtectedSessionAgentUnavailable => "protected_session_agent_unavailable",
            Self::DesktopPermissionsRequired => "desktop_permissions_required",
        }
    }
}

pub struct AgentRuntime;

impl AgentRuntime {
    /// Starts the production Agent with the platform-protected identity store.
    ///
    /// # Errors
    ///
    /// Returns a stable error when the platform, protected storage, private
    /// paths, persisted grants, random source, or local transport is unavailable.
    pub fn start(config: &AgentRuntimeConfig) -> Result<RunningAgent, RuntimeError> {
        let store =
            host_identity_secret_store(config.paths.data_dir()).map_err(|error| match error {
                roammand_host_platform::SecretStoreError::UnsupportedPlatform => {
                    RuntimeError::UnsupportedPlatform
                }
                _ => RuntimeError::ProtectedIdentity,
            })?;
        Self::start_with_store(config, store.as_ref())
    }

    #[doc(hidden)]
    /// Starts the Agent with an injected protected store for platform contract tests.
    ///
    /// # Errors
    ///
    /// Returns the same stable runtime errors as [`Self::start`].
    pub fn start_with_store(
        config: &AgentRuntimeConfig,
        secret_store: &dyn ProtectedSecretStore,
    ) -> Result<RunningAgent, RuntimeError> {
        config
            .paths
            .prepare()
            .map_err(|_| RuntimeError::PrivatePaths)?;
        let identity =
            HostIdentity::load_or_create(secret_store, &config.display_name, config.platform)
                .map_err(|_| RuntimeError::ProtectedIdentity)?;
        let grant_store = Arc::new(FileGrantStore::new(
            config.paths.data_dir().join(GRANT_SNAPSHOT_FILE_NAME),
        ));
        let authorization =
            AuthorizationRegistry::load(identity.device_identity().device_id.clone(), grant_store)
                .map_err(|_| RuntimeError::AuthorizationData)?;

        let instance_id = secure_random::<INSTANCE_ID_BYTES>()?;
        let token = Arc::new(Zeroizing::new(secure_random::<IPC_TOKEN_BYTES>()?));
        let started_at_unix_ms = now_unix_ms()?;
        let listener = bind_listener(&config.paths, instance_id, token.as_ref())?;
        let service = Arc::new(HostService::new(
            identity,
            authorization,
            instance_id,
            started_at_unix_ms,
        ));
        let remote = prepare_remote(
            config.remote.as_ref(),
            config.privileged_bridge.as_ref(),
            service.clone(),
        )?;
        let (shutdown_sender, shutdown_receiver) = watch::channel(false);
        let task = tokio::spawn(run_agent(
            listener,
            service,
            token,
            instance_id,
            remote,
            shutdown_receiver,
        ));
        Ok(RunningAgent {
            shutdown_sender: Some(shutdown_sender),
            task: Some(task),
        })
    }
}

pub struct RunningAgent {
    shutdown_sender: Option<watch::Sender<bool>>,
    task: Option<JoinHandle<Result<(), RuntimeError>>>,
}

impl RunningAgent {
    /// Waits until the Agent task exits or the process receives a shutdown signal.
    ///
    /// Unlike waiting for the operating-system signal alone, this also surfaces an
    /// unexpected local IPC or remote-session failure to the owning process.
    ///
    /// # Errors
    ///
    /// Returns a stable error if signal handling or the Agent task fails.
    pub async fn wait_for_shutdown(mut self) -> Result<(), RuntimeError> {
        let mut task = self.task.take().ok_or(RuntimeError::Task)?;
        tokio::select! {
            signal_result = wait_for_shutdown_signal() => {
                signal_result?;
                if let Some(sender) = self.shutdown_sender.take() {
                    let _ = sender.send(true);
                }
                task.await.map_err(|_| RuntimeError::Task)?
            }
            task_result = &mut task => {
                self.shutdown_sender.take();
                task_result.map_err(|_| RuntimeError::Task)?
            }
        }
    }

    /// Stops accepting clients, closes active connections, joins their tasks,
    /// and removes local discovery artifacts.
    ///
    /// # Errors
    ///
    /// Returns a stable error if the Agent task failed.
    pub async fn shutdown(mut self) -> Result<(), RuntimeError> {
        if let Some(sender) = self.shutdown_sender.take() {
            let _ = sender.send(true);
        }
        let task = self.task.take().ok_or(RuntimeError::Task)?;
        task.await.map_err(|_| RuntimeError::Task)?
    }
}

impl fmt::Debug for RunningAgent {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("RunningAgent([REDACTED])")
    }
}

impl Drop for RunningAgent {
    fn drop(&mut self) {
        if let Some(sender) = self.shutdown_sender.take() {
            let _ = sender.send(true);
        }
    }
}

/// Builds the production configuration from current-user directories.
///
/// `ROAMMAND_DATA_DIR`, `ROAMMAND_RUNTIME_DIR`, and `ROAMMAND_DEVICE_NAME` may override the
/// defaults for packaging and local development. Their values are never logged.
///
/// # Errors
///
/// Returns a stable error on unsupported platforms or when a required current-
/// user directory is unavailable.
pub fn production_config_from_env() -> Result<AgentRuntimeConfig, RuntimeError> {
    let display_name = env::var(DEVICE_NAME_ENV).unwrap_or_else(|_| DEFAULT_DEVICE_NAME.to_owned());

    #[cfg(target_os = "macos")]
    {
        let home = env::var_os("HOME").ok_or(RuntimeError::Environment)?;
        let home = PathBuf::from(home);
        let data_dir = env::var_os(DATA_DIR_ENV).map_or_else(
            || preferred_product_directory(&home.join("Library/Application Support")),
            PathBuf::from,
        );
        let runtime_dir = env::var_os(RUNTIME_DIR_ENV).map_or_else(
            || preferred_product_directory(&home.join("Library/Caches")).join("runtime"),
            PathBuf::from,
        );
        let config = with_remote_config_from_env(AgentRuntimeConfig::new(
            RuntimePaths::from_roots(data_dir, runtime_dir),
            display_name,
            roammand_protocol::roammand::v1::DevicePlatform::Macos,
        ))?;
        with_macos_installed_bridge(config)
    }

    #[cfg(windows)]
    {
        let local_app_data = env::var_os("LOCALAPPDATA").ok_or(RuntimeError::Environment)?;
        let root = preferred_product_directory(&PathBuf::from(local_app_data));
        let data_dir = env::var_os(DATA_DIR_ENV).map_or_else(|| root.join("data"), PathBuf::from);
        let runtime_dir =
            env::var_os(RUNTIME_DIR_ENV).map_or_else(|| root.join("runtime"), PathBuf::from);
        let config = with_remote_config_from_env(AgentRuntimeConfig::new(
            RuntimePaths::from_roots(data_dir, runtime_dir),
            display_name,
            roammand_protocol::roammand::v1::DevicePlatform::Windows,
        ))?;
        with_windows_installed_bridge(config)
    }

    #[cfg(not(any(target_os = "macos", windows)))]
    {
        let _ = display_name;
        Err(RuntimeError::UnsupportedPlatform)
    }
}

#[cfg(any(target_os = "macos", windows))]
fn preferred_product_directory(parent: &Path) -> PathBuf {
    let current = parent.join(PRODUCT_DATA_DIRECTORY);
    let legacy = parent.join(LEGACY_PRODUCT_DATA_DIRECTORY);
    if current.exists() || !legacy.exists() {
        current
    } else {
        legacy
    }
}

#[cfg(windows)]
fn with_windows_installed_bridge(
    config: AgentRuntimeConfig,
) -> Result<AgentRuntimeConfig, RuntimeError> {
    let secret = PathBuf::from(WINDOWS_INSTALL_SECRET_PATH);
    if !secret
        .try_exists()
        .map_err(|_| RuntimeError::PrivilegedBridgeUnavailable)?
    {
        return Ok(config);
    }
    let executable = env::current_exe().map_err(|_| RuntimeError::PrivilegedBridgeUnavailable)?;
    if executable.as_path() != std::path::Path::new(WINDOWS_HOST_AGENT_PATH) {
        return Err(RuntimeError::PrivilegedBridgeUnavailable);
    }
    let privileged_bridge = PrivilegedBridgeRuntimeConfig::new(
        PathBuf::from(BRIDGE_PIPE_NAME),
        read_install_secret(&secret).map_err(|_| RuntimeError::PrivilegedBridgeUnavailable)?,
        installed_file_sha256(&executable)
            .map_err(|_| RuntimeError::PrivilegedBridgeUnavailable)?,
        current_process_session_id().map_err(|_| RuntimeError::PrivilegedBridgeUnavailable)?,
    )?;
    Ok(config.with_privileged_bridge(privileged_bridge))
}

#[cfg(target_os = "macos")]
fn with_macos_installed_bridge(
    config: AgentRuntimeConfig,
) -> Result<AgentRuntimeConfig, RuntimeError> {
    let secret = PathBuf::from(MACOS_INSTALL_SECRET_PATH);
    let owner = PathBuf::from(MACOS_OWNER_ID_PATH);
    let secret_exists = secret
        .try_exists()
        .map_err(|_| RuntimeError::PrivilegedBridgeUnavailable)?;
    let owner_exists = owner
        .try_exists()
        .map_err(|_| RuntimeError::PrivilegedBridgeUnavailable)?;
    if !secret_exists && !owner_exists {
        return Ok(config);
    }
    if !secret_exists || !owner_exists {
        return Err(RuntimeError::PrivilegedBridgeUnavailable);
    }
    let expected_executable = PathBuf::from(MACOS_HOST_AGENT_PATH);
    let executable = env::current_exe().map_err(|_| RuntimeError::PrivilegedBridgeUnavailable)?;
    if !same_macos_installed_executable(&executable, &expected_executable) {
        return Err(RuntimeError::PrivilegedBridgeUnavailable);
    }
    let privileged_bridge = PrivilegedBridgeRuntimeConfig::load_installed(
        PathBuf::from(MACOS_BRIDGE_SOCKET_PATH),
        &secret,
        &owner,
        &expected_executable,
    )?;
    Ok(config.with_privileged_bridge(privileged_bridge))
}

#[cfg(target_os = "macos")]
fn same_macos_installed_executable(actual: &Path, expected: &Path) -> bool {
    use std::{fs, os::unix::fs::MetadataExt};

    let Ok(actual_metadata) = fs::symlink_metadata(actual) else {
        return false;
    };
    let Ok(expected_metadata) = fs::symlink_metadata(expected) else {
        return false;
    };
    if !actual_metadata.is_file()
        || actual_metadata.file_type().is_symlink()
        || !expected_metadata.is_file()
        || expected_metadata.file_type().is_symlink()
    {
        return false;
    }
    actual_metadata.dev() == expected_metadata.dev()
        && actual_metadata.ino() == expected_metadata.ino()
}

/// Waits for Ctrl-C or the platform termination signal.
///
/// # Errors
///
/// Returns a stable error if the operating system signal handler cannot be installed.
pub async fn wait_for_shutdown_signal() -> Result<(), RuntimeError> {
    #[cfg(unix)]
    {
        let mut terminate =
            tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
                .map_err(|_| RuntimeError::ShutdownSignal)?;
        tokio::select! {
            result = tokio::signal::ctrl_c() => result.map_err(|_| RuntimeError::ShutdownSignal),
            _ = terminate.recv() => Ok(()),
        }
    }

    #[cfg(not(unix))]
    tokio::signal::ctrl_c()
        .await
        .map_err(|_| RuntimeError::ShutdownSignal)
}

#[cfg(unix)]
type PlatformListener = UnixLocalListener;
#[cfg(windows)]
type PlatformListener = WindowsLocalListener;

#[cfg(unix)]
fn bind_listener(
    paths: &RuntimePaths,
    instance_id: [u8; INSTANCE_ID_BYTES],
    token: &[u8; IPC_TOKEN_BYTES],
) -> Result<PlatformListener, RuntimeError> {
    UnixLocalListener::bind(paths.runtime_dir(), instance_id, token).map_err(map_transport_error)
}

#[cfg(windows)]
fn bind_listener(
    paths: &RuntimePaths,
    instance_id: [u8; INSTANCE_ID_BYTES],
    token: &[u8; IPC_TOKEN_BYTES],
) -> Result<PlatformListener, RuntimeError> {
    WindowsLocalListener::bind(paths.runtime_dir(), instance_id, token).map_err(map_transport_error)
}

const fn map_transport_error(error: LocalTransportError) -> RuntimeError {
    match error {
        LocalTransportError::EndpointAlreadyActive => RuntimeError::AlreadyRunning,
        LocalTransportError::UnsupportedPlatform => RuntimeError::UnsupportedPlatform,
        _ => RuntimeError::LocalTransport,
    }
}

async fn run_agent(
    listener: PlatformListener,
    service: Arc<HostService>,
    token: Arc<Zeroizing<[u8; IPC_TOKEN_BYTES]>>,
    instance_id: [u8; INSTANCE_ID_BYTES],
    remote: Option<PreparedRemote>,
    shutdown: watch::Receiver<bool>,
) -> Result<(), RuntimeError> {
    let listener_task = run_listener(listener, service, token, instance_id, shutdown.clone());
    if let Some(remote) = remote {
        tokio::try_join!(listener_task, run_remote_sessions(remote, shutdown))?;
        Ok(())
    } else {
        listener_task.await
    }
}

#[cfg(unix)]
async fn run_listener(
    listener: PlatformListener,
    service: Arc<HostService>,
    token: Arc<Zeroizing<[u8; IPC_TOKEN_BYTES]>>,
    instance_id: [u8; INSTANCE_ID_BYTES],
    mut shutdown: watch::Receiver<bool>,
) -> Result<(), RuntimeError> {
    let (cancel_sender, cancel_receiver) = watch::channel(false);
    let clients = Arc::new(Semaphore::new(MAX_LOCAL_CLIENTS));
    let mut connections = JoinSet::new();
    let mut accept_error = None;
    loop {
        tokio::select! {
            changed = shutdown.changed() => {
                if changed.is_err() || *shutdown.borrow() {
                    break;
                }
            }
            accepted = listener.accept() => {
                let stream = match accepted {
                    Ok(stream) => stream,
                    Err(LocalTransportError::PeerUserMismatch) => continue,
                    Err(error) => {
                        accept_error = Some(map_transport_error(error));
                        break;
                    }
                };
                spawn_connection(
                    &mut connections,
                    stream,
                    &clients,
                    &service,
                    &token,
                    instance_id,
                    cancel_receiver.clone(),
                );
            }
            Some(_) = connections.join_next(), if !connections.is_empty() => {}
        }
    }
    stop_connections(cancel_sender, connections).await?;
    accept_error.map_or(Ok(()), Err)
}

#[cfg(windows)]
async fn run_listener(
    mut listener: PlatformListener,
    service: Arc<HostService>,
    token: Arc<Zeroizing<[u8; IPC_TOKEN_BYTES]>>,
    instance_id: [u8; INSTANCE_ID_BYTES],
    mut shutdown: watch::Receiver<bool>,
) -> Result<(), RuntimeError> {
    let (cancel_sender, cancel_receiver) = watch::channel(false);
    let clients = Arc::new(Semaphore::new(MAX_LOCAL_CLIENTS));
    let mut connections = JoinSet::new();
    let mut accept_error = None;
    loop {
        tokio::select! {
            changed = shutdown.changed() => {
                if changed.is_err() || *shutdown.borrow() {
                    break;
                }
            }
            accepted = listener.accept() => {
                let stream = match accepted {
                    Ok(stream) => stream,
                    Err(LocalTransportError::PeerUserMismatch) => continue,
                    Err(error) => {
                        accept_error = Some(map_transport_error(error));
                        break;
                    }
                };
                spawn_connection(
                    &mut connections,
                    stream,
                    &clients,
                    &service,
                    &token,
                    instance_id,
                    cancel_receiver.clone(),
                );
            }
            Some(_) = connections.join_next(), if !connections.is_empty() => {}
        }
    }
    stop_connections(cancel_sender, connections).await?;
    accept_error.map_or(Ok(()), Err)
}

fn spawn_connection<Stream>(
    connections: &mut JoinSet<()>,
    stream: Stream,
    clients: &Arc<Semaphore>,
    service: &Arc<HostService>,
    token: &Arc<Zeroizing<[u8; IPC_TOKEN_BYTES]>>,
    instance_id: [u8; INSTANCE_ID_BYTES],
    cancel: watch::Receiver<bool>,
) where
    Stream: AsyncRead + AsyncWrite + Unpin + Send + 'static,
{
    let Ok(permit) = clients.clone().try_acquire_owned() else {
        return;
    };
    let service = service.clone();
    let token = token.clone();
    connections.spawn(async move {
        let _permit = permit;
        let _ = handle_connection(stream, service, token, instance_id, cancel).await;
    });
}

async fn stop_connections(
    cancel_sender: watch::Sender<bool>,
    mut connections: JoinSet<()>,
) -> Result<(), RuntimeError> {
    let _ = cancel_sender.send(true);
    while let Some(result) = connections.join_next().await {
        result.map_err(|_| RuntimeError::Task)?;
    }
    Ok(())
}

async fn handle_connection<Stream>(
    stream: Stream,
    service: Arc<HostService>,
    token: Arc<Zeroizing<[u8; IPC_TOKEN_BYTES]>>,
    instance_id: [u8; INSTANCE_ID_BYTES],
    mut cancel: watch::Receiver<bool>,
) -> Result<(), RuntimeError>
where
    Stream: AsyncRead + AsyncWrite + Unpin + Send + 'static,
{
    let (reader, writer) = tokio::io::split(stream);
    let mut reader = IncomingFrameReader::new(reader);
    let (outbound, receiver) = mpsc::channel(OUTBOUND_QUEUE_CAPACITY);
    let mut writer_task = tokio::spawn(write_frames(writer, receiver));

    let result = connection_session(
        &mut reader,
        &outbound,
        &service,
        &token,
        instance_id,
        &mut cancel,
    )
    .await;
    drop(outbound);
    let writer_result = if let Ok(joined) = timeout(REQUEST_TIMEOUT, &mut writer_task).await {
        joined.map_err(|_| RuntimeError::Task)?
    } else {
        writer_task.abort();
        return Err(RuntimeError::LocalProtocol);
    };
    result?;
    writer_result
}

async fn connection_session<Reader>(
    reader: &mut IncomingFrameReader<Reader>,
    outbound: &mpsc::Sender<LocalIpcServerFrame>,
    service: &Arc<HostService>,
    token: &Arc<Zeroizing<[u8; IPC_TOKEN_BYTES]>>,
    instance_id: [u8; INSTANCE_ID_BYTES],
    cancel: &mut watch::Receiver<bool>,
) -> Result<(), RuntimeError>
where
    Reader: AsyncRead + Unpin,
{
    let server_nonce = secure_random::<NONCE_BYTES>()?;
    let mut protocol =
        ServerProtocol::new(IpcToken::new(**token.as_ref()), instance_id, server_nonce);
    send_outbound(
        outbound,
        LocalIpcServerFrame {
            protocol_version: Some(protocol_version()),
            request_id: String::new(),
            payload: Some(local_ipc_server_frame::Payload::Challenge(
                protocol.challenge(),
            )),
        },
    )
    .await?;

    let authentication = timeout(HANDSHAKE_TIMEOUT, reader.next_frame())
        .await
        .map_err(|_| RuntimeError::LocalProtocol)??
        .ok_or(RuntimeError::LocalProtocol)?;
    let authenticated = match protocol.authenticate(&authentication) {
        Ok(authenticated) => authenticated,
        Err(error) => {
            send_outbound(
                outbound,
                protocol_error_frame(&authentication.request_id, error),
            )
            .await?;
            return Ok(());
        }
    };
    send_outbound(
        outbound,
        LocalIpcServerFrame {
            protocol_version: Some(protocol_version()),
            request_id: authentication.request_id,
            payload: Some(local_ipc_server_frame::Payload::Authenticated(
                authenticated,
            )),
        },
    )
    .await?;

    let mut events = service.subscribe_session_terminations();
    let mut pairing_states = service.subscribe_host_pairing_states();
    loop {
        tokio::select! {
            changed = cancel.changed() => {
                if changed.is_err() || *cancel.borrow() {
                    return Ok(());
                }
            }
            frame = reader.next_frame() => {
                let Some(frame) = frame? else {
                    return Ok(());
                };
                if let Err(error) = protocol.begin_request(&frame) {
                    send_outbound(outbound, protocol_error_frame(&frame.request_id, error)).await?;
                    continue;
                }
                let request_id = frame.request_id.clone();
                let service = service.clone();
                let response = timeout(
                    REQUEST_TIMEOUT,
                    tokio::task::spawn_blocking(move || {
                        now_unix_ms().map(|now| service.handle_frame(&frame, now))
                    }),
                )
                .await
                .map_err(|_| RuntimeError::LocalProtocol)?
                .map_err(|_| RuntimeError::Task)??;
                protocol.complete_request(&request_id);
                send_outbound(outbound, response).await?;
            }
            event = events.recv() => {
                match event {
                    Ok(event) => {
                        send_outbound(outbound, session_terminated_frame(event)).await?;
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => {}
                    Err(tokio::sync::broadcast::error::RecvError::Closed) => return Ok(()),
                }
            }
            state = pairing_states.recv() => {
                match state {
                    Ok(status) => {
                        send_outbound(outbound, host_pairing_state_frame(status)).await?;
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => {}
                    Err(tokio::sync::broadcast::error::RecvError::Closed) => return Ok(()),
                }
            }
        }
    }
}

fn session_terminated_frame(event: SessionTerminatedEvent) -> LocalIpcServerFrame {
    LocalIpcServerFrame {
        protocol_version: Some(protocol_version()),
        request_id: String::new(),
        payload: Some(local_ipc_server_frame::Payload::SessionTerminated(event)),
    }
}

fn host_pairing_state_frame(status: HostPairingStatusSnapshot) -> LocalIpcServerFrame {
    LocalIpcServerFrame {
        protocol_version: Some(protocol_version()),
        request_id: String::new(),
        payload: Some(local_ipc_server_frame::Payload::HostPairingStateChanged(
            HostPairingStateChangedEvent {
                status: Some(status),
            },
        )),
    }
}

async fn send_outbound(
    outbound: &mpsc::Sender<LocalIpcServerFrame>,
    frame: LocalIpcServerFrame,
) -> Result<(), RuntimeError> {
    timeout(REQUEST_TIMEOUT, outbound.send(frame))
        .await
        .map_err(|_| RuntimeError::LocalProtocol)?
        .map_err(|_| RuntimeError::LocalProtocol)
}

async fn write_frames<Writer>(
    mut writer: Writer,
    mut receiver: mpsc::Receiver<LocalIpcServerFrame>,
) -> Result<(), RuntimeError>
where
    Writer: AsyncWrite + Unpin,
{
    while let Some(frame) = receiver.recv().await {
        let bytes =
            encode_frame(&frame.encode_to_vec()).map_err(|_| RuntimeError::LocalProtocol)?;
        writer
            .write_all(&bytes)
            .await
            .map_err(|_| RuntimeError::LocalProtocol)?;
    }
    writer
        .shutdown()
        .await
        .map_err(|_| RuntimeError::LocalProtocol)
}

struct IncomingFrameReader<Reader> {
    reader: Reader,
    decoder: FrameDecoder,
    queued: VecDeque<Vec<u8>>,
}

impl<Reader> IncomingFrameReader<Reader>
where
    Reader: AsyncRead + Unpin,
{
    const fn new(reader: Reader) -> Self {
        Self {
            reader,
            decoder: FrameDecoder::new(),
            queued: VecDeque::new(),
        }
    }

    async fn next_frame(&mut self) -> Result<Option<LocalIpcClientFrame>, RuntimeError> {
        loop {
            if let Some(payload) = self.queued.pop_front() {
                return LocalIpcClientFrame::decode(payload.as_slice())
                    .map(Some)
                    .map_err(|_| RuntimeError::LocalProtocol);
            }
            let mut buffer = [0_u8; READ_BUFFER_BYTES];
            let read = self
                .reader
                .read(&mut buffer)
                .await
                .map_err(|_| RuntimeError::LocalProtocol)?;
            if read == 0 {
                self.decoder
                    .finish()
                    .map_err(|_| RuntimeError::LocalProtocol)?;
                return Ok(None);
            }
            self.queued.extend(
                self.decoder
                    .push(&buffer[..read])
                    .map_err(|_| RuntimeError::LocalProtocol)?,
            );
        }
    }
}

fn protocol_error_frame(request_id: &str, error: ProtocolError) -> LocalIpcServerFrame {
    let (code, message_key) = match error {
        ProtocolError::AuthenticationFailed | ProtocolError::InvalidAuthenticationLength => {
            (ErrorCode::AuthInvalid, "local_ipc.authentication_failed")
        }
        ProtocolError::UnsupportedVersion => (
            ErrorCode::ProtocolUnsupported,
            "local_ipc.version_unsupported",
        ),
        _ => (ErrorCode::InvalidRequest, "local_ipc.invalid_request"),
    };
    LocalIpcServerFrame {
        protocol_version: Some(protocol_version()),
        request_id: request_id.to_owned(),
        payload: Some(local_ipc_server_frame::Payload::Error(UnifiedError {
            code: code as i32,
            message_key: message_key.to_owned(),
            retryable: false,
            request_id: request_id.to_owned(),
            details: None,
        })),
    }
}

fn secure_random<const SIZE: usize>() -> Result<[u8; SIZE], RuntimeError> {
    let mut bytes = [0_u8; SIZE];
    getrandom::fill(&mut bytes).map_err(|_| RuntimeError::RandomGeneration)?;
    Ok(bytes)
}

pub(crate) fn now_unix_ms() -> Result<u64, RuntimeError> {
    let elapsed = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|_| RuntimeError::SystemClock)?;
    u64::try_from(elapsed.as_millis()).map_err(|_| RuntimeError::SystemClock)
}

const fn protocol_version() -> ProtocolVersion {
    ProtocolVersion {
        major: PROTOCOL_MAJOR_VERSION,
        minor: PROTOCOL_MINOR_VERSION,
    }
}

#[cfg(all(test, target_os = "macos"))]
mod macos_installed_executable_tests {
    use std::{fs, os::unix::fs::symlink};

    use tempfile::tempdir;

    use super::same_macos_installed_executable;

    #[test]
    fn accepts_two_paths_to_the_same_regular_file() {
        let directory = tempdir().expect("temporary directory");
        let installed = directory.path().join("installed-agent");
        let alternate = directory.path().join("alternate-agent");
        fs::write(&installed, b"agent").expect("installed fixture");
        fs::hard_link(&installed, &alternate).expect("alternate file identity");

        assert!(same_macos_installed_executable(&alternate, &installed));
    }

    #[test]
    fn rejects_different_files_and_symbolic_links() {
        let directory = tempdir().expect("temporary directory");
        let installed = directory.path().join("installed-agent");
        let other = directory.path().join("other-agent");
        let link = directory.path().join("linked-agent");
        fs::write(&installed, b"agent").expect("installed fixture");
        fs::write(&other, b"agent").expect("other fixture");
        symlink(&installed, &link).expect("symbolic link fixture");

        assert!(!same_macos_installed_executable(&other, &installed));
        assert!(!same_macos_installed_executable(&link, &installed));
    }
}
