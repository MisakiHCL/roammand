// SPDX-License-Identifier: MPL-2.0

use thiserror::Error;

#[derive(Clone, Copy, Eq, PartialEq)]
pub struct TransportPeerIdentity {
    pub process_id: u32,
    pub os_session_id: u64,
    pub unix_uid: Option<u32>,
    pub executable_sha256: [u8; 32],
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum TransportError {
    #[error("privileged bridge transport is disconnected")]
    Disconnected,
    #[error("privileged bridge transport rejected the peer")]
    PeerRejected,
    #[error("privileged bridge transport failed closed")]
    FailedClosed,
}

pub trait LocalBridgeTransport: Send {
    /// Sends one already authenticated, bounded frame.
    ///
    /// # Errors
    ///
    /// Returns a stable transport category without exposing payload data.
    fn send(&mut self, frame: &[u8]) -> Result<(), TransportError>;

    /// Waits for one already authenticated, bounded frame.
    ///
    /// # Errors
    ///
    /// Returns a stable category on disconnect, rejection, or fail-closed state.
    fn receive(&mut self) -> Result<Vec<u8>, TransportError>;

    /// Receives one already authenticated, bounded frame when available.
    ///
    /// # Errors
    ///
    /// Returns a stable transport category without exposing peer details.
    fn try_receive(&mut self) -> Result<Option<Vec<u8>>, TransportError>;

    #[must_use]
    fn peer_identity(&self) -> Option<TransportPeerIdentity> {
        None
    }

    fn fail_closed(&mut self);
}
