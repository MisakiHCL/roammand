// SPDX-License-Identifier: MPL-2.0

use std::{fmt, time::Instant};

use roammand_host_webrtc::{IceTransportPolicy, PeerAnswer, PeerIceCandidate, SessionConfig};
use roammand_protocol::{
    protocol_limits::{
        MAX_DEVICE_NAME_UTF8_BYTES, MAX_ERROR_DETAIL_UTF8_BYTES, MAX_PRIVILEGED_ICE_SERVERS,
        MAX_PRIVILEGED_ICE_URLS_PER_SERVER, MAX_SIGNALING_ENDPOINT_UTF8_BYTES,
        MINIMUM_PROTOCOL_MINOR_VERSION, NONCE_OR_HASH_BYTES, PROTOCOL_MAJOR_VERSION,
    },
    roammand::v1::{
        AddPrivilegedIceCandidateRequest, ClosePrivilegedPeerRequest, IceCandidate, KeyboardEvent,
        PointerButtonEvent, PointerMoveEvent, PointerScrollEvent, PrivilegedBridgeClientFrame,
        PrivilegedBridgeServerFrame, PrivilegedFastPointerEvent, PrivilegedIceServer,
        PrivilegedIceTransportPolicy, PrivilegedInputCommand, PrivilegedLocalIceCandidate,
        PrivilegedPeerConfiguration, PrivilegedPeerState, PrivilegedReliableInputEvent,
        ProtocolVersion, ReleaseAllInput, ReleasePrivilegedLeaseRequest,
        RenewPrivilegedLeaseRequest, RestartPrivilegedPeerRequest, SessionDescriptionType,
        StartPrivilegedPeerRequest, TextInputEvent, WebRtcSessionDescription,
        privileged_bridge_client_frame, privileged_bridge_server_frame, privileged_input_command,
    },
};

use crate::{
    lease::RENEW_INTERVAL_MS,
    proxy::{
        BridgeRequest, BridgeResponse, BridgeWire, ProxyError, ProxyEvent, ProxyParts,
        ProxyPartsFactory, ProxyRoute, ProxySessionContext, ValidatedInput, new_proxy_parts,
    },
};

pub use crate::connector::{AuthenticatedBridgeConnector, BridgeTransportConnector};

const REQUEST_ID_PREFIX: &str = "session";

/// A request/response transport that has already authenticated its local peer
/// and strictly decoded each bounded Protobuf frame at the IPC boundary.
pub trait BridgeRpc: Send {
    /// Sends one typed request and waits for its correlated typed response.
    ///
    /// # Errors
    ///
    /// Returns only a stable proxy category; frame contents must never be logged.
    fn call(
        &mut self,
        request: PrivilegedBridgeClientFrame,
    ) -> Result<PrivilegedBridgeServerFrame, ProxyError>;

    /// Polls one unsolicited, strictly decoded helper event.
    ///
    /// # Errors
    ///
    /// Returns a stable proxy category when the IPC boundary fails.
    fn try_event(&mut self) -> Result<Option<PrivilegedBridgeServerFrame>, ProxyError>;

    fn fail_closed(&mut self);
}

pub struct BridgeConnection {
    route: ProxyRoute,
    rpc: Box<dyn BridgeRpc>,
    next_frame_sequence: u64,
}

impl BridgeConnection {
    #[must_use]
    pub fn new(route: ProxyRoute, rpc: Box<dyn BridgeRpc>) -> Self {
        Self {
            route,
            rpc,
            next_frame_sequence: 1,
        }
    }

    pub(crate) fn with_next_frame_sequence(
        route: ProxyRoute,
        rpc: Box<dyn BridgeRpc>,
        next_frame_sequence: u64,
    ) -> Self {
        Self {
            route,
            rpc,
            next_frame_sequence,
        }
    }

    #[must_use]
    pub const fn route(&self) -> ProxyRoute {
        self.route
    }

    fn into_parts(self) -> (ProxyRoute, Box<dyn BridgeRpc>, u64) {
        (self.route, self.rpc, self.next_frame_sequence)
    }
}

pub trait BridgeRpcConnector: Send {
    /// Authenticates the Host process and acquires one ephemeral route for the
    /// already verified remote session.
    ///
    /// # Errors
    ///
    /// Fails closed if peer authentication or lease acquisition fails.
    fn connect(&mut self, context: &ProxySessionContext) -> Result<BridgeConnection, ProxyError>;
}

pub struct RpcProxyPartsFactory {
    connector: Box<dyn BridgeRpcConnector>,
    options: BridgePeerOptions,
}

