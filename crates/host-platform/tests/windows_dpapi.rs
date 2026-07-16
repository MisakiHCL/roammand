// SPDX-License-Identifier: MPL-2.0

#![cfg(windows)]

use std::fs;

use roammand_host_platform::{ProtectedSecretStore, SecretStoreError, WindowsDpapiSecretStore};
use tempfile::tempdir;

const SECRET_BYTES: usize = 32;

#[test]
fn current_user_dpapi_round_trips_ciphertext_without_seed_bytes() {
    let temporary = tempdir().expect("temporary directory must be created");
    let path = temporary.path().join("identity.dpapi");
    let store = WindowsDpapiSecretStore::new(path.clone());
    let seed = [0x73; SECRET_BYTES];

    assert!(store.load().expect("missing load must succeed").is_none());
    store.store(&seed).expect("store must succeed");
    let ciphertext = fs::read(&path).expect("ciphertext must be readable");
    assert!(!ciphertext.windows(seed.len()).any(|window| window == seed));
    assert_eq!(
        store
            .load()
            .expect("load must succeed")
            .expect("seed must exist")
            .as_slice(),
        seed
    );

    store.delete().expect("delete must succeed");
    store.delete().expect("repeated delete must succeed");
}

#[test]
fn current_user_dpapi_rejects_tampering_and_wrong_entropy() {
    let temporary = tempdir().expect("temporary directory must be created");
    let path = temporary.path().join("identity.dpapi");
    let store = WindowsDpapiSecretStore::with_entropy_for_testing(
        path.clone(),
        b"roammand-test-entropy-a".to_vec(),
    );
    store
        .store(&[0x25; SECRET_BYTES])
        .expect("store must succeed");

    let wrong_entropy = WindowsDpapiSecretStore::with_entropy_for_testing(
        path.clone(),
        b"roammand-test-entropy-b".to_vec(),
    );
    assert!(matches!(
        wrong_entropy.load(),
        Err(SecretStoreError::Corrupt)
    ));

    let mut ciphertext = fs::read(&path).expect("ciphertext must be readable");
    let last = ciphertext.last_mut().expect("ciphertext must not be empty");
    *last ^= 0x80;
    fs::write(&path, ciphertext).expect("ciphertext must be overwritten");
    assert!(matches!(store.load(), Err(SecretStoreError::Corrupt)));
}

#[test]
fn current_user_dpapi_rejects_invalid_secret_lengths() {
    let temporary = tempdir().expect("temporary directory must be created");
    let store = WindowsDpapiSecretStore::new(temporary.path().join("identity.dpapi"));

    for length in [31, 33] {
        assert_eq!(
            store.store(&vec![0; length]),
            Err(SecretStoreError::InvalidSecretLength)
        );
    }
}
