// SPDX-License-Identifier: MPL-2.0

use std::{
    path::PathBuf,
    sync::{
        Mutex,
        atomic::{AtomicBool, Ordering},
    },
};

use prost::Message;
use roammand_host_platform::{RestrictedFsError, atomic_write_private, read_private_file};
use roammand_protocol::{
    protocol_limits::MAX_HOST_AUTHORIZATION_SNAPSHOT_BYTES,
    roammand::v1::{ControllerGrantView, HostAuthorizationSnapshot},
};
use sha2::{Digest, Sha256};
use thiserror::Error;

const SNAPSHOT_MAGIC: &[u8; 4] = b"PRDG";
const SNAPSHOT_VERSION: u16 = 1;
const MAGIC_OFFSET: usize = 0;
const VERSION_OFFSET: usize = 4;
const LENGTH_OFFSET: usize = 6;
const CHECKSUM_OFFSET: usize = 10;
const CHECKSUM_BYTES: usize = 32;
const ENVELOPE_HEADER_BYTES: usize = CHECKSUM_OFFSET + CHECKSUM_BYTES;
const MAX_ENVELOPE_BYTES: usize = ENVELOPE_HEADER_BYTES + MAX_HOST_AUTHORIZATION_SNAPSHOT_BYTES;

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum GrantStoreError {
    #[error("authorization store operation failed")]
    Io,
    #[error("authorization snapshot is too large")]
    SnapshotTooLarge,
    #[error("authorization snapshot envelope is invalid")]
    InvalidEnvelope,
    #[error("authorization snapshot version is unsupported")]
    UnsupportedVersion,
    #[error("authorization snapshot checksum does not match")]
    ChecksumMismatch,
    #[error("authorization snapshot payload is invalid")]
    InvalidPayload,
    #[error("authorization snapshot belongs to another host")]
    HostMismatch,
    #[error("injected authorization store failure")]
    InjectedFailure,
}

pub trait GrantStore: Send + Sync {
    /// Loads all grants for `host_device_id`.
    ///
    /// # Errors
    ///
    /// Returns a stable store error when the snapshot is unavailable, corrupt,
    /// oversized, or belongs to another Host.
    fn load(&self, host_device_id: &[u8]) -> Result<Vec<ControllerGrantView>, GrantStoreError>;

    /// Atomically persists all grants for `host_device_id`.
    ///
    /// # Errors
    ///
    /// Returns a stable store error when encoding or persistence fails.
    fn persist(
        &self,
        host_device_id: &[u8],
        grants: &[ControllerGrantView],
    ) -> Result<(), GrantStoreError>;
}

pub struct FileGrantStore {
    path: PathBuf,
}

impl FileGrantStore {
    #[must_use]
    pub const fn new(path: PathBuf) -> Self {
        Self { path }
    }
}

impl GrantStore for FileGrantStore {
    fn load(&self, host_device_id: &[u8]) -> Result<Vec<ControllerGrantView>, GrantStoreError> {
        if !self.path.try_exists().map_err(|_| GrantStoreError::Io)? {
            return Ok(Vec::new());
        }
        let envelope = read_private_file(&self.path, MAX_ENVELOPE_BYTES)
            .map_err(|error| map_read_error(&error))?;
        decode_envelope(&envelope, host_device_id)
    }

    fn persist(
        &self,
        host_device_id: &[u8],
        grants: &[ControllerGrantView],
    ) -> Result<(), GrantStoreError> {
        let snapshot = HostAuthorizationSnapshot {
            host_device_id: host_device_id.to_vec(),
            grants: grants.to_vec(),
        };
        let payload = snapshot.encode_to_vec();
        if payload.len() > MAX_HOST_AUTHORIZATION_SNAPSHOT_BYTES {
            return Err(GrantStoreError::SnapshotTooLarge);
        }
        let payload_length =
            u32::try_from(payload.len()).map_err(|_| GrantStoreError::SnapshotTooLarge)?;
        let mut envelope = Vec::with_capacity(ENVELOPE_HEADER_BYTES + payload.len());
        envelope.extend_from_slice(SNAPSHOT_MAGIC);
        envelope.extend_from_slice(&SNAPSHOT_VERSION.to_be_bytes());
        envelope.extend_from_slice(&payload_length.to_be_bytes());
        envelope.extend_from_slice(&Sha256::digest(&payload));
        envelope.extend_from_slice(&payload);
        atomic_write_private(&self.path, &envelope).map_err(|_| GrantStoreError::Io)
    }
}

