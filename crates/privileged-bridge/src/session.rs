// SPDX-License-Identifier: MPL-2.0

use thiserror::Error;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum Platform {
    Windows,
    Macos,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum DesktopKind {
    Normal,
    LockedLogin,
    Secure,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct RouteSession {
    pub platform: Platform,
    pub os_session_id: u64,
    pub desktop: DesktopKind,
    pub generation: u64,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum RouteEvent {
    SessionAvailable(RouteSession),
    RouteLost { generation: u64 },
    HelperCrashed { generation: u64 },
    BrokerRestarted { generation: u64 },
    HostDisconnected { generation: u64 },
    LoggedOut { generation: u64 },
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum SessionAction {
    FreezeInput,
    ReleaseAllInput,
    PeerDisconnected,
    ClearRoute,
    PublishRoute(RouteSession),
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum SessionError {
    #[error("session generation is stale")]
    StaleGeneration,
    #[error("session generation has a gap")]
    GenerationGap,
    #[error("duplicate generation conflicts with current route")]
    ConflictingDuplicate,
    #[error("unexpected operating-system session")]
    UnexpectedOsSession,
    #[error("no routable session is available")]
    RouteUnavailable,
}

#[derive(Debug, Default)]
pub struct SessionStateMachine {
    generation: u64,
    current: Option<RouteSession>,
    controlled_lease: bool,
    input_enabled: bool,
}

impl SessionStateMachine {
    #[must_use]
    pub const fn new() -> Self {
        Self {
            generation: 0,
            current: None,
            controlled_lease: false,
            input_enabled: false,
        }
    }

    /// Applies an observed graphical-session event and returns ordered effects.
    ///
    /// # Errors
    ///
    /// Returns an error without changing state for stale, gapped, conflicting,
    /// or unexpected-session observations.
    pub fn apply(&mut self, event: RouteEvent) -> Result<Vec<SessionAction>, SessionError> {
        match event {
            RouteEvent::SessionAvailable(next) => self.apply_available(next),
            RouteEvent::RouteLost { generation }
            | RouteEvent::HelperCrashed { generation }
            | RouteEvent::BrokerRestarted { generation }
            | RouteEvent::HostDisconnected { generation }
            | RouteEvent::LoggedOut { generation } => self.apply_unavailable(generation),
        }
    }

    /// Marks the current generation controlled after its lease is established.
    ///
    /// # Errors
    ///
    /// Returns [`SessionError::RouteUnavailable`] when the route or generation
    /// does not exactly match.
    pub fn begin_control(&mut self, generation: u64) -> Result<(), SessionError> {
        let route = self.current.ok_or(SessionError::RouteUnavailable)?;
        if generation != self.generation || generation != route.generation {
            return Err(SessionError::RouteUnavailable);
        }
        self.controlled_lease = true;
        self.input_enabled = true;
        Ok(())
    }

    #[must_use]
    pub const fn generation(&self) -> u64 {
        self.generation
    }

    #[must_use]
    pub const fn current(&self) -> Option<RouteSession> {
        self.current
    }

    #[must_use]
    pub const fn input_enabled(&self) -> bool {
        self.input_enabled
    }

    #[must_use]
    pub const fn has_controlled_lease(&self) -> bool {
        self.controlled_lease
    }

    fn apply_available(&mut self, next: RouteSession) -> Result<Vec<SessionAction>, SessionError> {
        if next.os_session_id == 0 {
            return Err(SessionError::UnexpectedOsSession);
        }
        if next.generation < self.generation {
            return Err(SessionError::StaleGeneration);
        }
        if next.generation == self.generation {
            return if self.current == Some(next) {
                Ok(Vec::new())
            } else {
                Err(SessionError::ConflictingDuplicate)
            };
        }
        if self.generation != 0 && next.generation != self.generation + 1 {
            return Err(SessionError::GenerationGap);
        }
        if let Some(current) = self.current
            && next.os_session_id != current.os_session_id
        {
            return Err(SessionError::UnexpectedOsSession);
        }

        let mut actions = self.freeze_actions(false);
        self.generation = next.generation;
        self.current = Some(next);
        actions.push(SessionAction::PublishRoute(next));
        Ok(actions)
    }

    fn apply_unavailable(&mut self, generation: u64) -> Result<Vec<SessionAction>, SessionError> {
        if generation < self.generation {
            return Err(SessionError::StaleGeneration);
        }
        if generation == self.generation {
            return if self.current.is_none() {
                Ok(Vec::new())
            } else {
                Err(SessionError::ConflictingDuplicate)
            };
        }
        if self.generation != 0 && generation != self.generation + 1 {
            return Err(SessionError::GenerationGap);
        }

        let actions = self.freeze_actions(true);
        self.generation = generation;
        self.current = None;
        Ok(actions)
    }

    fn freeze_actions(&mut self, clear_route: bool) -> Vec<SessionAction> {
        let mut actions = Vec::new();
        if self.controlled_lease || self.input_enabled {
            actions.extend([
                SessionAction::FreezeInput,
                SessionAction::ReleaseAllInput,
                SessionAction::PeerDisconnected,
            ]);
        }
        self.input_enabled = false;
        self.controlled_lease = false;
        if clear_route && self.current.is_some() {
            actions.push(SessionAction::ClearRoute);
        }
        actions
    }
}
