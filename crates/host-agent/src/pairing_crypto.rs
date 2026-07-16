// SPDX-License-Identifier: MPL-2.0

use ed25519_dalek::{Signature, Verifier, VerifyingKey};
use prost::Message;
use roammand_protocol::{
    canonical_transcript::{
        CanonicalTranscript, TranscriptField, TranscriptPurpose, encode, sha256,
    },
    identity_derivation::derive_device_id_v1,
    pairing_crypto::{
        CryptoDirection, PairingKeySchedule, derive_pairing_keys, open_pairing_payload,
        pairing_aad, sas_words, seal_pairing_payload, x25519_shared_secret,
    },
    protocol_limits::{
        DEVICE_ID_BYTES, NONCE_OR_HASH_BYTES, PROTOCOL_MAJOR_VERSION, PUBLIC_KEY_BYTES,
        RENDEZVOUS_ID_BYTES, SIGNATURE_BYTES,
    },
    roammand::v1::{
        ControllerPairingHello, DeviceIdentity, EncryptedPairingEnvelope, PairingDirection,
        PairingMessage, PairingPlaintext, ProtocolVersion, pairing_message,
    },
    validation::validate_device_identity,
};
use thiserror::Error;
use zeroize::Zeroizing;

const BIP39_ENGLISH: &str = include_str!("../../../conformance/wordlists/bip39-english.txt");

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub(crate) enum HostPairingCryptoError {
    #[error("pairing message is invalid")]
    InvalidMessage,
    #[error("pairing identity is invalid")]
    InvalidIdentity,
    #[error("pairing transcript does not match")]
    TranscriptMismatch,
    #[error("pairing signature is invalid")]
    InvalidSignature,
    #[error("pairing cryptography failed")]
    Cryptography,
}

pub(crate) struct VerifiedControllerHello {
    pub controller: DeviceIdentity,
    pub controller_ephemeral_public_key: Vec<u8>,
    pub transcript: Vec<u8>,
    pub transcript_sha256: [u8; 32],
    pub keys: PairingKeySchedule,
}

pub(crate) fn decode_pairing_message(
    encoded: &[u8],
) -> Result<PairingMessage, HostPairingCryptoError> {
    strict_decode(encoded)
}

pub(crate) fn encode_pairing_payload(payload: pairing_message::Payload) -> Vec<u8> {
    PairingMessage {
        payload: Some(payload),
    }
    .encode_to_vec()
}

pub(crate) fn verify_controller_hello(
    hello: ControllerPairingHello,
    sender_device_id: &[u8],
    expected_rendezvous_id: &[u8],
    host_identity: &DeviceIdentity,
    host_ephemeral_private_key: &[u8],
    host_ephemeral_public_key: &[u8],
) -> Result<VerifiedControllerHello, HostPairingCryptoError> {
    if hello.rendezvous_id != expected_rendezvous_id
        || hello.rendezvous_id.len() != RENDEZVOUS_ID_BYTES
        || hello.ephemeral_public_key.len() != PUBLIC_KEY_BYTES
        || hello.transcript_sha256.len() != NONCE_OR_HASH_BYTES
        || hello.signature.len() != SIGNATURE_BYTES
    {
        return Err(HostPairingCryptoError::InvalidMessage);
    }
    let controller = hello
        .identity
        .ok_or(HostPairingCryptoError::InvalidIdentity)?;
    validate_device_identity(&controller).map_err(|_| HostPairingCryptoError::InvalidIdentity)?;
    if controller.display_name.is_empty()
        || controller.device_id != sender_device_id
        || controller.device_id == host_identity.device_id
    {
        return Err(HostPairingCryptoError::InvalidIdentity);
    }
    let controller_public_key: [u8; PUBLIC_KEY_BYTES] = controller
        .public_key
        .as_slice()
        .try_into()
        .map_err(|_| HostPairingCryptoError::InvalidIdentity)?;
    if derive_device_id_v1(&controller_public_key)
        .map_err(|_| HostPairingCryptoError::InvalidIdentity)?
        .as_slice()
        != controller.device_id
    {
        return Err(HostPairingCryptoError::InvalidIdentity);
    }
    let transcript = encode_pairing_transcript(
        &controller,
        host_identity,
        expected_rendezvous_id,
        &hello.ephemeral_public_key,
        host_ephemeral_public_key,
    )?;
    let transcript_digest = sha256(&transcript);
    if hello.transcript_sha256 != transcript_digest {
        return Err(HostPairingCryptoError::TranscriptMismatch);
    }
    let signature = Signature::try_from(hello.signature.as_slice())
        .map_err(|_| HostPairingCryptoError::InvalidSignature)?;
    VerifyingKey::from_bytes(&controller_public_key)
        .map_err(|_| HostPairingCryptoError::InvalidIdentity)?
        .verify(&transcript, &signature)
        .map_err(|_| HostPairingCryptoError::InvalidSignature)?;
    let shared_secret = Zeroizing::new(
        x25519_shared_secret(host_ephemeral_private_key, &hello.ephemeral_public_key)
            .map_err(|_| HostPairingCryptoError::Cryptography)?,
    );
    let keys = derive_pairing_keys(shared_secret.as_ref(), &transcript_digest)
        .map_err(|_| HostPairingCryptoError::Cryptography)?;
    Ok(VerifiedControllerHello {
        controller,
        controller_ephemeral_public_key: hello.ephemeral_public_key,
        transcript,
        transcript_sha256: transcript_digest,
        keys,
    })
}

