// SPDX-License-Identifier: MPL-2.0

#![allow(unsafe_code)]

use std::{
    ffi::OsString,
    os::unix::{ffi::OsStringExt, net::UnixStream},
    path::PathBuf,
};

use nix::{
    sys::socket::{getsockopt, sockopt::LocalPeerPid},
    unistd::getpeereid,
};

use crate::{
    installed::installed_file_sha256,
    transport::{TransportError, TransportPeerIdentity},
};

const PROCESS_PATH_BYTES: usize = 4_096;

pub fn macos_peer_identity(stream: &UnixStream) -> Result<TransportPeerIdentity, TransportError> {
    let process_id = getsockopt(stream, LocalPeerPid).map_err(|_| TransportError::FailedClosed)?;
    let process_id = u32::try_from(process_id).map_err(|_| TransportError::FailedClosed)?;
    let (uid, _) = getpeereid(stream).map_err(|_| TransportError::FailedClosed)?;
    if process_id == 0 {
        return Err(TransportError::FailedClosed);
    }
    let mut path = vec![0_u8; PROCESS_PATH_BYTES];
    // SAFETY: the PID came from LOCAL_PEERPID and the buffer is writable for
    // exactly the declared size.
    let length = unsafe {
        libc::proc_pidpath(
            i32::try_from(process_id).map_err(|_| TransportError::FailedClosed)?,
            path.as_mut_ptr().cast(),
            u32::try_from(path.len()).map_err(|_| TransportError::FailedClosed)?,
        )
    };
    let length = usize::try_from(length).map_err(|_| TransportError::FailedClosed)?;
    if length == 0 || length > path.len() {
        return Err(TransportError::FailedClosed);
    }
    path.truncate(length);
    if path.last() == Some(&0) {
        path.pop();
    }
    let executable = PathBuf::from(OsString::from_vec(path));
    Ok(TransportPeerIdentity {
        process_id,
        os_session_id: 0,
        unix_uid: Some(uid.as_raw()),
        executable_sha256: installed_file_sha256(&executable)
            .map_err(|_| TransportError::FailedClosed)?,
    })
}
