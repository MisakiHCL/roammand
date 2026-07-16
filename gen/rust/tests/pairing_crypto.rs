// SPDX-License-Identifier: Apache-2.0

use std::{fs, path::PathBuf};

use roammand_protocol::{
    canonical_transcript::sha256,
    pairing_crypto::{
        CryptoDirection, PairingCryptoError, PairingSequenceValidator, derive_pairing_keys,
        open_pairing_payload, pairing_aad, pairing_nonce, sas_indexes, sas_words,
        seal_pairing_payload, x25519_public_key, x25519_shared_secret,
    },
};
use serde::Deserialize;
use sha2::{Digest, Sha256};

#[derive(Deserialize)]
struct PairingVector {
    controller_device_id_hex: String,
    host_device_id_hex: String,
    rendezvous_id_hex: String,
    controller_x25519_private_key_hex: String,
    controller_x25519_public_key_hex: String,
    host_x25519_private_key_hex: String,
    host_x25519_public_key_hex: String,
    x25519_shared_secret_hex: String,
    canonical_transcript_hex: String,
    transcript_sha256_hex: String,
    sas_indexes: [u16; 4],
    sas_words: [String; 4],
    wordlist_sha256_hex: String,
    controller_to_host_key_hex: String,
    host_to_controller_key_hex: String,
    sequence: u64,
    nonce_hex: String,
    aad_hex: String,
    plaintext_hex: String,
    ciphertext_and_tag_hex: String,
}

#[test]
fn pairing_crypto_v1_maps_the_first_44_digest_bits_to_four_indexes() {
    let digest = hex::decode("f89f31c4716edbcff1d8a4ad5fbe1161730b022cf28770146e481a06ef5981c6")
        .expect("hex");

    assert_eq!(sas_indexes(&digest), Ok([1988, 1996, 904, 1814]));
}

#[test]
fn pairing_crypto_v1_rejects_invalid_digest_and_sequence_values() {
    assert_eq!(
        sas_indexes(&[0_u8; 31]),
        Err(PairingCryptoError::InvalidLength)
    );
    assert_eq!(
        pairing_nonce(CryptoDirection::ControllerToHost, 0),
        Err(PairingCryptoError::InvalidSequence)
    );
    assert_eq!(
        pairing_nonce(CryptoDirection::ControllerToHost, (i64::MAX as u64) + 1),
        Err(PairingCryptoError::InvalidSequence)
    );
    assert_eq!(
        x25519_shared_secret(&[0_u8; 32], &[0_u8; 32]),
        Err(PairingCryptoError::InvalidPublicKey)
    );
}

#[test]
fn pairing_crypto_v1_matches_the_shared_golden_vector() {
    let vector: PairingVector = load_json("protocol_vectors/pairing_crypto_v1.json");
    let word_bytes = fs::read(fixture_path("wordlists/bip39-english.txt")).expect("word list");
    let word_text = std::str::from_utf8(&word_bytes).expect("UTF-8 word list");
    let words: Vec<_> = word_text.lines().collect();
    let transcript = decode(&vector.canonical_transcript_hex);
    let transcript_hash = sha256(&transcript);
    let controller_private = decode(&vector.controller_x25519_private_key_hex);
    let host_private = decode(&vector.host_x25519_private_key_hex);

    assert_eq!(hex::encode(transcript_hash), vector.transcript_sha256_hex);
    assert_eq!(
        hex::encode(x25519_public_key(&controller_private).expect("controller public key")),
        vector.controller_x25519_public_key_hex
    );
    assert_eq!(
        hex::encode(x25519_public_key(&host_private).expect("host public key")),
        vector.host_x25519_public_key_hex
    );
    let shared = x25519_shared_secret(
        &controller_private,
        &decode(&vector.host_x25519_public_key_hex),
    )
    .expect("shared secret");
    assert_eq!(hex::encode(shared), vector.x25519_shared_secret_hex);
    assert_eq!(sas_indexes(&transcript_hash), Ok(vector.sas_indexes));
    let resolved = sas_words(&transcript_hash, &words).expect("SAS words");
    assert_eq!(resolved, vector.sas_words.each_ref().map(String::as_str));
    assert_eq!(
        hex::encode(Sha256::digest(&word_bytes)),
        vector.wordlist_sha256_hex
    );

    let keys = derive_pairing_keys(&shared, &transcript_hash).expect("key schedule");
    assert_eq!(
        hex::encode(keys.controller_to_host),
        vector.controller_to_host_key_hex
    );
    assert_eq!(
        hex::encode(keys.host_to_controller),
        vector.host_to_controller_key_hex
    );
    let nonce = pairing_nonce(CryptoDirection::ControllerToHost, vector.sequence).expect("nonce");
    let aad = pairing_aad(
        CryptoDirection::ControllerToHost,
        vector.sequence,
        &decode(&vector.rendezvous_id_hex),
        &decode(&vector.controller_device_id_hex),
        &decode(&vector.host_device_id_hex),
    )
    .expect("AAD");
    assert_eq!(hex::encode(nonce), vector.nonce_hex);
    assert_eq!(hex::encode(&aad), vector.aad_hex);
    let plaintext = decode(&vector.plaintext_hex);
    let sealed = seal_pairing_payload(
        &keys.controller_to_host,
        CryptoDirection::ControllerToHost,
        vector.sequence,
        &aad,
        &plaintext,
    )
    .expect("seal");
    assert_eq!(hex::encode(&sealed), vector.ciphertext_and_tag_hex);
    assert_eq!(
        open_pairing_payload(
            &keys.controller_to_host,
            CryptoDirection::ControllerToHost,
            vector.sequence,
            &aad,
            &sealed,
        ),
        Ok(plaintext)
    );
}