#[derive(Debug, Default)]
pub struct MemoryGrantStore {
    snapshot: Mutex<Option<HostAuthorizationSnapshot>>,
    fail_next_persist: AtomicBool,
}

impl MemoryGrantStore {
    #[must_use]
    pub const fn new() -> Self {
        Self {
            snapshot: Mutex::new(None),
            fail_next_persist: AtomicBool::new(false),
        }
    }

    pub fn fail_next_persist(&self) {
        self.fail_next_persist.store(true, Ordering::SeqCst);
    }
}

impl GrantStore for MemoryGrantStore {
    fn load(&self, host_device_id: &[u8]) -> Result<Vec<ControllerGrantView>, GrantStoreError> {
        let snapshot = self.snapshot.lock().map_err(|_| GrantStoreError::Io)?;
        match snapshot.as_ref() {
            None => Ok(Vec::new()),
            Some(value) if value.host_device_id == host_device_id => Ok(value.grants.clone()),
            Some(_) => Err(GrantStoreError::HostMismatch),
        }
    }

    fn persist(
        &self,
        host_device_id: &[u8],
        grants: &[ControllerGrantView],
    ) -> Result<(), GrantStoreError> {
        if self.fail_next_persist.swap(false, Ordering::SeqCst) {
            return Err(GrantStoreError::InjectedFailure);
        }
        let snapshot = HostAuthorizationSnapshot {
            host_device_id: host_device_id.to_vec(),
            grants: grants.to_vec(),
        };
        if snapshot.encoded_len() > MAX_HOST_AUTHORIZATION_SNAPSHOT_BYTES {
            return Err(GrantStoreError::SnapshotTooLarge);
        }
        *self.snapshot.lock().map_err(|_| GrantStoreError::Io)? = Some(snapshot);
        Ok(())
    }
}

fn decode_envelope(
    envelope: &[u8],
    expected_host_device_id: &[u8],
) -> Result<Vec<ControllerGrantView>, GrantStoreError> {
    if envelope.len() < ENVELOPE_HEADER_BYTES {
        return Err(GrantStoreError::InvalidEnvelope);
    }
    if &envelope[MAGIC_OFFSET..VERSION_OFFSET] != SNAPSHOT_MAGIC {
        return Err(GrantStoreError::InvalidEnvelope);
    }
    let version = u16::from_be_bytes(
        envelope[VERSION_OFFSET..LENGTH_OFFSET]
            .try_into()
            .map_err(|_| GrantStoreError::InvalidEnvelope)?,
    );
    if version != SNAPSHOT_VERSION {
        return Err(GrantStoreError::UnsupportedVersion);
    }
    let payload_length = usize::try_from(u32::from_be_bytes(
        envelope[LENGTH_OFFSET..CHECKSUM_OFFSET]
            .try_into()
            .map_err(|_| GrantStoreError::InvalidEnvelope)?,
    ))
    .map_err(|_| GrantStoreError::SnapshotTooLarge)?;
    if payload_length > MAX_HOST_AUTHORIZATION_SNAPSHOT_BYTES {
        return Err(GrantStoreError::SnapshotTooLarge);
    }
    if envelope.len() != ENVELOPE_HEADER_BYTES + payload_length {
        return Err(GrantStoreError::InvalidEnvelope);
    }

    let expected_checksum = &envelope[CHECKSUM_OFFSET..ENVELOPE_HEADER_BYTES];
    let payload = &envelope[ENVELOPE_HEADER_BYTES..];
    if Sha256::digest(payload).as_slice() != expected_checksum {
        return Err(GrantStoreError::ChecksumMismatch);
    }
    let snapshot =
        HostAuthorizationSnapshot::decode(payload).map_err(|_| GrantStoreError::InvalidPayload)?;
    if snapshot.host_device_id != expected_host_device_id {
        return Err(GrantStoreError::HostMismatch);
    }
    Ok(snapshot.grants)
}

const fn map_read_error(error: &RestrictedFsError) -> GrantStoreError {
    match error {
        RestrictedFsError::FileTooLarge => GrantStoreError::SnapshotTooLarge,
        _ => GrantStoreError::Io,
    }
}
