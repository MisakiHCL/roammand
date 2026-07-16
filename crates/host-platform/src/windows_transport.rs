// SPDX-License-Identifier: MPL-2.0

#![allow(unsafe_code)]

use std::{
    os::windows::io::AsRawHandle,
    path::{Path, PathBuf},
};

use sha2::{Digest, Sha256};
use tokio::net::windows::named_pipe::{NamedPipeServer, ServerOptions};

use crate::{
    LocalTransportError, atomic_write_private, ensure_private_directory,
    local_transport::{DISCOVERY_FILE_NAME, TOKEN_FILE_NAME},
    remove_private_file,
    windows_security::{
        CurrentUserSecurityAttributes, current_user_sid_string,
        named_pipe_peer_matches_current_user,
    },
};

const PIPE_PREFIX: &str = r"\\.\pipe\roammand-";
const PIPE_SID_DIGEST_BYTES: usize = 16;

pub struct WindowsLocalListener {
    server: NamedPipeServer,
    pipe_name: String,
    token_path: PathBuf,
    discovery_path: PathBuf,
}

impl WindowsLocalListener {
    /// Binds a current-user-only local Named Pipe and discovery files.
    ///
    /// # Errors
    ///
    /// Returns an error when the current SID, explicit DACL, runtime files, or
    /// first Named Pipe instance cannot be created.
    pub fn bind(
        runtime_dir: &Path,
        instance_id: [u8; 16],
        token: &[u8; 32],
    ) -> Result<Self, LocalTransportError> {
        ensure_private_directory(runtime_dir).map_err(|_| LocalTransportError::Io)?;
        let sid = current_user_sid_string().map_err(|_| LocalTransportError::Io)?;
        let digest = Sha256::digest(sid.as_bytes());
        let pipe_name = format!(
            "{PIPE_PREFIX}{}",
            hex::encode(&digest[..PIPE_SID_DIGEST_BYTES])
        );
        let server = create_server(&pipe_name, true)?;
        let token_path = runtime_dir.join(TOKEN_FILE_NAME);
        let discovery_path = runtime_dir.join(DISCOVERY_FILE_NAME);
        let setup_result = (|| -> Result<(), LocalTransportError> {
            atomic_write_private(&token_path, token).map_err(|_| LocalTransportError::Io)?;
            let discovery = format!(
                "version=1\ntransport=named-pipe\nendpoint={pipe_name}\ninstance_id={}\n",
                hex::encode(instance_id)
            );
            atomic_write_private(&discovery_path, discovery.as_bytes())
                .map_err(|_| LocalTransportError::Io)
        })();
        if let Err(error) = setup_result {
            let _ = remove_private_file(&token_path);
            let _ = remove_private_file(&discovery_path);
            return Err(error);
        }

        Ok(Self {
            server,
            pipe_name,
            token_path,
            discovery_path,
        })
    }

    #[must_use]
    pub fn pipe_name(&self) -> &str {
        &self.pipe_name
    }

    #[must_use]
    pub fn token_path(&self) -> &Path {
        &self.token_path
    }

    #[must_use]
    pub fn discovery_path(&self) -> &Path {
        &self.discovery_path
    }

    /// Accepts a connected pipe only when the impersonated client SID matches.
    ///
    /// # Errors
    ///
    /// Returns an error for connection/peer-verification failures or when the
    /// next protected pipe instance cannot be prepared. SID rejection occurs
    /// before the connected stream is returned.
    pub async fn accept(&mut self) -> Result<NamedPipeServer, LocalTransportError> {
        self.server
            .connect()
            .await
            .map_err(|_| LocalTransportError::Io)?;
        let peer_matches = named_pipe_peer_matches_current_user(self.server.as_raw_handle())
            .map_err(|_| LocalTransportError::Io)?;
        let next = create_server(&self.pipe_name, false)?;
        let connected = std::mem::replace(&mut self.server, next);
        if !peer_matches {
            return Err(LocalTransportError::PeerUserMismatch);
        }
        Ok(connected)
    }
}

impl Drop for WindowsLocalListener {
    fn drop(&mut self) {
        let _ = remove_private_file(&self.token_path);
        let _ = remove_private_file(&self.discovery_path);
    }
}

fn create_server(
    pipe_name: &str,
    first_instance: bool,
) -> Result<NamedPipeServer, LocalTransportError> {
    let mut security = CurrentUserSecurityAttributes::new().map_err(|_| LocalTransportError::Io)?;
    let mut options = ServerOptions::new();
    options
        .first_pipe_instance(first_instance)
        .reject_remote_clients(true);
    // SAFETY: `security` owns an initialized `SECURITY_ATTRIBUTES` and its
    // descriptor through the call. Windows copies the descriptor while
    // creating the pipe handle; neither pointer escapes this function.
    unsafe { options.create_with_security_attributes_raw(pipe_name, security.as_mut_ptr()) }
        .map_err(|_| LocalTransportError::Io)
}
