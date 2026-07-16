// SPDX-License-Identifier: Apache-2.0

use std::{error::Error, fmt};

use aes_gcm::{
    Aes256Gcm, KeyInit,
    aead::{Aead, Payload},
};
use hkdf::Hkdf;
use sha2::Sha256;
use x25519_dalek::{PublicKey, StaticSecret};

use crate::protocol_limits::{
    DEVICE_ID_BYTES, MAX_PAIRING_CIPHERTEXT_BYTES, NONCE_OR_HASH_BYTES, PUBLIC_KEY_BYTES,
    RENDEZVOUS_ID_BYTES,
};

const AAD_MAGIC: &[u8; 4] = b"PRDP";
const CRYPTO_VERSION: u16 = 1;
const AES_GCM_TAG_BYTES: usize = 16;
const MAX_PAIRING_SEQUENCE: u64 = i64::MAX as u64;
// Protocol V1 domains remain stable so existing grants can still pair.
const CONTROLLER_TO_HOST_INFO: &[u8] = b"personal-remote-desktop/pairing/v1/controller-to-host";
const HOST_TO_CONTROLLER_INFO: &[u8] = b"personal-remote-desktop/pairing/v1/host-to-controller";

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum CryptoDirection {
    ControllerToHost,
    HostToController,
}

impl CryptoDirection {
    const fn code(self) -> u8 {
        match self {
            Self::ControllerToHost => 1,
            Self::HostToController => 2,
        }
    }

    const fn nonce_prefix(self) -> [u8; 4] {
        match self {
            Self::ControllerToHost => *b"C2H\x01",
            Self::HostToController => *b"H2C\x01",
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PairingCryptoError {
    InvalidLength,
    InvalidSequence,
    InvalidPublicKey,
    InvalidWordList,
    KeyDerivation,
    AuthenticationFailed,
}

impl fmt::Display for PairingCryptoError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(match self {
            Self::InvalidLength => "pairing crypto length is invalid",
            Self::InvalidSequence => "pairing crypto sequence is invalid",
            Self::InvalidPublicKey => "pairing X25519 public key is invalid",
            Self::InvalidWordList => "pairing SAS word list is invalid",
            Self::KeyDerivation => "pairing key derivation failed",
            Self::AuthenticationFailed => "pairing payload authentication failed",
        })
    }
}

impl Error for PairingCryptoError {}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PairingKeySchedule {
    pub controller_to_host: [u8; 32],
    pub host_to_controller: [u8; 32],
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PairingSequenceValidator {
    next: u64,
    exhausted: bool,
}

impl PairingSequenceValidator {
    #[must_use]
    pub const fn new() -> Self {
        Self {
            next: 1,
            exhausted: false,
        }
    }

    #[must_use]
    pub const fn next(&self) -> u64 {
        self.next
    }

