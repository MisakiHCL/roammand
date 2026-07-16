// SPDX-License-Identifier: MPL-2.0

use ed25519_dalek::{Signature, Verifier, VerifyingKey};
use prost::Message;
use roammand_host_agent::{HostIdentity, IdentityError};
use roammand_host_platform::{
    MemorySecretStore, ProtectedSecret, ProtectedSecretStore, SecretStoreError,
};
use roammand_protocol::{
    canonical_transcript::{CanonicalTranscript, TranscriptField, TranscriptPurpose, encode},
    roammand::v1::{DevicePlatform, PairingIdentityRole},
};
use zeroize::Zeroizing;

const SECRET_BYTES: usize = 32;

#[test]
fn identity_is_created_once_and_reloaded_from_the_protected_store() {
    let store = MemorySecretStore::new();
    let first = HostIdentity::load_or_create(&store, "Office Mac", DevicePlatform::Macos)
        .expect("first identity must be created");
    let second = HostIdentity::load_or_create(&store, "Office Mac", DevicePlatform::Macos)
        .expect("identity must be reloaded");

    assert_eq!(first.device_identity(), second.device_identity());
    assert_eq!(first.device_identity().device_id.len(), 32);
    assert_eq!(first.device_identity().public_key.len(), 32);
    assert_eq!(first.device_identity().display_name, "Office Mac");

    let other = HostIdentity::load_or_create(
        &MemorySecretStore::new(),
        "Other Mac",
        DevicePlatform::Macos,
    )
    .expect("other identity must be created");
    assert_ne!(
        first.device_identity().device_id,
        other.device_identity().device_id
    );
}

#[test]
fn identity_rejects_corrupt_seed_and_non_desktop_platform() {
    assert!(matches!(
        HostIdentity::load_or_create(&BadLengthStore, "Host", DevicePlatform::Macos),
        Err(IdentityError::InvalidSeed)
    ));
    assert!(matches!(
        HostIdentity::load_or_create(&MemorySecretStore::new(), "Phone", DevicePlatform::Ios),
        Err(IdentityError::InvalidPlatform)
    ));
}

#[test]
fn signs_only_host_bound_session_answer_or_reconnect_transcripts() {
    let store = MemorySecretStore::new();
    store
        .store(&[0x42; SECRET_BYTES])
        .expect("deterministic test seed must be stored");
    let identity = HostIdentity::load_or_create(&store, "Host", DevicePlatform::Macos)
        .expect("identity must load");
    let answer = transcript_for(
        TranscriptPurpose::SessionAnswer,
        &identity.device_identity().device_id,
    );

    let signed = identity
        .sign_canonical_transcript(&answer)
        .expect("session answer must be signed");
    assert_eq!(signed.host_device_id, identity.device_identity().device_id);
    assert_eq!(
        signed.host_public_key,
        identity.device_identity().public_key
    );
    assert_eq!(signed.signature.len(), 64);
    assert_eq!(signed.transcript_sha256.len(), 32);
    let public_key: [u8; 32] = signed
        .host_public_key
        .as_slice()
        .try_into()
        .expect("public key length");
    let signature = Signature::try_from(signed.signature.as_slice()).expect("signature length");
    VerifyingKey::from_bytes(&public_key)
        .expect("public key must be valid")
        .verify(&answer, &signature)
        .expect("signature must verify");

    let reconnect = transcript_for(
        TranscriptPurpose::SessionReconnect,
        &identity.device_identity().device_id,
    );
    identity
        .sign_canonical_transcript(&reconnect)
        .expect("session reconnect must be signed");

    let offer = transcript_for(
        TranscriptPurpose::SessionOffer,
        &identity.device_identity().device_id,
    );
    assert!(matches!(
        identity.sign_canonical_transcript(&offer),
        Err(IdentityError::UnsupportedTranscriptPurpose)
    ));

    let mismatched = transcript_for(TranscriptPurpose::SessionAnswer, &[0x99; 32]);
    assert!(matches!(
        identity.sign_canonical_transcript(&mismatched),
        Err(IdentityError::HostDeviceIdMismatch)
    ));
}

