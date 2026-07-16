// SPDX-License-Identifier: MPL-2.0

use std::fmt;

use ed25519_dalek::{Signer, SigningKey};
use roammand_host_platform::{PROTECTED_SECRET_BYTES, ProtectedSecretStore, SecretStoreError};
use roammand_protocol::{
    canonical_transcript::{TranscriptError, TranscriptPurpose, decode, sha256},
    identity_derivation::derive_device_id_v1,
    protocol_limits::MAX_DEVICE_NAME_UTF8_BYTES,
    roammand::v1::{
        CanonicalTranscriptSignature, DeviceIdentity, DevicePlatform, PairingIdentityRole,
        PairingTranscriptSignature, PublicKeyAlgorithm, SessionOfferSignature,
    },
};
use thiserror::Error;
use zeroize::Zeroizing;

#[derive(Debug, Error)]
pub enum IdentityError {
    #[error("protected identity storage failed")]
    SecretStore(#[from] SecretStoreError),
    #[error("secure random generation failed")]
    RandomGeneration,
    #[error("protected identity seed is invalid")]
    InvalidSeed,
    #[error("host identity requires a desktop platform")]
    InvalidPlatform,
    #[error("host display name is invalid")]
    InvalidDisplayName,
    #[error("invalid canonical transcript: {0:?}")]
    InvalidTranscript(TranscriptError),
    #[error("canonical transcript purpose cannot be signed by the host")]
    UnsupportedTranscriptPurpose,
    #[error("canonical transcript is bound to another host")]
    HostDeviceIdMismatch,
    #[error("canonical transcript is bound to another controller")]
    ControllerDeviceIdMismatch,
    #[error("pairing identity role is invalid")]
    InvalidPairingRole,
}

pub struct HostIdentity {
    signing_key: SigningKey,
    device_identity: DeviceIdentity,
}

impl HostIdentity {
    /// Loads the desktop identity or creates and protects a new Ed25519 seed.
    ///
    /// # Errors
    ///
    /// Returns an error when the platform or display name is invalid, protected
    /// storage fails, stored seed bytes are corrupt, or secure random generation
    /// fails.
    pub fn load_or_create(
        store: &dyn ProtectedSecretStore,
        display_name: &str,
        platform: DevicePlatform,
    ) -> Result<Self, IdentityError> {
        validate_identity_metadata(display_name, platform)?;
        let signing_key = if let Some(seed) = store.load()? {
            signing_key_from_seed(seed.as_slice())?
        } else {
            let mut seed = Zeroizing::new([0_u8; PROTECTED_SECRET_BYTES]);
            getrandom::fill(seed.as_mut()).map_err(|_| IdentityError::RandomGeneration)?;
            store.store(seed.as_ref())?;
            SigningKey::from_bytes(&seed)
        };
        let public_key = signing_key.verifying_key().to_bytes();
        let device_id = derive_device_id_v1(&public_key).map_err(|_| IdentityError::InvalidSeed)?;
        let device_identity = DeviceIdentity {
            device_id: device_id.to_vec(),
            public_key_algorithm: PublicKeyAlgorithm::Ed25519 as i32,
            public_key: public_key.to_vec(),
            display_name: display_name.to_owned(),
            platform: platform as i32,
        };

        Ok(Self {
            signing_key,
            device_identity,
        })
    }

    #[must_use]
    pub const fn device_identity(&self) -> &DeviceIdentity {
        &self.device_identity
    }

    /// Signs a canonical `SessionAnswer` or `SessionReconnect` bound to this Host.
    ///
    /// # Errors
    ///
    /// Returns an error when the transcript is malformed, uses a purpose the
    /// Host must not sign, or contains another Host device identifier in tag 2.
    pub fn sign_canonical_transcript(
        &self,
        canonical_transcript: &[u8],
    ) -> Result<CanonicalTranscriptSignature, IdentityError> {
        let decoded = decode(canonical_transcript).map_err(IdentityError::InvalidTranscript)?;
        if !matches!(
            decoded.purpose,
            TranscriptPurpose::SessionAnswer | TranscriptPurpose::SessionReconnect
        ) {
            return Err(IdentityError::UnsupportedTranscriptPurpose);
        }
        let transcript_host = decoded
            .fields
            .iter()
            .find(|field| field.tag == 2)
            .ok_or(IdentityError::HostDeviceIdMismatch)?;
        if transcript_host.value != self.device_identity.device_id {
            return Err(IdentityError::HostDeviceIdMismatch);
        }

        Ok(CanonicalTranscriptSignature {
            host_device_id: self.device_identity.device_id.clone(),
            host_public_key: self.device_identity.public_key.clone(),
            signature: self
                .signing_key
                .sign(canonical_transcript)
                .to_bytes()
                .to_vec(),
            transcript_sha256: sha256(canonical_transcript).to_vec(),
        })
    }

