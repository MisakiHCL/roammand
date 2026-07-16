// SPDX-License-Identifier: Apache-2.0

use std::collections::HashSet;

use prost::Message;

use crate::{
    protocol_limits::{
        DESKTOP_PAIRING_CODE_BYTES, DEVICE_ID_BYTES, EXECUTABLE_SHA256_BYTES,
        MAX_DEVICE_NAME_UTF8_BYTES, MAX_ERROR_DETAIL_UTF8_BYTES, MAX_ICE_CANDIDATE_UTF8_BYTES,
        MAX_MESSAGE_KEY_UTF8_BYTES, MAX_PAIRING_CIPHERTEXT_BYTES, MAX_POINTER_FAST_ENVELOPE_BYTES,
        MAX_PRIVILEGED_BRIDGE_FRAME_BYTES, MAX_PRIVILEGED_ICE_SERVERS,
        MAX_PRIVILEGED_ICE_URLS_PER_SERVER, MAX_RELIABLE_INPUT_ENVELOPE_BYTES,
        MAX_REQUEST_ID_UTF8_BYTES, MAX_SDP_MID_UTF8_BYTES, MAX_SDP_UTF8_BYTES,
        MAX_SIGNALING_ENDPOINT_UTF8_BYTES, MAX_SIGNALING_ENVELOPE_BYTES, MAX_TEXT_INPUT_UTF8_BYTES,
        MINIMUM_PROTOCOL_MINOR_VERSION, NONCE_OR_HASH_BYTES, PAIRING_RENDEZVOUS_LIFETIME_MS,
        PRIVILEGED_BRIDGE_INSTANCE_ID_BYTES, PRIVILEGED_BRIDGE_NONCE_BYTES,
        PRIVILEGED_BRIDGE_PROOF_BYTES, PRIVILEGED_LEASE_ID_BYTES, PROTOCOL_MAJOR_VERSION,
        PUBLIC_KEY_BYTES, RENDEZVOUS_ID_BYTES, SESSION_ID_BYTES, SIGNATURE_BYTES,
    },
    roammand::v1 as proto,
};

#[derive(Debug, Clone, Copy, Eq, PartialEq)]
pub enum ValidationError {
    MessageTooLarge,
    InvalidProtocolVersion,
    MissingPayload,
    InvalidLength,
    InvalidEnum,
    InvalidState,
    InvalidUtf8Length,
    InvalidLifetime,
    DuplicateValue,
}

impl ValidationError {
    #[must_use]
    pub const fn wire_name(self) -> &'static str {
        match self {
            Self::MessageTooLarge => "message_too_large",
            Self::InvalidProtocolVersion => "invalid_protocol_version",
            Self::MissingPayload => "missing_payload",
            Self::InvalidLength => "invalid_length",
            Self::InvalidEnum => "invalid_enum",
            Self::InvalidState => "invalid_state",
            Self::InvalidUtf8Length => "invalid_utf8_length",
            Self::InvalidLifetime => "invalid_lifetime",
            Self::DuplicateValue => "duplicate_value",
        }
    }
}

/// Decodes and validates a signaling envelope at its wire boundary.
///
/// # Errors
///
/// Returns [`ValidationError`] when the encoded message or any nested payload
/// violates the protocol contract.
pub fn decode_and_validate_signaling_envelope(
    encoded: &[u8],
) -> Result<proto::SignalingEnvelope, ValidationError> {
    validate_encoded_length(encoded, MAX_SIGNALING_ENVELOPE_BYTES)?;
    let envelope =
        proto::SignalingEnvelope::decode(encoded).map_err(|_| ValidationError::InvalidLength)?;
    validate_signaling_envelope(&envelope)?;
    Ok(envelope)
}

/// Decodes and validates an `input.reliable` envelope at its wire boundary.
///
/// # Errors
///
/// Returns [`ValidationError`] when the encoded message violates the protocol
/// contract.
pub fn decode_and_validate_reliable_input_envelope(
    encoded: &[u8],
) -> Result<proto::ReliableInputEnvelope, ValidationError> {
    validate_encoded_length(encoded, MAX_RELIABLE_INPUT_ENVELOPE_BYTES)?;
    let envelope = proto::ReliableInputEnvelope::decode(encoded)
        .map_err(|_| ValidationError::InvalidLength)?;
    validate_protocol_version(envelope.protocol_version.as_ref())?;
    let event = envelope
        .event
        .as_ref()
        .ok_or(ValidationError::MissingPayload)?;
    validate_length(&envelope.session_id, SESSION_ID_BYTES)?;
    validate_reliable_event(event)?;
    Ok(envelope)
}

/// Decodes and validates a `pointer.fast` envelope at its wire boundary.
///
/// # Errors
///
/// Returns [`ValidationError`] when the encoded message violates the protocol
/// contract.
pub fn decode_and_validate_pointer_fast_envelope(
    encoded: &[u8],
) -> Result<proto::PointerFastEnvelope, ValidationError> {
    validate_encoded_length(encoded, MAX_POINTER_FAST_ENVELOPE_BYTES)?;
    let envelope =
        proto::PointerFastEnvelope::decode(encoded).map_err(|_| ValidationError::InvalidLength)?;
    validate_protocol_version(envelope.protocol_version.as_ref())?;
    envelope
        .event
        .as_ref()
        .ok_or(ValidationError::MissingPayload)?;
    validate_length(&envelope.session_id, SESSION_ID_BYTES)?;
    Ok(envelope)
}

