// SPDX-License-Identifier: MPL-2.0

mod desktop;
mod indicator;
mod peer;
mod process;
mod sas;
mod service;
mod transport;

pub use desktop::{
    DesktopDecision, DesktopError, WindowsDesktop, WindowsSessionSignal, WindowsSessionState,
    decide_desktop,
};
pub use indicator::WindowsIndicatorWindowSpec;
pub use peer::WindowsPeerPlacement;
pub use process::{HelperLaunchError, HelperLaunchSpec};
pub use sas::{SasAuthorization, SasContext, SasError, authorize_send_sas};
pub use service::{ServiceAction, ServiceControl, ServiceCore};
pub use transport::{BRIDGE_PIPE_NAME, PipeAccessPolicy};
