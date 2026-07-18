// SPDX-License-Identifier: MPL-2.0

use roammand_privileged_bridge::macos::{
    ComponentRole, MacOsVersion, SessionType, validate_component_role,
};
use roammand_privileged_bridge::windows::{PipeAccessPolicy, ServiceControl, ServiceCore};

const COMPONENT: &str = "roammand-privileged-bridge";
#[cfg(all(target_os = "macos", feature = "native-webrtc"))]
const MACOS_PERMISSION_STATUS_COMMAND: &str = "macos-permission-status";
#[cfg(all(target_os = "macos", feature = "native-webrtc"))]
const MACOS_REQUEST_SCREEN_RECORDING_COMMAND: &str = "macos-request-screen-recording";
#[cfg(all(target_os = "macos", feature = "native-webrtc"))]
const MACOS_REQUEST_ACCESSIBILITY_COMMAND: &str = "macos-request-accessibility";
#[cfg(all(target_os = "macos", feature = "native-webrtc"))]
const MACOS_PERMISSION_EXIT_CODE_BASE: u8 = 40;

fn main() {
    #[cfg(windows)]
    if std::env::args_os().len() == 1 {
        if windows_service_runtime::run().is_err() {
            eprintln!("{COMPONENT}: service failed");
            std::process::exit(1);
        }
        return;
    }
    #[cfg(all(target_os = "macos", feature = "native-webrtc"))]
    if let Some(exit_code) = macos_permission_command() {
        std::process::exit(i32::from(exit_code));
    }
    if let Err(error) = run(std::env::args().skip(1)) {
        eprintln!("{COMPONENT}: {error}");
        std::process::exit(1);
    }
}

#[cfg(all(target_os = "macos", feature = "native-webrtc"))]
fn macos_permission_command() -> Option<u8> {
    let mut arguments = std::env::args().skip(1);
    let command = arguments.next()?;
    if arguments.next().is_some() {
        return None;
    }
    let status = match command.as_str() {
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

fn run(mut arguments: impl Iterator<Item = String>) -> Result<(), &'static str> {
    let Some(command) = arguments.next() else {
        return Err("an installed role is required");
    };
    match command.as_str() {
        #[cfg(target_os = "macos")]
        "macos-daemon" => {
            require_no_arguments(&mut arguments)?;
            macos_runtime::run_daemon()?;
        }
        #[cfg(target_os = "macos")]
        "macos-agent" => {
            require_no_arguments(&mut arguments)?;
            macos_runtime::run_agent()?;
        }
        #[cfg(windows)]
        "windows-helper" => {
            let desktop = arguments.next().ok_or("desktop argument is required")?;
            let generation = arguments
                .next()
                .ok_or("generation argument is required")?
                .parse::<u64>()
                .map_err(|_| "generation argument is invalid")?;
            require_no_arguments(&mut arguments)?;
            windows_service_runtime::run_helper(&desktop, generation)?;
        }
        "check-macos-daemon" => {
            require_no_arguments(&mut arguments)?;
            validate_component_role(ComponentRole::Daemon, 0, SessionType::Background)
                .map_err(|_| "daemon role contract failed")?;
            if !MacOsVersion::new(14, 4, 0).is_supported() {
                return Err("macOS version contract failed");
            }
        }
        "check-macos-agent" => {
            require_no_arguments(&mut arguments)?;
            validate_component_role(ComponentRole::SessionAgent, 501, SessionType::Aqua)
                .map_err(|_| "agent role contract failed")?;
        }
        "check-windows-service" => {
            require_no_arguments(&mut arguments)?;
            let policy = PipeAccessPolicy::installed_default();
            if !policy.local_only()
                || !policy.reject_remote_clients()
                || !policy.requires_authenticated_peer_process()
                || policy.allows_everyone()
            {
                return Err("Windows service transport contract failed");
            }
            let mut service = ServiceCore::new();
            if service.apply(ServiceControl::Start).is_empty() {
                return Err("Windows service lifecycle contract failed");
            }
        }
        _ => return Err("unknown installed role"),
    }
    println!("{COMPONENT}: contract ok");
    Ok(())
}

fn require_no_arguments(arguments: &mut impl Iterator<Item = String>) -> Result<(), &'static str> {
    if arguments.next().is_some() {
        Err("unexpected argument")
    } else {
        Ok(())
    }
}

#[cfg(target_os = "macos")]
mod macos_runtime {
    use std::{
        path::Path,
        sync::{Arc, atomic::AtomicBool},
        time::Duration,
    };

