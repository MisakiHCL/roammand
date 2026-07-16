// SPDX-License-Identifier: MPL-2.0

use roammand_privileged_bridge::windows::{
    DesktopDecision, HelperLaunchSpec, PipeAccessPolicy, SasAuthorization, SasContext, SasError,
    ServiceAction, ServiceControl, ServiceCore, WindowsDesktop, WindowsSessionSignal,
    WindowsSessionState, authorize_send_sas, decide_desktop,
};

fn signal(desktop: WindowsDesktop) -> WindowsSessionSignal {
    WindowsSessionSignal {
        session_id: 7,
        active_console_session_id: 7,
        state: WindowsSessionState::Active,
        desktop,
        workstation_locked: false,
    }
}

#[test]
fn maps_only_the_active_console_default_and_winlogon_desktops() {
    assert_eq!(
        decide_desktop(signal(WindowsDesktop::Default)),
        Ok(DesktopDecision::Normal { session_id: 7 })
    );
    assert_eq!(
        decide_desktop(WindowsSessionSignal {
            workstation_locked: true,
            ..signal(WindowsDesktop::Winlogon)
        }),
        Ok(DesktopDecision::LockedLogin { session_id: 7 })
    );
    assert_eq!(
        decide_desktop(signal(WindowsDesktop::Winlogon)),
        Ok(DesktopDecision::Secure { session_id: 7 })
    );
    assert_eq!(
        decide_desktop(WindowsSessionSignal {
            state: WindowsSessionState::Connected,
            ..signal(WindowsDesktop::Default)
        }),
        Ok(DesktopDecision::Transitioning)
    );

    for invalid in [
        WindowsSessionSignal {
            session_id: 0,
            ..signal(WindowsDesktop::Default)
        },
        WindowsSessionSignal {
            active_console_session_id: 8,
            ..signal(WindowsDesktop::Default)
        },
        signal(WindowsDesktop::Unknown),
    ] {
        assert!(decide_desktop(invalid).is_err());
    }
}

#[test]
fn named_pipe_and_service_controls_are_fail_closed() {
    let policy = PipeAccessPolicy::installed_default();
    assert!(policy.local_only());
    assert!(policy.reject_remote_clients());
    assert!(policy.requires_authenticated_peer_process());
    assert!(policy.allows_local_system());
    assert!(!policy.allows_everyone());

    let mut service = ServiceCore::new();
    assert_eq!(
        service.apply(ServiceControl::Start),
        vec![ServiceAction::ObserveSessions]
    );
    assert_eq!(
        service.apply(ServiceControl::SessionChanged),
        vec![ServiceAction::FreezeInput, ServiceAction::ObserveSessions]
    );
    assert_eq!(
        service.apply(ServiceControl::Stop),
        vec![
            ServiceAction::FreezeInput,
            ServiceAction::ReleaseAllInput,
            ServiceAction::StopHelper,
            ServiceAction::CloseTransport,
        ]
    );
    assert!(service.apply(ServiceControl::Stop).is_empty());
}

#[test]
fn helper_launch_is_exact_bounded_and_inherits_only_bootstrap_channel() {
    let spec = HelperLaunchSpec::new(
        r"C:\Program Files\Roammand\roammand-session-helper.exe",
        7,
        WindowsDesktop::Winlogon,
        42,
    )
    .expect("launch spec");
    assert_eq!(spec.desktop_name(), r"winsta0\winlogon");
    assert_eq!(spec.inherited_handles(), &[42]);
    assert!(spec.kill_on_job_close());
    assert!(spec.command_line().starts_with('"'));
    assert!(!spec.command_line().contains("cmd.exe"));

    for invalid in [
        "roammand-session-helper.exe",
        r"C:\Program Files\..\other.exe",
        r"\\server\share\helper.exe",
        r#"C:\Program Files\Roammand\helper.exe" --shell"#,
    ] {
        assert!(HelperLaunchSpec::new(invalid, 7, WindowsDesktop::Default, 42).is_err());
    }
    assert!(HelperLaunchSpec::new(r"C:\helper.exe", 0, WindowsDesktop::Default, 42).is_err());
    assert!(HelperLaunchSpec::new(r"C:\helper.exe", 7, WindowsDesktop::Unknown, 42).is_err());
    assert!(HelperLaunchSpec::new(r"C:\helper.exe", 7, WindowsDesktop::Default, 0).is_err());
}

#[test]
fn send_sas_requires_exact_current_controlled_winlogon_route_and_policy() {
    let allowed = SasContext {
        lease_active: true,
        control_input_granted: true,
        current_generation: 9,
        request_generation: 9,
        desktop: WindowsDesktop::Winlogon,
        system_policy_enabled: true,
    };
    assert_eq!(authorize_send_sas(allowed), Ok(SasAuthorization::SendSas));

    assert_eq!(
        authorize_send_sas(SasContext {
            lease_active: false,
            ..allowed
        }),
        Err(SasError::LeaseRequired)
    );
    assert_eq!(
        authorize_send_sas(SasContext {
            control_input_granted: false,
            ..allowed
        }),
        Err(SasError::ControlPermissionRequired)
    );
    assert_eq!(
        authorize_send_sas(SasContext {
            request_generation: 8,
            ..allowed
        }),
        Err(SasError::StaleRoute)
    );
    assert_eq!(
        authorize_send_sas(SasContext {
            desktop: WindowsDesktop::Default,
            ..allowed
        }),
        Err(SasError::WinlogonRequired)
    );
    assert_eq!(
        authorize_send_sas(SasContext {
            system_policy_enabled: false,
            ..allowed
        }),
        Err(SasError::SystemPolicyRequired)
    );
}
