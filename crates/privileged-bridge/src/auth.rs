// SPDX-License-Identifier: MPL-2.0

use std::{
    collections::{HashSet, VecDeque},
    fmt,
};

use roammand_ipc::{AuthChannel, IpcToken, channel_server_proof, verify_channel_client_proof};
use thiserror::Error;

const NONCE_BYTES: usize = 32;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum BridgeRole {
    HostAgent,
    SessionHelper,
}

impl BridgeRole {
    #[must_use]
    pub const fn auth_channel(self) -> AuthChannel {
        match self {
            Self::HostAgent => AuthChannel::PrivilegedHost,
            Self::SessionHelper => AuthChannel::PrivilegedHelper,
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum AuthenticationError {
    #[error("bridge authentication fields have invalid lengths")]
    InvalidLength,
    #[error("bridge authentication rejected a reflected nonce")]
    ReflectedNonce,
    #[error("bridge authentication failed")]
    AuthenticationFailed,
    #[error("bridge authentication nonce was already used")]
    NonceReused,
    #[error("bridge connection is already authenticated")]
    AlreadyAuthenticated,
    #[error("bridge replay cache capacity is invalid")]
    InvalidReplayCapacity,
}

#[derive(Debug)]
pub struct NonceReplayGuard {
    used: HashSet<[u8; NONCE_BYTES]>,
    insertion_order: VecDeque<[u8; NONCE_BYTES]>,
    capacity: usize,
}

impl NonceReplayGuard {
    /// Creates a bounded nonce replay cache.
    ///
    /// # Errors
    ///
    /// Returns [`AuthenticationError::InvalidReplayCapacity`] for zero.
    pub fn new(capacity: usize) -> Result<Self, AuthenticationError> {
        if capacity == 0 {
            return Err(AuthenticationError::InvalidReplayCapacity);
        }
        Ok(Self {
            used: HashSet::with_capacity(capacity),
            insertion_order: VecDeque::with_capacity(capacity),
            capacity,
        })
    }

    fn claim(&mut self, nonce: [u8; NONCE_BYTES]) -> Result<(), AuthenticationError> {
        if self.used.contains(&nonce) {
            return Err(AuthenticationError::NonceReused);
        }
        if self.used.len() == self.capacity
            && let Some(expired) = self.insertion_order.pop_front()
        {
            self.used.remove(&expired);
        }
        self.used.insert(nonce);
        self.insertion_order.push_back(nonce);
        Ok(())
    }
}

pub struct BridgeAuthenticator {
    role: BridgeRole,
    secret: IpcToken,
    instance_id: [u8; 16],
    server_nonce: [u8; NONCE_BYTES],
    authenticated: bool,
}

impl BridgeAuthenticator {
    #[must_use]
    pub fn new(
        role: BridgeRole,
        secret: IpcToken,
        instance_id: [u8; 16],
        server_nonce: [u8; NONCE_BYTES],
    ) -> Self {
        Self {
            role,
            secret,
            instance_id,
            server_nonce,
            authenticated: false,
        }
    }

    #[must_use]
    pub const fn challenge(&self) -> ([u8; 16], [u8; NONCE_BYTES]) {
        (self.instance_id, self.server_nonce)
    }

    /// Verifies one role-bound proof and returns the distinct server proof.
    ///
    /// # Errors
    ///
    /// Rejects repeated authentication, malformed/reflected/replayed nonces,
    /// invalid proofs, and recently replayed nonces before business frames run.
    pub fn authenticate(
        &mut self,
        client_nonce: &[u8],
        client_proof: &[u8],
        replay_guard: &mut NonceReplayGuard,
    ) -> Result<[u8; 32], AuthenticationError> {
        if self.authenticated {
            return Err(AuthenticationError::AlreadyAuthenticated);
        }
        let client_nonce: [u8; NONCE_BYTES] = client_nonce
            .try_into()
            .map_err(|_| AuthenticationError::InvalidLength)?;
        if client_proof.len() != NONCE_BYTES {
            return Err(AuthenticationError::InvalidLength);
        }
        if client_nonce == self.server_nonce {
            return Err(AuthenticationError::ReflectedNonce);
        }
        if !verify_channel_client_proof(
            &self.secret,
            self.role.auth_channel(),
            &self.instance_id,
            &self.server_nonce,
            &client_nonce,
            client_proof,
        ) {
            return Err(AuthenticationError::AuthenticationFailed);
        }
        replay_guard.claim(client_nonce)?;
        self.authenticated = true;
        Ok(channel_server_proof(
            &self.secret,
            self.role.auth_channel(),
            &self.instance_id,
            &self.server_nonce,
            &client_nonce,
        ))
    }

    #[must_use]
    pub const fn is_authenticated(&self) -> bool {
        self.authenticated
    }
}

#[allow(clippy::missing_fields_in_debug)]
impl fmt::Debug for BridgeAuthenticator {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("BridgeAuthenticator")
            .field("role", &self.role)
            .field("authenticated", &self.authenticated)
            .finish()
    }
}
