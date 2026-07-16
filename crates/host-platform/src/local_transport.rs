// SPDX-License-Identifier: MPL-2.0

use thiserror::Error;

#[cfg(unix)]
pub(crate) const SOCKET_FILE_NAME: &str = "host-agent.sock";
pub(crate) const TOKEN_FILE_NAME: &str = "ipc-token.bin";
pub(crate) const DISCOVERY_FILE_NAME: &str = "ipc-endpoint.txt";

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum LocalTransportError {
    #[error("local IPC transport operation failed")]
    Io,
    #[error("local IPC peer belongs to another user")]
    PeerUserMismatch,
    #[error("local IPC stale endpoint is unsafe to replace")]
    UnsafeStaleEndpoint,
    #[error("local IPC endpoint is already active")]
    EndpointAlreadyActive,
    #[error("local IPC transport is unsupported on this platform")]
    UnsupportedPlatform,
}