impl RpcProxyPartsFactory {
    #[must_use]
    pub fn new(connector: Box<dyn BridgeRpcConnector>, options: BridgePeerOptions) -> Self {
        Self { connector, options }
    }
}

impl ProxyPartsFactory for RpcProxyPartsFactory {
    fn create(
        &mut self,
        _config: &SessionConfig,
        context: &ProxySessionContext,
    ) -> Result<ProxyParts, ProxyError> {
        let (route, rpc, next_frame_sequence) = self.connector.connect(context)?.into_parts();
        Ok(new_proxy_parts(
            route,
            Box::new(ProtobufBridgeWire::with_connection(
                rpc,
                self.options.clone(),
                context.controller_display_name().to_owned(),
                route,
                next_frame_sequence,
            )?),
        ))
    }
}

#[derive(Clone, Eq, PartialEq)]
pub struct BridgeIceServer {
    urls: Vec<String>,
    username: String,
    credential: String,
}

impl BridgeIceServer {
    /// Creates a protocol-bounded ICE server without exposing credentials in
    /// its debug representation.
    ///
    /// # Errors
    ///
    /// Returns [`ProxyError::InvalidConfiguration`] for an invalid bound.
    pub fn new(
        urls: Vec<String>,
        username: String,
        credential: String,
    ) -> Result<Self, ProxyError> {
        if urls.is_empty()
            || urls.len() > MAX_PRIVILEGED_ICE_URLS_PER_SERVER
            || urls
                .iter()
                .any(|url| url.is_empty() || url.len() > MAX_SIGNALING_ENDPOINT_UTF8_BYTES)
            || username.len() > MAX_ERROR_DETAIL_UTF8_BYTES
            || credential.len() > MAX_ERROR_DETAIL_UTF8_BYTES
        {
            return Err(ProxyError::InvalidConfiguration);
        }
        Ok(Self {
            urls,
            username,
            credential,
        })
    }

    fn to_proto(&self) -> PrivilegedIceServer {
        PrivilegedIceServer {
            urls: self.urls.clone(),
            username: self.username.clone(),
            credential: self.credential.clone(),
        }
    }
}

impl fmt::Debug for BridgeIceServer {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("BridgeIceServer")
            .field("url_count", &self.urls.len())
            .field("has_username", &!self.username.is_empty())
            .field("has_credential", &!self.credential.is_empty())
            .finish()
    }
}

#[derive(Clone, Eq, PartialEq)]
pub struct BridgePeerOptions {
    ice_servers: Vec<BridgeIceServer>,
}

impl BridgePeerOptions {
    /// Creates bounded peer options for the privileged helper.
    ///
    /// # Errors
    ///
    /// Returns [`ProxyError::InvalidConfiguration`] when too many servers are supplied.
    pub fn new(ice_servers: Vec<BridgeIceServer>) -> Result<Self, ProxyError> {
        if ice_servers.len() > MAX_PRIVILEGED_ICE_SERVERS {
            return Err(ProxyError::InvalidConfiguration);
        }
        Ok(Self { ice_servers })
    }

    fn configuration(&self, config: &SessionConfig) -> PrivilegedPeerConfiguration {
        let policy = match config.ice_transport_policy() {
            IceTransportPolicy::All => PrivilegedIceTransportPolicy::All,
            IceTransportPolicy::Relay => PrivilegedIceTransportPolicy::Relay,
        };
        PrivilegedPeerConfiguration {
            ice_transport_policy: policy as i32,
            ice_servers: self
                .ice_servers
                .iter()
                .map(BridgeIceServer::to_proto)
                .collect(),
        }
    }
}

impl fmt::Debug for BridgePeerOptions {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter
            .debug_struct("BridgePeerOptions")
            .field("ice_server_count", &self.ice_servers.len())
            .finish()
    }
}

pub struct ProtobufBridgeWire {
    rpc: Box<dyn BridgeRpc>,
    options: BridgePeerOptions,
    controller_display_name: String,
    route: Option<ProxyRoute>,
    next_frame_sequence: u64,
    last_renewed_at_ms: u64,
    clock: Box<dyn BridgeClock>,
    failed: bool,
}

pub trait BridgeClock: Send {
    fn now_ms(&self) -> u64;
}

struct SystemBridgeClock(Instant);

impl SystemBridgeClock {
    fn new() -> Self {
        Self(Instant::now())
    }
}

