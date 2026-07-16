// SPDX-License-Identifier: MPL-2.0

use super::WindowsDesktop;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct WindowsPeerPlacement {
    pub session_id: u32,
    pub desktop: WindowsDesktop,
}

impl WindowsPeerPlacement {
    #[must_use]
    pub const fn is_routable(self) -> bool {
        self.session_id != 0 && !matches!(self.desktop, WindowsDesktop::Unknown)
    }
}