    use roammand_privileged_bridge::{
        installed::{
            InstalledBridgeConfig, MACOS_BRIDGE_SOCKET_PATH, MACOS_HOST_AGENT_PATH,
            MACOS_INSTALL_SECRET_PATH, MACOS_OWNER_ID_PATH, MACOS_SESSION_AGENT_PATH,
            installed_file_sha256,
        },
        macos::{ComponentRole, MacOsVersion, SessionType, validate_component_role},
        runtime::{BrokerRuntimeConfig, run_unix_broker},
    };
    use signal_hook::{
        consts::{SIGINT, SIGTERM},
        flag,
    };

    #[cfg(feature = "native-webrtc")]
    use {
        roammand_privileged_bridge::{
            macos_indicator_runtime::run_macos_indicator,
            native_helper::NativeHelperBackend,
            native_indicator::native_indicator_channel,
            runtime::{HelperClientConfig, run_unix_helper},
        },
        roammand_protocol::roammand::v1::{
            DevicePlatform, InteractiveDesktopKind, PrivilegedSessionDescriptor,
        },
        std::{
            thread,
            time::{SystemTime, UNIX_EPOCH},
        },
    };

    const IO_TIMEOUT: Duration = Duration::from_secs(5);

    pub fn run_daemon() -> Result<(), &'static str> {
        validate_component_role(
            ComponentRole::Daemon,
            current_uid(),
            SessionType::Background,
        )
        .map_err(|_| "daemon role contract failed")?;
        validate_macos_version()?;
        let installed = installed_config()?;
        let mut instance_id = [0_u8; 16];
        getrandom::fill(&mut instance_id).map_err(|_| "secure random failed")?;
        let config = BrokerRuntimeConfig::new(
            installed.token(),
            instance_id,
            installed_file_sha256(Path::new(MACOS_HOST_AGENT_PATH))
                .map_err(|_| "Host Agent identity failed")?,
            installed_file_sha256(Path::new(MACOS_SESSION_AGENT_PATH))
                .map_err(|_| "session Agent identity failed")?,
            installed.owner_os_session_id(),
        )
        .map_err(|_| "daemon configuration failed")?;
        let shutdown = shutdown_flag()?;
        run_unix_broker(
            Path::new(MACOS_BRIDGE_SOCKET_PATH),
            config,
            shutdown.as_ref(),
            IO_TIMEOUT,
        )
        .map_err(|_| "daemon runtime failed")
    }

    #[cfg(feature = "native-webrtc")]
    pub fn run_agent() -> Result<(), &'static str> {
        let uid = current_uid();
        let session_type = if uid == 0 {
            SessionType::LoginWindow
        } else {
            SessionType::Aqua
        };
        validate_component_role(ComponentRole::SessionAgent, uid, session_type)
            .map_err(|_| "session Agent role contract failed")?;
        validate_macos_version()?;
        let installed = installed_config()?;
        let executable = std::env::current_exe().map_err(|_| "session Agent path failed")?;
        let config = HelperClientConfig::new(
            installed.token(),
            installed_file_sha256(&executable).map_err(|_| "session Agent identity failed")?,
            PrivilegedSessionDescriptor {
                platform: DevicePlatform::Macos as i32,
                os_session_id: installed.owner_os_session_id(),
                desktop_kind: if uid == 0 {
                    InteractiveDesktopKind::LockedLogin as i32
                } else {
                    InteractiveDesktopKind::Normal as i32
                },
                generation: route_generation()?,
            },
        )
        .map_err(|_| "session Agent configuration failed")?;
        let shutdown = shutdown_flag()?;
        wait_for_desktop_permissions(shutdown.as_ref())?;
        let (indicator, indicator_runtime) = native_indicator_channel();
        let worker_indicator = indicator.clone();
        let worker_shutdown = Arc::clone(&shutdown);
        let worker = thread::spawn(move || {
            let result = run_unix_helper(
                Path::new(MACOS_BRIDGE_SOCKET_PATH),
                config,
                Box::new(NativeHelperBackend::new().with_indicator(worker_indicator.clone())),
                worker_shutdown.as_ref(),
                IO_TIMEOUT,
            );
            worker_indicator.finish();
            result
        });
        let ui_result = run_macos_indicator(indicator_runtime);
        shutdown.store(true, std::sync::atomic::Ordering::Relaxed);
        let worker_result = worker
            .join()
            .map_err(|_| "session Agent worker failed")?
            .map_err(|_| "session Agent runtime failed");
        ui_result.and(worker_result)
    }

    #[cfg(feature = "native-webrtc")]
    fn wait_for_desktop_permissions(shutdown: &AtomicBool) -> Result<(), &'static str> {
        while !shutdown.load(std::sync::atomic::Ordering::Relaxed) {
            if roammand_host_platform::macos_desktop_permission_status(false, false).ready() {
                return Ok(());
            }
            thread::sleep(Duration::from_millis(500));
        }
        Err("session Agent stopped before permissions were granted")
    }

    #[cfg(not(feature = "native-webrtc"))]
    pub fn run_agent() -> Result<(), &'static str> {
        Err("session Agent was built without native WebRTC")
    }

    fn installed_config() -> Result<InstalledBridgeConfig, &'static str> {
        InstalledBridgeConfig::load(
            Path::new(MACOS_INSTALL_SECRET_PATH),
            Path::new(MACOS_OWNER_ID_PATH),
        )
        .map_err(|_| "installed bridge configuration failed")
    }

    fn shutdown_flag() -> Result<Arc<AtomicBool>, &'static str> {
        let shutdown = Arc::new(AtomicBool::new(false));
        flag::register(SIGINT, Arc::clone(&shutdown)).map_err(|_| "signal handler failed")?;
        flag::register(SIGTERM, Arc::clone(&shutdown)).map_err(|_| "signal handler failed")?;
        Ok(shutdown)
    }

    fn validate_macos_version() -> Result<(), &'static str> {
        let output = std::process::Command::new("/usr/bin/sw_vers")
            .arg("-productVersion")
            .output()
            .map_err(|_| "macOS version unavailable")?;
        if !output.status.success() {
            return Err("macOS version unavailable");
        }
        let value = std::str::from_utf8(&output.stdout)
            .map_err(|_| "macOS version unavailable")?
            .trim();
        let mut parts = value.split('.');
        let major = parse_version_part(parts.next())?;
        let minor = parse_version_part(parts.next())?;
        let patch = parts
            .next()
            .map_or(Ok(0), |part| parse_version_part(Some(part)))?;
        if parts.next().is_some() || !MacOsVersion::new(major, minor, patch).is_supported() {
            return Err("unsupported macOS version");
        }
        Ok(())
    }

    fn parse_version_part(value: Option<&str>) -> Result<u16, &'static str> {
        value
            .filter(|part| !part.is_empty() && part.bytes().all(|value| value.is_ascii_digit()))
            .ok_or("macOS version unavailable")?
            .parse()
            .map_err(|_| "macOS version unavailable")
    }

    #[cfg(feature = "native-webrtc")]
    fn route_generation() -> Result<u64, &'static str> {
        let elapsed = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map_err(|_| "system clock failed")?;
        let seconds = elapsed.as_secs();
        let process = u64::from(std::process::id());
        seconds
            .checked_shl(32)
            .and_then(|value| value.checked_add(process))
            .filter(|value| *value != 0)
            .ok_or("route generation failed")
    }

    fn current_uid() -> u32 {
        nix::unistd::Uid::effective().as_raw()
    }
}