impl BridgeClock for SystemBridgeClock {
    fn now_ms(&self) -> u64 {
        u64::try_from(self.0.elapsed().as_millis()).unwrap_or(u64::MAX)
    }
}

impl ProtobufBridgeWire {
    /// Creates a typed wire bound to one authenticated Controller name.
    ///
    /// # Errors
    ///
    /// Rejects an invalid display name before emitting IPC.
    pub fn new(
        rpc: Box<dyn BridgeRpc>,
        options: BridgePeerOptions,
        controller_display_name: String,
    ) -> Result<Self, ProxyError> {
        validate_controller_display_name(&controller_display_name)?;
        let clock: Box<dyn BridgeClock> = Box::new(SystemBridgeClock::new());
        let last_renewed_at_ms = clock.now_ms();
        Ok(Self {
            rpc,
            options,
            controller_display_name,
            route: None,
            next_frame_sequence: 1,
            last_renewed_at_ms,
            clock,
            failed: false,
        })
    }

    /// Creates a route-bound wire with an injected monotonic clock.
    ///
    /// # Errors
    ///
    /// Rejects a zero frame sequence or route generation.
    pub fn with_clock(
        rpc: Box<dyn BridgeRpc>,
        options: BridgePeerOptions,
        controller_display_name: String,
        route: ProxyRoute,
        next_frame_sequence: u64,
        clock: Box<dyn BridgeClock>,
    ) -> Result<Self, ProxyError> {
        if route.generation == 0 || next_frame_sequence == 0 {
            return Err(ProxyError::InvalidConfiguration);
        }
        validate_controller_display_name(&controller_display_name)?;
        let last_renewed_at_ms = clock.now_ms();
        Ok(Self {
            rpc,
            options,
            controller_display_name,
            route: Some(route),
            next_frame_sequence,
            last_renewed_at_ms,
            clock,
            failed: false,
        })
    }

    fn with_connection(
        rpc: Box<dyn BridgeRpc>,
        options: BridgePeerOptions,
        controller_display_name: String,
        route: ProxyRoute,
        next_frame_sequence: u64,
    ) -> Result<Self, ProxyError> {
        Self::with_clock(
            rpc,
            options,
            controller_display_name,
            route,
            next_frame_sequence,
            Box::new(SystemBridgeClock::new()),
        )
    }

    fn call(
        &mut self,
        request: BridgeRequest,
        payload: privileged_bridge_client_frame::Payload,
    ) -> Result<PrivilegedBridgeServerFrame, ProxyError> {
        if self.failed {
            return Err(ProxyError::FailedClosed);
        }
        if let Some(route) = self.route {
            if route != request.route {
                return self.reject(ProxyError::StaleRoute);
            }
        } else {
            self.route = Some(request.route);
        }
        let frame_sequence = self.next_frame_sequence;
        self.next_frame_sequence = match frame_sequence.checked_add(1) {
            Some(sequence) => sequence,
            None => return self.reject(ProxyError::FailedClosed),
        };
        let request_id = request_id(request.route, frame_sequence);
        let response = match self.rpc.call(PrivilegedBridgeClientFrame {
            protocol_version: Some(version()),
            request_id: request_id.clone(),
            sequence: frame_sequence,
            payload: Some(payload),
        }) {
            Ok(response) => response,
            Err(error) => return self.reject(error),
        };
        if !valid_version(response.protocol_version.as_ref())
            || response.request_id != request_id
            || response.sequence != frame_sequence
        {
            return self.reject(ProxyError::StaleResponse);
        }
        Ok(response)
    }

    fn accepted(
        &mut self,
        request: BridgeRequest,
        payload: privileged_bridge_client_frame::Payload,
    ) -> Result<BridgeResponse<()>, ProxyError> {
        let response = self.call(request, payload)?;
        match response.payload {
            Some(privileged_bridge_server_frame::Payload::CommandAccepted(value)) => {
                Ok(BridgeResponse {
                    route: route(value.lease_id, value.generation)?,
                    sequence: request.sequence,
                    value: (),
                })
            }
            Some(privileged_bridge_server_frame::Payload::Error(_)) => {
                self.reject(ProxyError::Rejected)
            }
            _ => self.reject(ProxyError::StaleResponse),
        }
    }

    fn reject<T>(&mut self, error: ProxyError) -> Result<T, ProxyError> {
        if !self.failed {
            self.failed = true;
            self.rpc.fail_closed();
        }
        Err(error)
    }

