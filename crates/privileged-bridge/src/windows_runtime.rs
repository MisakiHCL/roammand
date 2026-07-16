// SPDX-License-Identifier: MPL-2.0

#![allow(unsafe_code)]

use std::{
    collections::VecDeque,
    ffi::{OsStr, c_void},
    fs::{File, OpenOptions},
    io::{ErrorKind, Read, Write},
    os::windows::{
        ffi::OsStrExt,
        io::{AsRawHandle, FromRawHandle},
    },
    path::PathBuf,
    ptr,
    time::{Duration, Instant},
};

use windows_sys::Win32::{
    Foundation::{
        CloseHandle, ERROR_BROKEN_PIPE, ERROR_NO_DATA, ERROR_PIPE_CONNECTED, ERROR_PIPE_LISTENING,
        HANDLE, INVALID_HANDLE_VALUE, LocalFree,
    },
    Security::{
        Authorization::{ConvertStringSecurityDescriptorToSecurityDescriptorW, SDDL_REVISION_1},
        PSECURITY_DESCRIPTOR, SECURITY_ATTRIBUTES,
    },
    Storage::FileSystem::PIPE_ACCESS_DUPLEX,
    System::{
        Pipes::{
            ConnectNamedPipe, CreateNamedPipeW, GetNamedPipeClientProcessId,
            GetNamedPipeClientSessionId, PIPE_NOWAIT, PIPE_READMODE_BYTE,
            PIPE_REJECT_REMOTE_CLIENTS, PIPE_TYPE_BYTE, PIPE_WAIT, PeekNamedPipe,
            SetNamedPipeHandleState, WaitNamedPipeW,
        },
        RemoteDesktop::ProcessIdToSessionId,
        Threading::{
            GetCurrentProcessId, OpenProcess, PROCESS_QUERY_LIMITED_INFORMATION,
            QueryFullProcessImageNameW,
        },
    },
};

use crate::{
    client::BridgeTransportConnector,
    framing::{BridgeFrameDecoder, encode_bridge_frame},
    installed::installed_file_sha256,
    proxy::ProxyError,
    transport::{LocalBridgeTransport, TransportError, TransportPeerIdentity},
    windows::BRIDGE_PIPE_NAME,
};

const PIPE_BUFFER_BYTES: u32 = 256 * 1024;
const READ_BUFFER_BYTES: usize = 16 * 1024;
const MAX_IMAGE_PATH_UTF16: usize = 32_768;

/// Returns the nonzero Windows session containing the current process.
///
/// # Errors
///
/// Fails when Windows does not return a routable session identifier.
pub fn current_process_session_id() -> Result<u64, TransportError> {
    let mut session_id = 0_u32;
    // SAFETY: the current process identifier is valid and the output pointer
    // refers to initialized writable storage.
    if unsafe { ProcessIdToSessionId(GetCurrentProcessId(), &raw mut session_id) } == 0
        || session_id == 0
    {
        return Err(TransportError::FailedClosed);
    }
    Ok(u64::from(session_id))
}

pub struct WindowsPipeListener {
    pipe: File,
    owner_sid: String,
    owner_session_id: u64,
    timeout: Duration,
}

impl WindowsPipeListener {
    /// Creates a local-only pipe restricted to `LocalSystem` and the installed owner SID.
    ///
    /// # Errors
    ///
    /// Rejects malformed owner evidence, zero sessions/timeouts, or Win32 setup failures.
    pub fn new(
        owner_sid: String,
        owner_session_id: u64,
        timeout: Duration,
    ) -> Result<Self, TransportError> {
        if !valid_sid_text(&owner_sid) || owner_session_id == 0 || timeout.is_zero() {
            return Err(TransportError::FailedClosed);
        }
        let pipe = create_server(&owner_sid)?;
        Ok(Self {
            pipe,
            owner_sid,
            owner_session_id,
            timeout,
        })
    }

