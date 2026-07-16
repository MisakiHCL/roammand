// SPDX-License-Identifier: Apache-2.0

use std::{collections::HashMap, fs, path::PathBuf};

use proptest::prelude::*;
use roammand_protocol::canonical_transcript::{
    CanonicalTranscript, TranscriptField, TranscriptPurpose, decode, encode, sha256,
};
use serde::Deserialize;

#[derive(Deserialize)]
struct GoldenFixture {
    values: HashMap<String, String>,
    cases: Vec<GoldenCase>,
}

#[derive(Deserialize)]
struct GoldenCase {
    name: String,
    purpose: u16,
    tags: Vec<u16>,
    expected_transcript_hex: String,
    expected_sha256_hex: String,
}

#[derive(Deserialize)]
struct InvalidFixture {
    cases: Vec<InvalidCase>,
}

#[derive(Deserialize)]
struct InvalidCase {
    name: String,
    expected_error: String,
    transcript_hex: Option<String>,
    repeat_hex: Option<String>,
    repeat_count: Option<usize>,
}

#[test]
fn all_canonical_transcript_v1_golden_cases_match() {
    let fixture: GoldenFixture = load_fixture("canonical_transcript_v1.json");

    for vector in fixture.cases {
        let transcript = CanonicalTranscript {
            purpose: TranscriptPurpose::try_from(vector.purpose)
                .expect("fixture purpose must be valid"),
            fields: vector
                .tags
                .iter()
                .map(|tag| TranscriptField {
                    tag: *tag,
                    value: hex::decode(&fixture.values[&tag.to_string()])
                        .expect("fixture value must be hex"),
                })
                .collect(),
        };

        let encoded = encode(&transcript).expect("golden transcript must encode");
        assert_eq!(
            hex::encode(&encoded),
            vector.expected_transcript_hex,
            "{} transcript bytes",
            vector.name
        );
        assert_eq!(
            hex::encode(sha256(&encoded)),
            vector.expected_sha256_hex,
            "{} SHA-256",
            vector.name
        );
        assert_eq!(
            decode(&encoded).expect("golden transcript must decode"),
            transcript,
            "{} round trip",
            vector.name
        );
    }
}

#[test]
fn all_invalid_canonical_transcript_v1_cases_return_stable_errors() {
    let fixture: InvalidFixture = load_fixture("canonical_transcript_v1_invalid.json");

    for vector in fixture.cases {
        let bytes = invalid_bytes(&vector);
        let error = decode(&bytes).expect_err("invalid transcript must be rejected");
        assert_eq!(error.wire_name(), vector.expected_error, "{}", vector.name);
    }
}

proptest! {
    #[test]
    fn non_increasing_adjacent_tags_never_decode(
        tag_index in 1_usize..7,
        duplicate in any::<bool>(),
    ) {
        const TAG_OFFSETS: [usize; 7] = [10, 48, 86, 108, 146, 184, 222];
        let fixture: GoldenFixture = load_fixture("canonical_transcript_v1.json");
        let pairing = fixture
            .cases
            .iter()
            .find(|vector| vector.name == "pairing_sas")
            .expect("pairing fixture must exist");
        let mut encoded = hex::decode(&pairing.expected_transcript_hex)
            .expect("pairing transcript must be hex");
        let previous_offset = TAG_OFFSETS[tag_index - 1];
        let previous_tag = u16::from_be_bytes([
            encoded[previous_offset],
            encoded[previous_offset + 1],
        ]);
        let mutated_tag = if duplicate {
            previous_tag
        } else {
            previous_tag.saturating_sub(1)
        };
        let offset = TAG_OFFSETS[tag_index];
        encoded[offset..offset + 2].copy_from_slice(&mutated_tag.to_be_bytes());

        let error = decode(&encoded).expect_err("non-increasing tags must be rejected");
        prop_assert!(matches!(
            error,
            roammand_protocol::canonical_transcript::TranscriptError::DuplicateField
                | roammand_protocol::canonical_transcript::TranscriptError::FieldOrder
        ));
    }
}

fn load_fixture<T: for<'de> Deserialize<'de>>(name: &str) -> T {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../conformance/protocol_vectors")
        .join(name);
    let contents = fs::read_to_string(path).expect("fixture must be readable");
    serde_json::from_str(&contents).expect("fixture must be valid JSON")
}

fn invalid_bytes(vector: &InvalidCase) -> Vec<u8> {
    if let Some(value) = &vector.transcript_hex {
        return hex::decode(value).expect("fixture transcript must be hex");
    }

    let repeated = hex::decode(
        vector
            .repeat_hex
            .as_ref()
            .expect("repeat fixture must include repeat_hex"),
    )
    .expect("repeat fixture must be hex");
    repeated.repeat(
        vector
            .repeat_count
            .expect("repeat fixture must include repeat_count"),
    )
}
