// SPDX-License-Identifier: MPL-2.0

use proptest::prelude::*;
use roammand_privileged_bridge::session::{
    DesktopKind, Platform, RouteEvent, RouteSession, SessionAction, SessionError,
    SessionStateMachine,
};

fn session(generation: u64, desktop: DesktopKind) -> RouteSession {
    RouteSession {
        platform: Platform::Macos,
        os_session_id: 501,
        desktop,
        generation,
    }
}

#[test]
fn migrates_normal_locked_secure_normal_in_fail_closed_order() {
    let mut machine = SessionStateMachine::new();
    assert_eq!(
        machine.apply(RouteEvent::SessionAvailable(session(
            1,
            DesktopKind::Normal
        ))),
        Ok(vec![SessionAction::PublishRoute(session(
            1,
            DesktopKind::Normal
        ))])
    );
    machine.begin_control(1).expect("control normal desktop");

    let locked = machine
        .apply(RouteEvent::SessionAvailable(session(
            2,
            DesktopKind::LockedLogin,
        )))
        .expect("lock");
    assert_eq!(
        locked,
        vec![
            SessionAction::FreezeInput,
            SessionAction::ReleaseAllInput,
            SessionAction::PeerDisconnected,
            SessionAction::PublishRoute(session(2, DesktopKind::LockedLogin)),
        ]
    );
    assert!(!machine.input_enabled());
    machine.begin_control(2).expect("control login desktop");

    let secure = machine
        .apply(RouteEvent::SessionAvailable(session(
            3,
            DesktopKind::Secure,
        )))
        .expect("secure desktop");
    assert_eq!(secure[0], SessionAction::FreezeInput);
    assert_eq!(secure[1], SessionAction::ReleaseAllInput);
    assert_eq!(secure[2], SessionAction::PeerDisconnected);
    assert_eq!(
        secure[3],
        SessionAction::PublishRoute(session(3, DesktopKind::Secure))
    );
    machine.begin_control(3).expect("control secure desktop");

    machine
        .apply(RouteEvent::SessionAvailable(session(
            4,
            DesktopKind::Normal,
        )))
        .expect("return normal");
    assert!(!machine.input_enabled());
    assert_eq!(machine.generation(), 4);
}

#[test]
fn rejects_duplicates_with_changes_gaps_and_wrong_sessions() {
    let mut machine = SessionStateMachine::new();
    let normal = session(4, DesktopKind::Normal);
    machine
        .apply(RouteEvent::SessionAvailable(normal))
        .expect("initial observation");
    assert_eq!(
        machine.apply(RouteEvent::SessionAvailable(normal)),
        Ok(Vec::new())
    );
    assert_eq!(
        machine.apply(RouteEvent::SessionAvailable(RouteSession {
            desktop: DesktopKind::Secure,
            ..normal
        })),
        Err(SessionError::ConflictingDuplicate)
    );
    assert_eq!(
        machine.apply(RouteEvent::SessionAvailable(session(
            6,
            DesktopKind::Secure
        ))),
        Err(SessionError::GenerationGap)
    );
    assert_eq!(
        machine.apply(RouteEvent::SessionAvailable(RouteSession {
            os_session_id: 502,
            generation: 5,
            ..normal
        })),
        Err(SessionError::UnexpectedOsSession)
    );
}

#[test]
fn route_loss_helper_crash_broker_restart_and_logout_release_everything() {
    for event in [
        RouteEvent::RouteLost { generation: 2 },
        RouteEvent::HelperCrashed { generation: 2 },
        RouteEvent::BrokerRestarted { generation: 2 },
        RouteEvent::HostDisconnected { generation: 2 },
        RouteEvent::LoggedOut { generation: 2 },
    ] {
        let mut machine = SessionStateMachine::new();
        machine
            .apply(RouteEvent::SessionAvailable(session(
                1,
                DesktopKind::Normal,
            )))
            .expect("route");
        machine.begin_control(1).expect("control");

        let actions = machine.apply(event).expect("termination event");
        assert_eq!(actions[0], SessionAction::FreezeInput);
        assert_eq!(actions[1], SessionAction::ReleaseAllInput);
        assert_eq!(actions[2], SessionAction::PeerDisconnected);
        assert_eq!(actions[3], SessionAction::ClearRoute);
        assert!(!machine.input_enabled());
    }
}

proptest! {
    #[test]
    fn arbitrary_transition_sequences_never_enable_input_without_control(
        kinds in proptest::collection::vec(0_u8..3, 1..64)
    ) {
        let mut machine = SessionStateMachine::new();
        for (generation, value) in (1_u64..).zip(kinds) {
            let kind = match value {
                0 => DesktopKind::Normal,
                1 => DesktopKind::LockedLogin,
                _ => DesktopKind::Secure,
            };
            let _ = machine.apply(RouteEvent::SessionAvailable(session(generation, kind)));
            if generation % 2 == 1 {
                let _ = machine.begin_control(generation);
            }
            prop_assert!(!machine.input_enabled() || machine.has_controlled_lease());
            prop_assert_eq!(machine.generation(), generation);
        }
    }
}
