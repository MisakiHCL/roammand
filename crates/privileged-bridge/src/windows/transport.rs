// SPDX-License-Identifier: MPL-2.0

pub const BRIDGE_PIPE_NAME: &str = r"\\.\pipe\RoammandPrivilegedBridge-v1";

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PipeAccessPolicy;

impl PipeAccessPolicy {
    #[must_use]
    pub const fn installed_default() -> Self {
        Self
    }

    #[must_use]
    pub const fn local_only(self) -> bool {
        true
    }

    #[must_use]
    pub const fn reject_remote_clients(self) -> bool {
        true
    }

    #[must_use]
    pub const fn requires_authenticated_peer_process(self) -> bool {
        true
    }

    #[must_use]
    pub const fn allows_local_system(self) -> bool {
        true
    }

    #[must_use]
    pub const fn allows_everyone(self) -> bool {
        false
    }
}
