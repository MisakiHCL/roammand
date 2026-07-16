// SPDX-License-Identifier: MPL-2.0

use std::collections::HashSet;

use roammand_protocol::{
    protocol_limits::{
        MAX_REQUEST_ID_UTF8_BYTES, MINIMUM_PROTOCOL_MINOR_VERSION, PROTOCOL_MAJOR_VERSION,
    },
    roammand::v1::{
        LocalIpcAuthenticated, LocalIpcChallenge, LocalIpcClientFrame, ProtocolVersion,
        local_ipc_client_frame,
    },
};
use thiserror::Error;

use crate::auth::{IpcToken, server_proof, verify_client_proof};

const NONCE_BYTES: usize = 32;
const MAX_PENDING_REQUESTS: usize = 32;

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum ProtocolError {
    #[error("local IPC authentication is required")]
    AuthenticationRequired,
    #[error("local IPC connection is already authenticated")]
    AlreadyAuthenticated,
    #[error("local IPC authentication failed")]
    AuthenticationFailed,
    #[error("local IPC authentication fields have invalid lengths")]
    InvalidAuthenticationLength,
    #[error("local IPC protocol version is unsupported")]
    UnsupportedVersion,
    #[error("local IPC request identifier is invalid")]
    InvalidRequestId,
    #[error("local IPC request identifier is already pending")]
    DuplicateRequestId,
    #[error("local IPC request is missing its payload")]
    MissingPayload,
    #[error("local IPC pending request limit reached")]
    PendingRequestLimit,
}

pub struct ServerProtocol {
    token: IpcToken,
    instance_id: [u8; 16],
    server_nonce: [u8; NONCE_BYTES],
    authenticated: bool,
    pending_request_ids: HashSet<String>,
}

impl ServerProtocol {
    #[must_use]
    pub fn new(token: IpcToken, instance_id: [u8; 16], server_nonce: [u8; NONCE_BYTES]) -> Self {
        Self {
            token,
            instance_id,
            server_nonce,
            authenticated: false,
            pending_request_ids: HashSet::with_capacity(MAX_PENDING_REQUESTS),
        }
    }

    #[must_use]
    pub fn challenge(&self) -> LocalIpcChallenge {
        LocalIpcChallenge {
            agent_instance_id: self.instance_id.to_vec(),
            server_nonce: self.server_nonce.to_vec(),
        }
    }

    /// Verifies the client proof once and returns the server proof.
    ///
    /// # Errors
    ///
    /// Returns an error for malformed frames, unsupported versions, repeated
    /// authentication, invalid lengths, or a proof mismatch.
    pub fn authenticate(
        &mut self,
        frame: &LocalIpcClientFrame,
    ) -> Result<LocalIpcAuthenticated, ProtocolError> {
        if self.authenticated {
            return Err(ProtocolError::AlreadyAuthenticated);
        }
        validate_common_frame(frame)?;
        let local_ipc_client_frame::Payload::Authenticate(authentication) = frame
            .payload
            .as_ref()
            .ok_or(ProtocolError::MissingPayload)?
        else {
            return Err(ProtocolError::AuthenticationRequired);
        };
        let client_nonce: [u8; NONCE_BYTES] = authentication
            .client_nonce
            .as_slice()
            .try_into()
            .map_err(|_| ProtocolError::InvalidAuthenticationLength)?;
        if authentication.client_proof.len() != NONCE_BYTES {
            return Err(ProtocolError::InvalidAuthenticationLength);
        }
        if !verify_client_proof(
            &self.token,
            &self.instance_id,
            &self.server_nonce,
            &client_nonce,
            &authentication.client_proof,
        ) {
            return Err(ProtocolError::AuthenticationFailed);
        }
        self.authenticated = true;
        Ok(LocalIpcAuthenticated {
            server_proof: server_proof(
                &self.token,
                &self.instance_id,
                &self.server_nonce,
                &client_nonce,
            )
            .to_vec(),
        })
    }

    #[must_use]
    pub const fn is_authenticated(&self) -> bool {
        self.authenticated
    }

    /// Registers one authenticated business request as pending.
    ///
    /// # Errors
    ///
    /// Returns an error before authentication or for malformed, duplicate, or
    /// excessive pending requests.
    pub fn begin_request(&mut self, frame: &LocalIpcClientFrame) -> Result<(), ProtocolError> {
        if !self.authenticated {
            return Err(ProtocolError::AuthenticationRequired);
        }
        validate_common_frame(frame)?;
        if matches!(
            frame.payload,
            Some(local_ipc_client_frame::Payload::Authenticate(_))
        ) {
            return Err(ProtocolError::AlreadyAuthenticated);
        }
        if self.pending_request_ids.contains(&frame.request_id) {
            return Err(ProtocolError::DuplicateRequestId);
        }
        if self.pending_request_ids.len() >= MAX_PENDING_REQUESTS {
            return Err(ProtocolError::PendingRequestLimit);
        }
        self.pending_request_ids.insert(frame.request_id.clone());
        Ok(())
    }

    pub fn complete_request(&mut self, request_id: &str) {
        self.pending_request_ids.remove(request_id);
    }
}

fn validate_common_frame(frame: &LocalIpcClientFrame) -> Result<(), ProtocolError> {
    let version = frame
        .protocol_version
        .as_ref()
        .ok_or(ProtocolError::UnsupportedVersion)?;
    if !supported_version(*version) {
        return Err(ProtocolError::UnsupportedVersion);
    }
    if frame.request_id.is_empty() || frame.request_id.len() > MAX_REQUEST_ID_UTF8_BYTES {
        return Err(ProtocolError::InvalidRequestId);
    }
    if frame.payload.is_none() {
        return Err(ProtocolError::MissingPayload);
    }
    Ok(())
}

const fn supported_version(version: ProtocolVersion) -> bool {
    version.major == PROTOCOL_MAJOR_VERSION && version.minor == MINIMUM_PROTOCOL_MINOR_VERSION
}
