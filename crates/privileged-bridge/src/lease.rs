// SPDX-License-Identifier: MPL-2.0

use std::fmt;

use thiserror::Error;

pub const RENEW_INTERVAL_MS: u64 = 5_000;
pub const LEASE_DURATION_MS: u64 = 15_000;
const MAX_CONTROLLER_NAME_BYTES: usize = 128;

#[derive(Clone, Copy, Eq, Hash, PartialEq)]
pub struct LeaseId([u8; 16]);

impl LeaseId {
    #[must_use]
    pub const fn new(value: [u8; 16]) -> Self {
        Self(value)
    }

    #[must_use]
    pub const fn into_bytes(self) -> [u8; 16] {
        self.0
    }
}

impl fmt::Debug for LeaseId {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("LeaseId([REDACTED; 16])")
    }
}

#[derive(Clone, Copy, Eq, Hash, PartialEq)]
pub struct SessionId([u8; 16]);

impl SessionId {
    #[must_use]
    pub const fn new(value: [u8; 16]) -> Self {
        Self(value)
    }

    #[must_use]
    pub const fn into_bytes(self) -> [u8; 16] {
        self.0
    }
}

impl fmt::Debug for SessionId {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("SessionId([REDACTED; 16])")
    }
}

pub trait LeaseIdSource {
    /// Produces a cryptographically random lease identifier.
    ///
    /// # Errors
    ///
    /// Returns [`LeaseError::RandomUnavailable`] when secure randomness fails.
    fn next_lease_id(&mut self) -> Result<LeaseId, LeaseError>;
}

#[derive(Debug, Default)]
pub struct SystemLeaseIdSource;

impl LeaseIdSource for SystemLeaseIdSource {
    fn next_lease_id(&mut self) -> Result<LeaseId, LeaseError> {
        let mut bytes = [0_u8; 16];
        getrandom::fill(&mut bytes).map_err(|_| LeaseError::RandomUnavailable)?;
        Ok(LeaseId::new(bytes))
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct AcquireLease {
    pub session_id: SessionId,
    pub generation: u64,
    pub controller_display_name: String,
    pub may_control_input: bool,
}

#[derive(Clone, Eq, PartialEq)]
pub struct Lease {
    id: LeaseId,
    session_id: SessionId,
    generation: u64,
    issued_at_ms: u64,
    expires_at_ms: u64,
    last_renewed_at_ms: u64,
    last_command_sequence: u64,
    controller_display_name: String,
    may_control_input: bool,
}

impl fmt::Debug for Lease {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("Lease")
            .field("id", &self.id)
            .field("session_id", &self.session_id)
            .field("generation", &self.generation)
            .field("issued_at_ms", &self.issued_at_ms)
            .field("expires_at_ms", &self.expires_at_ms)
            .field("controller_display_name", &"[REDACTED]")
            .field("may_control_input", &self.may_control_input)
            .finish_non_exhaustive()
    }
}

impl Lease {
    #[must_use]
    pub const fn id(&self) -> LeaseId {
        self.id
    }

    #[must_use]
    pub const fn session_id(&self) -> SessionId {
        self.session_id
    }

    #[must_use]
    pub const fn generation(&self) -> u64 {
        self.generation
    }

    #[must_use]
    pub const fn issued_at_ms(&self) -> u64 {
        self.issued_at_ms
    }

    #[must_use]
    pub const fn expires_at_ms(&self) -> u64 {
        self.expires_at_ms
    }

    #[must_use]
    pub fn controller_display_name(&self) -> &str {
        &self.controller_display_name
    }