#[cfg(windows)]
mod windows_service_runtime {
    use std::{
        ffi::OsString,
        io,
        path::Path,
        sync::{
            Arc,
            atomic::{AtomicBool, Ordering},
            mpsc,
        },
        thread::{self, JoinHandle},
        time::Duration,
    };

    use roammand_privileged_bridge::{
        installed::{
            WINDOWS_HOST_AGENT_PATH, WINDOWS_INSTALL_SECRET_PATH, WINDOWS_OWNER_SID_PATH,
            WINDOWS_SESSION_HELPER_PATH, installed_file_sha256, read_install_secret,
            read_windows_owner_sid,
        },
        runtime::{BrokerRuntimeConfig, RuntimeBridgeError, run_windows_broker},
        windows::{ServiceControl as CoreControl, ServiceCore, WindowsDesktop},
        windows_process_runtime::{WindowsHelperProcess, active_console_session_id},
    };
    use windows_service::{
        Error, Result as ServiceResult, define_windows_service,
        service::{
            ServiceControl, ServiceControlAccept, ServiceExitCode, ServiceState, ServiceStatus,
            ServiceType, SessionChangeParam, SessionChangeReason,
        },
        service_control_handler::{self, ServiceControlHandlerResult},
        service_dispatcher,
    };

    #[cfg(feature = "native-webrtc")]
    use {
        roammand_privileged_bridge::{
            native_helper::NativeHelperBackend,
            runtime::{HelperClientConfig, run_windows_helper},
            windows_indicator_runtime::run_supervised_windows_helper,
            windows_runtime::current_process_session_id,
        },
        roammand_protocol::roammand::v1::{
            DevicePlatform, InteractiveDesktopKind, PrivilegedSessionDescriptor,
        },
    };

