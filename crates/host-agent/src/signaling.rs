// SPDX-License-Identifier: MPL-2.0

use std::{collections::VecDeque, fmt};

use prost::Message;
use roammand_protocol::{
    protocol_limits::{
        DESKTOP_PAIRING_CODE_BYTES, DEVICE_ID_BYTES, MAX_OPAQUE_SIGNALING_ENVELOPE_BYTES,
        MAX_REQUEST_ID_UTF8_BYTES, MAX_SIGNALING_SERVICE_FRAME_BYTES,
        MINIMUM_PROTOCOL_MINOR_VERSION, PROTOCOL_MAJOR_VERSION, RENDEZVOUS_ID_BYTES,
    },
    roammand::v1::{
        CompletePairingRendezvous, CreatePairingRendezvous, ErrorCode, Heartbeat,
        HeartbeatAcknowledged, PairingRendezvousCompletion, PairingRendezvousKind, ProtocolVersion,
        RegisterDevice, RelayPairingEnvelope, RelaySessionEnvelope, SignalingClientFrame,
        SignalingServerFrame, signaling_client_frame, signaling_server_frame,
    },
};
use thiserror::Error;

mod transport;

pub use transport::{WebSocketSignalingTransport, validate_signaling_endpoint};

#[derive(Clone, Copy, Debug, Eq, Error, PartialEq)]
pub enum SignalingClientError {
    #[error("signaling device identity is invalid")]
    InvalidDeviceId,
    #[error("signaling request identifier is invalid")]
    InvalidRequestId,
    #[error("pairing rendezvous identifier is invalid")]
    InvalidRendezvousId,
    #[error("pairing rendezvous kind is invalid")]
    InvalidPairingKind,
    #[error("desktop pairing code is invalid")]
    InvalidPairingCode,
    #[error("pairing completion is invalid")]
    InvalidPairingCompletion,
    #[error("pairing frame came from an unexpected peer")]
    UnexpectedPairingPeer,
    #[error("signaling client state is invalid")]
    InvalidState,
    #[error("signaling response does not match its request")]
    CorrelationMismatch,
    #[error("signaling frame is too large")]
    FrameTooLarge,
    #[error("opaque signaling envelope is too large")]
    OpaqueEnvelopeTooLarge,
    #[error("signaling frame is malformed")]
    InvalidFrame,
    #[error("signaling protocol version is unsupported")]
    ProtocolUnsupported,
    #[error("signaling payload is unexpected")]
    UnexpectedPayload,
    #[error("signaling error code is invalid")]
    InvalidErrorCode,
    #[error("signaling queue capacity is invalid")]
    InvalidQueueCapacity,
    #[error("signaling queue is full")]
    QueueFull,
    #[error("signaling endpoint is invalid")]
    InvalidEndpoint,
    #[error("plaintext signaling is allowed only on loopback")]
    InsecureEndpoint,
    #[error("signaling endpoint must not contain credentials")]
    EndpointCredentials,
    #[error("signaling WebSocket transport failed")]
    Transport,
    #[error("signaling WebSocket subprotocol was not selected")]
    SubprotocolRequired,
    #[error("signaling WebSocket was closed")]
    Closed,
}

#[derive(Clone, Eq, PartialEq)]
pub enum SignalingEvent {
    Registered {
        presence_expires_at_unix_ms: u64,
    },
    HeartbeatAcknowledged {
        server_time_unix_ms: u64,
        presence_expires_at_unix_ms: u64,
    },
    RoutedSession {
        sender_device_id: Vec<u8>,
        opaque_envelope: Vec<u8>,
    },
    PairingCreated {
        rendezvous_id: Vec<u8>,
        kind: PairingRendezvousKind,
        expires_at_unix_ms: u64,
    },
    PairingJoined {
        rendezvous_id: Vec<u8>,
        peer_device_id: Vec<u8>,
        expires_at_unix_ms: u64,
    },
    RoutedPairing {
        rendezvous_id: Vec<u8>,
        sender_device_id: Vec<u8>,
        opaque_envelope: Vec<u8>,
    },
    PairingClosed {
        rendezvous_id: Vec<u8>,
        completion: PairingRendezvousCompletion,
    },
    RemoteError {
        code: ErrorCode,
        retryable: bool,
    },
}

