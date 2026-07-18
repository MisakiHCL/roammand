// SPDX-License-Identifier: MPL-2.0

use std::{fmt, fs, io::Read, path::Path};

use sha2::{Digest, Sha256};
use thiserror::Error;

const INSTALL_SECRET_BYTES: usize = 32;
const MAX_OWNER_ID_BYTES: u64 = 11;
const MAX_WINDOWS_SID_BYTES: u64 = 184;
const MAX_INSTALLED_COMPONENT_BYTES: u64 = 256 * 1024 * 1024;
const HASH_BUFFER_BYTES: usize = 16 * 1024;

pub const MACOS_BRIDGE_SOCKET_PATH: &str = "/var/run/roammand/bridge.sock";
pub const MACOS_INSTALL_SECRET_PATH: &str =
    "/Library/Application Support/Roammand/bridge-install-secret.bin";
pub const MACOS_OWNER_ID_PATH: &str = "/Library/Application Support/Roammand/bridge-owner-id";
pub const MACOS_HOST_AGENT_PATH: &str = "/Library/PrivilegedHelperTools/roammand-host-agent";
pub const MACOS_SESSION_AGENT_PATH: &str = "/Applications/Roammand.app/Contents/Library/LoginItems/\
RoammandSessionAgent.app/Contents/MacOS/roammand-session-agent";
pub const WINDOWS_INSTALL_SECRET_PATH: &str = r"C:\ProgramData\Roammand\bridge-install-secret.bin";
pub const WINDOWS_OWNER_SID_PATH: &str = r"C:\ProgramData\Roammand\bridge-owner-sid.txt";
pub const WINDOWS_HOST_AGENT_PATH: &str = r"C:\Program Files\Roammand\roammand-host-agent.exe";
pub const WINDOWS_SESSION_HELPER_PATH: &str =
    r"C:\Program Files\Roammand\roammand-session-helper.exe";

#[derive(Clone, Copy, Eq, PartialEq)]
pub struct InstalledBridgeConfig {
    token: [u8; INSTALL_SECRET_BYTES],
    owner_os_session_id: u64,
}

impl InstalledBridgeConfig {
    /// Loads the exact installed secret and owner identifier files.
    ///
    /// # Errors
    ///
    /// Rejects relative, symbolic-link, non-regular, malformed, empty, or
    /// over-limit installation data.
    pub fn load(secret_path: &Path, owner_path: &Path) -> Result<Self, InstalledConfigError> {
        let token = read_install_secret(secret_path)?;
        let owner = read_bounded_regular_file(owner_path, MAX_OWNER_ID_BYTES)?;
        let owner = std::str::from_utf8(&owner).map_err(|_| InstalledConfigError::Rejected)?;
        let owner = owner.strip_suffix('\n').unwrap_or(owner);
        if owner.is_empty() || !owner.bytes().all(|value| value.is_ascii_digit()) {
            return Err(InstalledConfigError::Rejected);
        }
        let owner = owner
            .parse::<u32>()
            .map_err(|_| InstalledConfigError::Rejected)?;
        if token == [0; INSTALL_SECRET_BYTES] || owner == 0 {
            return Err(InstalledConfigError::Rejected);
        }
        Ok(Self {
            token,
            owner_os_session_id: u64::from(owner),
        })
    }

    #[must_use]
    pub const fn token(self) -> [u8; INSTALL_SECRET_BYTES] {
        self.token
    }

    #[must_use]
    pub const fn owner_os_session_id(self) -> u64 {
        self.owner_os_session_id
    }
}

/// Loads the exact nonzero 32-byte installation secret.
///
/// # Errors
///
/// Rejects relative, symbolic-link, non-regular, missing, malformed, or zero data.
pub fn read_install_secret(
    path: &Path,
) -> Result<[u8; INSTALL_SECRET_BYTES], InstalledConfigError> {
    let secret = read_bounded_regular_file(path, INSTALL_SECRET_BYTES as u64)?;
    let token: [u8; INSTALL_SECRET_BYTES] = secret
        .try_into()
        .map_err(|_| InstalledConfigError::Rejected)?;
    if token == [0; INSTALL_SECRET_BYTES] {
        return Err(InstalledConfigError::Rejected);
    }
    Ok(token)
}