#[test]
fn signs_session_offers_only_through_the_controller_role() {
    let store = MemorySecretStore::new();
    store
        .store(&[0x42; SECRET_BYTES])
        .expect("deterministic test seed must be stored");
    let identity = HostIdentity::load_or_create(&store, "Controller", DevicePlatform::Macos)
        .expect("identity must load");
    let offer = session_offer(&identity.device_identity().device_id, &[0x77; 32]);

    let signed = identity
        .sign_session_offer(&offer)
        .expect("local Controller offer must be signed");
    assert_eq!(
        signed.controller_device_id,
        identity.device_identity().device_id
    );
    assert_eq!(
        signed.controller_public_key,
        identity.device_identity().public_key
    );
    assert_eq!(signed.signature.len(), 64);
    assert_eq!(signed.transcript_sha256.len(), 32);
    let public_key: [u8; 32] = signed
        .controller_public_key
        .as_slice()
        .try_into()
        .expect("public key length");
    let signature = Signature::try_from(signed.signature.as_slice()).expect("signature length");
    VerifyingKey::from_bytes(&public_key)
        .expect("public key must be valid")
        .verify(&offer, &signature)
        .expect("offer signature must verify");

    assert!(matches!(
        identity.sign_canonical_transcript(&offer),
        Err(IdentityError::UnsupportedTranscriptPurpose)
    ));
    let mismatched = session_offer(&[0x99; 32], &[0x77; 32]);
    assert!(matches!(
        identity.sign_session_offer(&mismatched),
        Err(IdentityError::ControllerDeviceIdMismatch)
    ));
    let pairing = transcript_for(
        TranscriptPurpose::PairingSas,
        &identity.device_identity().device_id,
    );
    assert!(matches!(
        identity.sign_session_offer(&pairing),
        Err(IdentityError::UnsupportedTranscriptPurpose)
    ));
}

#[test]
fn signs_pairing_transcripts_only_for_the_bound_local_role() {
    let store = MemorySecretStore::new();
    store
        .store(&[0x42; SECRET_BYTES])
        .expect("deterministic test seed must be stored");
    let identity = HostIdentity::load_or_create(&store, "Desktop", DevicePlatform::Macos)
        .expect("identity must load");
    let local_device_id = identity.device_identity().device_id.as_slice();

    let controller_transcript = pairing_transcript(local_device_id, &[0x77; 32]);
    let controller_signature = identity
        .sign_pairing_transcript(&controller_transcript, PairingIdentityRole::Controller)
        .expect("local Controller pairing proof must be signed");
    assert_eq!(
        controller_signature.role,
        PairingIdentityRole::Controller as i32
    );
    assert_eq!(controller_signature.signer_device_id, local_device_id);
    assert_eq!(
        controller_signature.signer_public_key,
        identity.device_identity().public_key
    );
    verify_signature(
        &controller_signature.signer_public_key,
        &controller_signature.signature,
        &controller_transcript,
    );

    let host_transcript = pairing_transcript(&[0x66; 32], local_device_id);
    let host_signature = identity
        .sign_pairing_transcript(&host_transcript, PairingIdentityRole::Host)
        .expect("local Host pairing proof must be signed");
    assert_eq!(host_signature.role, PairingIdentityRole::Host as i32);
    assert_eq!(host_signature.signer_device_id, local_device_id);
    verify_signature(
        &host_signature.signer_public_key,
        &host_signature.signature,
        &host_transcript,
    );

    assert!(matches!(
        identity.sign_pairing_transcript(&controller_transcript, PairingIdentityRole::Unspecified),
        Err(IdentityError::InvalidPairingRole)
    ));
    assert!(matches!(
        identity.sign_pairing_transcript(&controller_transcript, PairingIdentityRole::Host),
        Err(IdentityError::HostDeviceIdMismatch)
    ));
    assert!(matches!(
        identity.sign_pairing_transcript(&host_transcript, PairingIdentityRole::Controller),
        Err(IdentityError::ControllerDeviceIdMismatch)
    ));

    let session = session_offer(local_device_id, &[0x77; 32]);
    assert!(matches!(
        identity.sign_pairing_transcript(&session, PairingIdentityRole::Controller),
        Err(IdentityError::UnsupportedTranscriptPurpose)
    ));
}

#[test]
fn malformed_and_oversized_transcripts_are_rejected_before_signing() {
    let identity =
        HostIdentity::load_or_create(&MemorySecretStore::new(), "Host", DevicePlatform::Windows)
            .expect("identity must load");
    let valid = transcript_for(
        TranscriptPurpose::SessionAnswer,
        &identity.device_identity().device_id,
    );

    for invalid in [
        with_unknown_version(&valid),
        with_duplicate_second_tag(&valid),
        with_trailing_byte(&valid),
        vec![0; 4097],
    ] {
        assert!(matches!(
            identity.sign_canonical_transcript(&invalid),
            Err(IdentityError::InvalidTranscript(_))
        ));
    }
}

#[test]
fn debug_and_signature_response_do_not_expose_the_private_seed() {
    let seed = [0x42; SECRET_BYTES];
    let store = MemorySecretStore::new();
    store.store(&seed).expect("test seed must be stored");
    let identity = HostIdentity::load_or_create(&store, "Host", DevicePlatform::Macos)
        .expect("identity must load");
    let transcript = transcript_for(
        TranscriptPurpose::SessionAnswer,
        &identity.device_identity().device_id,
    );
    let response = identity
        .sign_canonical_transcript(&transcript)
        .expect("transcript must be signed");

    assert!(!format!("{identity:?}").contains(&"42".repeat(32)));
    assert!(
        !response
            .encode_to_vec()
            .windows(seed.len())
            .any(|window| window == seed)
    );
}

