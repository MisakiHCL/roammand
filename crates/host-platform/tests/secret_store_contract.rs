// SPDX-License-Identifier: MPL-2.0

use roammand_host_platform::{MemorySecretStore, ProtectedSecretStore, SecretStoreError};

const SECRET_BYTES: usize = 32;

#[test]
fn memory_store_supports_missing_round_trip_replace_and_delete() {
    let store = MemorySecretStore::new();
    assert!(store.load().expect("missing load must succeed").is_none());

    let first = [0x11; SECRET_BYTES];
    store.store(&first).expect("first store must succeed");
    assert_eq!(
        store
            .load()
            .expect("stored load must succeed")
            .as_ref()
            .map(|secret| secret.as_slice()),
        Some(first.as_slice())
    );

    let second = [0x22; SECRET_BYTES];
    store.store(&second).expect("replacement must succeed");
    assert_eq!(
        store
            .load()
            .expect("replacement load must succeed")
            .as_ref()
            .map(|secret| secret.as_slice()),
        Some(second.as_slice())
    );

    store.delete().expect("delete must succeed");
    store.delete().expect("repeated delete must succeed");
    assert!(store.load().expect("deleted load must succeed").is_none());
}

#[test]
fn memory_store_rejects_secret_lengths_other_than_32_bytes() {
    let store = MemorySecretStore::new();

    for length in [31, 33] {
        assert_eq!(
            store.store(&vec![0; length]),
            Err(SecretStoreError::InvalidSecretLength),
            "length {length}"
        );
    }
}

#[test]
fn loaded_secret_uses_a_zeroizing_buffer() {
    let store = MemorySecretStore::new();
    store
        .store(&[0x44; SECRET_BYTES])
        .expect("store must succeed");

    let loaded = store
        .load()
        .expect("load must succeed")
        .expect("secret must exist");
    let _: &zeroize::Zeroizing<Vec<u8>> = &loaded;
}