/// Loads one exact installed Windows owner SID.
///
/// # Errors
///
/// Rejects malformed, over-limit, relative, symbolic-link, or missing data.
pub fn read_windows_owner_sid(path: &Path) -> Result<String, InstalledConfigError> {
    let encoded = read_bounded_regular_file(path, MAX_WINDOWS_SID_BYTES)?;
    let value = std::str::from_utf8(&encoded).map_err(|_| InstalledConfigError::Rejected)?;
    let value = value.strip_suffix('\n').unwrap_or(value);
    if value.len() < 5
        || !value.starts_with("S-1-")
        || !value
            .bytes()
            .all(|character| character.is_ascii_digit() || matches!(character, b'-' | b'S'))
    {
        return Err(InstalledConfigError::Rejected);
    }
    Ok(value.to_owned())
}

impl fmt::Debug for InstalledBridgeConfig {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str("InstalledBridgeConfig([REDACTED])")
    }
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum InstalledConfigError {
    #[error("installed bridge configuration was rejected")]
    Rejected,
}

/// Hashes one bounded, absolute, non-symbolic-link installed component.
///
/// # Errors
///
/// Rejects relative, symbolic-link, non-regular, empty, or oversized files and
/// any read failure.
pub fn installed_file_sha256(path: &Path) -> Result<[u8; 32], InstalledConfigError> {
    let metadata = checked_regular_file(path, MAX_INSTALLED_COMPONENT_BYTES)?;
    if metadata.len() == 0 {
        return Err(InstalledConfigError::Rejected);
    }
    let mut file = fs::File::open(path).map_err(|_| InstalledConfigError::Rejected)?;
    let mut hasher = Sha256::new();
    let mut buffer = [0_u8; HASH_BUFFER_BYTES];
    let mut read_bytes = 0_u64;
    loop {
        let read = file
            .read(&mut buffer)
            .map_err(|_| InstalledConfigError::Rejected)?;
        if read == 0 {
            break;
        }
        read_bytes = read_bytes
            .checked_add(u64::try_from(read).map_err(|_| InstalledConfigError::Rejected)?)
            .ok_or(InstalledConfigError::Rejected)?;
        if read_bytes > metadata.len() || read_bytes > MAX_INSTALLED_COMPONENT_BYTES {
            return Err(InstalledConfigError::Rejected);
        }
        hasher.update(&buffer[..read]);
    }
    if read_bytes != metadata.len() {
        return Err(InstalledConfigError::Rejected);
    }
    Ok(hasher.finalize().into())
}

fn read_bounded_regular_file(
    path: &Path,
    maximum_bytes: u64,
) -> Result<Vec<u8>, InstalledConfigError> {
    let metadata = checked_regular_file(path, maximum_bytes)?;
    let capacity = usize::try_from(metadata.len()).map_err(|_| InstalledConfigError::Rejected)?;
    let file = fs::File::open(path).map_err(|_| InstalledConfigError::Rejected)?;
    let mut output = Vec::with_capacity(capacity);
    file.take(maximum_bytes.saturating_add(1))
        .read_to_end(&mut output)
        .map_err(|_| InstalledConfigError::Rejected)?;
    if output.len() != capacity {
        return Err(InstalledConfigError::Rejected);
    }
    Ok(output)
}

fn checked_regular_file(
    path: &Path,
    maximum_bytes: u64,
) -> Result<fs::Metadata, InstalledConfigError> {
    if !path.is_absolute() || maximum_bytes == 0 {
        return Err(InstalledConfigError::Rejected);
    }
    let metadata = fs::symlink_metadata(path).map_err(|_| InstalledConfigError::Rejected)?;
    if !metadata.is_file() || metadata.file_type().is_symlink() || metadata.len() > maximum_bytes {
        return Err(InstalledConfigError::Rejected);
    }
    Ok(metadata)
}