    /// Polls one connection and returns only a session-bound process-identified peer.
    ///
    /// # Errors
    ///
    /// Fails closed for pipe, process, session, or executable evidence failures.
    pub fn try_accept(&mut self) -> Result<Option<Box<dyn LocalBridgeTransport>>, TransportError> {
        let handle = self.pipe.as_raw_handle();
        // SAFETY: the handle owns one server pipe instance and no OVERLAPPED
        // operation is used in nonblocking mode.
        let connected = unsafe { ConnectNamedPipe(handle, ptr::null_mut()) };
        if connected == 0 {
            let code = std::io::Error::last_os_error()
                .raw_os_error()
                .unwrap_or_default()
                .cast_unsigned();
            if matches!(code, ERROR_PIPE_LISTENING | ERROR_NO_DATA) {
                return Ok(None);
            }
            if code != ERROR_PIPE_CONNECTED {
                return Err(TransportError::FailedClosed);
            }
        }
        let mut wait_mode = PIPE_READMODE_BYTE | PIPE_WAIT;
        // SAFETY: the connected pipe handle is valid and the mode pointer lives through the call.
        if unsafe { SetNamedPipeHandleState(handle, &raw mut wait_mode, ptr::null(), ptr::null()) }
            == 0
        {
            return Err(TransportError::FailedClosed);
        }
        let identity = peer_identity(handle)?;
        if identity.os_session_id != self.owner_session_id {
            return Err(TransportError::FailedClosed);
        }
        let next = create_server(&self.owner_sid)?;
        let connected = std::mem::replace(&mut self.pipe, next);
        Ok(Some(Box::new(WindowsPipeTransport::from_file(
            connected,
            self.timeout,
            Some(identity),
        )?)))
    }
}

pub struct WindowsPipeTransport {
    file: Option<File>,
    decoder: BridgeFrameDecoder,
    ready: VecDeque<Vec<u8>>,
    timeout: Duration,
    peer: Option<TransportPeerIdentity>,
    failed: bool,
}

impl WindowsPipeTransport {
    /// Opens the fixed local bridge pipe as a bounded client transport.
    ///
    /// # Errors
    ///
    /// Returns a stable transport error on timeout or open failure.
    pub fn connect(timeout: Duration) -> Result<Self, TransportError> {
        if timeout.is_zero() {
            return Err(TransportError::FailedClosed);
        }
        let name = wide_null(OsStr::new(BRIDGE_PIPE_NAME));
        let milliseconds = u32::try_from(timeout.as_millis()).unwrap_or(u32::MAX);
        // SAFETY: the pipe name is NUL-terminated and lives through the call.
        if unsafe { WaitNamedPipeW(name.as_ptr(), milliseconds) } == 0 {
            return Err(TransportError::Disconnected);
        }
        let file = OpenOptions::new()
            .read(true)
            .write(true)
            .open(BRIDGE_PIPE_NAME)
            .map_err(|_| TransportError::Disconnected)?;
        Self::from_file(file, timeout, None)
    }

    fn from_file(
        file: File,
        timeout: Duration,
        peer: Option<TransportPeerIdentity>,
    ) -> Result<Self, TransportError> {
        if timeout.is_zero() {
            return Err(TransportError::FailedClosed);
        }
        Ok(Self {
            file: Some(file),
            decoder: BridgeFrameDecoder::new(),
            ready: VecDeque::new(),
            timeout,
            peer,
            failed: false,
        })
    }

    fn read_available(&mut self) -> Result<(), TransportError> {
        let available = self.available_bytes()?;
        if available == 0 {
            return Ok(());
        }
        let read_bytes = available.min(READ_BUFFER_BYTES);
        let mut buffer = [0_u8; READ_BUFFER_BYTES];
        let read = self
            .file
            .as_mut()
            .ok_or(TransportError::FailedClosed)?
            .read(&mut buffer[..read_bytes])
            .map_err(|error| map_io_error(&error))?;
        if read == 0 {
            return Err(TransportError::Disconnected);
        }
        self.ready.extend(
            self.decoder
                .push(&buffer[..read])
                .map_err(|_| TransportError::FailedClosed)?,
        );
        Ok(())
    }