impl fmt::Debug for SignalingEvent {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        let (kind, opaque_bytes) = match self {
            Self::Registered { .. } => ("registered", 0),
            Self::HeartbeatAcknowledged { .. } => ("heartbeat_acknowledged", 0),
            Self::RoutedSession {
                opaque_envelope, ..
            } => ("routed_session", opaque_envelope.len()),
            Self::PairingCreated { .. } => ("pairing_created", 0),
            Self::PairingJoined { .. } => ("pairing_joined", 0),
            Self::RoutedPairing {
                opaque_envelope, ..
            } => ("routed_pairing", opaque_envelope.len()),
            Self::PairingClosed { .. } => ("pairing_closed", 0),
            Self::RemoteError { .. } => ("remote_error", 0),
        };
        formatter
            .debug_struct("SignalingEvent")
            .field("kind", &kind)
            .field("opaque_bytes", &opaque_bytes)
            .field("sensitive", &"[REDACTED]")
            .finish()
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
enum SignalingState {
    Disconnected,
    Registering { request_id: String },
    Ready,
}

#[derive(Clone, Debug, Eq, PartialEq)]
enum PairingPhase {
    Creating {
        request_id: String,
    },
    Inviting,
    Joined {
        peer_device_id: Vec<u8>,
    },
    Completing {
        request_id: String,
        completion: PairingRendezvousCompletion,
    },
}

#[derive(Clone, Debug, Eq, PartialEq)]
struct ActivePairing {
    rendezvous_id: Vec<u8>,
    kind: PairingRendezvousKind,
    expires_at_unix_ms: u64,
    phase: PairingPhase,
}

pub struct SignalingProtocol {
    device_id: Vec<u8>,
    state: SignalingState,
    pairing: Option<ActivePairing>,
    pending_heartbeat_request_id: Option<String>,
}

impl SignalingProtocol {
    /// Creates the protocol state machine for one local device.
    ///
    /// # Errors
    ///
    /// Returns an error unless the device identifier contains 32 bytes.
    pub fn new(device_id: Vec<u8>) -> Result<Self, SignalingClientError> {
        if device_id.len() != DEVICE_ID_BYTES {
            return Err(SignalingClientError::InvalidDeviceId);
        }
        Ok(Self {
            device_id,
            state: SignalingState::Disconnected,
            pairing: None,
            pending_heartbeat_request_id: None,
        })
    }

    /// Builds the first registration frame for a new WebSocket connection.
    ///
    /// # Errors
    ///
    /// Returns an error for invalid state or request identifier.
    pub fn registration(
        &mut self,
        request_id: &str,
    ) -> Result<SignalingClientFrame, SignalingClientError> {
        if self.state != SignalingState::Disconnected {
            return Err(SignalingClientError::InvalidState);
        }
        validate_request_id(request_id)?;
        self.state = SignalingState::Registering {
            request_id: request_id.to_owned(),
        };
        Ok(client_frame(
            request_id,
            signaling_client_frame::Payload::Register(RegisterDevice {
                device_id: self.device_id.clone(),
            }),
        ))
    }

