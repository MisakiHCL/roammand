// SPDX-License-Identifier: MPL-2.0

use roammand_protocol::protocol_limits::MAX_LOCAL_IPC_FRAME_BYTES;
use thiserror::Error;

const LENGTH_PREFIX_BYTES: usize = 4;

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum FrameError {
    #[error("local IPC frame limit must be positive")]
    InvalidLimit,
    #[error("local IPC frame cannot be empty")]
    ZeroLength,
    #[error("local IPC frame exceeds its configured limit")]
    FrameTooLarge,
    #[error("local IPC stream ended with a partial frame")]
    Truncated,
    #[error("local IPC decoder previously rejected the stream")]
    Failed,
}

/// Encodes one bounded local IPC payload with a big-endian length prefix.
///
/// # Errors
///
/// Returns an error when the payload is empty or exceeds 65,536 bytes.
pub fn encode_frame(payload: &[u8]) -> Result<Vec<u8>, FrameError> {
    encode_frame_with_limit(payload, MAX_LOCAL_IPC_FRAME_BYTES)
}

/// Encodes one payload using an explicit positive frame limit.
///
/// # Errors
///
/// Returns an error when the limit or payload length is invalid.
pub fn encode_frame_with_limit(payload: &[u8], maximum: usize) -> Result<Vec<u8>, FrameError> {
    validate_limit(maximum)?;
    validate_frame_length(payload.len(), maximum)?;
    let length = u32::try_from(payload.len()).map_err(|_| FrameError::FrameTooLarge)?;
    let mut encoded = Vec::with_capacity(LENGTH_PREFIX_BYTES + payload.len());
    encoded.extend_from_slice(&length.to_be_bytes());
    encoded.extend_from_slice(payload);
    Ok(encoded)
}

#[derive(Debug)]
pub struct FrameDecoder {
    header: [u8; LENGTH_PREFIX_BYTES],
    header_length: usize,
    expected_payload_length: Option<usize>,
    payload: Vec<u8>,
    failed: bool,
    maximum: usize,
}

impl FrameDecoder {
    #[must_use]
    pub const fn new() -> Self {
        Self {
            header: [0; LENGTH_PREFIX_BYTES],
            header_length: 0,
            expected_payload_length: None,
            payload: Vec::new(),
            failed: false,
            maximum: MAX_LOCAL_IPC_FRAME_BYTES,
        }
    }

    /// Creates a decoder with a protocol-specific positive limit.
    ///
    /// # Errors
    ///
    /// Returns [`FrameError::InvalidLimit`] when `maximum` is zero or cannot
    /// fit in the four-byte length prefix.
    pub fn with_limit(maximum: usize) -> Result<Self, FrameError> {
        match validate_limit(maximum) {
            Ok(()) => Ok(Self {
                maximum,
                ..Self::new()
            }),
            Err(error) => Err(error),
        }
    }

    /// Incrementally decodes zero or more frames from a stream chunk.
    ///
    /// # Errors
    ///
    /// Returns an error for zero/oversized declared lengths or when the decoder
    /// already rejected an earlier chunk.
    pub fn push(&mut self, chunk: &[u8]) -> Result<Vec<Vec<u8>>, FrameError> {
        if self.failed {
            return Err(FrameError::Failed);
        }
        match self.push_valid(chunk) {
            Ok(frames) => Ok(frames),
            Err(error) => {
                self.failed = true;
                Err(error)
            }
        }
    }

    /// Confirms that the stream ended exactly between frames.
    ///
    /// # Errors
    ///
    /// Returns [`FrameError::Truncated`] for a partial header/payload, or
    /// [`FrameError::Failed`] after an earlier decoding error.
    pub const fn finish(&self) -> Result<(), FrameError> {
        if self.failed {
            return Err(FrameError::Failed);
        }
        if self.header_length != 0 || self.expected_payload_length.is_some() {
            return Err(FrameError::Truncated);
        }
        Ok(())
    }

    #[must_use]
    pub const fn buffered_bytes(&self) -> usize {
        self.header_length + self.payload.len()
    }

    fn push_valid(&mut self, chunk: &[u8]) -> Result<Vec<Vec<u8>>, FrameError> {
        let mut frames = Vec::new();
        let mut offset = 0;
        while offset < chunk.len() {
            if let Some(expected) = self.expected_payload_length {
                let remaining = expected - self.payload.len();
                let copied = remaining.min(chunk.len() - offset);
                self.payload
                    .extend_from_slice(&chunk[offset..offset + copied]);
                offset += copied;
                if self.payload.len() == expected {
                    frames.push(std::mem::take(&mut self.payload));
                    self.expected_payload_length = None;
                }
                continue;
            }

            let remaining = LENGTH_PREFIX_BYTES - self.header_length;
            let copied = remaining.min(chunk.len() - offset);
            self.header[self.header_length..self.header_length + copied]
                .copy_from_slice(&chunk[offset..offset + copied]);
            self.header_length += copied;
            offset += copied;
            if self.header_length == LENGTH_PREFIX_BYTES {
                let length = usize::try_from(u32::from_be_bytes(self.header))
                    .map_err(|_| FrameError::FrameTooLarge)?;
                validate_frame_length(length, self.maximum)?;
                self.header_length = 0;
                self.expected_payload_length = Some(length);
                self.payload.reserve(length);
            }
        }
        Ok(frames)
    }
}

impl Default for FrameDecoder {
    fn default() -> Self {
        Self::new()
    }
}

const fn validate_limit(maximum: usize) -> Result<(), FrameError> {
    if maximum == 0 || maximum > u32::MAX as usize {
        return Err(FrameError::InvalidLimit);
    }
    Ok(())
}

const fn validate_frame_length(length: usize, maximum: usize) -> Result<(), FrameError> {
    if length == 0 {
        return Err(FrameError::ZeroLength);
    }
    if length > maximum {
        return Err(FrameError::FrameTooLarge);
    }
    Ok(())
}