    fn available_bytes(&self) -> Result<usize, TransportError> {
        let file = self.file.as_ref().ok_or(TransportError::FailedClosed)?;
        let mut available = 0_u32;
        // SAFETY: the pipe handle is open and the only requested output points
        // to initialized writable storage.
        if unsafe {
            PeekNamedPipe(
                file.as_raw_handle(),
                ptr::null_mut(),
                0,
                ptr::null_mut(),
                &raw mut available,
                ptr::null_mut(),
            )
        } == 0
        {
            let code = std::io::Error::last_os_error()
                .raw_os_error()
                .unwrap_or_default()
                .cast_unsigned();
            return if matches!(code, ERROR_BROKEN_PIPE | ERROR_NO_DATA) {
                Err(TransportError::Disconnected)
            } else {
                Err(TransportError::FailedClosed)
            };
        }
        usize::try_from(available).map_err(|_| TransportError::FailedClosed)
    }
}

impl LocalBridgeTransport for WindowsPipeTransport {
    fn send(&mut self, frame: &[u8]) -> Result<(), TransportError> {
        if self.failed {
            return Err(TransportError::FailedClosed);
        }
        let encoded = encode_bridge_frame(frame).map_err(|_| TransportError::FailedClosed)?;
        self.file
            .as_mut()
            .ok_or(TransportError::FailedClosed)?
            .write_all(&encoded)
            .and_then(|()| self.file.as_mut().expect("pipe checked").flush())
            .map_err(|error| map_io_error(&error))
    }

    fn receive(&mut self) -> Result<Vec<u8>, TransportError> {
        let deadline = Instant::now()
            .checked_add(self.timeout)
            .ok_or(TransportError::FailedClosed)?;
        while self.ready.is_empty() {
            self.read_available()?;
            if self.ready.is_empty() {
                if Instant::now() >= deadline {
                    return Err(TransportError::Disconnected);
                }
                std::thread::sleep(Duration::from_millis(2));
            }
        }
        self.ready.pop_front().ok_or(TransportError::Disconnected)
    }

    fn try_receive(&mut self) -> Result<Option<Vec<u8>>, TransportError> {
        if self.failed {
            return Err(TransportError::FailedClosed);
        }
        if self.ready.is_empty() {
            self.read_available()?;
        }
        Ok(self.ready.pop_front())
    }

    fn peer_identity(&self) -> Option<TransportPeerIdentity> {
        self.peer
    }

    fn fail_closed(&mut self) {
        self.failed = true;
        self.ready.clear();
        self.file = None;
    }
}

pub struct WindowsBridgeTransportConnector {
    timeout: Duration,
}

impl WindowsBridgeTransportConnector {
    /// Creates a fixed named-pipe connector.
    ///
    /// # Errors
    ///
    /// Rejects a zero timeout.
    pub fn new(timeout: Duration) -> Result<Self, ProxyError> {
        if timeout.is_zero() {
            return Err(ProxyError::InvalidConfiguration);
        }
        Ok(Self { timeout })
    }
}

impl BridgeTransportConnector for WindowsBridgeTransportConnector {
    fn connect(&mut self) -> Result<Box<dyn LocalBridgeTransport>, ProxyError> {
        WindowsPipeTransport::connect(self.timeout)
            .map(|transport| Box::new(transport) as Box<dyn LocalBridgeTransport>)
            .map_err(|_| ProxyError::Transport)
    }
}

fn create_server(owner_sid: &str) -> Result<File, TransportError> {
    let sddl = format!("D:P(A;;GA;;;SY)(A;;GA;;;{owner_sid})");
    let mut security = SecurityAttributes::new(&sddl)?;
    let name = wide_null(OsStr::new(BRIDGE_PIPE_NAME));
    // SAFETY: all pointers are valid for the call. Windows copies the security
    // descriptor while creating the owned handle.
    let handle = unsafe {
        CreateNamedPipeW(
            name.as_ptr(),
            PIPE_ACCESS_DUPLEX,
            PIPE_TYPE_BYTE | PIPE_READMODE_BYTE | PIPE_NOWAIT | PIPE_REJECT_REMOTE_CLIENTS,
            1,
            PIPE_BUFFER_BYTES,
            PIPE_BUFFER_BYTES,
            5_000,
            security.as_ptr(),
        )
    };
    if handle == INVALID_HANDLE_VALUE {
        return Err(TransportError::FailedClosed);
    }
    // SAFETY: the successful CreateNamedPipeW handle is uniquely owned and is
    // transferred to File exactly once.
    Ok(unsafe { File::from_raw_handle(handle) })
}