    /// Builds a session relay frame once registration has succeeded.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized content, invalid identity/request, or
    /// non-ready state.
    pub fn relay_session(
        &self,
        recipient_device_id: Vec<u8>,
        opaque_envelope: Vec<u8>,
        request_id: &str,
    ) -> Result<SignalingClientFrame, SignalingClientError> {
        if opaque_envelope.len() > MAX_OPAQUE_SIGNALING_ENVELOPE_BYTES {
            return Err(SignalingClientError::OpaqueEnvelopeTooLarge);
        }
        if self.state != SignalingState::Ready {
            return Err(SignalingClientError::InvalidState);
        }
        if recipient_device_id.len() != DEVICE_ID_BYTES {
            return Err(SignalingClientError::InvalidDeviceId);
        }
        validate_request_id(request_id)?;
        Ok(client_frame(
            request_id,
            signaling_client_frame::Payload::RelaySession(RelaySessionEnvelope {
                recipient_device_id,
                opaque_envelope,
            }),
        ))
    }

    /// Builds a request for one Host-owned pairing rendezvous.
    ///
    /// # Errors
    ///
    /// Returns an error for invalid state, identifier, kind, code, or request
    /// identifier. Only one rendezvous may be active on a connection.
    pub fn create_pairing(
        &mut self,
        rendezvous_id: Vec<u8>,
        kind: PairingRendezvousKind,
        pairing_code: String,
        request_id: &str,
    ) -> Result<SignalingClientFrame, SignalingClientError> {
        if self.state != SignalingState::Ready || self.pairing.is_some() {
            return Err(SignalingClientError::InvalidState);
        }
        validate_rendezvous_id(&rendezvous_id)?;
        validate_pairing_code(kind, &pairing_code)?;
        validate_request_id(request_id)?;
        self.pairing = Some(ActivePairing {
            rendezvous_id: rendezvous_id.clone(),
            kind,
            expires_at_unix_ms: 0,
            phase: PairingPhase::Creating {
                request_id: request_id.to_owned(),
            },
        });
        Ok(client_frame(
            request_id,
            signaling_client_frame::Payload::CreateRendezvous(CreatePairingRendezvous {
                rendezvous_id,
                kind: kind as i32,
                pairing_code,
            }),
        ))
    }

    /// Relays opaque pairing bytes to the peer bound by the service.
    ///
    /// # Errors
    ///
    /// Returns an error for invalid state, identifiers, request identifiers,
    /// or an oversized opaque envelope.
    pub fn relay_pairing(
        &self,
        rendezvous_id: Vec<u8>,
        opaque_envelope: Vec<u8>,
        request_id: &str,
    ) -> Result<SignalingClientFrame, SignalingClientError> {
        if opaque_envelope.len() > MAX_OPAQUE_SIGNALING_ENVELOPE_BYTES {
            return Err(SignalingClientError::OpaqueEnvelopeTooLarge);
        }
        validate_rendezvous_id(&rendezvous_id)?;
        validate_request_id(request_id)?;
        let Some(active) = self.pairing.as_ref() else {
            return Err(SignalingClientError::InvalidState);
        };
        if self.state != SignalingState::Ready
            || active.rendezvous_id != rendezvous_id
            || !matches!(active.phase, PairingPhase::Joined { .. })
        {
            return Err(SignalingClientError::InvalidState);
        }
        Ok(client_frame(
            request_id,
            signaling_client_frame::Payload::RelayPairing(RelayPairingEnvelope {
                rendezvous_id,
                opaque_envelope,
            }),
        ))
    }

    /// Completes the active Host-owned pairing rendezvous.
    ///
    /// # Errors
    ///
    /// Returns an error for invalid state, identifiers, completion, or request
    /// identifier. A Host may report only success or explicit rejection.
    pub fn complete_pairing(
        &mut self,
        rendezvous_id: Vec<u8>,
        completion: PairingRendezvousCompletion,
        request_id: &str,
    ) -> Result<SignalingClientFrame, SignalingClientError> {
        validate_rendezvous_id(&rendezvous_id)?;
        if !matches!(
            completion,
            PairingRendezvousCompletion::Succeeded | PairingRendezvousCompletion::Rejected
        ) {
            return Err(SignalingClientError::InvalidPairingCompletion);
        }
        validate_request_id(request_id)?;
        let Some(active) = self.pairing.as_mut() else {
            return Err(SignalingClientError::InvalidState);
        };
        if self.state != SignalingState::Ready
            || active.rendezvous_id != rendezvous_id
            || !matches!(
                active.phase,
                PairingPhase::Inviting | PairingPhase::Joined { .. }
            )
        {
            return Err(SignalingClientError::InvalidState);
        }
        active.phase = PairingPhase::Completing {
            request_id: request_id.to_owned(),
            completion,
        };
        Ok(client_frame(
            request_id,
            signaling_client_frame::Payload::CompleteRendezvous(CompletePairingRendezvous {
                rendezvous_id,
                completion: completion as i32,
            }),
        ))
    }

