// SPDX-License-Identifier: MPL-2.0

use std::{collections::BTreeMap, fmt};

use ed25519_dalek::{Signature, Verifier, VerifyingKey};
use roammand_protocol::{
    canonical_transcript::{
        CanonicalTranscript, TranscriptError, TranscriptField, TranscriptPurpose, encode, sha256,
    },
    protocol_limits::{DEVICE_ID_BYTES, NONCE_OR_HASH_BYTES, SESSION_ID_BYTES, SIGNATURE_BYTES},
    roammand::v1::{
        DeviceIdentity, SessionAnswerAuthentication, SessionOfferAuthentication, SessionPermission,
        SessionReconnectAuthentication,
    },
};
use thiserror::Error;

use crate::AuthorizationRegistry;

const SESSION_AUTH_MAX_LIFETIME_MS: u64 = 30_000;
const SESSION_AUTH_FUTURE_SKEW_MS: u64 = 10_000;
const MAX_REPLAY_CACHE_ENTRIES: usize = 1_024;

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum SessionAuthenticationError {
    #[error("Host identity is invalid")]
    InvalidHostIdentity,
    #[error("session authentication fields are invalid")]
    InvalidOffer,
    #[error("session offer targets another Host")]
    HostMismatch,
    #[error("session offer is not valid yet")]
    NotYetValid,
    #[error("session offer has expired")]
    Expired,
    #[error("session offer validity is too long")]
    LifetimeTooLong,
    #[error("session permissions are invalid")]
    InvalidPermissions,
    #[error("Controller is not authorized")]
    ControllerNotAuthorized,
    #[error("requested session permissions were not granted")]
    PermissionDenied,
    #[error("session offer content hash does not match")]
    OfferHashMismatch,
    #[error("session offer DTLS fingerprint does not match")]
    FingerprintMismatch,
    #[error("session offer signature is invalid")]
    InvalidSignature,
    #[error("session nonce was already used")]
    Replay,
    #[error("session replay cache is full")]
    ReplayCacheFull,
    #[error("canonical session transcript is invalid")]
    InvalidTranscript,
}

#[derive(Clone, PartialEq)]
pub struct VerifiedSessionOffer {
    pub controller: DeviceIdentity,
    pub session_id: Vec<u8>,
    pub permissions: Vec<SessionPermission>,
}

impl fmt::Debug for VerifiedSessionOffer {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("VerifiedSessionOffer")
            .field("permission_count", &self.permissions.len())
            .field("sensitive", &"[REDACTED]")
            .finish_non_exhaustive()
    }
}

pub struct OfferVerifier {
    host_device_id: Vec<u8>,
    used_nonces: BTreeMap<Vec<u8>, u64>,
}

impl OfferVerifier {
    /// Creates a verifier bound to one local Host identity.
    ///
    /// # Errors
    ///
    /// Returns an error unless the Host device identifier contains 32 bytes.
    pub fn new(host_device_id: Vec<u8>) -> Result<Self, SessionAuthenticationError> {
        if host_device_id.len() != DEVICE_ID_BYTES {
            return Err(SessionAuthenticationError::InvalidHostIdentity);
        }
        Ok(Self {
            host_device_id,
            used_nonces: BTreeMap::new(),
        })
    }

    /// Verifies every security binding before a `PeerConnection` is created.
    ///
    /// # Errors
    ///
    /// Returns a stable authentication error for malformed, unauthorized,
    /// expired, replayed, mismatched, or incorrectly signed offers.
    pub fn verify(
        &mut self,
        authentication: &SessionOfferAuthentication,
        offer_sdp: &str,
        controller_dtls_fingerprint_sha256: &[u8],
        authorization: &AuthorizationRegistry,
        now_unix_ms: u64,
    ) -> Result<VerifiedSessionOffer, SessionAuthenticationError> {
        validate_fixed_fields(authentication)?;
        if authentication.host_device_id != self.host_device_id {
            return Err(SessionAuthenticationError::HostMismatch);
        }
        validate_time(authentication, now_unix_ms)?;
        let permissions = normalize_permissions(&authentication.requested_permissions)?;
        if authentication.offer_sha256 != sha256(offer_sdp.as_bytes()) {
            return Err(SessionAuthenticationError::OfferHashMismatch);
        }
        if authentication.controller_dtls_fingerprint_sha256 != controller_dtls_fingerprint_sha256 {
            return Err(SessionAuthenticationError::FingerprintMismatch);
        }

        let grant_view = authorization
            .controller_grant(&authentication.controller_device_id)
            .ok_or(SessionAuthenticationError::ControllerNotAuthorized)?;
        let grant = grant_view
            .grant
            .as_ref()
            .ok_or(SessionAuthenticationError::ControllerNotAuthorized)?;
        let controller = grant
            .controller
            .as_ref()
            .ok_or(SessionAuthenticationError::ControllerNotAuthorized)?;
        if permissions
            .iter()
            .any(|permission| !grant.permissions.contains(&(*permission as i32)))
        {
            return Err(SessionAuthenticationError::PermissionDenied);
        }

        let transcript = encode_session_offer_transcript(authentication)?;
        verify_signature(controller, &transcript, &authentication.signature)?;

        self.used_nonces
            .retain(|_, expires_at| *expires_at >= now_unix_ms);
        let nonce_key = nonce_key(authentication);
        if self.used_nonces.contains_key(&nonce_key) {
            return Err(SessionAuthenticationError::Replay);
        }
        if self.used_nonces.len() >= MAX_REPLAY_CACHE_ENTRIES {
            return Err(SessionAuthenticationError::ReplayCacheFull);
        }
        self.used_nonces
            .insert(nonce_key, authentication.expires_at_unix_ms);

        Ok(VerifiedSessionOffer {
            controller: controller.clone(),
            session_id: authentication.session_id.clone(),
            permissions,
        })
    }
}

