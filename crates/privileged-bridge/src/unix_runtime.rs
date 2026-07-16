// SPDX-License-Identifier: MPL-2.0

use std::{
    collections::VecDeque,
    io::{ErrorKind, Read, Write},
    net::Shutdown,
    os::unix::net::UnixStream,
    path::PathBuf,
    time::Duration,
};

use crate::{
    client::BridgeTransportConnector,
    framing::{BridgeFrameDecoder, encode_bridge_frame},
    proxy::ProxyError,
    transport::{LocalBridgeTransport, TransportError, TransportPeerIdentity},
};

#[cfg(target_os = "macos")]
use crate::macos_peer_runtime::macos_peer_identity;

const READ_BUFFER_BYTES: usize = 16 * 1024;

pub struct UnixStreamTransport {
    stream: UnixStream,
    decoder: BridgeFrameDecoder,
    ready: VecDeque<Vec<u8>>,
    timeout: Duration,
    peer: Option<TransportPeerIdentity>,
    failed: bool,
}

impl UnixStreamTransport {
    /// Wraps one connected local stream in bounded bridge framing.
    ///
    /// # Errors
    ///
    /// Rejects a zero timeout or a stream whose mode cannot be configured.
    pub fn new(stream: UnixStream, timeout: Duration) -> Result<Self, TransportError> {
        if timeout.is_zero() {
            return Err(TransportError::FailedClosed);
        }
        stream
            .set_read_timeout(Some(timeout))
            .map_err(|_| TransportError::FailedClosed)?;
        stream
            .set_write_timeout(Some(timeout))
            .map_err(|_| TransportError::FailedClosed)?;
        stream
            .set_nonblocking(true)
            .map_err(|_| TransportError::FailedClosed)?;
        #[cfg(target_os = "macos")]
        let peer = macos_peer_identity(&stream).ok();
        #[cfg(not(target_os = "macos"))]
        let peer = None;
        Ok(Self {
            stream,
            decoder: BridgeFrameDecoder::new(),
            ready: VecDeque::new(),
            timeout,
            peer,
            failed: false,
        })
    }

    fn read_until_ready(&mut self, blocking: bool) -> Result<(), TransportError> {
        self.stream
            .set_nonblocking(!blocking)
            .map_err(|_| TransportError::FailedClosed)?;
        self.stream
            .set_read_timeout(blocking.then_some(self.timeout))
            .map_err(|_| TransportError::FailedClosed)?;
        let mut buffer = [0_u8; READ_BUFFER_BYTES];
        loop {
            match self.stream.read(&mut buffer) {
                Ok(0) => return Err(TransportError::Disconnected),
                Ok(read) => {
                    let frames = self
                        .decoder
                        .push(&buffer[..read])
                        .map_err(|_| TransportError::FailedClosed)?;
                    self.ready.extend(frames);
                    if !self.ready.is_empty() {
                        return Ok(());
                    }
                }
                Err(error) if error.kind() == ErrorKind::Interrupted => {}
                Err(error)
                    if !blocking
                        && matches!(error.kind(), ErrorKind::WouldBlock | ErrorKind::TimedOut) =>
                {
                    return Ok(());
                }
                Err(error)
                    if blocking
                        && matches!(error.kind(), ErrorKind::WouldBlock | ErrorKind::TimedOut) =>
                {
                    return Err(TransportError::Disconnected);
                }
                Err(_) => return Err(TransportError::Disconnected),
            }
        }
    }
}

impl LocalBridgeTransport for UnixStreamTransport {
    fn send(&mut self, frame: &[u8]) -> Result<(), TransportError> {
        if self.failed {
            return Err(TransportError::FailedClosed);
        }
        let encoded = encode_bridge_frame(frame).map_err(|_| TransportError::FailedClosed)?;
        self.stream
            .set_nonblocking(false)
            .map_err(|_| TransportError::FailedClosed)?;
        self.stream
            .write_all(&encoded)
            .and_then(|()| self.stream.flush())
            .map_err(|_| TransportError::Disconnected)
    }

    fn receive(&mut self) -> Result<Vec<u8>, TransportError> {
        if self.failed {
            return Err(TransportError::FailedClosed);
        }
        if self.ready.is_empty() {
            self.read_until_ready(true)?;
        }
        self.ready.pop_front().ok_or(TransportError::Disconnected)
    }

    fn try_receive(&mut self) -> Result<Option<Vec<u8>>, TransportError> {
        if self.failed {
            return Err(TransportError::FailedClosed);
        }
        if self.ready.is_empty() {
            self.read_until_ready(false)?;
        }
        Ok(self.ready.pop_front())
    }

    fn peer_identity(&self) -> Option<TransportPeerIdentity> {
        self.peer
    }

    fn fail_closed(&mut self) {
        if !self.failed {
            self.failed = true;
            self.ready.clear();
            let _ = self.stream.shutdown(Shutdown::Both);
        }
    }
}

pub struct UnixBridgeTransportConnector {
    socket_path: PathBuf,
    timeout: Duration,
}

impl UnixBridgeTransportConnector {
    /// Creates a connector for an absolute, preconfigured local socket.
    ///
    /// # Errors
    ///
    /// Rejects relative paths and zero I/O timeouts.
    pub fn new(socket_path: PathBuf, timeout: Duration) -> Result<Self, ProxyError> {
        if !socket_path.is_absolute() || timeout.is_zero() {
            return Err(ProxyError::InvalidConfiguration);
        }
        Ok(Self {
            socket_path,
            timeout,
        })
    }
}

impl BridgeTransportConnector for UnixBridgeTransportConnector {
    fn connect(&mut self) -> Result<Box<dyn LocalBridgeTransport>, ProxyError> {
        let stream = UnixStream::connect(&self.socket_path).map_err(|_| ProxyError::Transport)?;
        let transport =
            UnixStreamTransport::new(stream, self.timeout).map_err(|_| ProxyError::Transport)?;
        Ok(Box::new(transport))
    }
}