    /// Resets all connection-scoped state after transport disconnection.
    pub fn disconnected(&mut self) {
        self.state = SignalingState::Disconnected;
        self.pairing = None;
        self.pending_heartbeat_request_id = None;
    }

    /// Builds a single-flight heartbeat frame once registration has succeeded.
    ///
    /// # Errors
    ///
    /// Returns an error for invalid state, an outstanding heartbeat, or an
    /// invalid request identifier.
    pub fn heartbeat(
        &mut self,
        request_id: &str,
    ) -> Result<SignalingClientFrame, SignalingClientError> {
        if self.state != SignalingState::Ready || self.pending_heartbeat_request_id.is_some() {
            return Err(SignalingClientError::InvalidState);
        }
        validate_request_id(request_id)?;
        self.pending_heartbeat_request_id = Some(request_id.to_owned());
        Ok(client_frame(
            request_id,
            signaling_client_frame::Payload::Heartbeat(Heartbeat {}),
        ))
    }

    /// Decodes and validates one binary server frame.
    ///
    /// # Errors
    ///
    /// Returns an error for size, protobuf, version, correlation, identity,
    /// enum, state, or payload violations.
    pub fn handle_binary(
        &mut self,
        encoded: &[u8],
    ) -> Result<SignalingEvent, SignalingClientError> {
        if encoded.len() > MAX_SIGNALING_SERVICE_FRAME_BYTES {
            return Err(SignalingClientError::FrameTooLarge);
        }
        let frame = SignalingServerFrame::decode(encoded)
            .map_err(|_| SignalingClientError::InvalidFrame)?;
        let version = frame
            .protocol_version
            .as_ref()
            .ok_or(SignalingClientError::ProtocolUnsupported)?;
        if version.major != PROTOCOL_MAJOR_VERSION {
            return Err(SignalingClientError::ProtocolUnsupported);
        }
        let payload = frame
            .payload
            .ok_or(SignalingClientError::UnexpectedPayload)?;
        match payload {
            signaling_server_frame::Payload::Registered(registered) => {
                let SignalingState::Registering { request_id } = &self.state else {
                    return Err(SignalingClientError::InvalidState);
                };
                if frame.request_id != *request_id {
                    return Err(SignalingClientError::CorrelationMismatch);
                }
                if registered.device_id != self.device_id {
                    return Err(SignalingClientError::InvalidDeviceId);
                }
                self.state = SignalingState::Ready;
                Ok(SignalingEvent::Registered {
                    presence_expires_at_unix_ms: registered.presence_expires_at_unix_ms,
                })
            }
            signaling_server_frame::Payload::HeartbeatAcknowledged(acknowledged) => {
                self.handle_heartbeat_acknowledged(&frame.request_id, acknowledged)
            }
            signaling_server_frame::Payload::RoutedSession(routed) => {
                if self.state != SignalingState::Ready {
                    return Err(SignalingClientError::InvalidState);
                }
                if !frame.request_id.is_empty() || routed.sender_device_id.len() != DEVICE_ID_BYTES
                {
                    return Err(SignalingClientError::InvalidFrame);
                }
                if routed.opaque_envelope.len() > MAX_OPAQUE_SIGNALING_ENVELOPE_BYTES {
                    return Err(SignalingClientError::OpaqueEnvelopeTooLarge);
                }
                Ok(SignalingEvent::RoutedSession {
                    sender_device_id: routed.sender_device_id,
                    opaque_envelope: routed.opaque_envelope,
                })
            }
            signaling_server_frame::Payload::RendezvousCreated(created) => {
                self.handle_pairing_created(&frame.request_id, created)
            }
            signaling_server_frame::Payload::RendezvousJoined(joined) => {
                self.handle_pairing_joined(&frame.request_id, joined)
            }
            signaling_server_frame::Payload::RoutedPairing(routed) => {
                self.handle_routed_pairing(&frame.request_id, routed)
            }
            signaling_server_frame::Payload::RendezvousClosed(closed) => {
                self.handle_pairing_closed(&frame.request_id, closed)
            }
            signaling_server_frame::Payload::Error(error) => {
                if frame.request_id.is_empty() || error.request_id != frame.request_id {
                    return Err(SignalingClientError::CorrelationMismatch);
                }
                validate_request_id(&frame.request_id)?;
                let code = ErrorCode::try_from(error.code)
                    .map_err(|_| SignalingClientError::InvalidErrorCode)?;
                if code == ErrorCode::Unspecified {
                    return Err(SignalingClientError::InvalidErrorCode);
                }
                let clears_pairing = self.pairing.as_ref().is_some_and(|active| {
                    matches!(
                        &active.phase,
                        PairingPhase::Creating { request_id }
                            | PairingPhase::Completing { request_id, .. }
                            if request_id == &frame.request_id
                    )
                });
                if clears_pairing {
                    self.pairing = None;
                }
                Ok(SignalingEvent::RemoteError {
                    code,
                    retryable: error.retryable,
                })
            }
            signaling_server_frame::Payload::PresenceResult(_) => {
                Err(SignalingClientError::UnexpectedPayload)
            }
        }
    }