/// Decodes and validates a privileged-bridge client frame at the local IPC boundary.
///
/// # Errors
///
/// Returns [`ValidationError`] when the frame exceeds its bound or contains an
/// invalid, incomplete, or unknown payload.
pub fn decode_and_validate_privileged_bridge_client_frame(
    encoded: &[u8],
) -> Result<proto::PrivilegedBridgeClientFrame, ValidationError> {
    validate_encoded_length(encoded, MAX_PRIVILEGED_BRIDGE_FRAME_BYTES)?;
    let frame = proto::PrivilegedBridgeClientFrame::decode(encoded)
        .map_err(|_| ValidationError::InvalidLength)?;
    validate_privileged_bridge_frame_header(
        frame.protocol_version.as_ref(),
        &frame.request_id,
        frame.sequence,
    )?;
    let payload = frame
        .payload
        .as_ref()
        .ok_or(ValidationError::MissingPayload)?;
    validate_privileged_bridge_client_payload(payload)?;
    Ok(frame)
}

/// Decodes and validates a privileged-bridge server frame at the local IPC boundary.
///
/// # Errors
///
/// Returns [`ValidationError`] when the frame exceeds its bound or contains an
/// invalid, incomplete, or unknown payload.
pub fn decode_and_validate_privileged_bridge_server_frame(
    encoded: &[u8],
) -> Result<proto::PrivilegedBridgeServerFrame, ValidationError> {
    validate_encoded_length(encoded, MAX_PRIVILEGED_BRIDGE_FRAME_BYTES)?;
    let frame = proto::PrivilegedBridgeServerFrame::decode(encoded)
        .map_err(|_| ValidationError::InvalidLength)?;
    validate_privileged_bridge_frame_header(
        frame.protocol_version.as_ref(),
        &frame.request_id,
        frame.sequence,
    )?;
    let payload = frame
        .payload
        .as_ref()
        .ok_or(ValidationError::MissingPayload)?;
    validate_privileged_bridge_server_payload(payload)?;
    Ok(frame)
}

/// Validates the state-dependent public view of the privileged session bridge.
///
/// # Errors
///
/// Returns [`ValidationError`] for unknown enums or contradictory status fields.
pub fn validate_privileged_bridge_status_snapshot(
    snapshot: &proto::PrivilegedBridgeStatusSnapshot,
) -> Result<(), ValidationError> {
    let state = proto::PrivilegedBridgeState::try_from(snapshot.state)
        .map_err(|_| ValidationError::InvalidEnum)?;
    if state == proto::PrivilegedBridgeState::Unspecified {
        return Err(ValidationError::InvalidEnum);
    }
    validate_utf8_length(
        &snapshot.active_controller_display_name,
        MAX_DEVICE_NAME_UTF8_BYTES,
    )?;

    match state {
        proto::PrivilegedBridgeState::NotInstalled
        | proto::PrivilegedBridgeState::ApprovalRequired
        | proto::PrivilegedBridgeState::PermissionRequired
        | proto::PrivilegedBridgeState::UserSessionOnly => {
            if snapshot.interactive_session.is_some()
                || snapshot.helper_connected
                || !snapshot.active_controller_display_name.is_empty()
                || snapshot.error.is_some()
            {
                return Err(ValidationError::InvalidState);
            }
        }
        proto::PrivilegedBridgeState::Ready => {
            validate_privileged_session_descriptor(
                snapshot
                    .interactive_session
                    .as_ref()
                    .ok_or(ValidationError::MissingPayload)?,
            )?;
            if !snapshot.helper_connected
                || !snapshot.active_controller_display_name.is_empty()
                || snapshot.error.is_some()
            {
                return Err(ValidationError::InvalidState);
            }
        }
        proto::PrivilegedBridgeState::Transitioning => {
            if let Some(session) = &snapshot.interactive_session {
                validate_privileged_session_descriptor(session)?;
            }
            if snapshot.error.is_some() {
                return Err(ValidationError::InvalidState);
            }
        }
        proto::PrivilegedBridgeState::Controlled => {
            validate_privileged_session_descriptor(
                snapshot
                    .interactive_session
                    .as_ref()
                    .ok_or(ValidationError::MissingPayload)?,
            )?;
            if !snapshot.helper_connected
                || snapshot.active_controller_display_name.is_empty()
                || snapshot.error.is_some()
            {
                return Err(ValidationError::InvalidState);
            }
        }
        proto::PrivilegedBridgeState::Failed => {
            if snapshot.helper_connected || !snapshot.active_controller_display_name.is_empty() {
                return Err(ValidationError::InvalidState);
            }
            validate_unified_error(
                snapshot
                    .error
                    .as_ref()
                    .ok_or(ValidationError::MissingPayload)?,
            )?;
        }
        proto::PrivilegedBridgeState::Unspecified => {
            return Err(ValidationError::InvalidEnum);
        }
    }
    Ok(())
}