    #[must_use]
    pub const fn may_control_input(&self) -> bool {
        self.may_control_input
    }
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum LeaseError {
    #[error("host is disconnected")]
    HostDisconnected,
    #[error("a host is already connected")]
    HostAlreadyConnected,
    #[error("a lease is already active")]
    LeaseAlreadyActive,
    #[error("lease is not active")]
    LeaseNotActive,
    #[error("lease has expired")]
    LeaseExpired,
    #[error("lease generation is stale")]
    StaleGeneration,
    #[error("lease id does not match")]
    LeaseIdMismatch,
    #[error("lease id is invalid")]
    InvalidLeaseId,
    #[error("secure lease randomness is unavailable")]
    RandomUnavailable,
    #[error("renewal was attempted too soon")]
    RenewedTooSoon,
    #[error("command sequence is invalid")]
    InvalidSequence,
    #[error("controller display name is invalid")]
    InvalidControllerName,
    #[error("lease timestamp overflow")]
    TimestampOverflow,
}

pub struct LeaseManager {
    broker_instance_id: [u8; 16],
    host_generation: Option<u64>,
    active: Option<Lease>,
    last_released: Option<(LeaseId, u64)>,
}

impl fmt::Debug for LeaseManager {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("LeaseManager")
            .field("broker_instance_id", &"[REDACTED]")
            .field("host_connected", &self.host_generation.is_some())
            .field("active", &self.active)
            .field("last_released", &self.last_released.is_some())
            .finish()
    }
}

impl LeaseManager {
    #[must_use]
    pub const fn new(broker_instance_id: [u8; 16]) -> Self {
        Self {
            broker_instance_id,
            host_generation: None,
            active: None,
            last_released: None,
        }
    }

    #[must_use]
    pub const fn broker_instance_id(&self) -> [u8; 16] {
        self.broker_instance_id
    }

    /// Registers the sole authenticated Host connection.
    ///
    /// # Errors
    ///
    /// Returns [`LeaseError::HostAlreadyConnected`] when a Host is already active.
    pub fn connect_host(&mut self, generation: u64) -> Result<(), LeaseError> {
        if self.host_generation.is_some() {
            return Err(LeaseError::HostAlreadyConnected);
        }
        if generation == 0 {
            return Err(LeaseError::StaleGeneration);
        }
        self.host_generation = Some(generation);
        Ok(())
    }

    #[must_use]
    pub fn disconnect_host(&mut self) -> bool {
        self.host_generation = None;
        self.freeze_active()
    }

    /// Acquires the only active bridge lease.
    ///
    /// # Errors
    ///
    /// Returns an error for a disconnected Host, stale route, invalid display
    /// name, invalid random identifier, active lease, or timestamp overflow.
    pub fn acquire(
        &mut self,
        request: AcquireLease,
        now_ms: u64,
        ids: &mut impl LeaseIdSource,
    ) -> Result<Lease, LeaseError> {
        let host_generation = self.host_generation.ok_or(LeaseError::HostDisconnected)?;
        if self.active.is_some() {
            return Err(LeaseError::LeaseAlreadyActive);
        }
        if request.generation != host_generation {
            return Err(LeaseError::StaleGeneration);
        }
        validate_controller_name(&request.controller_display_name)?;
        let id = ids.next_lease_id()?;
        if id.into_bytes() == [0; 16] {
            return Err(LeaseError::InvalidLeaseId);
        }
        let expires_at_ms = now_ms
            .checked_add(LEASE_DURATION_MS)
            .ok_or(LeaseError::TimestampOverflow)?;
        let lease = Lease {
            id,
            session_id: request.session_id,
            generation: request.generation,
            issued_at_ms: now_ms,
            expires_at_ms,
            last_renewed_at_ms: now_ms,
            last_command_sequence: 0,
            controller_display_name: request.controller_display_name,
            may_control_input: request.may_control_input,
        };
        self.active = Some(lease.clone());
        self.last_released = None;
        Ok(lease)
    }