    fn handle_heartbeat_acknowledged(
        &mut self,
        request_id: &str,
        acknowledged: HeartbeatAcknowledged,
    ) -> Result<SignalingEvent, SignalingClientError> {
        if self.state != SignalingState::Ready {
            return Err(SignalingClientError::InvalidState);
        }
        let expected_request_id = self
            .pending_heartbeat_request_id
            .as_deref()
            .ok_or(SignalingClientError::InvalidState)?;
        if request_id != expected_request_id {
            return Err(SignalingClientError::CorrelationMismatch);
        }
        if acknowledged.server_time_unix_ms == 0
            || acknowledged.presence_expires_at_unix_ms <= acknowledged.server_time_unix_ms
        {
            return Err(SignalingClientError::InvalidFrame);
        }
        self.pending_heartbeat_request_id = None;
        Ok(SignalingEvent::HeartbeatAcknowledged {
            server_time_unix_ms: acknowledged.server_time_unix_ms,
            presence_expires_at_unix_ms: acknowledged.presence_expires_at_unix_ms,
        })
    }

    fn handle_pairing_created(
        &mut self,
        request_id: &str,
        created: roammand_protocol::roammand::v1::PairingRendezvousCreated,
    ) -> Result<SignalingEvent, SignalingClientError> {
        let kind = PairingRendezvousKind::try_from(created.kind)
            .map_err(|_| SignalingClientError::InvalidPairingKind)?;
        if kind == PairingRendezvousKind::Unspecified || created.expires_at_unix_ms == 0 {
            return Err(SignalingClientError::InvalidFrame);
        }
        let Some(active) = self.pairing.as_mut() else {
            return Err(SignalingClientError::InvalidState);
        };
        let PairingPhase::Creating {
            request_id: expected_request_id,
        } = &active.phase
        else {
            return Err(SignalingClientError::InvalidState);
        };
        if request_id != expected_request_id {
            return Err(SignalingClientError::CorrelationMismatch);
        }
        if created.rendezvous_id != active.rendezvous_id || kind != active.kind {
            return Err(SignalingClientError::CorrelationMismatch);
        }
        active.expires_at_unix_ms = created.expires_at_unix_ms;
        active.phase = PairingPhase::Inviting;
        Ok(SignalingEvent::PairingCreated {
            rendezvous_id: created.rendezvous_id,
            kind,
            expires_at_unix_ms: created.expires_at_unix_ms,
        })
    }

