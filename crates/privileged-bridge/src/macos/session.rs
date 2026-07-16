// SPDX-License-Identifier: MPL-2.0

use thiserror::Error;

const MINIMUM_MAJOR: u16 = 14;
const MINIMUM_MINOR: u16 = 4;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct MacOsVersion {
    major: u16,
    minor: u16,
    patch: u16,
}

impl MacOsVersion {
    #[must_use]
    pub const fn new(major: u16, minor: u16, patch: u16) -> Self {
        Self {
            major,
            minor,
            patch,
        }
    }

    #[must_use]
    pub const fn is_supported(self) -> bool {
        self.major > MINIMUM_MAJOR || (self.major == MINIMUM_MAJOR && self.minor >= MINIMUM_MINOR)
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ComponentRole {
    Daemon,
    HostAgent,
    SessionAgent,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum SessionType {
    Aqua,
    LoginWindow,
    Background,
    Unknown,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum DaemonCapability {
    ObserveSessions,
    RouteFrames,
}

impl DaemonCapability {
    const ALL: [Self; 2] = [Self::ObserveSessions, Self::RouteFrames];

    #[must_use]
    pub const fn all() -> &'static [Self] {
        &Self::ALL
    }
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum TrustError {
    #[error("macOS component role rejected")]
    RoleRejected,
    #[error("macOS install manifest rejected")]
    ManifestRejected,
    #[error("macOS protected path rejected")]
    PathRejected,
    #[error("macOS protected path owner rejected")]
    OwnerRejected,
    #[error("macOS protected parent is mutable")]
    MutableParent,
    #[error("macOS symbolic link rejected")]
    SymlinkRejected,
    #[error("macOS protected transport unavailable")]
    TransportUnavailable,
}

/// Validates the fixed launchd role/session/uid combinations.
///
/// # Errors
///
/// Rejects root/user/session placement that does not match the installed role.
pub const fn validate_component_role(
    role: ComponentRole,
    uid: u32,
    session_type: SessionType,
) -> Result<(), TrustError> {
    let accepted = match role {
        ComponentRole::Daemon => uid == 0 && matches!(session_type, SessionType::Background),
        ComponentRole::HostAgent => uid != 0 && matches!(session_type, SessionType::Aqua),
        ComponentRole::SessionAgent => match session_type {
            SessionType::Aqua => uid != 0,
            SessionType::LoginWindow => true,
            SessionType::Background | SessionType::Unknown => false,
        },
    };
    if accepted {
        Ok(())
    } else {
        Err(TrustError::RoleRejected)
    }
}