    const SERVICE_NAME: &str = "RoammandPrivilegedBridge";
    const SERVICE_TYPE: ServiceType = ServiceType::OWN_PROCESS;
    const IO_TIMEOUT: Duration = Duration::from_secs(5);
    const CONTROL_POLL_INTERVAL: Duration = Duration::from_millis(250);

    #[derive(Clone, Copy)]
    enum ControlEvent {
        SessionChanged(SessionChangeParam),
        Stop,
    }

    pub fn run() -> ServiceResult<()> {
        service_dispatcher::start(SERVICE_NAME, ffi_service_main)
    }

    define_windows_service!(ffi_service_main, service_main);

    fn service_main(_arguments: Vec<OsString>) {
        let _ = run_service();
    }

    fn run_service() -> ServiceResult<()> {
        let (control_tx, control_rx) = mpsc::channel();
        let event_handler = move |event| match event {
            ServiceControl::Interrogate => ServiceControlHandlerResult::NoError,
            ServiceControl::SessionChange(change) => {
                let _ = control_tx.send(ControlEvent::SessionChanged(change));
                ServiceControlHandlerResult::NoError
            }
            ServiceControl::Stop | ServiceControl::Shutdown => {
                let _ = control_tx.send(ControlEvent::Stop);
                ServiceControlHandlerResult::NoError
            }
            _ => ServiceControlHandlerResult::NotImplemented,
        };
        let status = service_control_handler::register(SERVICE_NAME, event_handler)?;
        status.set_service_status(service_status(
            ServiceState::Running,
            ServiceControlAccept::STOP
                | ServiceControlAccept::SHUTDOWN
                | ServiceControlAccept::SESSION_CHANGE,
        ))?;

        let mut core = ServiceCore::new();
        let _ = core.apply(CoreControl::Start);
        let mut generation = 1_u64;
        let mut desktop = WindowsDesktop::Default;
        let mut route = RouteRuntime::start(desktop, generation).map_err(|()| service_error())?;
        loop {
            match control_rx.recv_timeout(CONTROL_POLL_INTERVAL) {
                Ok(ControlEvent::SessionChanged(change)) => {
                    let _ = core.apply(CoreControl::SessionChanged);
                    let Some(next_desktop) = desktop_for_change(change, desktop) else {
                        continue;
                    };
                    generation = generation.checked_add(1).ok_or_else(service_error)?;
                    if !route.stop() {
                        return Err(service_error());
                    }
                    desktop = next_desktop;
                    route =
                        RouteRuntime::start(desktop, generation).map_err(|()| service_error())?;
                }
                Ok(ControlEvent::Stop) | Err(mpsc::RecvTimeoutError::Disconnected) => {
                    let _ = core.apply(CoreControl::Stop);
                    let _ = route.stop();
                    break;
                }
                Err(mpsc::RecvTimeoutError::Timeout) if route.is_finished() => {
                    let _ = route.stop();
                    return Err(service_error());
                }
                Err(mpsc::RecvTimeoutError::Timeout) => {}
            }
        }
        status.set_service_status(service_status(
            ServiceState::Stopped,
            ServiceControlAccept::empty(),
        ))?;
        Ok(())
    }

    struct RouteRuntime {
        shutdown: Arc<AtomicBool>,
        broker: JoinHandle<Result<(), RuntimeBridgeError>>,
        helper: WindowsHelperProcess,
    }

    impl RouteRuntime {
        fn start(desktop: WindowsDesktop, generation: u64) -> Result<Self, ()> {
            let session_id = active_console_session_id().map_err(|_| ())?;
            let token =
                read_install_secret(Path::new(WINDOWS_INSTALL_SECRET_PATH)).map_err(|_| ())?;
            let owner_sid =
                read_windows_owner_sid(Path::new(WINDOWS_OWNER_SID_PATH)).map_err(|_| ())?;
            let mut instance_id = [0_u8; 16];
            getrandom::fill(&mut instance_id).map_err(|_| ())?;
            let config = BrokerRuntimeConfig::new(
                token,
                instance_id,
                installed_file_sha256(Path::new(WINDOWS_HOST_AGENT_PATH)).map_err(|_| ())?,
                installed_file_sha256(Path::new(WINDOWS_SESSION_HELPER_PATH)).map_err(|_| ())?,
                u64::from(session_id),
            )
            .map_err(|_| ())?;
            let shutdown = Arc::new(AtomicBool::new(false));
            let broker_shutdown = Arc::clone(&shutdown);
            let broker = thread::spawn(move || {
                run_windows_broker(owner_sid, config, broker_shutdown.as_ref(), IO_TIMEOUT)
            });
            let Ok(helper) = WindowsHelperProcess::launch(
                Path::new(WINDOWS_SESSION_HELPER_PATH),
                session_id,
                desktop,
                generation,
            ) else {
                shutdown.store(true, Ordering::Relaxed);
                let _ = broker.join();
                return Err(());
            };
            Ok(Self {
                shutdown,
                broker,
                helper,
            })
        }

