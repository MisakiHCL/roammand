// SPDX-License-Identifier: MPL-2.0

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct MacIndicatorWindowSpec;

impl MacIndicatorWindowSpec {
    #[must_use]
    pub const fn login_window() -> Self {
        Self
    }

    #[must_use]
    pub const fn main_thread_only(self) -> bool {
        true
    }

    #[must_use]
    pub const fn non_activating(self) -> bool {
        true
    }

    #[must_use]
    pub const fn stop_is_only_focusable_control(self) -> bool {
        true
    }

    #[must_use]
    pub const fn inspects_screen_content(self) -> bool {
        false
    }
}
