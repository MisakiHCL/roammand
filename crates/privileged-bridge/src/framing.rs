// SPDX-License-Identifier: MPL-2.0

use std::collections::{HashSet, VecDeque};

use roammand_ipc::{FrameDecoder, FrameError, encode_frame_with_limit};
use roammand_protocol::protocol_limits::{
    MAX_PRIVILEGED_BRIDGE_FRAME_BYTES, MAX_REQUEST_ID_UTF8_BYTES,
};
use thiserror::Error;

const MAX_PENDING_REQUESTS: usize = 32;
const MAX_CRITICAL_EVENTS: usize = 256;

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum BridgeFrameError {
    #[error("privileged bridge frame is invalid")]
    Frame(#[from] FrameError),
    #[error("privileged bridge input must contain exactly one frame")]
    ExpectedSingleFrame,
}

/// Encodes one 256 KiB-bounded bridge frame.
///
/// # Errors
///
/// Returns an error for an empty or oversized payload.
pub fn encode_bridge_frame(payload: &[u8]) -> Result<Vec<u8>, FrameError> {
    encode_frame_with_limit(payload, MAX_PRIVILEGED_BRIDGE_FRAME_BYTES)
}

/// Decodes exactly one complete bridge frame, rejecting trailing bytes/frames.
///
/// # Errors
///
/// Returns an error for invalid framing, truncation, or anything other than one frame.
pub fn decode_exact_bridge_frame(encoded: &[u8]) -> Result<Vec<u8>, BridgeFrameError> {
    let mut decoder = BridgeFrameDecoder::new();
    let frames = decoder.push(encoded)?;
    decoder.finish()?;
    let mut frames = frames.into_iter();
    let frame = frames.next().ok_or(BridgeFrameError::ExpectedSingleFrame)?;
    if frames.next().is_some() {
        return Err(BridgeFrameError::ExpectedSingleFrame);
    }
    Ok(frame)
}

#[derive(Debug)]
pub struct BridgeFrameDecoder(FrameDecoder);

impl BridgeFrameDecoder {
    /// Creates a decoder using the compile-time bridge frame limit.
    ///
    /// # Panics
    ///
    /// Panics only if the protocol's positive 256 KiB constant stops fitting
    /// the four-byte framing format.
    #[must_use]
    pub fn new() -> Self {
        Self(
            FrameDecoder::with_limit(MAX_PRIVILEGED_BRIDGE_FRAME_BYTES)
                .expect("bridge frame limit is a positive u32"),
        )
    }

    /// Pushes a stream chunk into the bridge decoder.
    ///
    /// # Errors
    ///
    /// Returns framing errors before any Protobuf decoding occurs.
    pub fn push(&mut self, chunk: &[u8]) -> Result<Vec<Vec<u8>>, FrameError> {
        self.0.push(chunk)
    }

    /// Confirms the bridge stream ended between frames.
    ///
    /// # Errors
    ///
    /// Returns an error after invalid or partial framing.
    pub const fn finish(&self) -> Result<(), FrameError> {
        self.0.finish()
    }

    #[must_use]
    pub const fn buffered_bytes(&self) -> usize {
        self.0.buffered_bytes()
    }
}

impl Default for BridgeFrameDecoder {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum RequestError {
    #[error("bridge request identifier is invalid")]
    InvalidRequestId,
    #[error("bridge request identifier is already pending")]
    DuplicateRequest,
    #[error("bridge pending request limit reached")]
    PendingLimit,
    #[error("bridge response does not match a pending request")]
    StaleResponse,
}

#[derive(Debug, Default)]
pub struct RequestTracker {
    pending: HashSet<String>,
}

impl RequestTracker {
    #[must_use]
    pub fn new() -> Self {
        Self {
            pending: HashSet::with_capacity(MAX_PENDING_REQUESTS),
        }
    }

    /// Begins one bounded request correlation.
    ///
    /// # Errors
    ///
    /// Rejects invalid, duplicate, or excessive pending request identifiers.
    pub fn begin(&mut self, request_id: String) -> Result<(), RequestError> {
        if request_id.is_empty() || request_id.len() > MAX_REQUEST_ID_UTF8_BYTES {
            return Err(RequestError::InvalidRequestId);
        }
        if self.pending.contains(&request_id) {
            return Err(RequestError::DuplicateRequest);
        }
        if self.pending.len() >= MAX_PENDING_REQUESTS {
            return Err(RequestError::PendingLimit);
        }
        self.pending.insert(request_id);
        Ok(())
    }

    /// Completes one pending request and rejects unsolicited/stale responses.
    ///
    /// # Errors
    ///
    /// Returns [`RequestError::StaleResponse`] for an unknown identifier.
    pub fn complete(&mut self, request_id: &str) -> Result<(), RequestError> {
        if !self.pending.remove(request_id) {
            return Err(RequestError::StaleResponse);
        }
        Ok(())
    }

    #[must_use]
    pub fn pending_count(&self) -> usize {
        self.pending.len()
    }
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum EventQueueError {
    #[error("privileged bridge critical event queue overflowed")]
    CriticalOverflow,
    #[error("privileged bridge event queue is failed closed")]
    Failed,
}

pub struct EventQueue<T> {
    critical: VecDeque<T>,
    fast: Option<T>,
    failed: bool,
}

impl<T> EventQueue<T> {
    #[must_use]
    pub fn new() -> Self {
        Self {
            critical: VecDeque::with_capacity(MAX_CRITICAL_EVENTS),
            fast: None,
            failed: false,
        }
    }

    /// Enqueues a critical event or fails the queue closed on overflow.
    ///
    /// # Errors
    ///
    /// Returns overflow exactly once and [`EventQueueError::Failed`] thereafter.
    pub fn push_critical(&mut self, event: T) -> Result<(), EventQueueError> {
        if self.failed {
            return Err(EventQueueError::Failed);
        }
        if self.critical.len() >= MAX_CRITICAL_EVENTS {
            self.fail_closed();
            return Err(EventQueueError::CriticalOverflow);
        }
        self.critical.push_back(event);
        Ok(())
    }

    /// Replaces the pending lossy fast-pointer event with the newest value.
    ///
    /// # Errors
    ///
    /// Returns [`EventQueueError::Failed`] after a critical overflow.
    pub fn push_fast(&mut self, event: T) -> Result<(), EventQueueError> {
        if self.failed {
            return Err(EventQueueError::Failed);
        }
        self.fast = Some(event);
        Ok(())
    }

    /// Pops the oldest critical event.
    ///
    /// # Errors
    ///
    /// Returns [`EventQueueError::Failed`] after fail-closed overflow.
    pub fn pop_critical(&mut self) -> Result<Option<T>, EventQueueError> {
        if self.failed {
            return Err(EventQueueError::Failed);
        }
        Ok(self.critical.pop_front())
    }

    pub fn pop_fast(&mut self) -> Option<T> {
        if self.failed {
            return None;
        }
        self.fast.take()
    }

    #[must_use]
    pub const fn is_failed(&self) -> bool {
        self.failed
    }

    fn fail_closed(&mut self) {
        self.failed = true;
        self.critical.clear();
        self.fast = None;
    }
}

impl<T> Default for EventQueue<T> {
    fn default() -> Self {
        Self::new()
    }
}