/// Validates the state-dependent fields of a session status.
///
/// # Errors
///
/// Returns [`ValidationError`] for unknown states, invalid identifiers, or an
/// error/state combination that is not allowed.
pub fn validate_session_status(status: &proto::SessionStatus) -> Result<(), ValidationError> {
    if !status.session_id.is_empty() && status.session_id.len() != SESSION_ID_BYTES {
        return Err(ValidationError::InvalidLength);
    }
    let state =
        proto::SessionState::try_from(status.state).map_err(|_| ValidationError::InvalidEnum)?;
    if state == proto::SessionState::Unspecified {
        return Err(ValidationError::InvalidEnum);
    }

    match state {
        proto::SessionState::Idle => {
            if !status.session_id.is_empty() || status.error.is_some() {
                return Err(ValidationError::InvalidState);
            }
        }
        proto::SessionState::Signaling
        | proto::SessionState::Authenticating
        | proto::SessionState::Connecting
        | proto::SessionState::Connected
        | proto::SessionState::Reconnecting
        | proto::SessionState::Closing => {
            validate_length(&status.session_id, SESSION_ID_BYTES)?;
            if status.error.is_some() {
                return Err(ValidationError::InvalidState);
            }
        }
        proto::SessionState::Failed => {
            validate_length(&status.session_id, SESSION_ID_BYTES)?;
            validate_unified_error(status.error.as_ref().ok_or(ValidationError::InvalidState)?)?;
        }
        proto::SessionState::Unspecified => return Err(ValidationError::InvalidEnum),
    }
    Ok(())
}

/// Validates the sanitized local view of a remote session.
///
/// # Errors
///
/// Returns [`ValidationError`] when the nested status is invalid or its peer
/// binding does not match the idle/active state.
pub fn validate_remote_session_status_snapshot(
    snapshot: &proto::RemoteSessionStatusSnapshot,
) -> Result<(), ValidationError> {
    let status = snapshot
        .session_status
        .as_ref()
        .ok_or(ValidationError::MissingPayload)?;
    validate_session_status(status)?;
    let state =
        proto::SessionState::try_from(status.state).map_err(|_| ValidationError::InvalidEnum)?;
    if state == proto::SessionState::Idle {
        if snapshot.controller_device_id.is_empty() {
            Ok(())
        } else {
            Err(ValidationError::InvalidState)
        }
    } else {
        validate_length(&snapshot.controller_device_id, DEVICE_ID_BYTES)
    }
}

/// Validates a device's fixed-length identity material and public enums.
///
/// # Errors
///
/// Returns [`ValidationError`] when identity material has an invalid length,
/// enum, or display-name byte length.
pub fn validate_device_identity(identity: &proto::DeviceIdentity) -> Result<(), ValidationError> {
    validate_length(&identity.device_id, DEVICE_ID_BYTES)?;
    validate_length(&identity.public_key, PUBLIC_KEY_BYTES)?;
    if proto::PublicKeyAlgorithm::try_from(identity.public_key_algorithm)
        != Ok(proto::PublicKeyAlgorithm::Ed25519)
    {
        return Err(ValidationError::InvalidEnum);
    }
    validate_nonzero_enum(proto::DevicePlatform::try_from(identity.platform))?;
    validate_utf8_length(&identity.display_name, MAX_DEVICE_NAME_UTF8_BYTES)
}

fn validate_privileged_bridge_frame_header(
    version: Option<&proto::ProtocolVersion>,
    request_id: &str,
    sequence: u64,
) -> Result<(), ValidationError> {
    validate_protocol_version(version)?;
    validate_utf8_length(request_id, MAX_REQUEST_ID_UTF8_BYTES)?;
    if sequence == 0 {
        return Err(ValidationError::InvalidState);
    }
    Ok(())
}

fn validate_privileged_bridge_client_payload(
    payload: &proto::privileged_bridge_client_frame::Payload,
) -> Result<(), ValidationError> {
    use proto::privileged_bridge_client_frame::Payload;

    match payload {
        Payload::Authenticate(value) => {
            validate_nonzero_enum(proto::PrivilegedBridgeRole::try_from(value.role))?;
            validate_length(&value.client_nonce, PRIVILEGED_BRIDGE_NONCE_BYTES)?;
            validate_length(&value.client_proof, PRIVILEGED_BRIDGE_PROOF_BYTES)?;
            validate_length(&value.executable_sha256, EXECUTABLE_SHA256_BYTES)?;
            if value.os_session_id == 0 {
                return Err(ValidationError::InvalidState);
            }
            Ok(())
        }
        Payload::RegisterHelper(value) => validate_privileged_session_descriptor(
            value
                .session
                .as_ref()
                .ok_or(ValidationError::MissingPayload)?,
        ),
        Payload::AcquireLease(value) => {
            validate_length(&value.session_id, SESSION_ID_BYTES)?;
            validate_generation(value.generation)?;
            validate_permissions(&value.permissions)?;
            validate_nonempty_utf8_length(
                &value.controller_display_name,
                MAX_DEVICE_NAME_UTF8_BYTES,
            )
        }
        Payload::RenewLease(value) => {
            validate_privileged_lease_ref(&value.lease_id, value.generation)
        }
        Payload::ReleaseLease(value) => {
            validate_privileged_lease_ref(&value.lease_id, value.generation)
        }
        Payload::StartPeer(value) => validate_privileged_peer_request(
            &value.lease_id,
            value.generation,
            value.configuration.as_ref(),
            value.offer.as_ref(),
            &value.controller_display_name,
        ),
        Payload::RestartPeer(value) => validate_privileged_peer_request(
            &value.lease_id,
            value.generation,
            value.configuration.as_ref(),
            value.offer.as_ref(),
            &value.controller_display_name,
        ),
        Payload::AddIceCandidate(value) => {
            validate_privileged_lease_ref(&value.lease_id, value.generation)?;
            validate_ice_candidate(
                value
                    .candidate
                    .as_ref()
                    .ok_or(ValidationError::MissingPayload)?,
            )
        }
        Payload::SendSecureAttention(value) => {
            validate_privileged_lease_ref(&value.lease_id, value.generation)
        }
        Payload::InputCommand(value) => validate_privileged_input_command(value),
        Payload::ClosePeer(value) => {
            validate_privileged_lease_ref(&value.lease_id, value.generation)
        }
    }
}

