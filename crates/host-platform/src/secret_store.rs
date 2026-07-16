// SPDX-License-Identifier: MPL-2.0

use std::sync::Mutex;

use thiserror::Error;
use zeroize::Zeroizing;

pub const PROTECTED_SECRET_BYTES: usize = 32;

pub type ProtectedSecret = Zeroizing<Vec<u8>>;

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum SecretStoreError {
    #[error("invalid protected secret length")]
    InvalidSecretLength,
    #[error("protected secret storage is unavailable")]
    Unavailable,
    #[error("protected secret storage access was denied")]
    AccessDenied,
    #[error("protected secret storage contains invalid data")]
    Corrupt,
    #[error("protected secret storage is unsupported on this platform")]
    UnsupportedPlatform,
}

pub trait ProtectedSecretStore: Send + Sync {
    /// Loads a protected secret into a zeroizing buffer.
    ///
    /// # Errors
    ///
    /// Returns a stable storage error when the platform backend cannot read or
    /// validate its protected value.
    fn load(&self) -> Result<Option<ProtectedSecret>, SecretStoreError>;

    /// Creates or replaces the protected secret.
    ///
    /// # Errors
    ///
    /// Returns [`SecretStoreError::InvalidSecretLength`] unless `secret` is 32
    /// bytes, or a stable storage error when persistence fails.
    fn store(&self, secret: &[u8]) -> Result<(), SecretStoreError>;

    /// Deletes the protected secret if one exists.
    ///
    /// # Errors
    ///
    /// Returns a stable storage error when the platform backend cannot delete
    /// its protected value.
    fn delete(&self) -> Result<(), SecretStoreError>;
}

#[derive(Debug, Default)]
pub struct MemorySecretStore {
    value: Mutex<Option<ProtectedSecret>>,
}

impl MemorySecretStore {
    #[must_use]
    pub const fn new() -> Self {
        Self {
            value: Mutex::new(None),
        }
    }
}

impl ProtectedSecretStore for MemorySecretStore {
    fn load(&self) -> Result<Option<ProtectedSecret>, SecretStoreError> {
        let value = self
            .value
            .lock()
            .map_err(|_| SecretStoreError::Unavailable)?;
        Ok(value
            .as_ref()
            .map(|secret| Zeroizing::new(secret.as_slice().to_vec())))
    }

    fn store(&self, secret: &[u8]) -> Result<(), SecretStoreError> {
        if secret.len() != PROTECTED_SECRET_BYTES {
            return Err(SecretStoreError::InvalidSecretLength);
        }

        let mut value = self
            .value
            .lock()
            .map_err(|_| SecretStoreError::Unavailable)?;
        *value = Some(Zeroizing::new(secret.to_vec()));
        Ok(())
    }

    fn delete(&self) -> Result<(), SecretStoreError> {
        let mut value = self
            .value
            .lock()
            .map_err(|_| SecretStoreError::Unavailable)?;
        *value = None;
        Ok(())
    }
}
