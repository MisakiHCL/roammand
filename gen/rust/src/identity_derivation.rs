// SPDX-License-Identifier: Apache-2.0

use std::{error::Error, fmt};

use sha2::{Digest, Sha256};

// Protocol V1 domain; changing it would rotate every existing device ID.
const IDENTITY_DERIVATION_DOMAIN: &[u8] = b"personal-remote-device-id-v1";
const ED25519_ALGORITHM: u16 = 1;
const ED25519_PUBLIC_KEY_BYTES: usize = 32;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum IdentityDerivationError {
    InvalidPublicKeyLength,
}

impl fmt::Display for IdentityDerivationError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidPublicKeyLength => formatter.write_str("invalid public key length"),
        }
    }
}

impl Error for IdentityDerivationError {}

/// Derives a stable V1 device identifier from an Ed25519 public key.
///
/// # Errors
///
/// Returns [`IdentityDerivationError::InvalidPublicKeyLength`] when the public
/// key does not contain exactly 32 bytes.
pub fn derive_device_id_v1(public_key: &[u8]) -> Result<[u8; 32], IdentityDerivationError> {
    if public_key.len() != ED25519_PUBLIC_KEY_BYTES {
        return Err(IdentityDerivationError::InvalidPublicKeyLength);
    }

    let mut hasher = Sha256::new();
    hasher.update(IDENTITY_DERIVATION_DOMAIN);
    hasher.update([0]);
    hasher.update(ED25519_ALGORITHM.to_be_bytes());
    hasher.update(public_key);
    Ok(hasher.finalize().into())
}
