// SPDX-License-Identifier: MPL-2.0

use roammand_host_webrtc::{HostPeerSession, PeerAnswer, PeerIceCandidate};
use roammand_protocol::roammand::v1::{
    SessionAnswerAuthentication, SessionOfferAuthentication, WebRtcSessionDescription,
};

use crate::{RemotePeerEventSource, RemoteSessionError};

pub(super) const MAX_PENDING_ICE_CANDIDATES: usize = 64;
pub(super) const MAX_PENDING_ICE_BYTES: usize = 65_536;
pub(super) const PENDING_SESSION_LIFETIME_MS: u64 = 30_000;
// The Host must outlive the Controller's bounded 30-second recovery window so
// the final authenticated ICE Restart still has time to complete.
pub(super) const ACTIVE_RECONNECT_LIFETIME_MS: u64 = 45_000;

pub(super) struct PendingSession {
    pub(super) controller_device_id: Vec<u8>,
    pub(super) session_id: Vec<u8>,
    pub(super) request_id: String,
    pub(super) created_at_unix_ms: u64,
    pub(super) authentication: Option<SessionOfferAuthentication>,
    pub(super) description: Option<WebRtcSessionDescription>,
    pub(super) candidates: Vec<PeerIceCandidate>,
    candidate_bytes: usize,
}

impl PendingSession {
    pub(super) fn new(
        controller_device_id: Vec<u8>,
        session_id: Vec<u8>,
        request_id: String,
        created_at_unix_ms: u64,
    ) -> Self {
        Self {
            controller_device_id,
            session_id,
            request_id,
            created_at_unix_ms,
            authentication: None,
            description: None,
            candidates: Vec::new(),
            candidate_bytes: 0,
        }
    }

    pub(super) fn push_candidate(
        &mut self,
        candidate: PeerIceCandidate,
    ) -> Result<(), RemoteSessionError> {
        let candidate_bytes = candidate
            .candidate
            .len()
            .checked_add(candidate.sdp_mid.len())
            .and_then(|value| value.checked_add(self.candidate_bytes))
            .ok_or(RemoteSessionError::PendingIceLimit)?;
        if self.candidates.len() >= MAX_PENDING_ICE_CANDIDATES
            || candidate_bytes > MAX_PENDING_ICE_BYTES
        {
            return Err(RemoteSessionError::PendingIceLimit);
        }
        self.candidates.push(candidate);
        self.candidate_bytes = candidate_bytes;
        Ok(())
    }

    pub(super) fn is_ready(&self) -> bool {
        self.authentication.is_some() && self.description.is_some()
    }
}

pub(super) struct FailedSessionAttempt {
    controller_device_id: Vec<u8>,
    session_id: Vec<u8>,
    failed_at_unix_ms: u64,
}

impl FailedSessionAttempt {
    pub(super) fn new(
        controller_device_id: Vec<u8>,
        session_id: Vec<u8>,
        failed_at_unix_ms: u64,
    ) -> Self {
        Self {
            controller_device_id,
            session_id,
            failed_at_unix_ms,
        }
    }

    pub(super) fn matches(&self, controller_device_id: &[u8], session_id: &[u8]) -> bool {
        self.controller_device_id == controller_device_id && self.session_id == session_id
    }

    pub(super) fn is_expired(&self, now_unix_ms: u64) -> bool {
        now_unix_ms.saturating_sub(self.failed_at_unix_ms) > PENDING_SESSION_LIFETIME_MS
    }
}

pub(super) struct ActiveSession {
    pub(super) controller_device_id: Vec<u8>,
    pub(super) session_id: Vec<u8>,
    pub(super) session: HostPeerSession,
    pub(super) events: Box<dyn RemotePeerEventSource>,
    pub(super) reconnect: Option<PendingSession>,
    pub(super) reconnect_generation: u32,
    pub(super) reconnect_deadline_unix_ms: Option<u64>,
}

pub(super) struct StartedSession {
    pub(super) controller_device_id: Vec<u8>,
    pub(super) session_id: Vec<u8>,
    pub(super) answer: PeerAnswer,
    pub(super) answer_authentication: SessionAnswerAuthentication,
}
