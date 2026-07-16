// SPDX-License-Identifier: MPL-2.0

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum BridgeAvailability {
    NotInstalled,
    ApprovalRequired,
    PermissionRequired,
    UserSessionOnly,
    Ready,
    Transitioning,
    Controlled,
    Failed,
}