#[test]
fn debug_does_not_expose_public_identity_metadata() {
    const NAME_SENTINEL: &str = "PRIVATE_DEVICE_NAME_5913";
    let identity = HostIdentity::load_or_create(
        &MemorySecretStore::new(),
        NAME_SENTINEL,
        DevicePlatform::Macos,
    )
    .expect("identity must load");

    let debug = format!("{identity:?}");
    assert!(debug.contains("REDACTED"));
    assert!(!debug.contains(NAME_SENTINEL));
    assert!(!debug.contains(&format!("{:?}", identity.device_identity().device_id)));
}

fn transcript_for(purpose: TranscriptPurpose, host_device_id: &[u8]) -> Vec<u8> {
    let tags: &[u16] = match purpose {
        TranscriptPurpose::PairingSas => &[1, 2, 3, 4, 5, 6, 7],
        TranscriptPurpose::SessionOffer => &[1, 2, 8, 9, 10, 11, 12, 13, 14],
        TranscriptPurpose::SessionAnswer => &[1, 2, 8, 9, 10, 11, 12, 13, 14, 15, 16],
        TranscriptPurpose::SessionReconnect => &[1, 2, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
    };
    let fields = tags
        .iter()
        .map(|tag| TranscriptField {
            tag: *tag,
            value: if *tag == 2 {
                host_device_id.to_vec()
            } else {
                vec![u8::try_from(*tag).expect("test tag fits in a byte"); field_length(*tag)]
            },
        })
        .collect();
    encode(&CanonicalTranscript { purpose, fields }).expect("test transcript must encode")
}

fn session_offer(controller_device_id: &[u8], host_device_id: &[u8]) -> Vec<u8> {
    let tags = [1_u16, 2, 8, 9, 10, 11, 12, 13, 14];
    let fields = tags
        .into_iter()
        .map(|tag| TranscriptField {
            tag,
            value: match tag {
                1 => controller_device_id.to_vec(),
                2 => host_device_id.to_vec(),
                _ => vec![u8::try_from(tag).expect("tag fits"); field_length(tag)],
            },
        })
        .collect();
    encode(&CanonicalTranscript {
        purpose: TranscriptPurpose::SessionOffer,
        fields,
    })
    .expect("offer transcript must encode")
}

fn pairing_transcript(controller_device_id: &[u8], host_device_id: &[u8]) -> Vec<u8> {
    let tags = [1_u16, 2, 3, 4, 5, 6, 7];
    let fields = tags
        .into_iter()
        .map(|tag| TranscriptField {
            tag,
            value: match tag {
                1 => controller_device_id.to_vec(),
                2 => host_device_id.to_vec(),
                _ => vec![u8::try_from(tag).expect("tag fits"); field_length(tag)],
            },
        })
        .collect();
    encode(&CanonicalTranscript {
        purpose: TranscriptPurpose::PairingSas,
        fields,
    })
    .expect("pairing transcript must encode")
}

fn verify_signature(public_key: &[u8], signature: &[u8], transcript: &[u8]) {
    let public_key: [u8; 32] = public_key.try_into().expect("public key length");
    let signature = Signature::try_from(signature).expect("signature length");
    VerifyingKey::from_bytes(&public_key)
        .expect("public key must be valid")
        .verify(transcript, &signature)
        .expect("signature must verify");
}

const fn field_length(tag: u16) -> usize {
    match tag {
        3 | 8 => 16,
        10 | 11 => 8,
        12 | 17 => 4,
        _ => 32,
    }
}

fn with_unknown_version(valid: &[u8]) -> Vec<u8> {
    let mut invalid = valid.to_vec();
    invalid[4..6].copy_from_slice(&2_u16.to_be_bytes());
    invalid
}

fn with_duplicate_second_tag(valid: &[u8]) -> Vec<u8> {
    let mut invalid = valid.to_vec();
    let second_tag_offset = 10 + 6 + 32;
    invalid[second_tag_offset..second_tag_offset + 2].copy_from_slice(&1_u16.to_be_bytes());
    invalid
}

fn with_trailing_byte(valid: &[u8]) -> Vec<u8> {
    let mut invalid = valid.to_vec();
    invalid.push(0);
    invalid
}

struct BadLengthStore;

impl ProtectedSecretStore for BadLengthStore {
    fn load(&self) -> Result<Option<ProtectedSecret>, SecretStoreError> {
        Ok(Some(Zeroizing::new(vec![0; 31])))
    }

    fn store(&self, _secret: &[u8]) -> Result<(), SecretStoreError> {
        unreachable!("corrupt load must fail before store")
    }

    fn delete(&self) -> Result<(), SecretStoreError> {
        Ok(())
    }
}
