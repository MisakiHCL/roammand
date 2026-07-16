// SPDX-License-Identifier: MPL-2.0

mod indicator;
mod peer;
mod session;
mod transport;

pub use indicator::MacIndicatorWindowSpec;
pub use peer::{MacAgentAction, MacAgentRoute, MacAgentRouter, MacPeerPlacement, MacRouteError};
pub use session::{
    ComponentRole, DaemonCapability, MacOsVersion, SessionType, TrustError, validate_component_role,
};
pub use transport::InstallManifest;
#[cfg(target_family = "unix")]
pub use transport::{MacSecureSocket, SecureSocketConfig, bind_secure_socket};
