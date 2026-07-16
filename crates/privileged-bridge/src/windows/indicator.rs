// SPDX-License-Identifier: MPL-2.0

use thiserror::Error;

use super::WindowsDesktop;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct WindowsIndicatorWindowSpec {
    desktop: WindowsDesktop,
}

impl WindowsIndicatorWindowSpec {
    /// Creates a fixed protected-desktop window contract.
    ///
    /// # Errors
    ///
    /// Rejects unknown desktop placement.
    pub const fn for_desktop(desktop: WindowsDesktop) -> Result<Self, WindowSpecError> {
        if matches!(desktop, WindowsDesktop::Unknown) {
            return Err(WindowSpecError::UnknownDesktop);
        }
        Ok(Self { desktop })
    }

    #[must_use]
    pub const fn desktop_name(self) -> &'static str {
        match self.desktop.name() {
            Some(name) => name,
            None => "",
        }
    }

    #[must_use]
    pub const fn topmost(self) -> bool {
        true
    }

    #[must_use]
    pub const fn local_stop_only(self) -> bool {
        true
    }

    #[must_use]
    pub const fn remote_close_allowed(self) -> bool {
        false
    }
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum WindowSpecError {
    #[error("protected indicator desktop is unknown")]
    UnknownDesktop,
}