        fn is_finished(&self) -> bool {
            self.broker.is_finished()
        }

        fn stop(self) -> bool {
            self.shutdown.store(true, Ordering::Relaxed);
            self.helper.stop();
            matches!(self.broker.join(), Ok(Ok(())))
        }
    }

    fn desktop_for_change(
        change: SessionChangeParam,
        current: WindowsDesktop,
    ) -> Option<WindowsDesktop> {
        let active = active_console_session_id().ok()?;
        if change.notification.session_id != active {
            return None;
        }
        let next = match change.reason {
            SessionChangeReason::SessionLock => WindowsDesktop::Winlogon,
            SessionChangeReason::SessionUnlock
            | SessionChangeReason::SessionLogon
            | SessionChangeReason::ConsoleConnect => WindowsDesktop::Default,
            SessionChangeReason::ConsoleDisconnect
            | SessionChangeReason::RemoteConnect
            | SessionChangeReason::RemoteDisconnect
            | SessionChangeReason::SessionLogoff
            | SessionChangeReason::SessionRemoteControl
            | SessionChangeReason::SessionCreate
            | SessionChangeReason::SessionTerminate => return None,
        };
        (next != current).then_some(next)
    }

    #[cfg(feature = "native-webrtc")]
    pub fn run_helper(desktop: &str, generation: u64) -> Result<(), &'static str> {
        if generation == 0 {
            return Err("Helper generation is invalid");
        }
        let (desktop_kind, assigned_desktop, secure_attention) = match desktop {
            "normal" => (
                InteractiveDesktopKind::Normal,
                WindowsDesktop::Default,
                false,
            ),
            "locked" => (
                InteractiveDesktopKind::LockedLogin,
                WindowsDesktop::Winlogon,
                true,
            ),
            "secure" => (
                InteractiveDesktopKind::Secure,
                WindowsDesktop::Winlogon,
                true,
            ),
            _ => return Err("Helper desktop is invalid"),
        };
        let executable = std::env::current_exe().map_err(|_| "Helper path failed")?;
        if executable.as_path() != Path::new(WINDOWS_SESSION_HELPER_PATH) {
            return Err("Helper installed path failed");
        }
        let session_id = current_process_session_id().map_err(|_| "Helper session failed")?;
        let config = HelperClientConfig::new(
            read_install_secret(Path::new(WINDOWS_INSTALL_SECRET_PATH))
                .map_err(|_| "Helper secret failed")?,
            installed_file_sha256(&executable).map_err(|_| "Helper identity failed")?,
            PrivilegedSessionDescriptor {
                platform: DevicePlatform::Windows as i32,
                os_session_id: session_id,
                desktop_kind: desktop_kind as i32,
                generation,
            },
        )
        .map_err(|_| "Helper configuration failed")?;
        run_supervised_windows_helper(
            executable,
            assigned_desktop,
            generation,
            move |indicator, shutdown| {
                run_windows_helper(
                    config,
                    Box::new(
                        NativeHelperBackend::new()
                            .with_secure_attention(secure_attention)
                            .with_indicator(indicator),
                    ),
                    shutdown.as_ref(),
                    IO_TIMEOUT,
                )
                .map_err(|_| ())
            },
        )
    }

    #[cfg(not(feature = "native-webrtc"))]
    pub fn run_helper(_desktop: &str, _generation: u64) -> Result<(), &'static str> {
        Err("Windows Helper was built without native WebRTC")
    }

    fn service_error() -> Error {
        Error::Winapi(io::Error::other("privileged route runtime failed"))
    }

    const fn service_status(
        current_state: ServiceState,
        controls_accepted: ServiceControlAccept,
    ) -> ServiceStatus {
        ServiceStatus {
            service_type: SERVICE_TYPE,
            current_state,
            controls_accepted,
            exit_code: ServiceExitCode::Win32(0),
            checkpoint: 0,
            wait_hint: Duration::ZERO,
            process_id: None,
        }
    }
}