fn validate_privileged_bridge_server_payload(
    payload: &proto::privileged_bridge_server_frame::Payload,
) -> Result<(), ValidationError> {
    use proto::privileged_bridge_server_frame::Payload;

    match payload {
        Payload::Challenge(value) => {
            validate_length(
                &value.broker_instance_id,
                PRIVILEGED_BRIDGE_INSTANCE_ID_BYTES,
            )?;
            validate_length(&value.server_nonce, PRIVILEGED_BRIDGE_NONCE_BYTES)
        }
        Payload::Authenticated(value) => {
            validate_length(&value.server_proof, PRIVILEGED_BRIDGE_PROOF_BYTES)
        }
        Payload::HelperRegistered(value) => validate_privileged_session_descriptor(
            value
                .session
                .as_ref()
                .ok_or(ValidationError::MissingPayload)?,
        ),
        Payload::Status(value) => validate_privileged_bridge_status_snapshot(value),
        Payload::Lease(value) => validate_privileged_lease(value),
        Payload::PeerAnswer(value) => {
            validate_privileged_lease_ref(&value.lease_id, value.generation)?;
            validate_session_description(
                value
                    .answer
                    .as_ref()
                    .ok_or(ValidationError::MissingPayload)?,
                proto::SessionDescriptionType::Answer,
            )
        }
        Payload::LocalIceCandidate(value) => {
            validate_privileged_lease_ref(&value.lease_id, value.generation)?;
            validate_ice_candidate(
                value
                    .candidate
                    .as_ref()
                    .ok_or(ValidationError::MissingPayload)?,
            )
        }
        Payload::PeerStateChanged(value) => {
            validate_privileged_lease_ref(&value.lease_id, value.generation)?;
            validate_nonzero_enum(proto::PrivilegedPeerState::try_from(value.state))
        }
        Payload::ReliableInput(value) => {
            validate_privileged_lease_ref(&value.lease_id, value.generation)?;
            validate_encoded_length(&value.encoded_envelope, MAX_RELIABLE_INPUT_ENVELOPE_BYTES)?;
            if value.encoded_envelope.is_empty() {
                return Err(ValidationError::InvalidLength);
            }
            Ok(())
        }
        Payload::FastPointer(value) => {
            validate_privileged_lease_ref(&value.lease_id, value.generation)?;
            validate_encoded_length(&value.encoded_envelope, MAX_POINTER_FAST_ENVELOPE_BYTES)?;
            if value.encoded_envelope.is_empty() {
                return Err(ValidationError::InvalidLength);
            }
            Ok(())
        }
        Payload::CommandAccepted(value) => {
            validate_privileged_lease_ref(&value.lease_id, value.generation)
        }
        Payload::Error(value) => validate_unified_error(value),
    }
}

fn validate_privileged_session_descriptor(
    descriptor: &proto::PrivilegedSessionDescriptor,
) -> Result<(), ValidationError> {
    let platform = proto::DevicePlatform::try_from(descriptor.platform)
        .map_err(|_| ValidationError::InvalidEnum)?;
    if !matches!(
        platform,
        proto::DevicePlatform::Windows | proto::DevicePlatform::Macos
    ) {
        return Err(ValidationError::InvalidEnum);
    }
    validate_nonzero_enum(proto::InteractiveDesktopKind::try_from(
        descriptor.desktop_kind,
    ))?;
    if descriptor.os_session_id == 0 || descriptor.generation == 0 {
        return Err(ValidationError::InvalidState);
    }
    Ok(())
}

fn validate_privileged_lease(value: &proto::PrivilegedLease) -> Result<(), ValidationError> {
    validate_privileged_lease_ref(&value.lease_id, value.generation)?;
    validate_length(&value.session_id, SESSION_ID_BYTES)?;
    validate_permissions(&value.permissions)?;
    validate_nonempty_utf8_length(&value.controller_display_name, MAX_DEVICE_NAME_UTF8_BYTES)?;
    if value.expires_at_unix_ms <= value.issued_at_unix_ms {
        return Err(ValidationError::InvalidLifetime);
    }
    Ok(())
}

fn validate_privileged_lease_ref(lease_id: &[u8], generation: u64) -> Result<(), ValidationError> {
    validate_length(lease_id, PRIVILEGED_LEASE_ID_BYTES)?;
    validate_generation(generation)
}

fn validate_generation(generation: u64) -> Result<(), ValidationError> {
    if generation == 0 {
        return Err(ValidationError::InvalidState);
    }
    Ok(())
}

fn validate_privileged_peer_request(
    lease_id: &[u8],
    generation: u64,
    configuration: Option<&proto::PrivilegedPeerConfiguration>,
    offer: Option<&proto::WebRtcSessionDescription>,
    controller_display_name: &str,
) -> Result<(), ValidationError> {
    validate_privileged_lease_ref(lease_id, generation)?;
    validate_privileged_peer_configuration(configuration.ok_or(ValidationError::MissingPayload)?)?;
    validate_nonempty_utf8_length(controller_display_name, MAX_DEVICE_NAME_UTF8_BYTES)?;
    validate_session_description(
        offer.ok_or(ValidationError::MissingPayload)?,
        proto::SessionDescriptionType::Offer,
    )
}

