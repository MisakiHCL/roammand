// SPDX-License-Identifier: MPL-2.0

#![cfg(target_os = "macos")]

use std::time::{SystemTime, UNIX_EPOCH};

use roammand_host_platform::{MacOsKeychainSecretStore, ProtectedSecretStore, SecretStoreError};

const SECRET_BYTES: usize = 32;

#[test]
fn keychain_supports_missing_round_trip_replace_and_delete() {
    let store = temporary_store();
    store.delete().expect("test item cleanup must succeed");
    assert!(store.load().expect("missing load must succeed").is_none());

    let first = [0x51; SECRET_BYTES];
    store.store(&first).expect("first store must succeed");
    assert_eq!(
        store
            .load()
            .expect("first load must succeed")
            .expect("first secret must exist")
            .as_slice(),
        first
    );

    let second = [0x62; SECRET_BYTES];
    store.store(&second).expect("replacement must succeed");
    assert_eq!(
        store
            .load()
            .expect("replacement load must succeed")
            .expect("replacement secret must exist")
            .as_slice(),
        second
    );

    store.delete().expect("delete must succeed");
    store.delete().expect("repeated delete must succeed");
    assert!(store.load().expect("deleted load must succeed").is_none());
}

#[test]
fn keychain_rejects_invalid_secret_lengths_before_platform_access() {
    let store = temporary_store();
    for length in [31, 33] {
        assert_eq!(
            store.store(&vec![0; length]),
            Err(SecretStoreError::InvalidSecretLength)
        );
    }
}

fn temporary_store() -> MacOsKeychainSecretStore {
    let unique = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("system clock must follow Unix epoch")
        .as_nanos();
    MacOsKeychainSecretStore::new(format!("m3-live-test-{}-{unique}", std::process::id()))
}