    /// Signs a canonical `SessionOffer` bound to this local Controller identity.
    ///
    /// # Errors
    ///
    /// Returns an error when the transcript is malformed, is not a session
    /// offer, or contains another Controller device identifier in tag 1.
    pub fn sign_session_offer(
        &self,
        canonical_transcript: &[u8],
    ) -> Result<SessionOfferSignature, IdentityError> {
        let decoded = decode(canonical_transcript).map_err(IdentityError::InvalidTranscript)?;
        if decoded.purpose != TranscriptPurpose::SessionOffer {
            return Err(IdentityError::UnsupportedTranscriptPurpose);
        }
        let transcript_controller = decoded
            .fields
            .iter()
            .find(|field| field.tag == 1)
            .ok_or(IdentityError::ControllerDeviceIdMismatch)?;
        if transcript_controller.value != self.device_identity.device_id {
            return Err(IdentityError::ControllerDeviceIdMismatch);
        }

        Ok(SessionOfferSignature {
            controller_device_id: self.device_identity.device_id.clone(),
            controller_public_key: self.device_identity.public_key.clone(),
            signature: self
                .signing_key
                .sign(canonical_transcript)
                .to_bytes()
                .to_vec(),
            transcript_sha256: sha256(canonical_transcript).to_vec(),
        })
    }

    /// Signs a canonical pairing transcript for a role bound to this identity.
    ///
    /// # Errors
    ///
    /// Returns an error when the transcript is malformed, is not a pairing
    /// transcript, has an unspecified role, or binds that role to another
    /// device identifier.
    pub fn sign_pairing_transcript(
        &self,
        canonical_transcript: &[u8],
        role: PairingIdentityRole,
    ) -> Result<PairingTranscriptSignature, IdentityError> {
        let decoded = decode(canonical_transcript).map_err(IdentityError::InvalidTranscript)?;
        if decoded.purpose != TranscriptPurpose::PairingSas {
            return Err(IdentityError::UnsupportedTranscriptPurpose);
        }
        let device_id_tag = match role {
            PairingIdentityRole::Controller => 1,
            PairingIdentityRole::Host => 2,
            PairingIdentityRole::Unspecified => return Err(IdentityError::InvalidPairingRole),
        };
        let transcript_identity = decoded
            .fields
            .iter()
            .find(|field| field.tag == device_id_tag)
            .ok_or_else(|| pairing_identity_mismatch(role))?;
        if transcript_identity.value != self.device_identity.device_id {
            return Err(pairing_identity_mismatch(role));
        }

        Ok(PairingTranscriptSignature {
            role: role as i32,
            signer_device_id: self.device_identity.device_id.clone(),
            signer_public_key: self.device_identity.public_key.clone(),
            signature: self
                .signing_key
                .sign(canonical_transcript)
                .to_bytes()
                .to_vec(),
            transcript_sha256: sha256(canonical_transcript).to_vec(),
        })
    }
}

const fn pairing_identity_mismatch(role: PairingIdentityRole) -> IdentityError {
    match role {
        PairingIdentityRole::Controller => IdentityError::ControllerDeviceIdMismatch,
        PairingIdentityRole::Host => IdentityError::HostDeviceIdMismatch,
        PairingIdentityRole::Unspecified => IdentityError::InvalidPairingRole,
    }
}

impl fmt::Debug for HostIdentity {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("HostIdentity([REDACTED])")
    }
}

fn signing_key_from_seed(seed: &[u8]) -> Result<SigningKey, IdentityError> {
    let mut seed_bytes = Zeroizing::new([0_u8; PROTECTED_SECRET_BYTES]);
    if seed.len() != seed_bytes.len() {
        return Err(IdentityError::InvalidSeed);
    }
    seed_bytes.copy_from_slice(seed);
    Ok(SigningKey::from_bytes(&seed_bytes))
}

fn validate_identity_metadata(
    display_name: &str,
    platform: DevicePlatform,
) -> Result<(), IdentityError> {
    if display_name.is_empty() || display_name.len() > MAX_DEVICE_NAME_UTF8_BYTES {
        return Err(IdentityError::InvalidDisplayName);
    }
    if !matches!(platform, DevicePlatform::Windows | DevicePlatform::Macos) {
        return Err(IdentityError::InvalidPlatform);
    }
    Ok(())
}