fn validate_privileged_peer_configuration(
    configuration: &proto::PrivilegedPeerConfiguration,
) -> Result<(), ValidationError> {
    validate_nonzero_enum(proto::PrivilegedIceTransportPolicy::try_from(
        configuration.ice_transport_policy,
    ))?;
    if configuration.ice_servers.len() > MAX_PRIVILEGED_ICE_SERVERS {
        return Err(ValidationError::InvalidLength);
    }
    for server in &configuration.ice_servers {
        if server.urls.is_empty() || server.urls.len() > MAX_PRIVILEGED_ICE_URLS_PER_SERVER {
            return Err(ValidationError::InvalidLength);
        }
        for url in &server.urls {
            validate_nonempty_utf8_length(url, MAX_SIGNALING_ENDPOINT_UTF8_BYTES)?;
        }
        validate_utf8_length(&server.username, MAX_ERROR_DETAIL_UTF8_BYTES)?;
        validate_utf8_length(&server.credential, MAX_ERROR_DETAIL_UTF8_BYTES)?;
    }
    Ok(())
}

fn validate_session_description(
    description: &proto::WebRtcSessionDescription,
    expected_type: proto::SessionDescriptionType,
) -> Result<(), ValidationError> {
    if proto::SessionDescriptionType::try_from(description.r#type) != Ok(expected_type) {
        return Err(ValidationError::InvalidState);
    }
    validate_nonempty_utf8_length(&description.sdp, MAX_SDP_UTF8_BYTES)?;
    validate_length(&description.dtls_fingerprint_sha256, NONCE_OR_HASH_BYTES)
}

fn validate_ice_candidate(candidate: &proto::IceCandidate) -> Result<(), ValidationError> {
    validate_nonempty_utf8_length(&candidate.candidate, MAX_ICE_CANDIDATE_UTF8_BYTES)?;
    validate_utf8_length(&candidate.sdp_mid, MAX_SDP_MID_UTF8_BYTES)
}

fn validate_privileged_input_command(
    command: &proto::PrivilegedInputCommand,
) -> Result<(), ValidationError> {
    validate_privileged_lease_ref(&command.lease_id, command.generation)?;
    let input = command
        .input
        .as_ref()
        .ok_or(ValidationError::MissingPayload)?;
    match input {
        proto::privileged_input_command::Input::PointerButton(value) => {
            validate_nonzero_enum(proto::PointerButton::try_from(value.button))?;
            validate_nonzero_enum(proto::ButtonAction::try_from(value.action))
        }
        proto::privileged_input_command::Input::Keyboard(value) => {
            validate_nonzero_enum(proto::KeyboardAction::try_from(value.action))
        }
        proto::privileged_input_command::Input::Text(value) => {
            validate_utf8_length(&value.text, MAX_TEXT_INPUT_UTF8_BYTES)
        }
        proto::privileged_input_command::Input::PointerMove(_)
        | proto::privileged_input_command::Input::PointerScroll(_)
        | proto::privileged_input_command::Input::ReleaseAll(_) => Ok(()),
    }
}

fn validate_signaling_envelope(envelope: &proto::SignalingEnvelope) -> Result<(), ValidationError> {
    validate_protocol_version(envelope.protocol_version.as_ref())?;
    let payload = envelope
        .payload
        .as_ref()
        .ok_or(ValidationError::MissingPayload)?;
    validate_length(&envelope.sender_device_id, DEVICE_ID_BYTES)?;
    validate_length(&envelope.recipient_device_id, DEVICE_ID_BYTES)?;
    validate_utf8_length(&envelope.request_id, MAX_REQUEST_ID_UTF8_BYTES)?;

    match payload {
        proto::signaling_envelope::Payload::CapabilityNegotiation(value) => {
            validate_capability_negotiation(value)
        }
        proto::signaling_envelope::Payload::Pairing(value) => validate_pairing_message(value),
        proto::signaling_envelope::Payload::SessionAuthentication(value) => {
            validate_session_authentication(value)
        }
        proto::signaling_envelope::Payload::WebrtcNegotiation(value) => {
            validate_webrtc_negotiation(value)
        }
        proto::signaling_envelope::Payload::SessionStatus(value) => validate_session_status(value),
        proto::signaling_envelope::Payload::Error(value) => validate_unified_error(value),
    }
}

fn validate_capability_negotiation(
    negotiation: &proto::CapabilityNegotiation,
) -> Result<(), ValidationError> {
    validate_protocol_version(negotiation.protocol_version.as_ref())?;
    let mut seen = HashSet::new();
    for value in negotiation
        .required_capabilities
        .iter()
        .chain(&negotiation.optional_capabilities)
    {
        validate_nonzero_enum(proto::Capability::try_from(*value))?;
        if !seen.insert(*value) {
            return Err(ValidationError::DuplicateValue);
        }
    }
    Ok(())
}

