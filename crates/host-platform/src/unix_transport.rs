// SPDX-License-Identifier: MPL-2.0

use std::{
    fs,
    os::unix::fs::{FileTypeExt, MetadataExt, PermissionsExt},
    path::{Path, PathBuf},
};

use nix::unistd::Uid;
use tokio::net::{UnixListener, UnixStream};

use crate::{
    LocalTransportError, atomic_write_private, ensure_private_directory,
    local_transport::{DISCOVERY_FILE_NAME, SOCKET_FILE_NAME, TOKEN_FILE_NAME},
    remove_private_file,
};

const SOCKET_MODE: u32 = 0o600;

pub struct UnixLocalListener {
    listener: UnixListener,
    socket_path: PathBuf,
    token_path: PathBuf,
    discovery_path: PathBuf,
    expected_uid: u32,
}

impl UnixLocalListener {
    /// Binds the Host Agent UDS for the current effective user.
    ///
    /// # Errors
    ///
    /// Returns an error when runtime artifacts cannot be restricted, a stale
    /// endpoint is unsafe, or the socket cannot be bound.
    pub fn bind(
        runtime_dir: &Path,
        instance_id: [u8; 16],
        token: &[u8; 32],
    ) -> Result<Self, LocalTransportError> {
        Self::bind_with_expected_uid(runtime_dir, instance_id, token, Uid::effective().as_raw())
    }

    #[doc(hidden)]
    /// Binds with an injected expected UID for peer-gate tests.
    ///
    /// # Errors
    ///
    /// Returns the same errors as [`Self::bind`].
    pub fn bind_with_expected_uid_for_testing(
        runtime_dir: &Path,
        instance_id: [u8; 16],
        token: &[u8; 32],
        expected_uid: u32,
    ) -> Result<Self, LocalTransportError> {
        Self::bind_with_expected_uid(runtime_dir, instance_id, token, expected_uid)
    }

    #[must_use]
    pub fn socket_path(&self) -> &Path {
        &self.socket_path
    }

    #[must_use]
    pub fn token_path(&self) -> &Path {
        &self.token_path
    }

    #[must_use]
    pub fn discovery_path(&self) -> &Path {
        &self.discovery_path
    }

    /// Accepts a stream only when the peer effective UID matches the Agent.
    ///
    /// # Errors
    ///
    /// Returns an error for socket failures, unavailable credentials, or a
    /// different peer UID. Peer rejection occurs before any protocol bytes are
    /// returned to the caller.
    pub async fn accept(&self) -> Result<UnixStream, LocalTransportError> {
        let (stream, _) = self
            .listener
            .accept()
            .await
            .map_err(|_| LocalTransportError::Io)?;
        let peer_uid = stream
            .peer_cred()
            .map_err(|_| LocalTransportError::Io)?
            .uid();
        if peer_uid != self.expected_uid {
            return Err(LocalTransportError::PeerUserMismatch);
        }
        Ok(stream)
    }

    fn bind_with_expected_uid(
        runtime_dir: &Path,
        instance_id: [u8; 16],
        token: &[u8; 32],
        expected_uid: u32,
    ) -> Result<Self, LocalTransportError> {
        ensure_private_directory(runtime_dir).map_err(|_| LocalTransportError::Io)?;
        let socket_path = runtime_dir.join(SOCKET_FILE_NAME);
        let token_path = runtime_dir.join(TOKEN_FILE_NAME);
        let discovery_path = runtime_dir.join(DISCOVERY_FILE_NAME);
        remove_owned_stale_socket(&socket_path, Uid::effective().as_raw())?;

        let listener = UnixListener::bind(&socket_path).map_err(|_| LocalTransportError::Io)?;
        let setup_result = (|| -> Result<(), LocalTransportError> {
            fs::set_permissions(&socket_path, fs::Permissions::from_mode(SOCKET_MODE))
                .map_err(|_| LocalTransportError::Io)?;
            atomic_write_private(&token_path, token).map_err(|_| LocalTransportError::Io)?;
            let discovery = format!(
                "version=1\ntransport=unix\nendpoint={}\ninstance_id={}\n",
                socket_path.to_string_lossy(),
                hex::encode(instance_id)
            );
            atomic_write_private(&discovery_path, discovery.as_bytes())
                .map_err(|_| LocalTransportError::Io)?;
            Ok(())
        })();
        if let Err(error) = setup_result {
            cleanup_artifacts(&socket_path, &token_path, &discovery_path);
            return Err(error);
        }

        Ok(Self {
            listener,
            socket_path,
            token_path,
            discovery_path,
            expected_uid,
        })
    }
}

impl Drop for UnixLocalListener {
    fn drop(&mut self) {
        cleanup_artifacts(&self.socket_path, &self.token_path, &self.discovery_path);
    }
}

fn remove_owned_stale_socket(path: &Path, current_uid: u32) -> Result<(), LocalTransportError> {
    match fs::symlink_metadata(path) {
        Ok(metadata) if metadata.file_type().is_socket() && metadata.uid() == current_uid => {
            match std::os::unix::net::UnixStream::connect(path) {
                Ok(_) => Err(LocalTransportError::EndpointAlreadyActive),
                Err(error) if error.kind() == std::io::ErrorKind::ConnectionRefused => {
                    fs::remove_file(path).map_err(|_| LocalTransportError::Io)
                }
                Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
                Err(_) => Err(LocalTransportError::Io),
            }
        }
        Ok(_) => Err(LocalTransportError::UnsafeStaleEndpoint),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
        Err(_) => Err(LocalTransportError::Io),
    }
}

fn cleanup_artifacts(socket_path: &Path, token_path: &Path, discovery_path: &Path) {
    let _ = remove_owned_socket(socket_path, Uid::effective().as_raw());
    let _ = remove_private_file(token_path);
    let _ = remove_private_file(discovery_path);
}

fn remove_owned_socket(path: &Path, current_uid: u32) -> Result<(), LocalTransportError> {
    match fs::symlink_metadata(path) {
        Ok(metadata) if metadata.file_type().is_socket() && metadata.uid() == current_uid => {
            fs::remove_file(path).map_err(|_| LocalTransportError::Io)
        }
        Ok(_) => Err(LocalTransportError::UnsafeStaleEndpoint),
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => Ok(()),
        Err(_) => Err(LocalTransportError::Io),
    }
}