    /// Accepts exactly the next sequence without advancing on failure.
    ///
    /// # Errors
    ///
    /// Returns [`PairingCryptoError::InvalidSequence`] for duplicates, gaps,
    /// reordering, or exhaustion.
    pub fn accept(&mut self, sequence: u64) -> Result<(), PairingCryptoError> {
        if self.exhausted || sequence != self.next || sequence > MAX_PAIRING_SEQUENCE {
            return Err(PairingCryptoError::InvalidSequence);
        }
        if sequence == MAX_PAIRING_SEQUENCE {
            self.exhausted = true;
        } else {
            self.next += 1;
        }
        Ok(())
    }
}

impl Default for PairingSequenceValidator {
    fn default() -> Self {
        Self::new()
    }
}

/// Derives the X25519 public key for a fixed-size private key.
///
/// # Errors
///
/// Returns [`PairingCryptoError::InvalidLength`] unless the key is 32 bytes.
pub fn x25519_public_key(private_key: &[u8]) -> Result<[u8; 32], PairingCryptoError> {
    let private: [u8; 32] = private_key
        .try_into()
        .map_err(|_| PairingCryptoError::InvalidLength)?;
    Ok(PublicKey::from(&StaticSecret::from(private)).to_bytes())
}

/// Computes an X25519 shared secret using local private and remote public keys.
///
/// # Errors
///
/// Returns an error unless both keys are 32 bytes and produce a nonzero secret.
pub fn x25519_shared_secret(
    private_key: &[u8],
    remote_public_key: &[u8],
) -> Result<[u8; 32], PairingCryptoError> {
    let private: [u8; 32] = private_key
        .try_into()
        .map_err(|_| PairingCryptoError::InvalidLength)?;
    let public: [u8; 32] = remote_public_key
        .try_into()
        .map_err(|_| PairingCryptoError::InvalidLength)?;
    let shared = StaticSecret::from(private)
        .diffie_hellman(&PublicKey::from(public))
        .to_bytes();
    if shared.iter().all(|byte| *byte == 0) {
        return Err(PairingCryptoError::InvalidPublicKey);
    }
    Ok(shared)
}

/// Maps the first 44 bits of a transcript SHA-256 to four 11-bit indexes.
///
/// # Errors
///
/// Returns [`PairingCryptoError::InvalidLength`] unless the digest is 32 bytes.
pub fn sas_indexes(transcript_sha256: &[u8]) -> Result<[u16; 4], PairingCryptoError> {
    require_length(transcript_sha256, NONCE_OR_HASH_BYTES)?;
    Ok([
        (u16::from(transcript_sha256[0]) << 3) | u16::from(transcript_sha256[1] >> 5),
        (u16::from(transcript_sha256[1] & 0x1f) << 6) | u16::from(transcript_sha256[2] >> 2),
        (u16::from(transcript_sha256[2] & 0x03) << 9)
            | (u16::from(transcript_sha256[3]) << 1)
            | u16::from(transcript_sha256[4] >> 7),
        (u16::from(transcript_sha256[4] & 0x7f) << 4) | u16::from(transcript_sha256[5] >> 4),
    ])
}

/// Resolves the four SAS indexes through the fixed 2,048-word list.
///
/// # Errors
///
/// Returns an error for a malformed digest or word list.
pub fn sas_words<'a>(
    transcript_sha256: &[u8],
    word_list: &'a [&str],
) -> Result<[&'a str; 4], PairingCryptoError> {
    if word_list.len() != 2_048
        || word_list.iter().any(|word| {
            word.is_empty() || word.len() > 8 || !word.bytes().all(|b| b.is_ascii_lowercase())
        })
    {
        return Err(PairingCryptoError::InvalidWordList);
    }
    let indexes = sas_indexes(transcript_sha256)?;
    Ok([
        word_list[usize::from(indexes[0])],
        word_list[usize::from(indexes[1])],
        word_list[usize::from(indexes[2])],
        word_list[usize::from(indexes[3])],
    ])
}

/// Derives independent Controller-to-Host and Host-to-Controller AES keys.
///
/// # Errors
///
/// Returns an error for non-32-byte inputs, an all-zero shared secret, or HKDF
/// expansion failure.
pub fn derive_pairing_keys(
    shared_secret: &[u8],
    transcript_sha256: &[u8],
) -> Result<PairingKeySchedule, PairingCryptoError> {
    require_length(shared_secret, PUBLIC_KEY_BYTES)?;
    require_length(transcript_sha256, NONCE_OR_HASH_BYTES)?;
    if shared_secret.iter().all(|byte| *byte == 0) {
        return Err(PairingCryptoError::InvalidPublicKey);
    }
    let hkdf = Hkdf::<Sha256>::new(Some(transcript_sha256), shared_secret);
    let mut controller_to_host = [0_u8; 32];
    let mut host_to_controller = [0_u8; 32];
    hkdf.expand(CONTROLLER_TO_HOST_INFO, &mut controller_to_host)
        .map_err(|_| PairingCryptoError::KeyDerivation)?;
    hkdf.expand(HOST_TO_CONTROLLER_INFO, &mut host_to_controller)
        .map_err(|_| PairingCryptoError::KeyDerivation)?;
    Ok(PairingKeySchedule {
        controller_to_host,
        host_to_controller,
    })
}

/// Constructs the direction-separated 96-bit AES-GCM nonce.
///
/// # Errors
///
/// Returns [`PairingCryptoError::InvalidSequence`] when sequence is outside
/// the positive signed 64-bit protocol range.
pub fn pairing_nonce(
    direction: CryptoDirection,
    sequence: u64,
) -> Result<[u8; 12], PairingCryptoError> {
    if sequence == 0 || sequence > MAX_PAIRING_SEQUENCE {
        return Err(PairingCryptoError::InvalidSequence);
    }
    let mut nonce = [0_u8; 12];
    nonce[..4].copy_from_slice(&direction.nonce_prefix());
    nonce[4..].copy_from_slice(&sequence.to_be_bytes());
    Ok(nonce)
}

/// Encodes Pairing Crypto V1 authenticated additional data.
///
/// # Errors
///
/// Returns an error for invalid identifier lengths or sequence zero.
pub fn pairing_aad(
    direction: CryptoDirection,
    sequence: u64,
    rendezvous_id: &[u8],
    controller_device_id: &[u8],
    host_device_id: &[u8],
) -> Result<Vec<u8>, PairingCryptoError> {
    require_length(rendezvous_id, RENDEZVOUS_ID_BYTES)?;
    require_length(controller_device_id, DEVICE_ID_BYTES)?;
    require_length(host_device_id, DEVICE_ID_BYTES)?;
    pairing_nonce(direction, sequence)?;
    let mut aad = Vec::with_capacity(95);
    aad.extend_from_slice(AAD_MAGIC);
    aad.extend_from_slice(&CRYPTO_VERSION.to_be_bytes());
    aad.push(direction.code());
    aad.extend_from_slice(&sequence.to_be_bytes());
    aad.extend_from_slice(rendezvous_id);
    aad.extend_from_slice(controller_device_id);
    aad.extend_from_slice(host_device_id);
    Ok(aad)
}

/// Encrypts and authenticates one bounded pairing plaintext.
///
/// # Errors
///
/// Returns an error for invalid key/sequence/size or encryption failure.
pub fn seal_pairing_payload(
    key: &[u8],
    direction: CryptoDirection,
    sequence: u64,
    aad: &[u8],
    plaintext: &[u8],
) -> Result<Vec<u8>, PairingCryptoError> {
    require_length(key, 32)?;
    if plaintext.len() > MAX_PAIRING_CIPHERTEXT_BYTES - AES_GCM_TAG_BYTES {
        return Err(PairingCryptoError::InvalidLength);
    }
    let cipher = Aes256Gcm::new_from_slice(key).map_err(|_| PairingCryptoError::InvalidLength)?;
    cipher
        .encrypt(
            &pairing_nonce(direction, sequence)?.into(),
            Payload {
                msg: plaintext,
                aad,
            },
        )
        .map_err(|_| PairingCryptoError::AuthenticationFailed)
}

/// Authenticates and decrypts one bounded pairing payload.
///
/// # Errors
///
/// Returns an error for invalid key/sequence/size or authentication failure.
pub fn open_pairing_payload(
    key: &[u8],
    direction: CryptoDirection,
    sequence: u64,
    aad: &[u8],
    ciphertext_and_tag: &[u8],
) -> Result<Vec<u8>, PairingCryptoError> {
    require_length(key, 32)?;
    if !(AES_GCM_TAG_BYTES..=MAX_PAIRING_CIPHERTEXT_BYTES).contains(&ciphertext_and_tag.len()) {
        return Err(PairingCryptoError::InvalidLength);
    }
    let cipher = Aes256Gcm::new_from_slice(key).map_err(|_| PairingCryptoError::InvalidLength)?;
    cipher
        .decrypt(
            &pairing_nonce(direction, sequence)?.into(),
            Payload {
                msg: ciphertext_and_tag,
                aad,
            },
        )
        .map_err(|_| PairingCryptoError::AuthenticationFailed)
}

fn require_length(value: &[u8], expected: usize) -> Result<(), PairingCryptoError> {
    if value.len() != expected {
        return Err(PairingCryptoError::InvalidLength);
    }
    Ok(())
}