fn validate_pairing_message(message: &proto::PairingMessage) -> Result<(), ValidationError> {
    let payload = message
        .payload
        .as_ref()
        .ok_or(ValidationError::MissingPayload)?;
    match payload {
        proto::pairing_message::Payload::QrRendezvous(value) => {
            validate_length(&value.rendezvous_id, RENDEZVOUS_ID_BYTES)?;
            validate_device_identity(
                value
                    .host_identity
                    .as_ref()
                    .ok_or(ValidationError::MissingPayload)?,
            )?;
            validate_length(
                &value.host_public_key_fingerprint_sha256,
                NONCE_OR_HASH_BYTES,
            )?;
            validate_length(&value.host_ephemeral_public_key, PUBLIC_KEY_BYTES)?;
            validate_utf8_length(&value.signaling_endpoint, MAX_SIGNALING_ENDPOINT_UTF8_BYTES)?;
            validate_rendezvous_lifetime(value.issued_at_unix_ms, value.expires_at_unix_ms)
        }
        proto::pairing_message::Payload::DesktopRendezvous(value) => {
            validate_length(&value.rendezvous_id, RENDEZVOUS_ID_BYTES)?;
            if value.pairing_code.len() != DESKTOP_PAIRING_CODE_BYTES {
                return Err(ValidationError::InvalidLength);
            }
            if !value
                .pairing_code
                .bytes()
                .all(|byte| byte.is_ascii_uppercase() || (b'2'..=b'7').contains(&byte))
            {
                return Err(ValidationError::InvalidState);
            }
            validate_device_identity(
                value
                    .host_identity
                    .as_ref()
                    .ok_or(ValidationError::MissingPayload)?,
            )?;
            validate_length(&value.host_ephemeral_public_key, PUBLIC_KEY_BYTES)?;
            validate_rendezvous_lifetime(value.issued_at_unix_ms, value.expires_at_unix_ms)
        }
        proto::pairing_message::Payload::Hello(value) => {
            validate_length(&value.rendezvous_id, RENDEZVOUS_ID_BYTES)?;
            validate_device_identity(
                value
                    .identity
                    .as_ref()
                    .ok_or(ValidationError::MissingPayload)?,
            )?;
            validate_length(&value.ephemeral_public_key, PUBLIC_KEY_BYTES)
        }
        proto::pairing_message::Payload::Confirmation(value) => {
            validate_pairing_confirmation(value)
        }
        proto::pairing_message::Payload::Decision(value) => {
            validate_nonzero_enum(proto::PairingDecisionStatus::try_from(value.status))?;
            if let Some(identity) = &value.controller {
                validate_device_identity(identity)?;
            }
            if let Some(confirmation) = &value.confirmation {
                validate_pairing_confirmation(confirmation)?;
            }
            if let Some(grant) = &value.grant {
                validate_controller_grant(grant)?;
            }
            Ok(())
        }
        proto::pairing_message::Payload::HostInvitation(value) => {
            validate_host_pairing_invitation(value)
        }
        proto::pairing_message::Payload::ControllerHello(value) => {
            validate_controller_pairing_hello(value)
        }
        proto::pairing_message::Payload::EncryptedEnvelope(value) => {
            validate_encrypted_pairing_envelope(value)
        }
    }
}

fn validate_host_pairing_invitation(
    invitation: &proto::HostPairingInvitation,
) -> Result<(), ValidationError> {
    validate_protocol_version(invitation.protocol_version.as_ref())?;
    let kind = proto::PairingInvitationKind::try_from(invitation.kind)
        .map_err(|_| ValidationError::InvalidEnum)?;
    validate_nonzero_enum(proto::PairingInvitationKind::try_from(invitation.kind))?;
    validate_length(&invitation.rendezvous_id, RENDEZVOUS_ID_BYTES)?;
    validate_device_identity(
        invitation
            .host_identity
            .as_ref()
            .ok_or(ValidationError::MissingPayload)?,
    )?;
    validate_length(
        &invitation.host_public_key_fingerprint_sha256,
        NONCE_OR_HASH_BYTES,
    )?;
    validate_length(&invitation.host_ephemeral_public_key, PUBLIC_KEY_BYTES)?;
    validate_utf8_length(
        &invitation.signaling_endpoint,
        MAX_SIGNALING_ENDPOINT_UTF8_BYTES,
    )?;
    match kind {
        proto::PairingInvitationKind::Qr if invitation.pairing_code.is_empty() => {}
        proto::PairingInvitationKind::DesktopCode => {
            validate_desktop_pairing_code(&invitation.pairing_code)?;
        }
        _ => return Err(ValidationError::InvalidState),
    }
    validate_rendezvous_lifetime(invitation.issued_at_unix_ms, invitation.expires_at_unix_ms)
}

fn validate_controller_pairing_hello(
    hello: &proto::ControllerPairingHello,
) -> Result<(), ValidationError> {
    validate_length(&hello.rendezvous_id, RENDEZVOUS_ID_BYTES)?;
    validate_device_identity(
        hello
            .identity
            .as_ref()
            .ok_or(ValidationError::MissingPayload)?,
    )?;
    validate_length(&hello.ephemeral_public_key, PUBLIC_KEY_BYTES)?;
    validate_length(&hello.transcript_sha256, NONCE_OR_HASH_BYTES)?;
    validate_length(&hello.signature, SIGNATURE_BYTES)
}