    fn handle_pairing_joined(
        &mut self,
        request_id: &str,
        joined: roammand_protocol::roammand::v1::PairingRendezvousJoined,
    ) -> Result<SignalingEvent, SignalingClientError> {
        if !request_id.is_empty() {
            return Err(SignalingClientError::CorrelationMismatch);
        }
        let Some(active) = self.pairing.as_mut() else {
            return Err(SignalingClientError::InvalidState);
        };
        if !matches!(active.phase, PairingPhase::Inviting) {
            return Err(SignalingClientError::InvalidState);
        }
        if joined.rendezvous_id != active.rendezvous_id
            || joined.expires_at_unix_ms != active.expires_at_unix_ms
        {
            return Err(SignalingClientError::CorrelationMismatch);
        }
        if joined.peer_device_id.len() != DEVICE_ID_BYTES || joined.peer_device_id == self.device_id
        {
            return Err(SignalingClientError::UnexpectedPairingPeer);
        }
        active.phase = PairingPhase::Joined {
            peer_device_id: joined.peer_device_id.clone(),
        };
        Ok(SignalingEvent::PairingJoined {
            rendezvous_id: joined.rendezvous_id,
            peer_device_id: joined.peer_device_id,
            expires_at_unix_ms: joined.expires_at_unix_ms,
        })
    }

    fn handle_routed_pairing(
        &self,
        request_id: &str,
        routed: roammand_protocol::roammand::v1::RoutedPairingEnvelope,
    ) -> Result<SignalingEvent, SignalingClientError> {
        if !request_id.is_empty() {
            return Err(SignalingClientError::CorrelationMismatch);
        }
        if routed.opaque_envelope.len() > MAX_OPAQUE_SIGNALING_ENVELOPE_BYTES {
            return Err(SignalingClientError::OpaqueEnvelopeTooLarge);
        }
        let Some(active) = self.pairing.as_ref() else {
            return Err(SignalingClientError::InvalidState);
        };
        let PairingPhase::Joined { peer_device_id } = &active.phase else {
            return Err(SignalingClientError::InvalidState);
        };
        if routed.rendezvous_id != active.rendezvous_id {
            return Err(SignalingClientError::CorrelationMismatch);
        }
        if routed.sender_device_id != *peer_device_id {
            return Err(SignalingClientError::UnexpectedPairingPeer);
        }
        Ok(SignalingEvent::RoutedPairing {
            rendezvous_id: routed.rendezvous_id,
            sender_device_id: routed.sender_device_id,
            opaque_envelope: routed.opaque_envelope,
        })
    }