    /// Renews a current lease at the fixed cadence.
    ///
    /// # Errors
    ///
    /// Returns an error when the lease is stale, expired, unknown, renewed too
    /// soon, or cannot represent its next expiry.
    pub fn renew(
        &mut self,
        id: LeaseId,
        generation: u64,
        now_ms: u64,
    ) -> Result<Lease, LeaseError> {
        let lease = self.active.as_mut().ok_or(LeaseError::LeaseNotActive)?;
        validate_active_ref(lease, id, generation)?;
        if now_ms >= lease.expires_at_ms {
            self.freeze_active();
            return Err(LeaseError::LeaseExpired);
        }
        let next_renewal = lease
            .last_renewed_at_ms
            .checked_add(RENEW_INTERVAL_MS)
            .ok_or(LeaseError::TimestampOverflow)?;
        if now_ms < next_renewal {
            return Err(LeaseError::RenewedTooSoon);
        }
        lease.last_renewed_at_ms = now_ms;
        lease.expires_at_ms = now_ms
            .checked_add(LEASE_DURATION_MS)
            .ok_or(LeaseError::TimestampOverflow)?;
        Ok(lease.clone())
    }

    /// Authorizes a strictly sequenced command for the current, unexpired lease.
    ///
    /// # Errors
    ///
    /// Returns an error for an unknown/stale/expired lease or any sequence other
    /// than the next exact value.
    pub fn authorize_command(
        &mut self,
        id: LeaseId,
        generation: u64,
        sequence: u64,
        now_ms: u64,
    ) -> Result<(), LeaseError> {
        let lease = self.active.as_mut().ok_or(LeaseError::LeaseNotActive)?;
        validate_active_ref(lease, id, generation)?;
        if now_ms >= lease.expires_at_ms {
            self.freeze_active();
            return Err(LeaseError::LeaseExpired);
        }
        let expected = lease
            .last_command_sequence
            .checked_add(1)
            .ok_or(LeaseError::InvalidSequence)?;
        if sequence != expected {
            return Err(LeaseError::InvalidSequence);
        }
        lease.last_command_sequence = sequence;
        Ok(())
    }

    /// Releases a lease, treating a repeated release of the same lease as success.
    ///
    /// # Errors
    ///
    /// Returns an error when an active or remembered lease reference does not match.
    pub fn release(&mut self, id: LeaseId, generation: u64) -> Result<bool, LeaseError> {
        self.release_or_close(id, generation)
    }

    /// Closes a lease, sharing idempotence with [`Self::release`].
    ///
    /// # Errors
    ///
    /// Returns an error when an active or remembered lease reference does not match.
    pub fn close(&mut self, id: LeaseId, generation: u64) -> Result<bool, LeaseError> {
        self.release_or_close(id, generation)
    }

    #[must_use]
    pub fn expire(&mut self, now_ms: u64) -> Option<LeaseId> {
        let id = self
            .active
            .as_ref()
            .filter(|lease| now_ms >= lease.expires_at_ms)
            .map(|lease| lease.id)?;
        self.freeze_active();
        Some(id)
    }

    #[must_use]
    pub fn input_may_be_enabled(&self) -> bool {
        self.active
            .as_ref()
            .is_some_and(|lease| lease.may_control_input)
    }

    #[must_use]
    pub const fn active(&self) -> Option<&Lease> {
        self.active.as_ref()
    }

    fn release_or_close(&mut self, id: LeaseId, generation: u64) -> Result<bool, LeaseError> {
        if let Some(lease) = &self.active {
            validate_active_ref(lease, id, generation)?;
            self.freeze_active();
            return Ok(true);
        }
        if self.last_released == Some((id, generation)) {
            return Ok(false);
        }
        Err(LeaseError::LeaseNotActive)
    }

    fn freeze_active(&mut self) -> bool {
        let Some(lease) = self.active.take() else {
            return false;
        };
        self.last_released = Some((lease.id, lease.generation));
        true
    }
}

fn validate_active_ref(lease: &Lease, id: LeaseId, generation: u64) -> Result<(), LeaseError> {
    if generation != lease.generation {
        return Err(LeaseError::StaleGeneration);
    }
    if id != lease.id {
        return Err(LeaseError::LeaseIdMismatch);
    }
    Ok(())
}

fn validate_controller_name(value: &str) -> Result<(), LeaseError> {
    if value.is_empty()
        || value.len() > MAX_CONTROLLER_NAME_BYTES
        || value.chars().any(char::is_control)
    {
        return Err(LeaseError::InvalidControllerName);
    }
    Ok(())
}