    fn renew_if_due(&mut self) -> Result<(), ProxyError> {
        let now_ms = self.clock.now_ms();
        if now_ms.saturating_sub(self.last_renewed_at_ms) < RENEW_INTERVAL_MS {
            return Ok(());
        }
        let route = self.route.ok_or(ProxyError::InvalidMessage)?;
        let response = self.call(
            BridgeRequest { route, sequence: 0 },
            privileged_bridge_client_frame::Payload::RenewLease(RenewPrivilegedLeaseRequest {
                lease_id: route.lease_id.into_bytes().to_vec(),
                generation: route.generation,
            }),
        )?;
        let Some(privileged_bridge_server_frame::Payload::Lease(lease)) = response.payload else {
            return self.reject(ProxyError::Rejected);
        };
        if crate::client::route(lease.lease_id, lease.generation)? != route {
            return self.reject(ProxyError::StaleRoute);
        }
        self.last_renewed_at_ms = now_ms;
        Ok(())
    }

    fn peer_request(
        &self,
        request: BridgeRequest,
        config: &SessionConfig,
        offer_sdp: &str,
    ) -> Result<
        (
            Vec<u8>,
            u64,
            PrivilegedPeerConfiguration,
            WebRtcSessionDescription,
        ),
        ProxyError,
    > {
        let fingerprint =
            parse_dtls_sha256_fingerprint(offer_sdp).ok_or(ProxyError::InvalidMessage)?;
        Ok((
            request.route.lease_id.into_bytes().to_vec(),
            request.route.generation,
            self.options.configuration(config),
            WebRtcSessionDescription {
                r#type: SessionDescriptionType::Offer as i32,
                sdp: offer_sdp.to_owned(),
                dtls_fingerprint_sha256: fingerprint,
            },
        ))
    }
}

impl BridgeWire for ProtobufBridgeWire {
    fn start(
        &mut self,
        request: BridgeRequest,
        config: &SessionConfig,
        offer_sdp: &str,
    ) -> Result<BridgeResponse<PeerAnswer>, ProxyError> {
        self.renew_if_due()?;
        let (lease_id, generation, configuration, offer) =
            self.peer_request(request, config, offer_sdp)?;
        let response = self.call(
            request,
            privileged_bridge_client_frame::Payload::StartPeer(StartPrivilegedPeerRequest {
                lease_id,
                generation,
                configuration: Some(configuration),
                offer: Some(offer),
                controller_display_name: self.controller_display_name.clone(),
            }),
        )?;
        peer_answer(self, response, request.sequence)
    }

    fn restart(
        &mut self,
        request: BridgeRequest,
        config: &SessionConfig,
        offer_sdp: &str,
    ) -> Result<BridgeResponse<PeerAnswer>, ProxyError> {
        self.renew_if_due()?;
        let (lease_id, generation, configuration, offer) =
            self.peer_request(request, config, offer_sdp)?;
        let response = self.call(
            request,
            privileged_bridge_client_frame::Payload::RestartPeer(RestartPrivilegedPeerRequest {
                lease_id,
                generation,
                configuration: Some(configuration),
                offer: Some(offer),
                controller_display_name: self.controller_display_name.clone(),
            }),
        )?;
        peer_answer(self, response, request.sequence)
    }

    fn add_candidate(
        &mut self,
        request: BridgeRequest,
        candidate: &PeerIceCandidate,
    ) -> Result<BridgeResponse<()>, ProxyError> {
        self.renew_if_due()?;
        let route = request.route;
        self.accepted(
            request,
            privileged_bridge_client_frame::Payload::AddIceCandidate(
                AddPrivilegedIceCandidateRequest {
                    lease_id: route.lease_id.into_bytes().to_vec(),
                    generation: route.generation,
                    candidate: Some(to_candidate(candidate)),
                },
            ),
        )
    }

    fn input(
        &mut self,
        request: BridgeRequest,
        input: ValidatedInput<'_>,
    ) -> Result<BridgeResponse<()>, ProxyError> {
        self.renew_if_due()?;
        let route = request.route;
        self.accepted(
            request,
            privileged_bridge_client_frame::Payload::InputCommand(PrivilegedInputCommand {
                lease_id: route.lease_id.into_bytes().to_vec(),
                generation: route.generation,
                input: Some(to_input(input)),
            }),
        )
    }

    fn close(&mut self, request: BridgeRequest) -> Result<BridgeResponse<()>, ProxyError> {
        let route = request.route;
        self.accepted(
            request,
            privileged_bridge_client_frame::Payload::ClosePeer(ClosePrivilegedPeerRequest {
                lease_id: route.lease_id.into_bytes().to_vec(),
                generation: route.generation,
            }),
        )
    }

