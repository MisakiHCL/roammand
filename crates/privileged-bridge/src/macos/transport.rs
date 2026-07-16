// SPDX-License-Identifier: MPL-2.0

use std::collections::BTreeMap;
#[cfg(target_family = "unix")]
use std::{fmt, path::PathBuf};

use super::TrustError;

const MAX_MANIFEST_BYTES: usize = 4_096;
const MANIFEST_VERSION: &str = "1";
const HOST_HASH_KEY: &str = "host_agent_sha256";
const SESSION_HASH_KEY: &str = "session_agent_sha256";

#[derive(Clone, Eq, PartialEq)]
pub struct InstallManifest {
    host_agent_sha256: [u8; 32],
    session_agent_sha256: [u8; 32],
}

impl InstallManifest {
    /// Parses the exact, bounded installed-component hash manifest.
    ///
    /// # Errors
    ///
    /// Rejects unknown versions/keys, duplicates, missing fields, invalid UTF-8,
    /// malformed hashes, and oversized input.
    pub fn parse(encoded: &[u8]) -> Result<Self, TrustError> {
        if encoded.is_empty() || encoded.len() > MAX_MANIFEST_BYTES {
            return Err(TrustError::ManifestRejected);
        }
        let text = std::str::from_utf8(encoded).map_err(|_| TrustError::ManifestRejected)?;
        let mut values = BTreeMap::new();
        for line in text.lines() {
            let (key, value) = line.split_once('=').ok_or(TrustError::ManifestRejected)?;
            if !matches!(key, "version" | HOST_HASH_KEY | SESSION_HASH_KEY)
                || values.insert(key, value).is_some()
            {
                return Err(TrustError::ManifestRejected);
            }
        }
        if values.get("version") != Some(&MANIFEST_VERSION) || values.len() != 3 {
            return Err(TrustError::ManifestRejected);
        }
        Ok(Self {
            host_agent_sha256: decode_sha256(
                values
                    .get(HOST_HASH_KEY)
                    .ok_or(TrustError::ManifestRejected)?,
            )?,
            session_agent_sha256: decode_sha256(
                values
                    .get(SESSION_HASH_KEY)
                    .ok_or(TrustError::ManifestRejected)?,
            )?,
        })
    }

    #[must_use]
    pub const fn host_agent_sha256(&self) -> [u8; 32] {
        self.host_agent_sha256
    }

    #[must_use]
    pub const fn session_agent_sha256(&self) -> [u8; 32] {
        self.session_agent_sha256
    }
}

fn decode_sha256(value: &str) -> Result<[u8; 32], TrustError> {
    if value.len() != 64 {
        return Err(TrustError::ManifestRejected);
    }
    let mut output = [0_u8; 32];
    for (index, pair) in value.as_bytes().chunks_exact(2).enumerate() {
        let high = decode_hex_nibble(pair[0]).ok_or(TrustError::ManifestRejected)?;
        let low = decode_hex_nibble(pair[1]).ok_or(TrustError::ManifestRejected)?;
        output[index] = (high << 4) | low;
    }
    Ok(output)
}

const fn decode_hex_nibble(value: u8) -> Option<u8> {
    match value {
        b'0'..=b'9' => Some(value - b'0'),
        b'a'..=b'f' => Some(value - b'a' + 10),
        _ => None,
    }
}

#[derive(Clone, Eq, PartialEq)]
#[cfg(target_family = "unix")]
pub struct SecureSocketConfig {
    pub socket_path: PathBuf,
    pub expected_parent_owner: u32,
}

#[cfg(target_family = "unix")]
impl fmt::Debug for SecureSocketConfig {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("SecureSocketConfig")
            .field("socket_path", &"[REDACTED]")
            .field("expected_parent_owner", &"[REDACTED]")
            .finish()
    }
}

#[cfg(target_family = "unix")]
mod unix {
    use std::{
        fmt, fs,
        os::unix::{
            fs::{FileTypeExt, MetadataExt, PermissionsExt},
            net::UnixListener,
        },
    };

    use super::{SecureSocketConfig, TrustError};

    pub struct MacSecureSocket {
        listener: UnixListener,
    }

    impl MacSecureSocket {
        #[must_use]
        pub const fn listener(&self) -> &UnixListener {
            &self.listener
        }
    }

    impl fmt::Debug for MacSecureSocket {
        fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
            formatter.write_str("MacSecureSocket([REDACTED])")
        }
    }

    /// Binds a local-only Unix socket under an owner-fixed, non-writable parent.
    ///
    /// # Errors
    ///
    /// Rejects relative/symlink/existing paths, owner or mode mismatch, and I/O
    /// failures before accepting any client.
    pub fn bind_secure_socket(config: &SecureSocketConfig) -> Result<MacSecureSocket, TrustError> {
        if !config.socket_path.is_absolute() {
            return Err(TrustError::PathRejected);
        }
        if let Ok(metadata) = fs::symlink_metadata(&config.socket_path) {
            if metadata.file_type().is_symlink() {
                return Err(TrustError::SymlinkRejected);
            }
            return Err(TrustError::PathRejected);
        }
        let parent = config
            .socket_path
            .parent()
            .ok_or(TrustError::PathRejected)?;
        let metadata =
            fs::symlink_metadata(parent).map_err(|_| TrustError::TransportUnavailable)?;
        if metadata.file_type().is_symlink() {
            return Err(TrustError::SymlinkRejected);
        }
        if metadata.uid() != config.expected_parent_owner {
            return Err(TrustError::OwnerRejected);
        }
        if metadata.mode() & 0o022 != 0 {
            return Err(TrustError::MutableParent);
        }
        let listener = UnixListener::bind(&config.socket_path)
            .map_err(|_| TrustError::TransportUnavailable)?;
        fs::set_permissions(&config.socket_path, fs::Permissions::from_mode(0o600))
            .map_err(|_| TrustError::TransportUnavailable)?;
        let socket_metadata =
            fs::metadata(&config.socket_path).map_err(|_| TrustError::TransportUnavailable)?;
        if !socket_metadata.file_type().is_socket()
            || socket_metadata.uid() != config.expected_parent_owner
            || socket_metadata.mode() & 0o777 != 0o600
        {
            return Err(TrustError::PathRejected);
        }
        listener
            .set_nonblocking(true)
            .map_err(|_| TrustError::TransportUnavailable)?;
        Ok(MacSecureSocket { listener })
    }

    pub use MacSecureSocket as Socket;
}

#[cfg(target_family = "unix")]
pub use unix::{Socket as MacSecureSocket, bind_secure_socket};