    fn handle_pairing_closed(
        &mut self,
        request_id: &str,
        closed: roammand_protocol::roammand::v1::PairingRendezvousClosed,
    ) -> Result<SignalingEvent, SignalingClientError> {
        let completion = PairingRendezvousCompletion::try_from(closed.completion)
            .map_err(|_| SignalingClientError::InvalidPairingCompletion)?;
        if completion == PairingRendezvousCompletion::Unspecified {
            return Err(SignalingClientError::InvalidPairingCompletion);
        }
        let Some(active) = self.pairing.as_ref() else {
            return Err(SignalingClientError::InvalidState);
        };
        if closed.rendezvous_id != active.rendezvous_id {
            return Err(SignalingClientError::CorrelationMismatch);
        }
        match &active.phase {
            PairingPhase::Completing {
                request_id: expected_request_id,
                completion: expected_completion,
            } if request_id == expected_request_id && completion == *expected_completion => {}
            PairingPhase::Inviting | PairingPhase::Joined { .. }
                if request_id.is_empty()
                    && matches!(
                        completion,
                        PairingRendezvousCompletion::Expired
                            | PairingRendezvousCompletion::Disconnected
                    ) => {}
            PairingPhase::Completing { .. } => {
                return Err(SignalingClientError::CorrelationMismatch);
            }
            PairingPhase::Creating { .. }
            | PairingPhase::Inviting
            | PairingPhase::Joined { .. } => return Err(SignalingClientError::InvalidState),
        }
        self.pairing = None;
        Ok(SignalingEvent::PairingClosed {
            rendezvous_id: closed.rendezvous_id,
            completion,
        })
    }
}

pub struct SignalingOutbox {
    capacity: usize,
    frames: VecDeque<Vec<u8>>,
}

impl SignalingOutbox {
    /// Creates a bounded signaling frame queue.
    ///
    /// # Errors
    ///
    /// Returns an error when capacity is zero.
    pub fn new(capacity: usize) -> Result<Self, SignalingClientError> {
        if capacity == 0 {
            return Err(SignalingClientError::InvalidQueueCapacity);
        }
        Ok(Self {
            capacity,
            frames: VecDeque::with_capacity(capacity),
        })
    }

    /// Copies a frame into the queue without waiting.
    ///
    /// # Errors
    ///
    /// Returns an error when the frame is too large or the queue is full.
    pub fn try_push(&mut self, frame: Vec<u8>) -> Result<(), SignalingClientError> {
        if frame.len() > MAX_SIGNALING_SERVICE_FRAME_BYTES {
            return Err(SignalingClientError::FrameTooLarge);
        }
        if self.frames.len() >= self.capacity {
            return Err(SignalingClientError::QueueFull);
        }
        self.frames.push_back(frame);
        Ok(())
    }

    pub fn pop(&mut self) -> Option<Vec<u8>> {
        self.frames.pop_front()
    }
}

fn client_frame(
    request_id: &str,
    payload: signaling_client_frame::Payload,
) -> SignalingClientFrame {
    SignalingClientFrame {
        protocol_version: Some(ProtocolVersion {
            major: PROTOCOL_MAJOR_VERSION,
            minor: MINIMUM_PROTOCOL_MINOR_VERSION,
        }),
        request_id: request_id.to_owned(),
        payload: Some(payload),
    }
}

fn validate_request_id(request_id: &str) -> Result<(), SignalingClientError> {
    if request_id.is_empty() || request_id.len() > MAX_REQUEST_ID_UTF8_BYTES {
        return Err(SignalingClientError::InvalidRequestId);
    }
    Ok(())
}

fn validate_rendezvous_id(rendezvous_id: &[u8]) -> Result<(), SignalingClientError> {
    if rendezvous_id.len() != RENDEZVOUS_ID_BYTES {
        return Err(SignalingClientError::InvalidRendezvousId);
    }
    Ok(())
}

fn validate_pairing_code(
    kind: PairingRendezvousKind,
    pairing_code: &str,
) -> Result<(), SignalingClientError> {
    match kind {
        PairingRendezvousKind::Qr if pairing_code.is_empty() => Ok(()),
        PairingRendezvousKind::DesktopCode
            if pairing_code.len() == DESKTOP_PAIRING_CODE_BYTES
                && pairing_code
                    .bytes()
                    .all(|value| value.is_ascii_uppercase() || matches!(value, b'2'..=b'7')) =>
        {
            Ok(())
        }
        PairingRendezvousKind::Qr | PairingRendezvousKind::DesktopCode => {
            Err(SignalingClientError::InvalidPairingCode)
        }
        PairingRendezvousKind::Unspecified => Err(SignalingClientError::InvalidPairingKind),
    }
}