    fn release(&mut self, request: BridgeRequest) -> Result<BridgeResponse<()>, ProxyError> {
        let route = request.route;
        self.accepted(
            request,
            privileged_bridge_client_frame::Payload::ReleaseLease(ReleasePrivilegedLeaseRequest {
                lease_id: route.lease_id.into_bytes().to_vec(),
                generation: route.generation,
            }),
        )
    }

    fn try_event(&mut self) -> Result<Option<BridgeResponse<ProxyEvent>>, ProxyError> {
        if self.failed {
            return Err(ProxyError::FailedClosed);
        }
        self.renew_if_due()?;
        let frame = match self.rpc.try_event() {
            Ok(Some(frame)) => frame,
            Ok(None) => return Ok(None),
            Err(error) => return self.reject(error),
        };
        if !valid_version(frame.protocol_version.as_ref()) || frame.sequence == 0 {
            return self.reject(ProxyError::StaleResponse);
        }
        let event = match frame.payload {
            Some(privileged_bridge_server_frame::Payload::LocalIceCandidate(value)) => {
                map_candidate_event(value)
            }
            Some(privileged_bridge_server_frame::Payload::PeerStateChanged(value)) => {
                let event = match PrivilegedPeerState::try_from(value.state) {
                    Ok(PrivilegedPeerState::Connected) => ProxyEvent::Connected,
                    Ok(PrivilegedPeerState::Disconnected | PrivilegedPeerState::Closed) => {
                        ProxyEvent::Disconnected
                    }
                    Ok(PrivilegedPeerState::Failed) => ProxyEvent::Failed,
                    _ => return self.reject(ProxyError::InvalidMessage),
                };
                Ok((value.lease_id, value.generation, event))
            }
            Some(privileged_bridge_server_frame::Payload::ReliableInput(value)) => {
                map_reliable_event(value)
            }
            Some(privileged_bridge_server_frame::Payload::FastPointer(value)) => {
                map_fast_event(value)
            }
            Some(privileged_bridge_server_frame::Payload::Error(_)) => {
                return self.reject(ProxyError::Rejected);
            }
            _ => return self.reject(ProxyError::StaleResponse),
        }?;
        Ok(Some(BridgeResponse {
            route: route(event.0, event.1)?,
            sequence: frame.sequence,
            value: event.2,
        }))
    }

    fn fail_closed(&mut self) {
        if !self.failed {
            self.failed = true;
            self.rpc.fail_closed();
        }
    }
}

