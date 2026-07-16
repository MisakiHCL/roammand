// SPDX-License-Identifier: MPL-2.0

use crate::indicator::IndicatorStatusKey;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ProtectedIndicatorCopy {
    pub product_name: &'static str,
    pub controlled: &'static str,
    pub stopping: &'static str,
    pub controller_prefix: &'static str,
    pub stop: &'static str,
}

#[must_use]
pub fn protected_indicator_copy(language_tag: &str) -> ProtectedIndicatorCopy {
    if language_tag.trim().to_ascii_lowercase().starts_with("zh") {
        ProtectedIndicatorCopy {
            product_name: "Roammand",
            controlled: "正在远程控制此设备",
            stopping: "正在停止远程控制…",
            controller_prefix: "控制端",
            stop: "停止",
        }
    } else {
        ProtectedIndicatorCopy {
            product_name: "Roammand",
            controlled: "This device is being controlled remotely",
            stopping: "Stopping remote control…",
            controller_prefix: "Controller",
            stop: "Stop",
        }
    }
}

impl ProtectedIndicatorCopy {
    #[must_use]
    pub const fn status(self, key: IndicatorStatusKey) -> &'static str {
        match key {
            IndicatorStatusKey::Controlled => self.controlled,
            IndicatorStatusKey::Transitioning
            | IndicatorStatusKey::Reconnecting
            | IndicatorStatusKey::Error
            | IndicatorStatusKey::Stopping => self.stopping,
        }
    }
}