/// Encodes the signed fields of a session offer using Canonical Transcript V1.
///
/// # Errors
///
/// Returns an error when the authentication fields cannot form a canonical
/// Session Offer transcript.
pub fn encode_session_offer_transcript(
    authentication: &SessionOfferAuthentication,
) -> Result<Vec<u8>, SessionAuthenticationError> {
    let permission_bits = permission_bits(&authentication.requested_permissions)?;
    encode(&CanonicalTranscript {
        purpose: TranscriptPurpose::SessionOffer,
        fields: vec![
            field(1, &authentication.controller_device_id),
            field(2, &authentication.host_device_id),
            field(8, &authentication.session_id),
            field(9, &authentication.nonce),
            field(10, &authentication.issued_at_unix_ms.to_be_bytes()),
            field(11, &authentication.expires_at_unix_ms.to_be_bytes()),
            field(12, &permission_bits.to_be_bytes()),
            field(13, &authentication.offer_sha256),
            field(14, &authentication.controller_dtls_fingerprint_sha256),
        ],
    })
    .map_err(map_transcript_error)
}

/// Encodes the signed fields of a session answer using Canonical Transcript V1.
///
/// # Errors
///
/// Returns an error when the answer fields cannot form a canonical Session
/// Answer transcript.
pub fn encode_session_answer_transcript(
    authentication: &SessionAnswerAuthentication,
) -> Result<Vec<u8>, SessionAuthenticationError> {
    let permission_bits = permission_bits(&authentication.requested_permissions)?;
    encode(&CanonicalTranscript {
        purpose: TranscriptPurpose::SessionAnswer,
        fields: vec![
            field(1, &authentication.controller_device_id),
            field(2, &authentication.host_device_id),
            field(8, &authentication.session_id),
            field(9, &authentication.nonce),
            field(10, &authentication.issued_at_unix_ms.to_be_bytes()),
            field(11, &authentication.expires_at_unix_ms.to_be_bytes()),
            field(12, &permission_bits.to_be_bytes()),
            field(13, &authentication.offer_sha256),
            field(14, &authentication.controller_dtls_fingerprint_sha256),
            field(15, &authentication.answer_sha256),
            field(16, &authentication.host_dtls_fingerprint_sha256),
        ],
    })
    .map_err(map_transcript_error)
}

/// Encodes the signed fields of a retained-session reconnect using Canonical
/// Transcript V1.
///
/// # Errors
///
/// Returns an error when the reconnect fields cannot form a canonical Session
/// Reconnect transcript.
pub fn encode_session_reconnect_transcript(
    authentication: &SessionReconnectAuthentication,
) -> Result<Vec<u8>, SessionAuthenticationError> {
    let permission_bits = permission_bits(&authentication.requested_permissions)?;
    encode(&CanonicalTranscript {
        purpose: TranscriptPurpose::SessionReconnect,
        fields: vec![
            field(1, &authentication.controller_device_id),
            field(2, &authentication.host_device_id),
            field(8, &authentication.session_id),
            field(9, &authentication.nonce),
            field(10, &authentication.issued_at_unix_ms.to_be_bytes()),
            field(11, &authentication.expires_at_unix_ms.to_be_bytes()),
            field(12, &permission_bits.to_be_bytes()),
            field(13, &authentication.offer_sha256),
            field(14, &authentication.controller_dtls_fingerprint_sha256),
            field(15, &authentication.answer_sha256),
            field(16, &authentication.host_dtls_fingerprint_sha256),
            field(17, &authentication.reconnect_generation.to_be_bytes()),
        ],
    })
    .map_err(map_transcript_error)
}