fn peer_answer(
    wire: &mut ProtobufBridgeWire,
    response: PrivilegedBridgeServerFrame,
    proxy_sequence: u64,
) -> Result<BridgeResponse<PeerAnswer>, ProxyError> {
    match response.payload {
        Some(privileged_bridge_server_frame::Payload::PeerAnswer(value)) => {
            let answer = value.answer.ok_or(ProxyError::InvalidMessage)?;
            if SessionDescriptionType::try_from(answer.r#type) != Ok(SessionDescriptionType::Answer)
                || answer.sdp.is_empty()
                || answer.dtls_fingerprint_sha256.len() != NONCE_OR_HASH_BYTES
            {
                return wire.reject(ProxyError::InvalidMessage);
            }
            Ok(BridgeResponse {
                route: route(value.lease_id, value.generation)?,
                sequence: proxy_sequence,
                value: PeerAnswer {
                    sdp: answer.sdp,
                    dtls_fingerprint_sha256: answer.dtls_fingerprint_sha256,
                },
            })
        }
        Some(privileged_bridge_server_frame::Payload::Error(_)) => {
            wire.reject(ProxyError::Rejected)
        }
        _ => wire.reject(ProxyError::StaleResponse),
    }
}

fn map_candidate_event(
    value: PrivilegedLocalIceCandidate,
) -> Result<(Vec<u8>, u64, ProxyEvent), ProxyError> {
    let candidate = value.candidate.ok_or(ProxyError::InvalidMessage)?;
    Ok((
        value.lease_id,
        value.generation,
        ProxyEvent::LocalIceCandidate(PeerIceCandidate {
            candidate: candidate.candidate,
            sdp_mid: candidate.sdp_mid,
            sdp_m_line_index: candidate.sdp_m_line_index,
        }),
    ))
}

fn map_reliable_event(
    value: PrivilegedReliableInputEvent,
) -> Result<(Vec<u8>, u64, ProxyEvent), ProxyError> {
    if value.encoded_envelope.is_empty() {
        return Err(ProxyError::InvalidMessage);
    }
    Ok((
        value.lease_id,
        value.generation,
        ProxyEvent::ReliableInput(value.encoded_envelope),
    ))
}

fn map_fast_event(
    value: PrivilegedFastPointerEvent,
) -> Result<(Vec<u8>, u64, ProxyEvent), ProxyError> {
    if value.encoded_envelope.is_empty() {
        return Err(ProxyError::InvalidMessage);
    }
    Ok((
        value.lease_id,
        value.generation,
        ProxyEvent::FastPointer(value.encoded_envelope),
    ))
}

fn to_candidate(candidate: &PeerIceCandidate) -> IceCandidate {
    IceCandidate {
        candidate: candidate.candidate.clone(),
        sdp_mid: candidate.sdp_mid.clone(),
        sdp_m_line_index: candidate.sdp_m_line_index,
    }
}

fn to_input(input: ValidatedInput<'_>) -> privileged_input_command::Input {
    match input {
        ValidatedInput::Keyboard(action, usb_hid_usage, modifier_bits) => {
            privileged_input_command::Input::Keyboard(KeyboardEvent {
                action: action as i32,
                usb_hid_usage,
                modifier_bits,
            })
        }
        ValidatedInput::PointerButton(button, action, x, y) => {
            privileged_input_command::Input::PointerButton(PointerButtonEvent {
                button: button as i32,
                action: action as i32,
                x,
                y,
            })
        }
        ValidatedInput::PointerMove(x, y, pressed_button_bits) => {
            privileged_input_command::Input::PointerMove(PointerMoveEvent {
                x,
                y,
                pressed_button_bits,
            })
        }
        ValidatedInput::PointerScroll(delta_x, delta_y) => {
            privileged_input_command::Input::PointerScroll(PointerScrollEvent { delta_x, delta_y })
        }
        ValidatedInput::Text(text) => privileged_input_command::Input::Text(TextInputEvent {
            text: text.to_owned(),
        }),
        ValidatedInput::ReleaseAll => {
            privileged_input_command::Input::ReleaseAll(ReleaseAllInput {})
        }
    }
}

fn route(lease_id: Vec<u8>, generation: u64) -> Result<crate::proxy::ProxyRoute, ProxyError> {
    let bytes: [u8; 16] = lease_id
        .try_into()
        .map_err(|_| ProxyError::InvalidMessage)?;
    if generation == 0 {
        return Err(ProxyError::InvalidMessage);
    }
    Ok(crate::proxy::ProxyRoute::new(
        crate::lease::LeaseId::new(bytes),
        generation,
    ))
}

fn request_id(route: ProxyRoute, frame_sequence: u64) -> String {
    format!(
        "{REQUEST_ID_PREFIX}-{}-{}",
        route.generation, frame_sequence
    )
}

const fn version() -> ProtocolVersion {
    ProtocolVersion {
        major: PROTOCOL_MAJOR_VERSION,
        minor: MINIMUM_PROTOCOL_MINOR_VERSION,
    }
}

fn valid_version(version: Option<&ProtocolVersion>) -> bool {
    version.is_some_and(|value| {
        value.major == PROTOCOL_MAJOR_VERSION
            && value
                .minor
                .checked_sub(MINIMUM_PROTOCOL_MINOR_VERSION)
                .is_some()
    })
}

fn validate_controller_display_name(value: &str) -> Result<(), ProxyError> {
    if value.is_empty()
        || value.len() > MAX_DEVICE_NAME_UTF8_BYTES
        || value.chars().any(char::is_control)
    {
        Err(ProxyError::InvalidConfiguration)
    } else {
        Ok(())
    }
}

fn parse_dtls_sha256_fingerprint(sdp: &str) -> Option<Vec<u8>> {
    let encoded = sdp.lines().find_map(|line| {
        let value = line.trim_end_matches('\r').strip_prefix("a=fingerprint:")?;
        let (algorithm, fingerprint) = value.split_once(' ')?;
        algorithm
            .eq_ignore_ascii_case("sha-256")
            .then_some(fingerprint)
    })?;
    let parts = encoded.split(':').collect::<Vec<_>>();
    if parts.len() != NONCE_OR_HASH_BYTES || parts.iter().any(|part| part.len() != 2) {
        return None;
    }
    parts
        .into_iter()
        .map(|part| u8::from_str_radix(part, 16).ok())
        .collect()
}