pub(crate) fn seal_host_plaintext(
    key: &[u8],
    sequence: u64,
    rendezvous_id: &[u8],
    controller_device_id: &[u8],
    host_device_id: &[u8],
    plaintext: &PairingPlaintext,
) -> Result<Vec<u8>, HostPairingCryptoError> {
    let aad = pairing_aad(
        CryptoDirection::HostToController,
        sequence,
        rendezvous_id,
        controller_device_id,
        host_device_id,
    )
    .map_err(|_| HostPairingCryptoError::Cryptography)?;
    let ciphertext = seal_pairing_payload(
        key,
        CryptoDirection::HostToController,
        sequence,
        &aad,
        &plaintext.encode_to_vec(),
    )
    .map_err(|_| HostPairingCryptoError::Cryptography)?;
    Ok(encode_pairing_payload(
        pairing_message::Payload::EncryptedEnvelope(EncryptedPairingEnvelope {
            protocol_version: Some(ProtocolVersion {
                major: PROTOCOL_MAJOR_VERSION,
                minor: 0,
            }),
            rendezvous_id: rendezvous_id.to_vec(),
            direction: PairingDirection::HostToController as i32,
            sequence,
            ciphertext,
        }),
    ))
}

pub(crate) fn open_controller_plaintext(
    key: &[u8],
    expected_sequence: u64,
    rendezvous_id: &[u8],
    controller_device_id: &[u8],
    host_device_id: &[u8],
    encoded: &[u8],
) -> Result<PairingPlaintext, HostPairingCryptoError> {
    let message = decode_pairing_message(encoded)?;
    let Some(pairing_message::Payload::EncryptedEnvelope(envelope)) = message.payload else {
        return Err(HostPairingCryptoError::InvalidMessage);
    };
    let version = envelope
        .protocol_version
        .as_ref()
        .ok_or(HostPairingCryptoError::InvalidMessage)?;
    if version.major != PROTOCOL_MAJOR_VERSION
        || envelope.rendezvous_id != rendezvous_id
        || envelope.direction != PairingDirection::ControllerToHost as i32
        || envelope.sequence != expected_sequence
    {
        return Err(HostPairingCryptoError::InvalidMessage);
    }
    let aad = pairing_aad(
        CryptoDirection::ControllerToHost,
        expected_sequence,
        rendezvous_id,
        controller_device_id,
        host_device_id,
    )
    .map_err(|_| HostPairingCryptoError::Cryptography)?;
    let plaintext = open_pairing_payload(
        key,
        CryptoDirection::ControllerToHost,
        expected_sequence,
        &aad,
        &envelope.ciphertext,
    )
    .map_err(|_| HostPairingCryptoError::Cryptography)?;
    strict_decode(&plaintext)
}

