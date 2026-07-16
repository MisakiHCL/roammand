// SPDX-License-Identifier: MPL-2.0

use std::fmt;

use crate::{HostWebRtcError, SessionConfig};

#[derive(Clone, Eq, PartialEq)]
pub struct PeerIceCandidate {
    pub candidate: String,
    pub sdp_mid: String,
    pub sdp_m_line_index: u32,
}

impl fmt::Debug for PeerIceCandidate {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("PeerIceCandidate([REDACTED])")
    }
}

#[derive(Clone, Eq, PartialEq)]
pub struct PeerAnswer {
    pub sdp: String,
    pub dtls_fingerprint_sha256: Vec<u8>,
}

impl fmt::Debug for PeerAnswer {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("PeerAnswer")
            .field("sdp_bytes", &self.sdp.len())
            .field(
                "dtls_fingerprint_bytes",
                &self.dtls_fingerprint_sha256.len(),
            )
            .field("sensitive", &"[REDACTED]")
            .finish()
    }
}

pub trait PeerBackend: Send {
    /// Starts main-display capture and creates an answer for the remote offer.
    ///
    /// # Errors
    ///
    /// Returns a stable Host WebRTC error if peer, capture, track, codec, or
    /// `DataChannel` setup fails.
    fn start(
        &mut self,
        config: &SessionConfig,
        offer_sdp: &str,
    ) -> Result<PeerAnswer, HostWebRtcError>;

    /// Renegotiates an authenticated ICE Restart offer on the existing peer.
    ///
    /// # Errors
    ///
    /// Returns a stable peer error when no reusable peer exists or the new
    /// offer cannot be applied.
    fn restart(
        &mut self,
        _config: &SessionConfig,
        _offer_sdp: &str,
    ) -> Result<PeerAnswer, HostWebRtcError> {
        Err(HostWebRtcError::InvalidState)
    }

    /// Adds one authenticated remote ICE candidate after negotiation starts.
    ///
    /// # Errors
    ///
    /// Returns a stable peer error if the candidate cannot be parsed or added.
    fn add_remote_ice_candidate(
        &mut self,
        _candidate: &PeerIceCandidate,
    ) -> Result<(), HostWebRtcError> {
        Err(HostWebRtcError::PeerFailure)
    }

    /// Stops capture and closes every native peer resource idempotently.
    ///
    /// # Errors
    ///
    /// Returns a stable Host WebRTC error if shutdown reports a failure.
    fn close(&mut self) -> Result<(), HostWebRtcError>;
}
