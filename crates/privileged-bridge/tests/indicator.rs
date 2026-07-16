// SPDX-License-Identifier: MPL-2.0

use roammand_privileged_bridge::{
    indicator::{
        IndicatorAction, IndicatorController, IndicatorError, IndicatorPhase, IndicatorStatusKey,
        RemoteIndicatorCommand,
    },
    macos::MacIndicatorWindowSpec,
    windows::{WindowsDesktop, WindowsIndicatorWindowSpec},
};

#[test]
fn controlled_state_is_visible_bounded_and_transitions_fail_closed() {
    let mut indicator = IndicatorController::new();
    let actions = indicator
        .show_controlled("My phone")
        .expect("show controlled indicator");
    let IndicatorAction::Show(presentation) = actions[0].clone() else {
        panic!("expected show");
    };
    assert_eq!(presentation.product_name(), "Roammand");
    assert_eq!(presentation.controller_display_name(), Some("My phone"));
    assert_eq!(presentation.status_key(), IndicatorStatusKey::Controlled);
    assert!(presentation.stop_visible());
    assert!(presentation.input_enabled());

    let actions = indicator.set_phase(IndicatorPhase::Transitioning);
    let IndicatorAction::Update(presentation) = actions[0].clone() else {
        panic!("expected update");
    };
    assert_eq!(presentation.status_key(), IndicatorStatusKey::Transitioning);
    assert!(!presentation.input_enabled());
    assert!(presentation.stop_visible());

    assert_eq!(
        indicator.show_controlled("bad\nname"),
        Err(IndicatorError::InvalidControllerName)
    );
    assert_eq!(
        indicator.show_controlled(&"x".repeat(129)),
        Err(IndicatorError::InvalidControllerName)
    );
}

#[test]
fn only_local_stop_emits_once_and_teardown_always_destroys() {
    let mut indicator = IndicatorController::new();
    indicator.show_controlled("Controller").expect("show");
    for command in [
        RemoteIndicatorCommand::Hide,
        RemoteIndicatorCommand::Close,
        RemoteIndicatorCommand::Focus,
    ] {
        assert_eq!(
            indicator.handle_remote(command),
            Err(IndicatorError::RemoteCommandRejected)
        );
    }
    assert_eq!(
        indicator.local_stop(),
        vec![
            IndicatorAction::EmergencyStop,
            IndicatorAction::Update(indicator.presentation().expect("presentation")),
        ]
    );
    assert!(indicator.local_stop().is_empty());
    assert_eq!(indicator.teardown(), vec![IndicatorAction::Destroy]);
    assert!(indicator.teardown().is_empty());
}

#[test]
fn native_window_specs_are_fixed_to_the_assigned_protected_desktop() {
    let windows = WindowsIndicatorWindowSpec::for_desktop(WindowsDesktop::Winlogon)
        .expect("Windows indicator");
    assert_eq!(windows.desktop_name(), r"winsta0\winlogon");
    assert!(windows.topmost());
    assert!(windows.local_stop_only());
    assert!(!windows.remote_close_allowed());

    let mac = MacIndicatorWindowSpec::login_window();
    assert!(mac.main_thread_only());
    assert!(mac.non_activating());
    assert!(mac.stop_is_only_focusable_control());
    assert!(!mac.inspects_screen_content());
}
