// SPDX-License-Identifier: MPL-2.0

use thiserror::Error;

use super::WindowsDesktop;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct SasContext {
    pub lease_active: bool,
    pub control_input_granted: bool,
    pub current_generation: u64,
    pub request_generation: u64,
    pub desktop: WindowsDesktop,
    pub system_policy_enabled: bool,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum SasAuthorization {
    SendSas,
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum SasError {
    #[error("secure attention requires an active lease")]
    LeaseRequired,
    #[error("secure attention requires control permission")]
    ControlPermissionRequired,
    #[error("secure attention route is stale")]
    StaleRoute,
    #[error("secure attention requires the Winlogon desktop")]
    WinlogonRequired,
    #[error("secure attention is disabled by system policy")]
    SystemPolicyRequired,
}

/// Authorizes the dedicated system `SendSAS` operation.
///
/// This decision never authorizes synthetic keyboard input as a replacement.
///
/// # Errors
///
/// Returns a stable error for the first failed lease, permission, route,
/// desktop, or operating-system policy gate.
pub const fn authorize_send_sas(context: SasContext) -> Result<SasAuthorization, SasError> {
    if !context.lease_active {
        return Err(SasError::LeaseRequired);
    }
    if !context.control_input_granted {
        return Err(SasError::ControlPermissionRequired);
    }
    if context.current_generation == 0 || context.request_generation != context.current_generation {
        return Err(SasError::StaleRoute);
    }
    if !matches!(context.desktop, WindowsDesktop::Winlogon) {
        return Err(SasError::WinlogonRequired);
    }
    if !context.system_policy_enabled {
        return Err(SasError::SystemPolicyRequired);
    }
    Ok(SasAuthorization::SendSas)
}