pub(crate) fn pairing_sas_words(
    transcript_sha256: &[u8],
) -> Result<Vec<String>, HostPairingCryptoError> {
    let word_list = BIP39_ENGLISH.lines().collect::<Vec<_>>();
    sas_words(transcript_sha256, &word_list)
        .map(|words| words.into_iter().map(str::to_owned).collect())
        .map_err(|_| HostPairingCryptoError::Cryptography)
}

pub(crate) fn public_key_fingerprint(public_key: &[u8]) -> [u8; 32] {
    sha256(public_key)
}

fn encode_pairing_transcript(
    controller: &DeviceIdentity,
    host: &DeviceIdentity,
    rendezvous_id: &[u8],
    controller_ephemeral_public_key: &[u8],
    host_ephemeral_public_key: &[u8],
) -> Result<Vec<u8>, HostPairingCryptoError> {
    if controller.device_id.len() != DEVICE_ID_BYTES
        || host.device_id.len() != DEVICE_ID_BYTES
        || rendezvous_id.len() != RENDEZVOUS_ID_BYTES
    {
        return Err(HostPairingCryptoError::InvalidMessage);
    }
    let values = [
        controller.device_id.as_slice(),
        host.device_id.as_slice(),
        rendezvous_id,
        controller.public_key.as_slice(),
        host.public_key.as_slice(),
        controller_ephemeral_public_key,
        host_ephemeral_public_key,
    ];
    encode(&CanonicalTranscript {
        purpose: TranscriptPurpose::PairingSas,
        fields: values
            .into_iter()
            .enumerate()
            .map(|(index, value)| TranscriptField {
                tag: u16::try_from(index + 1).expect("pairing transcript tag fits"),
                value: value.to_vec(),
            })
            .collect(),
    })
    .map_err(|_| HostPairingCryptoError::InvalidMessage)
}

fn strict_decode<T>(encoded: &[u8]) -> Result<T, HostPairingCryptoError>
where
    T: Message + Default,
{
    let value = T::decode(encoded).map_err(|_| HostPairingCryptoError::InvalidMessage)?;
    if value.encode_to_vec() != encoded {
        return Err(HostPairingCryptoError::InvalidMessage);
    }
    Ok(value)
}

#[cfg(test)]
mod tests {
    use super::*;
    use roammand_protocol::roammand::v1::pairing_plaintext;

    #[test]
    fn accepts_canonical_controller_ready_emitted_by_dart() {
        let encoded = hex::decode(concat!(
            "42500a020801121051515151515151515151515151515151180120012a34",
            "894ef07c891c11770a4c8fd8c625e61864dc6cb8b91b6487ed038bef7",
            "cc85547126eda5801c235ae8333a8914b41d2f6fb62f14e"
        ))
        .expect("Dart ControllerReady fixture");
        let key = hex::decode("c1b3ff351ee44cc2747352ee66fd765ba96cdea3f97ae853d0c4115a09520cf3")
            .expect("Controller-to-Host key");
        let rendezvous_id = [0x51; 16];
        let controller_device_id =
            hex::decode("3fa87c7fc33688cc33f36dfbbd1e3a97bde650eaf1ea2f80ed9d1941512afbff")
                .expect("Controller device ID");
        let host_device_id =
            hex::decode("e85889ed9cdf1877c3e0d83310ae21df3d0827ec599df9ef251b2df30fbbc6ff")
                .expect("Host device ID");

        let plaintext = open_controller_plaintext(
            &key,
            1,
            &rendezvous_id,
            &controller_device_id,
            &host_device_id,
            &encoded,
        )
        .expect("canonical Dart ControllerReady must open in Rust");
        let Some(pairing_plaintext::Payload::ControllerReady(ready)) = plaintext.payload else {
            panic!("ControllerReady payload");
        };
        assert_eq!(ready.transcript_sha256.len(), NONCE_OR_HASH_BYTES);
    }
}