fn peer_identity(handle: HANDLE) -> Result<TransportPeerIdentity, TransportError> {
    let mut process_id = 0_u32;
    let mut session_id = 0_u32;
    // SAFETY: the connected server pipe is valid and both output pointers are initialized.
    if unsafe { GetNamedPipeClientProcessId(handle, &raw mut process_id) } == 0
        || unsafe { GetNamedPipeClientSessionId(handle, &raw mut session_id) } == 0
        || process_id == 0
        || session_id == 0
    {
        return Err(TransportError::FailedClosed);
    }
    // SAFETY: the PID comes from the connected local pipe and requests only query access.
    let process = unsafe { OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, 0, process_id) };
    if process.is_null() {
        return Err(TransportError::FailedClosed);
    }
    let process = HandleGuard(process);
    let mut path = vec![0_u16; MAX_IMAGE_PATH_UTF16];
    let mut path_length = u32::try_from(path.len()).map_err(|_| TransportError::FailedClosed)?;
    // SAFETY: the process handle is open and the UTF-16 buffer/output length are valid.
    if unsafe { QueryFullProcessImageNameW(process.0, 0, path.as_mut_ptr(), &raw mut path_length) }
        == 0
    {
        return Err(TransportError::FailedClosed);
    }
    path.truncate(usize::try_from(path_length).map_err(|_| TransportError::FailedClosed)?);
    let executable =
        PathBuf::from(String::from_utf16(&path).map_err(|_| TransportError::FailedClosed)?);
    let executable_sha256 =
        installed_file_sha256(&executable).map_err(|_| TransportError::FailedClosed)?;
    Ok(TransportPeerIdentity {
        process_id,
        os_session_id: u64::from(session_id),
        unix_uid: None,
        executable_sha256,
    })
}

fn valid_sid_text(value: &str) -> bool {
    value.len() >= 5
        && value.len() <= 184
        && value.starts_with("S-1-")
        && value
            .bytes()
            .all(|character| character.is_ascii_digit() || character == b'-' || character == b'S')
}

fn map_io_error(error: &std::io::Error) -> TransportError {
    if matches!(
        error.kind(),
        ErrorKind::BrokenPipe | ErrorKind::ConnectionAborted | ErrorKind::ConnectionReset
    ) {
        TransportError::Disconnected
    } else {
        TransportError::FailedClosed
    }
}

fn wide_null(value: &OsStr) -> Vec<u16> {
    value.encode_wide().chain([0]).collect()
}

struct SecurityAttributes {
    attributes: SECURITY_ATTRIBUTES,
    descriptor: PSECURITY_DESCRIPTOR,
}

impl SecurityAttributes {
    fn new(sddl: &str) -> Result<Self, TransportError> {
        let encoded = wide_null(OsStr::new(sddl));
        let mut descriptor: PSECURITY_DESCRIPTOR = ptr::null_mut();
        // SAFETY: the SDDL buffer is NUL-terminated and output pointer is valid.
        if unsafe {
            ConvertStringSecurityDescriptorToSecurityDescriptorW(
                encoded.as_ptr(),
                SDDL_REVISION_1,
                &raw mut descriptor,
                ptr::null_mut(),
            )
        } == 0
        {
            return Err(TransportError::FailedClosed);
        }
        Ok(Self {
            attributes: SECURITY_ATTRIBUTES {
                nLength: u32::try_from(size_of::<SECURITY_ATTRIBUTES>())
                    .map_err(|_| TransportError::FailedClosed)?,
                lpSecurityDescriptor: descriptor.cast::<c_void>(),
                bInheritHandle: 0,
            },
            descriptor,
        })
    }

    fn as_ptr(&mut self) -> *const SECURITY_ATTRIBUTES {
        &raw const self.attributes
    }
}

impl Drop for SecurityAttributes {
    fn drop(&mut self) {
        // SAFETY: the descriptor was allocated by the SDDL conversion API and
        // is owned by this guard exactly once.
        unsafe {
            LocalFree(self.descriptor.cast());
        }
    }
}

struct HandleGuard(HANDLE);

impl Drop for HandleGuard {
    fn drop(&mut self) {
        // SAFETY: the handle is uniquely owned by this guard.
        unsafe {
            CloseHandle(self.0);
        }
    }
}
