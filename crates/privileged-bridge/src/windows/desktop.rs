// SPDX-License-Identifier: MPL-2.0

use thiserror::Error;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum WindowsDesktop {
    Default,
    Winlogon,
    Unknown,
}

impl WindowsDesktop {
    #[must_use]
    pub const fn name(self) -> Option<&'static str> {
        match self {
            Self::Default => Some(r"winsta0\default"),
            Self::Winlogon => Some(r"winsta0\winlogon"),
            Self::Unknown => None,
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum WindowsSessionState {
    Active,
    Connected,
    Disconnected,
    Idle,
    Unknown,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct WindowsSessionSignal {
    pub session_id: u32,
    pub active_console_session_id: u32,
    pub state: WindowsSessionState,
    pub desktop: WindowsDesktop,
    pub workstation_locked: bool,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum DesktopDecision {
    Normal { session_id: u32 },
    LockedLogin { session_id: u32 },
    Secure { session_id: u32 },
    Transitioning,
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum DesktopError {
    #[error("Windows desktop observation rejected")]
    Rejected,
}

/// Maps an authenticated active-console WTS observation to one fixed desktop.
///
/// # Errors
///
/// Rejects session zero, another OS session, and unknown desktop names.
pub const fn decide_desktop(signal: WindowsSessionSignal) -> Result<DesktopDecision, DesktopError> {
    if signal.session_id == 0 || signal.session_id != signal.active_console_session_id {
        return Err(DesktopError::Rejected);
    }
    if !matches!(signal.state, WindowsSessionState::Active) {
        return Ok(DesktopDecision::Transitioning);
    }
    match (signal.desktop, signal.workstation_locked) {
        (WindowsDesktop::Default, false) => Ok(DesktopDecision::Normal {
            session_id: signal.session_id,
        }),
        (WindowsDesktop::Winlogon, true) => Ok(DesktopDecision::LockedLogin {
            session_id: signal.session_id,
        }),
        (WindowsDesktop::Winlogon, false) => Ok(DesktopDecision::Secure {
            session_id: signal.session_id,
        }),
        (WindowsDesktop::Default, true) | (WindowsDesktop::Unknown, _) => {
            Err(DesktopError::Rejected)
        }
    }
}
