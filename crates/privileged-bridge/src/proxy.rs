// SPDX-License-Identifier: MPL-2.0

use std::{
    collections::HashSet,
    fmt,
    sync::{Arc, Mutex, MutexGuard},
};

use roammand_host_webrtc::{
    HostWebRtcError, PeerAnswer, PeerBackend, PeerIceCandidate, RemoteInputSink, SessionConfig,
};
use roammand_protocol::{
    protocol_limits::{MAX_DEVICE_NAME_UTF8_BYTES, SESSION_ID_BYTES},
    roammand::v1::{ButtonAction, KeyboardAction, PointerButton, SessionPermission},
};
use thiserror::Error;

use crate::lease::LeaseId;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ProxyRoute {
    pub lease_id: LeaseId,
    pub generation: u64,
}

impl ProxyRoute {
    #[must_use]
    pub const fn new(lease_id: LeaseId, generation: u64) -> Self {
        Self {
            lease_id,
            generation,
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct BridgeRequest {
    pub route: ProxyRoute,
    pub sequence: u64,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct BridgeResponse<T> {
    pub route: ProxyRoute,
    pub sequence: u64,
    pub value: T,
}

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum ProxyError {
    #[error("privileged bridge transport failed")]
    Transport,
    #[error("privileged bridge response route is stale")]
    StaleRoute,
    #[error("privileged bridge response sequence is stale")]
    StaleResponse,
    #[error("privileged bridge proxy failed closed")]
    FailedClosed,
    #[error("privileged bridge route migration is invalid")]
    InvalidMigration,
    #[error("privileged bridge configuration is invalid")]
    InvalidConfiguration,
    #[error("privileged bridge message is invalid")]
    InvalidMessage,
    #[error("privileged bridge rejected the request")]
    Rejected,
}

#[derive(Clone, Eq, PartialEq)]
pub struct ProxySessionContext {
    session_id: Vec<u8>,
    permissions: Vec<SessionPermission>,
    controller_display_name: String,
}

impl ProxySessionContext {
    /// Creates the minimal verified authority passed to the privileged broker.
    ///
    /// # Errors
    ///
    /// Rejects malformed identifiers, permissions, and display names before IPC.
    pub fn new(
        session_id: Vec<u8>,
        permissions: Vec<SessionPermission>,
        controller_display_name: String,
    ) -> Result<Self, ProxyError> {
        let unique_permissions = permissions.iter().copied().collect::<HashSet<_>>();
        if session_id.len() != SESSION_ID_BYTES
            || permissions.is_empty()
            || unique_permissions.len() != permissions.len()
            || permissions.contains(&SessionPermission::Unspecified)
            || controller_display_name.is_empty()
            || controller_display_name.len() > MAX_DEVICE_NAME_UTF8_BYTES
        {
            return Err(ProxyError::InvalidConfiguration);
        }
        Ok(Self {
            session_id,
            permissions,
            controller_display_name,
        })
    }

    #[must_use]
    pub fn session_id(&self) -> &[u8] {
        &self.session_id
    }

    #[must_use]
    pub fn permissions(&self) -> &[SessionPermission] {
        &self.permissions
    }

    #[must_use]
    pub fn controller_display_name(&self) -> &str {
        &self.controller_display_name
    }
}

impl fmt::Debug for ProxySessionContext {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("ProxySessionContext")
            .field("permission_count", &self.permissions.len())
            .field("sensitive", &"[REDACTED]")
            .finish_non_exhaustive()
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum ValidatedInput<'a> {
    Keyboard(KeyboardAction, u32, u32),
    PointerButton(PointerButton, ButtonAction, i32, i32),
    PointerMove(i32, i32, u32),
    PointerScroll(i32, i32),
    Text(&'a str),
    ReleaseAll,
}

#[derive(Clone, Eq, PartialEq)]
pub enum ProxyEvent {
    Connected,
    Disconnected,
    Failed,
    LocalIceCandidate(PeerIceCandidate),
    ReliableInput(Vec<u8>),
    FastPointer(Vec<u8>),
}

impl fmt::Debug for ProxyEvent {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        let (kind, payload_bytes) = match self {
            Self::Connected => ("connected", 0),
            Self::Disconnected => ("disconnected", 0),
            Self::Failed => ("failed", 0),
            Self::LocalIceCandidate(_) => ("local_ice_candidate", 0),
            Self::ReliableInput(value) => ("reliable_input", value.len()),
            Self::FastPointer(value) => ("fast_pointer", value.len()),
        };
        formatter
            .debug_struct("ProxyEvent")
            .field("kind", &kind)
            .field("payload_bytes", &payload_bytes)
            .finish()
    }
}

pub trait BridgeWire: Send {
    /// Starts one ephemeral helper peer.
    ///
    /// # Errors
    ///
    /// Returns only a stable proxy error; SDP and credentials must not be logged.
    fn start(
        &mut self,
        request: BridgeRequest,
        config: &SessionConfig,
        offer_sdp: &str,
    ) -> Result<BridgeResponse<PeerAnswer>, ProxyError>;

    /// Recreates the peer for an authenticated reconnect.
    ///
    /// # Errors
    ///
    /// Returns only a stable proxy error.
    fn restart(
        &mut self,
        request: BridgeRequest,
        config: &SessionConfig,
        offer_sdp: &str,
    ) -> Result<BridgeResponse<PeerAnswer>, ProxyError>;

    /// Adds one authenticated remote ICE candidate.
    ///
    /// # Errors
    ///
    /// Returns only a stable proxy error.
    fn add_candidate(
        &mut self,
        request: BridgeRequest,
        candidate: &PeerIceCandidate,
    ) -> Result<BridgeResponse<()>, ProxyError>;

    /// Sends one Host-validated typed input operation.
    ///
    /// # Errors
    ///
    /// Returns only a stable proxy error.
    fn input(
        &mut self,
        request: BridgeRequest,
        input: ValidatedInput<'_>,
    ) -> Result<BridgeResponse<()>, ProxyError>;

    /// Closes helper peer resources.
    ///
    /// # Errors
    ///
    /// Returns only a stable proxy error.
    fn close(&mut self, request: BridgeRequest) -> Result<BridgeResponse<()>, ProxyError>;

    /// Releases the ephemeral route lease.
    ///
    /// # Errors
    ///
    /// Returns only a stable proxy error.
    fn release(&mut self, request: BridgeRequest) -> Result<BridgeResponse<()>, ProxyError>;

    /// Polls one helper event, including raw `DataChannel` payloads for Host validation.
    ///
    /// # Errors
    ///
    /// Returns only a stable proxy error.
    fn try_event(&mut self) -> Result<Option<BridgeResponse<ProxyEvent>>, ProxyError>;

    fn fail_closed(&mut self);
}

pub struct ProxyParts {
    peer: ProxyPeer,
    input: ProxyInputSink,
    events: ProxyEvents,
    route_control: ProxyRouteControl,
}

pub trait ProxyPartsFactory: Send {
    /// Acquires one route-bound proxy set for an authenticated Host session.
    ///
    /// # Errors
    ///
    /// Returns only stable bridge categories; no lease or peer evidence is exposed.
    fn create(
        &mut self,
        config: &SessionConfig,
        context: &ProxySessionContext,
    ) -> Result<ProxyParts, ProxyError>;
}

impl ProxyParts {
    #[must_use]
    pub fn into_parts(self) -> (ProxyPeer, ProxyInputSink, ProxyEvents, ProxyRouteControl) {
        (self.peer, self.input, self.events, self.route_control)
    }
}

#[must_use]
pub fn new_proxy_parts(route: ProxyRoute, wire: Box<dyn BridgeWire>) -> ProxyParts {
    let shared = Arc::new(Mutex::new(ProxyShared {
        route,
        next_request_sequence: 1,
        last_event_sequence: 0,
        wire,
        failed: false,
        closed: false,
    }));
    ProxyParts {
        peer: ProxyPeer(Arc::clone(&shared)),
        input: ProxyInputSink(Arc::clone(&shared)),
        events: ProxyEvents(Arc::clone(&shared)),
        route_control: ProxyRouteControl(shared),
    }
}

struct ProxyShared {
    route: ProxyRoute,
    next_request_sequence: u64,
    last_event_sequence: u64,
    wire: Box<dyn BridgeWire>,
    failed: bool,
    closed: bool,
}

impl ProxyShared {
    fn perform<T>(
        &mut self,
        call: impl FnOnce(&mut dyn BridgeWire, BridgeRequest) -> Result<BridgeResponse<T>, ProxyError>,
    ) -> Result<T, ProxyError> {
        if self.failed {
            return Err(ProxyError::FailedClosed);
        }
        let request = BridgeRequest {
            route: self.route,
            sequence: self.next_request_sequence,
        };
        self.next_request_sequence = self
            .next_request_sequence
            .checked_add(1)
            .ok_or(ProxyError::FailedClosed)?;
        let response = match call(self.wire.as_mut(), request) {
            Ok(response) => response,
            Err(error) => {
                self.fail_closed();
                return Err(error);
            }
        };
        if response.route != request.route {
            self.fail_closed();
            return Err(ProxyError::StaleRoute);
        }
        if response.sequence != request.sequence {
            self.fail_closed();
            return Err(ProxyError::StaleResponse);
        }
        Ok(response.value)
    }

    fn fail_closed(&mut self) {
        if !self.failed {
            self.failed = true;
            self.wire.fail_closed();
        }
    }
}

pub struct ProxyPeer(Arc<Mutex<ProxyShared>>);

impl PeerBackend for ProxyPeer {
    fn start(
        &mut self,
        config: &SessionConfig,
        offer_sdp: &str,
    ) -> Result<PeerAnswer, HostWebRtcError> {
        lock(&self.0)
            .and_then(|mut shared| {
                shared.perform(|wire, request| wire.start(request, config, offer_sdp))
            })
            .map_err(|_| HostWebRtcError::PeerFailure)
    }

    fn restart(
        &mut self,
        config: &SessionConfig,
        offer_sdp: &str,
    ) -> Result<PeerAnswer, HostWebRtcError> {
        lock(&self.0)
            .and_then(|mut shared| {
                shared.perform(|wire, request| wire.restart(request, config, offer_sdp))
            })
            .map_err(|_| HostWebRtcError::PeerFailure)
    }

    fn add_remote_ice_candidate(
        &mut self,
        candidate: &PeerIceCandidate,
    ) -> Result<(), HostWebRtcError> {
        lock(&self.0)
            .and_then(|mut shared| {
                shared.perform(|wire, request| wire.add_candidate(request, candidate))
            })
            .map_err(|_| HostWebRtcError::PeerFailure)
    }

    fn close(&mut self) -> Result<(), HostWebRtcError> {
        let mut shared = lock(&self.0).map_err(|_| HostWebRtcError::PeerFailure)?;
        if shared.closed {
            return Ok(());
        }
        let close_result = shared.perform(|wire, request| wire.close(request));
        let release_result = shared.perform(|wire, request| wire.release(request));
        shared.closed = true;
        close_result
            .and(release_result)
            .map_err(|_| HostWebRtcError::PeerFailure)
    }
}

pub struct ProxyInputSink(Arc<Mutex<ProxyShared>>);

impl RemoteInputSink for ProxyInputSink {
    fn keyboard(
        &mut self,
        action: KeyboardAction,
        usb_hid_usage: u32,
        modifier_bits: u32,
    ) -> Result<(), HostWebRtcError> {
        self.send(ValidatedInput::Keyboard(
            action,
            usb_hid_usage,
            modifier_bits,
        ))
    }

    fn pointer_button(
        &mut self,
        button: PointerButton,
        action: ButtonAction,
        x: i32,
        y: i32,
    ) -> Result<(), HostWebRtcError> {
        self.send(ValidatedInput::PointerButton(button, action, x, y))
    }

    fn pointer_move(
        &mut self,
        x: i32,
        y: i32,
        pressed_button_bits: u32,
    ) -> Result<(), HostWebRtcError> {
        self.send(ValidatedInput::PointerMove(x, y, pressed_button_bits))
    }

    fn pointer_scroll(&mut self, delta_x: i32, delta_y: i32) -> Result<(), HostWebRtcError> {
        self.send(ValidatedInput::PointerScroll(delta_x, delta_y))
    }

    fn text(&mut self, text: &str) -> Result<(), HostWebRtcError> {
        self.send(ValidatedInput::Text(text))
    }

    fn release_all(&mut self) -> Result<(), HostWebRtcError> {
        self.send(ValidatedInput::ReleaseAll)
    }
}

impl ProxyInputSink {
    fn send(&mut self, input: ValidatedInput<'_>) -> Result<(), HostWebRtcError> {
        lock(&self.0)
            .and_then(|mut shared| shared.perform(|wire, request| wire.input(request, input)))
            .map_err(|_| HostWebRtcError::InputFailure)
    }
}

pub struct ProxyEvents(Arc<Mutex<ProxyShared>>);

impl ProxyEvents {
    /// Polls one route-bound event.
    ///
    /// # Errors
    ///
    /// Rejects helper errors, stale routes, repeated/gapped event sequences, or
    /// a previously failed-closed proxy.
    pub fn try_recv(&self) -> Result<Option<ProxyEvent>, ProxyError> {
        let mut shared = lock(&self.0)?;
        if shared.failed {
            return Err(ProxyError::FailedClosed);
        }
        let response = match shared.wire.try_event() {
            Ok(Some(response)) => response,
            Ok(None) => return Ok(None),
            Err(error) => {
                shared.fail_closed();
                return Err(error);
            }
        };
        if response.route != shared.route {
            shared.fail_closed();
            return Err(ProxyError::StaleRoute);
        }
        let expected = shared
            .last_event_sequence
            .checked_add(1)
            .ok_or(ProxyError::StaleResponse)?;
        if response.sequence != expected {
            shared.fail_closed();
            return Err(ProxyError::StaleResponse);
        }
        shared.last_event_sequence = response.sequence;
        Ok(Some(response.value))
    }
}

#[derive(Clone)]
pub struct ProxyRouteControl(Arc<Mutex<ProxyShared>>);

impl ProxyRouteControl {
    /// Moves the retained proxy to the next broker generation after Host input
    /// has already been frozen by the reconnect state machine.
    ///
    /// # Errors
    ///
    /// Rejects skipped/stale generations and poisoned local state.
    pub fn migrate(&self, route: ProxyRoute) -> Result<(), ProxyError> {
        let mut shared = lock(&self.0)?;
        if route.generation != shared.route.generation.saturating_add(1)
            || route.lease_id == shared.route.lease_id
        {
            return Err(ProxyError::InvalidMigration);
        }
        shared.route = route;
        shared.next_request_sequence = 1;
        shared.last_event_sequence = 0;
        shared.closed = false;
        Ok(())
    }
}

fn lock(shared: &Arc<Mutex<ProxyShared>>) -> Result<MutexGuard<'_, ProxyShared>, ProxyError> {
    shared.lock().map_err(|_| ProxyError::FailedClosed)
}
