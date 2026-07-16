// SPDX-License-Identifier: MPL-2.0

#![cfg(unix)]

use std::{fs, os::unix::fs::symlink, path::Path};

use roammand_privileged_bridge::installed::{
    InstalledBridgeConfig, installed_file_sha256, read_windows_owner_sid,
};
use tempfile::TempDir;

#[test]
fn loads_only_exact_secret_owner_and_installed_regular_file() {
    let temporary = TempDir::new().expect("temp");
    let secret_path = temporary.path().join("secret.bin");
    let owner_path = temporary.path().join("owner-id");
    let executable_path = temporary.path().join("component");
    fs::write(&secret_path, [0x41; 32]).expect("secret");
    fs::write(&owner_path, b"501\n").expect("owner");
    fs::write(&executable_path, b"installed component").expect("component");

    let config = InstalledBridgeConfig::load(&secret_path, &owner_path).expect("config");
    assert_eq!(config.token(), [0x41; 32]);
    assert_eq!(config.owner_os_session_id(), 501);
    assert_ne!(
        installed_file_sha256(&executable_path).expect("hash"),
        [0; 32]
    );

    for invalid_secret in [Vec::new(), vec![0x41; 31], vec![0x41; 33], vec![0; 32]] {
        fs::write(&secret_path, invalid_secret).expect("invalid secret");
        assert!(InstalledBridgeConfig::load(&secret_path, &owner_path).is_err());
    }
    fs::write(&secret_path, [0x41; 32]).expect("restore secret");
    for invalid_owner in [b"".as_slice(), b"0", b" 501", b"501x", b"4294967296"] {
        fs::write(&owner_path, invalid_owner).expect("invalid owner");
        assert!(InstalledBridgeConfig::load(&secret_path, &owner_path).is_err());
    }
}

#[test]
fn rejects_relative_symlink_directory_and_oversized_installed_files() {
    let temporary = TempDir::new().expect("temp");
    let target = temporary.path().join("target");
    let link = temporary.path().join("link");
    fs::write(&target, b"component").expect("target");
    symlink(&target, &link).expect("link");

    assert!(installed_file_sha256(Path::new("relative")).is_err());
    assert!(installed_file_sha256(&link).is_err());
    assert!(installed_file_sha256(temporary.path()).is_err());

    let oversized = temporary.path().join("oversized");
    let file = fs::File::create(&oversized).expect("oversized file");
    file.set_len(256 * 1024 * 1024 + 1)
        .expect("oversized length");
    assert!(installed_file_sha256(&oversized).is_err());
}

#[test]
fn debug_and_errors_do_not_reveal_install_values() {
    let temporary = TempDir::new().expect("temp");
    let secret_path = temporary.path().join("secret.bin");
    let owner_path = temporary.path().join("owner-id");
    fs::write(&secret_path, [0x41; 32]).expect("secret");
    fs::write(&owner_path, b"501\n").expect("owner");
    let config = InstalledBridgeConfig::load(&secret_path, &owner_path).expect("config");

    let debug = format!("{config:?}");
    assert!(!debug.contains("501"));
    assert!(!debug.contains("414141"));
    assert_eq!(debug, "InstalledBridgeConfig([REDACTED])");
}

#[test]
fn windows_owner_sid_has_an_exact_noninjectable_shape() {
    let temporary = TempDir::new().expect("temp");
    let path = temporary.path().join("owner-sid.txt");
    fs::write(&path, b"S-1-5-21-100-200-300-1001\n").expect("SID");
    assert_eq!(
        read_windows_owner_sid(&path).expect("owner SID"),
        "S-1-5-21-100-200-300-1001"
    );
    for invalid in [
        b"".as_slice(),
        b"S-1-5-21;GA;;;WD",
        b"s-1-5-21",
        b"S-1-5-21\nextra",
    ] {
        fs::write(&path, invalid).expect("invalid SID");
        assert!(read_windows_owner_sid(&path).is_err());
    }
}