fn validate_fixed_fields(
    authentication: &SessionOfferAuthentication,
) -> Result<(), SessionAuthenticationError> {
    if authentication.controller_device_id.len() != DEVICE_ID_BYTES
        || authentication.host_device_id.len() != DEVICE_ID_BYTES
        || authentication.session_id.len() != SESSION_ID_BYTES
        || authentication.nonce.len() != NONCE_OR_HASH_BYTES
        || authentication.offer_sha256.len() != NONCE_OR_HASH_BYTES
        || authentication.controller_dtls_fingerprint_sha256.len() != NONCE_OR_HASH_BYTES
        || authentication.signature.len() != SIGNATURE_BYTES
    {
        return Err(SessionAuthenticationError::InvalidOffer);
    }
    Ok(())
}

fn validate_time(
    authentication: &SessionOfferAuthentication,
    now_unix_ms: u64,
) -> Result<(), SessionAuthenticationError> {
    let lifetime = authentication
        .expires_at_unix_ms
        .checked_sub(authentication.issued_at_unix_ms)
        .ok_or(SessionAuthenticationError::Expired)?;
    if lifetime > SESSION_AUTH_MAX_LIFETIME_MS {
        return Err(SessionAuthenticationError::LifetimeTooLong);
    }
    if authentication.issued_at_unix_ms > now_unix_ms.saturating_add(SESSION_AUTH_FUTURE_SKEW_MS) {
        return Err(SessionAuthenticationError::NotYetValid);
    }
    if authentication.expires_at_unix_ms < now_unix_ms {
        return Err(SessionAuthenticationError::Expired);
    }
    Ok(())
}

fn normalize_permissions(
    values: &[i32],
) -> Result<Vec<SessionPermission>, SessionAuthenticationError> {
    if values.is_empty() {
        return Err(SessionAuthenticationError::InvalidPermissions);
    }
    let mut previous = None;
    let mut permissions = Vec::with_capacity(values.len());
    for value in values {
        let permission = SessionPermission::try_from(*value)
            .map_err(|_| SessionAuthenticationError::InvalidPermissions)?;
        if permission == SessionPermission::Unspecified
            || previous.is_some_and(|previous| *value <= previous)
        {
            return Err(SessionAuthenticationError::InvalidPermissions);
        }
        previous = Some(*value);
        permissions.push(permission);
    }
    if permissions.contains(&SessionPermission::ControlInput)
        && !permissions.contains(&SessionPermission::ViewScreen)
    {
        return Err(SessionAuthenticationError::InvalidPermissions);
    }
    Ok(permissions)
}

fn permission_bits(values: &[i32]) -> Result<u32, SessionAuthenticationError> {
    let permissions = normalize_permissions(values)?;
    Ok(permissions
        .into_iter()
        .fold(0_u32, |bits, permission| bits | permission as u32))
}

fn verify_signature(
    controller: &DeviceIdentity,
    transcript: &[u8],
    signature: &[u8],
) -> Result<(), SessionAuthenticationError> {
    let public_key: [u8; 32] = controller
        .public_key
        .as_slice()
        .try_into()
        .map_err(|_| SessionAuthenticationError::InvalidSignature)?;
    let verifying_key = VerifyingKey::from_bytes(&public_key)
        .map_err(|_| SessionAuthenticationError::InvalidSignature)?;
    let signature =
        Signature::try_from(signature).map_err(|_| SessionAuthenticationError::InvalidSignature)?;
    verifying_key
        .verify(transcript, &signature)
        .map_err(|_| SessionAuthenticationError::InvalidSignature)
}

fn nonce_key(authentication: &SessionOfferAuthentication) -> Vec<u8> {
    let mut key = Vec::with_capacity(DEVICE_ID_BYTES + NONCE_OR_HASH_BYTES);
    key.extend_from_slice(&authentication.controller_device_id);
    key.extend_from_slice(&authentication.nonce);
    key
}

fn field(tag: u16, value: &[u8]) -> TranscriptField {
    TranscriptField {
        tag,
        value: value.to_vec(),
    }
}

const fn map_transcript_error(_error: TranscriptError) -> SessionAuthenticationError {
    SessionAuthenticationError::InvalidTranscript
}
