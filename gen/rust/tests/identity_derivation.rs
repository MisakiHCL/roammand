// SPDX-License-Identifier: Apache-2.0

use std::{fs, path::PathBuf};

use roammand_protocol::identity_derivation::{IdentityDerivationError, derive_device_id_v1};
use serde::Deserialize;

#[derive(Deserialize)]
struct GoldenFixture {
    cases: Vec<GoldenCase>,
}

#[derive(Deserialize)]
struct GoldenCase {
    name: String,
    public_key_hex: String,
    expected_device_id_hex: String,
}

#[test]
fn identity_derivation_v1_matches_every_golden_vector() {
    let fixture: GoldenFixture = load_fixture();

    for vector in fixture.cases {
        let public_key = hex::decode(vector.public_key_hex).expect("public key must be hex");
        let device_id = derive_device_id_v1(&public_key).expect("golden key must be valid");
        assert_eq!(
            hex::encode(device_id),
            vector.expected_device_id_hex,
            "{}",
            vector.name
        );
    }
}

#[test]
fn identity_derivation_v1_rejects_non_ed25519_key_lengths() {
    assert_eq!(
        derive_device_id_v1(&[0; 31]),
        Err(IdentityDerivationError::InvalidPublicKeyLength)
    );
    assert_eq!(
        derive_device_id_v1(&[0; 33]),
        Err(IdentityDerivationError::InvalidPublicKeyLength)
    );
}

fn load_fixture() -> GoldenFixture {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../../conformance/protocol_vectors/identity_derivation_v1.json");
    let contents = fs::read_to_string(path).expect("fixture must be readable");
    serde_json::from_str(&contents).expect("fixture must be valid JSON")
}
