// SPDX-License-Identifier: MPL-2.0

use super::SessionType;
use thiserror::Error;

const RELEASE_ACK_TIMEOUT_MS: u64 = 1_000;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum MacPeerPlacement {
    Aqua { uid: u32 },
    LoginWindow,
}

impl MacPeerPlacement {
    #[must_use]
    pub const fn session_type(self) -> SessionType {
        match self {
            Self::Aqua { .. } => SessionType::Aqua,
            Self::LoginWindow => SessionType::LoginWindow,
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct MacAgentRoute {
    pub placement: MacPeerPlacement,
    pub os_session_id: u64,
    pub generation: u64,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum MacAgentAction {
    FreezeInput,
    ReleaseAllInput,
    ClosePeer,
    StopAgent,
    ClearRoute,
    PublishAgent(MacAgentRoute),
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum MacRouteError {
    #[error("macOS agent route is invalid")]
    InvalidRoute,
    #[error("macOS agent route is stale")]
    StaleRoute,
    #[error("macOS agent release acknowledgment is stale")]
    StaleAcknowledgment,
    #[error("macOS agent route transition is already pending")]
    TransitionPending,
    #[error("macOS agent route timestamp overflow")]
    TimestampOverflow,
}

#[derive(Debug, Default)]
pub struct MacAgentRouter {
    current: Option<MacAgentRoute>,
    pending: Option<PendingRoute>,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct PendingRoute {
    route: MacAgentRoute,
    release_generation: u64,
    deadline_ms: u64,
}

impl MacAgentRouter {
    #[must_use]
    pub const fn new() -> Self {
        Self {
            current: None,
            pending: None,
        }
    }

    /// Starts an initial route or freezes the current route before migration.
    ///
    /// # Errors
    ///
    /// Rejects invalid, stale, gapped, cross-session, or overlapping routes.
    pub fn begin_route(
        &mut self,
        route: MacAgentRoute,
        now_ms: u64,
    ) -> Result<Vec<MacAgentAction>, MacRouteError> {
        validate_route(route)?;
        if self.pending.is_some() {
            return Err(MacRouteError::TransitionPending);
        }
        let Some(current) = self.current else {
            self.current = Some(route);
            return Ok(vec![MacAgentAction::PublishAgent(route)]);
        };
        if route == current {
            return Ok(Vec::new());
        }
        if route.os_session_id != current.os_session_id
            || route.generation
                != current
                    .generation
                    .checked_add(1)
                    .ok_or(MacRouteError::StaleRoute)?
        {
            return Err(MacRouteError::StaleRoute);
        }
        let deadline_ms = now_ms
            .checked_add(RELEASE_ACK_TIMEOUT_MS)
            .ok_or(MacRouteError::TimestampOverflow)?;
        self.pending = Some(PendingRoute {
            route,
            release_generation: current.generation,
            deadline_ms,
        });
        Ok(freeze_actions())
    }

    /// Completes migration after the old Agent confirms input and peer release.
    ///
    /// # Errors
    ///
    /// Rejects missing or stale acknowledgments without publishing the new route.
    pub fn acknowledge_release(
        &mut self,
        generation: u64,
    ) -> Result<Vec<MacAgentAction>, MacRouteError> {
        let pending = self.pending.ok_or(MacRouteError::StaleAcknowledgment)?;
        if generation != pending.release_generation {
            return Err(MacRouteError::StaleAcknowledgment);
        }
        Ok(self.publish_pending())
    }

    /// Stops an unresponsive old Agent at the fixed deadline before publishing.
    ///
    /// # Errors
    ///
    /// Fails only when the deadline timestamp could not be represented earlier.
    pub fn poll_release_timeout(
        &mut self,
        now_ms: u64,
    ) -> Result<Vec<MacAgentAction>, MacRouteError> {
        let Some(pending) = self.pending else {
            return Ok(Vec::new());
        };
        if now_ms < pending.deadline_ms {
            return Ok(Vec::new());
        }
        Ok(self.publish_pending())
    }

    #[must_use]
    pub fn disconnect_host(&mut self) -> Vec<MacAgentAction> {
        if self.current.is_none() && self.pending.is_none() {
            return Vec::new();
        }
        self.current = None;
        self.pending = None;
        let mut actions = freeze_actions();
        actions.extend([MacAgentAction::StopAgent, MacAgentAction::ClearRoute]);
        actions
    }

    #[must_use]
    pub const fn current(&self) -> Option<MacAgentRoute> {
        self.current
    }

    #[must_use]
    pub const fn pending(&self) -> Option<MacAgentRoute> {
        match self.pending {
            Some(pending) => Some(pending.route),
            None => None,
        }
    }

    fn publish_pending(&mut self) -> Vec<MacAgentAction> {
        let pending = self.pending.take().expect("pending route checked");
        self.current = Some(pending.route);
        vec![
            MacAgentAction::StopAgent,
            MacAgentAction::PublishAgent(pending.route),
        ]
    }
}

fn validate_route(route: MacAgentRoute) -> Result<(), MacRouteError> {
    if route.os_session_id == 0 || route.generation == 0 {
        return Err(MacRouteError::InvalidRoute);
    }
    match route.placement {
        MacPeerPlacement::Aqua { uid: 0 } => Err(MacRouteError::InvalidRoute),
        MacPeerPlacement::Aqua { .. } | MacPeerPlacement::LoginWindow => Ok(()),
    }
}

fn freeze_actions() -> Vec<MacAgentAction> {
    vec![
        MacAgentAction::FreezeInput,
        MacAgentAction::ReleaseAllInput,
        MacAgentAction::ClosePeer,
    ]
}