fn validate_encrypted_pairing_envelope(
    envelope: &proto::EncryptedPairingEnvelope,
) -> Result<(), ValidationError> {
    validate_protocol_version(envelope.protocol_version.as_ref())?;
    validate_length(&envelope.rendezvous_id, RENDEZVOUS_ID_BYTES)?;
    validate_nonzero_enum(proto::PairingDirection::try_from(envelope.direction))?;
    if envelope.sequence == 0
        || envelope.ciphertext.is_empty()
        || envelope.ciphertext.len() > MAX_PAIRING_CIPHERTEXT_BYTES
    {
        return Err(ValidationError::InvalidLength);
    }
    Ok(())
}

fn validate_desktop_pairing_code(code: &str) -> Result<(), ValidationError> {
    if code.len() != DESKTOP_PAIRING_CODE_BYTES {
        return Err(ValidationError::InvalidLength);
    }
    if !code
        .bytes()
        .all(|byte| byte.is_ascii_uppercase() || (b'2'..=b'7').contains(&byte))
    {
        return Err(ValidationError::InvalidState);
    }
    Ok(())
}

fn validate_pairing_confirmation(
    value: &proto::PairingConfirmationData,
) -> Result<(), ValidationError> {
    validate_length(&value.controller_device_id, DEVICE_ID_BYTES)?;
    validate_length(&value.host_device_id, DEVICE_ID_BYTES)?;
    validate_length(&value.rendezvous_id, RENDEZVOUS_ID_BYTES)?;
    validate_length(&value.controller_identity_public_key, PUBLIC_KEY_BYTES)?;
    validate_length(&value.host_identity_public_key, PUBLIC_KEY_BYTES)?;
    validate_length(&value.controller_ephemeral_public_key, PUBLIC_KEY_BYTES)?;
    validate_length(&value.host_ephemeral_public_key, PUBLIC_KEY_BYTES)?;
    validate_length(&value.transcript_sha256, NONCE_OR_HASH_BYTES)
}

fn validate_controller_grant(grant: &proto::ControllerGrant) -> Result<(), ValidationError> {
    validate_length(&grant.grant_id, RENDEZVOUS_ID_BYTES)?;
    validate_length(&grant.host_device_id, DEVICE_ID_BYTES)?;
    validate_device_identity(
        grant
            .controller
            .as_ref()
            .ok_or(ValidationError::MissingPayload)?,
    )?;
    validate_permissions(&grant.permissions)
}

fn validate_session_authentication(
    authentication: &proto::SessionAuthentication,
) -> Result<(), ValidationError> {
    let payload = authentication
        .payload
        .as_ref()
        .ok_or(ValidationError::MissingPayload)?;
    match payload {
        proto::session_authentication::Payload::Offer(value) => validate_session_auth_base(
            &value.controller_device_id,
            &value.host_device_id,
            &value.session_id,
            &value.nonce,
            value.issued_at_unix_ms,
            value.expires_at_unix_ms,
            &value.requested_permissions,
            &value.offer_sha256,
            &value.controller_dtls_fingerprint_sha256,
            &value.signature,
        ),
        proto::session_authentication::Payload::Answer(value) => {
            validate_session_auth_base(
                &value.controller_device_id,
                &value.host_device_id,
                &value.session_id,
                &value.nonce,
                value.issued_at_unix_ms,
                value.expires_at_unix_ms,
                &value.requested_permissions,
                &value.offer_sha256,
                &value.controller_dtls_fingerprint_sha256,
                &value.signature,
            )?;
            validate_length(&value.answer_sha256, NONCE_OR_HASH_BYTES)?;
            validate_length(&value.host_dtls_fingerprint_sha256, NONCE_OR_HASH_BYTES)
        }
        proto::session_authentication::Payload::Reconnect(value) => {
            validate_session_auth_base(
                &value.controller_device_id,
                &value.host_device_id,
                &value.session_id,
                &value.nonce,
                value.issued_at_unix_ms,
                value.expires_at_unix_ms,
                &value.requested_permissions,
                &value.offer_sha256,
                &value.controller_dtls_fingerprint_sha256,
                &value.signature,
            )?;
            validate_length(&value.answer_sha256, NONCE_OR_HASH_BYTES)?;
            validate_length(&value.host_dtls_fingerprint_sha256, NONCE_OR_HASH_BYTES)
        }
    }
}

#[allow(clippy::too_many_arguments)]
fn validate_session_auth_base(
    controller_device_id: &[u8],
    host_device_id: &[u8],
    session_id: &[u8],
    nonce: &[u8],
    issued_at: u64,
    expires_at: u64,
    permissions: &[i32],
    offer_hash: &[u8],
    controller_fingerprint: &[u8],
    signature: &[u8],
) -> Result<(), ValidationError> {
    validate_length(controller_device_id, DEVICE_ID_BYTES)?;
    validate_length(host_device_id, DEVICE_ID_BYTES)?;
    validate_length(session_id, SESSION_ID_BYTES)?;
    validate_length(nonce, NONCE_OR_HASH_BYTES)?;
    validate_length(offer_hash, NONCE_OR_HASH_BYTES)?;
    validate_length(controller_fingerprint, NONCE_OR_HASH_BYTES)?;
    validate_length(signature, SIGNATURE_BYTES)?;
    validate_permissions(permissions)?;
    if expires_at < issued_at {
        return Err(ValidationError::InvalidLifetime);
    }
    Ok(())
}

fn validate_permissions(permissions: &[i32]) -> Result<(), ValidationError> {
    let mut seen = HashSet::new();
    for value in permissions {
        validate_nonzero_enum(proto::SessionPermission::try_from(*value))?;
        if !seen.insert(*value) {
            return Err(ValidationError::DuplicateValue);
        }
    }
    Ok(())
}