#[test]
fn pairing_crypto_v1_rejects_tampered_authenticated_data() {
    let key = [0_u8; 32];
    let sealed = seal_pairing_payload(
        &key,
        CryptoDirection::HostToController,
        1,
        &[1, 2, 3],
        &[4, 5, 6],
    )
    .expect("seal");

    assert_eq!(
        open_pairing_payload(
            &key,
            CryptoDirection::HostToController,
            1,
            &[1, 2, 4],
            &sealed,
        ),
        Err(PairingCryptoError::AuthenticationFailed)
    );

    for index in 0..sealed.len() {
        let mut tampered = sealed.clone();
        tampered[index] ^= 0x01;
        assert_eq!(
            open_pairing_payload(
                &key,
                CryptoDirection::HostToController,
                1,
                &[1, 2, 3],
                &tampered,
            ),
            Err(PairingCryptoError::AuthenticationFailed),
            "tampered ciphertext byte {index}"
        );
    }
}

#[test]
fn pairing_crypto_v1_rejects_duplicate_and_skipped_sequences() {
    let mut validator = PairingSequenceValidator::new();
    assert_eq!(validator.accept(1), Ok(()));
    assert_eq!(
        validator.accept(1),
        Err(PairingCryptoError::InvalidSequence)
    );
    assert_eq!(
        validator.accept(3),
        Err(PairingCryptoError::InvalidSequence)
    );
    assert_eq!(validator.accept(2), Ok(()));
    assert_eq!(validator.next(), 3);
}

#[test]
fn pairing_crypto_v1_covers_word_list_and_size_boundaries() {
    let word_text =
        fs::read_to_string(fixture_path("wordlists/bip39-english.txt")).expect("word list");
    let words: Vec<_> = word_text.lines().collect();

    assert_eq!(
        sas_words(&[0_u8; 32], &words),
        Ok(["abandon", "abandon", "abandon", "abandon"])
    );
    assert_eq!(
        sas_words(&[0xff_u8; 32], &words),
        Ok(["zoo", "zoo", "zoo", "zoo"])
    );
    assert_eq!(
        seal_pairing_payload(
            &[0_u8; 32],
            CryptoDirection::ControllerToHost,
            1,
            &[],
            &vec![0_u8; 65_536],
        ),
        Err(PairingCryptoError::InvalidLength)
    );
}

fn fixture_path(relative: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../conformance")
        .join(relative)
}

fn load_json<T: for<'de> Deserialize<'de>>(relative: &str) -> T {
    let contents = fs::read_to_string(fixture_path(relative)).expect("fixture");
    serde_json::from_str(&contents).expect("valid JSON fixture")
}

fn decode(value: &str) -> Vec<u8> {
    hex::decode(value).expect("hex")
}