fn validate_webrtc_negotiation(
    negotiation: &proto::WebRtcNegotiation,
) -> Result<(), ValidationError> {
    let payload = negotiation
        .payload
        .as_ref()
        .ok_or(ValidationError::MissingPayload)?;
    validate_length(&negotiation.session_id, SESSION_ID_BYTES)?;
    match payload {
        proto::web_rtc_negotiation::Payload::Description(value) => {
            validate_length(&value.dtls_fingerprint_sha256, NONCE_OR_HASH_BYTES)?;
            validate_nonzero_enum(proto::SessionDescriptionType::try_from(value.r#type))?;
            validate_utf8_length(&value.sdp, MAX_SDP_UTF8_BYTES)
        }
        proto::web_rtc_negotiation::Payload::IceCandidate(value) => {
            validate_utf8_length(&value.candidate, MAX_ICE_CANDIDATE_UTF8_BYTES)?;
            validate_utf8_length(&value.sdp_mid, MAX_SDP_MID_UTF8_BYTES)
        }
        proto::web_rtc_negotiation::Payload::EndOfCandidates(_) => Ok(()),
    }
}

fn validate_reliable_event(
    event: &proto::reliable_input_envelope::Event,
) -> Result<(), ValidationError> {
    match event {
        proto::reliable_input_envelope::Event::PointerButton(value) => {
            validate_nonzero_enum(proto::PointerButton::try_from(value.button))?;
            validate_nonzero_enum(proto::ButtonAction::try_from(value.action))
        }
        proto::reliable_input_envelope::Event::Keyboard(value) => {
            validate_nonzero_enum(proto::KeyboardAction::try_from(value.action))
        }
        proto::reliable_input_envelope::Event::Text(value) => {
            validate_utf8_length(&value.text, MAX_TEXT_INPUT_UTF8_BYTES)
        }
        proto::reliable_input_envelope::Event::SessionControl(value) => {
            validate_nonzero_enum(proto::SessionControlAction::try_from(value.action))
        }
        proto::reliable_input_envelope::Event::ReleaseAllInput(_) => Ok(()),
    }
}

fn validate_unified_error(error: &proto::UnifiedError) -> Result<(), ValidationError> {
    validate_nonzero_enum(proto::ErrorCode::try_from(error.code))?;
    validate_utf8_length(&error.message_key, MAX_MESSAGE_KEY_UTF8_BYTES)?;
    validate_utf8_length(&error.request_id, MAX_REQUEST_ID_UTF8_BYTES)?;
    if let Some(details) = &error.details {
        match details {
            proto::unified_error::Details::RetryAfter(_) => {}
            proto::unified_error::Details::Permission(value) => {
                validate_utf8_length(&value.permission, MAX_ERROR_DETAIL_UTF8_BYTES)?;
            }
            proto::unified_error::Details::Codec(value) => {
                for codec in &value.supported_codecs {
                    validate_utf8_length(codec, MAX_ERROR_DETAIL_UTF8_BYTES)?;
                }
            }
            proto::unified_error::Details::Transport(value) => {
                validate_utf8_length(&value.transport, MAX_ERROR_DETAIL_UTF8_BYTES)?;
            }
        }
    }
    Ok(())
}

fn validate_protocol_version(
    version: Option<&proto::ProtocolVersion>,
) -> Result<(), ValidationError> {
    let version = version.ok_or(ValidationError::InvalidProtocolVersion)?;
    if version.major != PROTOCOL_MAJOR_VERSION
        || version
            .minor
            .checked_sub(MINIMUM_PROTOCOL_MINOR_VERSION)
            .is_none()
    {
        return Err(ValidationError::InvalidProtocolVersion);
    }
    Ok(())
}

fn validate_nonzero_enum<T>(value: Result<T, impl Sized>) -> Result<(), ValidationError>
where
    T: Copy + Into<i32>,
{
    let value = value.map_err(|_| ValidationError::InvalidEnum)?;
    if value.into() == 0 {
        return Err(ValidationError::InvalidEnum);
    }
    Ok(())
}

fn validate_rendezvous_lifetime(issued_at: u64, expires_at: u64) -> Result<(), ValidationError> {
    let lifetime = expires_at
        .checked_sub(issued_at)
        .ok_or(ValidationError::InvalidLifetime)?;
    if lifetime > PAIRING_RENDEZVOUS_LIFETIME_MS {
        return Err(ValidationError::InvalidLifetime);
    }
    Ok(())
}

fn validate_encoded_length(encoded: &[u8], maximum: usize) -> Result<(), ValidationError> {
    if encoded.len() > maximum {
        return Err(ValidationError::MessageTooLarge);
    }
    Ok(())
}

fn validate_length(value: &[u8], expected: usize) -> Result<(), ValidationError> {
    if value.len() != expected {
        return Err(ValidationError::InvalidLength);
    }
    Ok(())
}

fn validate_utf8_length(value: &str, maximum: usize) -> Result<(), ValidationError> {
    if value.len() > maximum {
        return Err(ValidationError::InvalidUtf8Length);
    }
    Ok(())
}

fn validate_nonempty_utf8_length(value: &str, maximum: usize) -> Result<(), ValidationError> {
    if value.is_empty() {
        return Err(ValidationError::InvalidLength);
    }
    validate_utf8_length(value, maximum)
}
