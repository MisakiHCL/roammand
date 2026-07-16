// SPDX-License-Identifier: Apache-2.0

package validation

import (
	"fmt"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	"google.golang.org/protobuf/proto"
)

type ErrorCode string

const (
	ErrorMessageTooLarge        ErrorCode = "message_too_large"
	ErrorInvalidProtocolVersion ErrorCode = "invalid_protocol_version"
	ErrorMissingPayload         ErrorCode = "missing_payload"
	ErrorInvalidLength          ErrorCode = "invalid_length"
	ErrorInvalidEnum            ErrorCode = "invalid_enum"
	ErrorInvalidState           ErrorCode = "invalid_state"
	ErrorInvalidUTF8Length      ErrorCode = "invalid_utf8_length"
	ErrorInvalidLifetime        ErrorCode = "invalid_lifetime"
	ErrorDuplicateValue         ErrorCode = "duplicate_value"
)

type ValidationError struct {
	Code ErrorCode
}

func (e *ValidationError) Error() string {
	return fmt.Sprintf("protocol validation: %s", e.Code)
}

func DecodeAndValidateSignalingEnvelope(encoded []byte) (*roammandv1.SignalingEnvelope, error) {
	if err := validateEncodedLength(encoded, MaxSignalingEnvelopeBytes); err != nil {
		return nil, err
	}
	envelope := &roammandv1.SignalingEnvelope{}
	if err := proto.Unmarshal(encoded, envelope); err != nil {
		return nil, newError(ErrorInvalidLength)
	}
	if err := validateSignalingEnvelope(envelope); err != nil {
		return nil, err
	}
	return envelope, nil
}

func DecodeAndValidateReliableInputEnvelope(encoded []byte) (*roammandv1.ReliableInputEnvelope, error) {
	if err := validateEncodedLength(encoded, MaxReliableInputEnvelopeBytes); err != nil {
		return nil, err
	}
	envelope := &roammandv1.ReliableInputEnvelope{}
	if err := proto.Unmarshal(encoded, envelope); err != nil {
		return nil, newError(ErrorInvalidLength)
	}
	if err := validateProtocolVersion(envelope.ProtocolVersion); err != nil {
		return nil, err
	}
	if envelope.Event == nil {
		return nil, newError(ErrorMissingPayload)
	}
	if err := validateLength(envelope.SessionId, SessionIDBytes); err != nil {
		return nil, err
	}
	if err := validateReliableEvent(envelope); err != nil {
		return nil, err
	}
	return envelope, nil
}

func DecodeAndValidatePointerFastEnvelope(encoded []byte) (*roammandv1.PointerFastEnvelope, error) {
	if err := validateEncodedLength(encoded, MaxPointerFastEnvelopeBytes); err != nil {
		return nil, err
	}
	envelope := &roammandv1.PointerFastEnvelope{}
	if err := proto.Unmarshal(encoded, envelope); err != nil {
		return nil, newError(ErrorInvalidLength)
	}
	if err := validateProtocolVersion(envelope.ProtocolVersion); err != nil {
		return nil, err
	}
	if envelope.Event == nil {
		return nil, newError(ErrorMissingPayload)
	}
	if err := validateLength(envelope.SessionId, SessionIDBytes); err != nil {
		return nil, err
	}
	return envelope, nil
}

func DecodeAndValidatePrivilegedBridgeClientFrame(encoded []byte) (*roammandv1.PrivilegedBridgeClientFrame, error) {
	if err := validateEncodedLength(encoded, MaxPrivilegedBridgeFrameBytes); err != nil {
		return nil, err
	}
	frame := &roammandv1.PrivilegedBridgeClientFrame{}
	if err := proto.Unmarshal(encoded, frame); err != nil {
		return nil, newError(ErrorInvalidLength)
	}
	if err := validatePrivilegedBridgeFrameHeader(frame.ProtocolVersion, frame.RequestId, frame.Sequence); err != nil {
		return nil, err
	}
	if frame.Payload == nil {
		return nil, newError(ErrorMissingPayload)
	}
	return frame, nil
}

func DecodeAndValidatePrivilegedBridgeServerFrame(encoded []byte) (*roammandv1.PrivilegedBridgeServerFrame, error) {
	if err := validateEncodedLength(encoded, MaxPrivilegedBridgeFrameBytes); err != nil {
		return nil, err
	}
	frame := &roammandv1.PrivilegedBridgeServerFrame{}
	if err := proto.Unmarshal(encoded, frame); err != nil {
		return nil, newError(ErrorInvalidLength)
	}
	if err := validatePrivilegedBridgeFrameHeader(frame.ProtocolVersion, frame.RequestId, frame.Sequence); err != nil {
		return nil, err
	}
	if frame.Payload == nil {
		return nil, newError(ErrorMissingPayload)
	}
	return frame, nil
}

func ValidatePrivilegedBridgeStatusSnapshot(snapshot *roammandv1.PrivilegedBridgeStatusSnapshot) error {
	if snapshot == nil {
		return newError(ErrorMissingPayload)
	}
	if err := validateEnum(int32(snapshot.State), roammandv1.PrivilegedBridgeState_name); err != nil {
		return err
	}
	if err := validateUTF8Length(snapshot.ActiveControllerDisplayName, MaxDeviceNameUTF8Bytes); err != nil {
		return err
	}

	switch snapshot.State {
	case roammandv1.PrivilegedBridgeState_PRIVILEGED_BRIDGE_STATE_NOT_INSTALLED,
		roammandv1.PrivilegedBridgeState_PRIVILEGED_BRIDGE_STATE_APPROVAL_REQUIRED,
		roammandv1.PrivilegedBridgeState_PRIVILEGED_BRIDGE_STATE_PERMISSION_REQUIRED,
		roammandv1.PrivilegedBridgeState_PRIVILEGED_BRIDGE_STATE_USER_SESSION_ONLY:
		if snapshot.InteractiveSession != nil || snapshot.HelperConnected ||
			snapshot.ActiveControllerDisplayName != "" || snapshot.Error != nil {
			return newError(ErrorInvalidState)
		}
	case roammandv1.PrivilegedBridgeState_PRIVILEGED_BRIDGE_STATE_READY:
		if err := validatePrivilegedSessionDescriptor(snapshot.InteractiveSession); err != nil {
			return err
		}
		if !snapshot.HelperConnected || snapshot.ActiveControllerDisplayName != "" || snapshot.Error != nil {
			return newError(ErrorInvalidState)
		}
	case roammandv1.PrivilegedBridgeState_PRIVILEGED_BRIDGE_STATE_TRANSITIONING:
		if snapshot.InteractiveSession != nil {
			if err := validatePrivilegedSessionDescriptor(snapshot.InteractiveSession); err != nil {
				return err
			}
		}
		if snapshot.Error != nil {
			return newError(ErrorInvalidState)
		}
	case roammandv1.PrivilegedBridgeState_PRIVILEGED_BRIDGE_STATE_CONTROLLED:
		if err := validatePrivilegedSessionDescriptor(snapshot.InteractiveSession); err != nil {
			return err
		}
		if !snapshot.HelperConnected || snapshot.ActiveControllerDisplayName == "" || snapshot.Error != nil {
			return newError(ErrorInvalidState)
		}
	case roammandv1.PrivilegedBridgeState_PRIVILEGED_BRIDGE_STATE_FAILED:
		if snapshot.HelperConnected || snapshot.ActiveControllerDisplayName != "" || snapshot.Error == nil {
			return newError(ErrorInvalidState)
		}
		return validateUnifiedError(snapshot.Error)
	default:
		return newError(ErrorInvalidEnum)
	}
	return nil
}

func ValidateSessionStatus(status *roammandv1.SessionStatus) error {
	if status == nil {
		return newError(ErrorMissingPayload)
	}
	if len(status.SessionId) != 0 && len(status.SessionId) != SessionIDBytes {
		return newError(ErrorInvalidLength)
	}
	if err := validateEnum(int32(status.State), roammandv1.SessionState_name); err != nil {
		return err
	}

	switch status.State {
	case roammandv1.SessionState_SESSION_STATE_IDLE:
		if len(status.SessionId) != 0 || status.Error != nil {
			return newError(ErrorInvalidState)
		}
	case roammandv1.SessionState_SESSION_STATE_SIGNALING,
		roammandv1.SessionState_SESSION_STATE_AUTHENTICATING,
		roammandv1.SessionState_SESSION_STATE_CONNECTING,
		roammandv1.SessionState_SESSION_STATE_CONNECTED,
		roammandv1.SessionState_SESSION_STATE_RECONNECTING,
		roammandv1.SessionState_SESSION_STATE_CLOSING:
		if err := validateLength(status.SessionId, SessionIDBytes); err != nil {
			return err
		}
		if status.Error != nil {
			return newError(ErrorInvalidState)
		}
	case roammandv1.SessionState_SESSION_STATE_FAILED:
		if err := validateLength(status.SessionId, SessionIDBytes); err != nil {
			return err
		}
		if status.Error == nil {
			return newError(ErrorInvalidState)
		}
		return validateUnifiedError(status.Error)
	default:
		return newError(ErrorInvalidEnum)
	}
	return nil
}

func ValidateRemoteSessionStatusSnapshot(snapshot *roammandv1.RemoteSessionStatusSnapshot) error {
	if snapshot == nil || snapshot.SessionStatus == nil {
		return newError(ErrorMissingPayload)
	}
	if err := ValidateSessionStatus(snapshot.SessionStatus); err != nil {
		return err
	}
	if snapshot.SessionStatus.State == roammandv1.SessionState_SESSION_STATE_IDLE {
		if len(snapshot.ControllerDeviceId) != 0 {
			return newError(ErrorInvalidState)
		}
		return nil
	}
	return validateLength(snapshot.ControllerDeviceId, DeviceIDBytes)
}

func ValidateDeviceIdentity(identity *roammandv1.DeviceIdentity) error {
	if identity == nil {
		return newError(ErrorMissingPayload)
	}
	if err := validateLength(identity.DeviceId, DeviceIDBytes); err != nil {
		return err
	}
	if err := validateLength(identity.PublicKey, PublicKeyBytes); err != nil {
		return err
	}
	if identity.PublicKeyAlgorithm != roammandv1.PublicKeyAlgorithm_PUBLIC_KEY_ALGORITHM_ED25519 {
		return newError(ErrorInvalidEnum)
	}
	if err := validateEnum(int32(identity.Platform), roammandv1.DevicePlatform_name); err != nil {
		return err
	}
	return validateUTF8Length(identity.DisplayName, MaxDeviceNameUTF8Bytes)
}

func validateSignalingEnvelope(envelope *roammandv1.SignalingEnvelope) error {
	if err := validateProtocolVersion(envelope.ProtocolVersion); err != nil {
		return err
	}
	if envelope.Payload == nil {
		return newError(ErrorMissingPayload)
	}
	if err := validateLength(envelope.SenderDeviceId, DeviceIDBytes); err != nil {
		return err
	}
	if err := validateLength(envelope.RecipientDeviceId, DeviceIDBytes); err != nil {
		return err
	}
	if err := validateUTF8Length(envelope.RequestId, MaxRequestIDUTF8Bytes); err != nil {
		return err
	}

	switch payload := envelope.Payload.(type) {
	case *roammandv1.SignalingEnvelope_CapabilityNegotiation:
		return validateCapabilityNegotiation(payload.CapabilityNegotiation)
	case *roammandv1.SignalingEnvelope_Pairing:
		return validatePairingMessage(payload.Pairing)
	case *roammandv1.SignalingEnvelope_SessionAuthentication:
		return validateSessionAuthentication(payload.SessionAuthentication)
	case *roammandv1.SignalingEnvelope_WebrtcNegotiation:
		return validateWebRTCNegotiation(payload.WebrtcNegotiation)
	case *roammandv1.SignalingEnvelope_SessionStatus:
		return ValidateSessionStatus(payload.SessionStatus)
	case *roammandv1.SignalingEnvelope_Error:
		return validateUnifiedError(payload.Error)
	default:
		return newError(ErrorMissingPayload)
	}
}

func validateCapabilityNegotiation(negotiation *roammandv1.CapabilityNegotiation) error {
	if negotiation == nil {
		return newError(ErrorMissingPayload)
	}
	if err := validateProtocolVersion(negotiation.ProtocolVersion); err != nil {
		return err
	}
	seen := make(map[int32]struct{})
	values := append(
		append([]roammandv1.Capability(nil), negotiation.RequiredCapabilities...),
		negotiation.OptionalCapabilities...,
	)
	for _, value := range values {
		key := int32(value)
		if err := validateEnum(key, roammandv1.Capability_name); err != nil {
			return err
		}
		if _, exists := seen[key]; exists {
			return newError(ErrorDuplicateValue)
		}
		seen[key] = struct{}{}
	}
	return nil
}

func validatePairingMessage(message *roammandv1.PairingMessage) error {
	if message == nil || message.Payload == nil {
		return newError(ErrorMissingPayload)
	}
	switch payload := message.Payload.(type) {
	case *roammandv1.PairingMessage_QrRendezvous:
		value := payload.QrRendezvous
		if value == nil {
			return newError(ErrorMissingPayload)
		}
		if err := validateLength(value.RendezvousId, RendezvousIDBytes); err != nil {
			return err
		}
		if err := ValidateDeviceIdentity(value.HostIdentity); err != nil {
			return err
		}
		if err := validateLength(value.HostPublicKeyFingerprintSha256, NonceOrHashBytes); err != nil {
			return err
		}
		if err := validateLength(value.HostEphemeralPublicKey, PublicKeyBytes); err != nil {
			return err
		}
		if err := validateUTF8Length(value.SignalingEndpoint, MaxSignalingEndpointUTF8Bytes); err != nil {
			return err
		}
		return validateRendezvousLifetime(value.IssuedAtUnixMs, value.ExpiresAtUnixMs)
	case *roammandv1.PairingMessage_DesktopRendezvous:
		value := payload.DesktopRendezvous
		if value == nil {
			return newError(ErrorMissingPayload)
		}
		if err := validateLength(value.RendezvousId, RendezvousIDBytes); err != nil {
			return err
		}
		if len(value.PairingCode) != DesktopPairingCodeBytes {
			return newError(ErrorInvalidLength)
		}
		for _, character := range []byte(value.PairingCode) {
			if !(character >= 'A' && character <= 'Z') && !(character >= '2' && character <= '7') {
				return newError(ErrorInvalidState)
			}
		}
		if err := ValidateDeviceIdentity(value.HostIdentity); err != nil {
			return err
		}
		if err := validateLength(value.HostEphemeralPublicKey, PublicKeyBytes); err != nil {
			return err
		}
		return validateRendezvousLifetime(value.IssuedAtUnixMs, value.ExpiresAtUnixMs)
	case *roammandv1.PairingMessage_Hello:
		value := payload.Hello
		if value == nil {
			return newError(ErrorMissingPayload)
		}
		if err := validateLength(value.RendezvousId, RendezvousIDBytes); err != nil {
			return err
		}
		if err := ValidateDeviceIdentity(value.Identity); err != nil {
			return err
		}
		return validateLength(value.EphemeralPublicKey, PublicKeyBytes)
	case *roammandv1.PairingMessage_Confirmation:
		return validatePairingConfirmation(payload.Confirmation)
	case *roammandv1.PairingMessage_Decision:
		return validatePairingDecision(payload.Decision)
	case *roammandv1.PairingMessage_HostInvitation:
		return validateHostPairingInvitation(payload.HostInvitation)
	case *roammandv1.PairingMessage_ControllerHello:
		return validateControllerPairingHello(payload.ControllerHello)
	case *roammandv1.PairingMessage_EncryptedEnvelope:
		return validateEncryptedPairingEnvelope(payload.EncryptedEnvelope)
	default:
		return newError(ErrorMissingPayload)
	}
}

func validateHostPairingInvitation(value *roammandv1.HostPairingInvitation) error {
	if value == nil {
		return newError(ErrorMissingPayload)
	}
	if err := validateProtocolVersion(value.ProtocolVersion); err != nil {
		return err
	}
	if err := validateEnum(int32(value.Kind), roammandv1.PairingInvitationKind_name); err != nil {
		return err
	}
	if err := validateLength(value.RendezvousId, RendezvousIDBytes); err != nil {
		return err
	}
	if err := ValidateDeviceIdentity(value.HostIdentity); err != nil {
		return err
	}
	if err := validateLength(value.HostPublicKeyFingerprintSha256, NonceOrHashBytes); err != nil {
		return err
	}
	if err := validateLength(value.HostEphemeralPublicKey, PublicKeyBytes); err != nil {
		return err
	}
	if err := validateUTF8Length(value.SignalingEndpoint, MaxSignalingEndpointUTF8Bytes); err != nil {
		return err
	}
	switch value.Kind {
	case roammandv1.PairingInvitationKind_PAIRING_INVITATION_KIND_QR:
		if value.PairingCode != "" {
			return newError(ErrorInvalidState)
		}
	case roammandv1.PairingInvitationKind_PAIRING_INVITATION_KIND_DESKTOP_CODE:
		if err := validateDesktopPairingCode(value.PairingCode); err != nil {
			return err
		}
	default:
		return newError(ErrorInvalidEnum)
	}
	return validateRendezvousLifetime(value.IssuedAtUnixMs, value.ExpiresAtUnixMs)
}

func validateControllerPairingHello(value *roammandv1.ControllerPairingHello) error {
	if value == nil {
		return newError(ErrorMissingPayload)
	}
	checks := []struct {
		value    []byte
		expected int
	}{
		{value.RendezvousId, RendezvousIDBytes},
		{value.EphemeralPublicKey, PublicKeyBytes},
		{value.TranscriptSha256, NonceOrHashBytes},
		{value.Signature, SignatureBytes},
	}
	for _, check := range checks {
		if err := validateLength(check.value, check.expected); err != nil {
			return err
		}
	}
	return ValidateDeviceIdentity(value.Identity)
}

func validateEncryptedPairingEnvelope(value *roammandv1.EncryptedPairingEnvelope) error {
	if value == nil {
		return newError(ErrorMissingPayload)
	}
	if err := validateProtocolVersion(value.ProtocolVersion); err != nil {
		return err
	}
	if err := validateLength(value.RendezvousId, RendezvousIDBytes); err != nil {
		return err
	}
	if err := validateEnum(int32(value.Direction), roammandv1.PairingDirection_name); err != nil {
		return err
	}
	if value.Sequence == 0 || len(value.Ciphertext) == 0 || len(value.Ciphertext) > MaxPairingCiphertextBytes {
		return newError(ErrorInvalidLength)
	}
	return nil
}

func validateDesktopPairingCode(value string) error {
	if len(value) != DesktopPairingCodeBytes {
		return newError(ErrorInvalidLength)
	}
	for _, character := range []byte(value) {
		if !(character >= 'A' && character <= 'Z') && !(character >= '2' && character <= '7') {
			return newError(ErrorInvalidState)
		}
	}
	return nil
}

func validatePairingConfirmation(value *roammandv1.PairingConfirmationData) error {
	if value == nil {
		return newError(ErrorMissingPayload)
	}
	checks := []struct {
		value    []byte
		expected int
	}{
		{value.ControllerDeviceId, DeviceIDBytes},
		{value.HostDeviceId, DeviceIDBytes},
		{value.RendezvousId, RendezvousIDBytes},
		{value.ControllerIdentityPublicKey, PublicKeyBytes},
		{value.HostIdentityPublicKey, PublicKeyBytes},
		{value.ControllerEphemeralPublicKey, PublicKeyBytes},
		{value.HostEphemeralPublicKey, PublicKeyBytes},
		{value.TranscriptSha256, NonceOrHashBytes},
	}
	for _, check := range checks {
		if err := validateLength(check.value, check.expected); err != nil {
			return err
		}
	}
	return nil
}

func validatePairingDecision(value *roammandv1.PairingDecision) error {
	if value == nil {
		return newError(ErrorMissingPayload)
	}
	if err := validateEnum(int32(value.Status), roammandv1.PairingDecisionStatus_name); err != nil {
		return err
	}
	if value.Controller != nil {
		if err := ValidateDeviceIdentity(value.Controller); err != nil {
			return err
		}
	}
	if value.Confirmation != nil {
		if err := validatePairingConfirmation(value.Confirmation); err != nil {
			return err
		}
	}
	if value.Grant != nil {
		return validateControllerGrant(value.Grant)
	}
	return nil
}

func validateControllerGrant(value *roammandv1.ControllerGrant) error {
	if err := validateLength(value.GrantId, RendezvousIDBytes); err != nil {
		return err
	}
	if err := validateLength(value.HostDeviceId, DeviceIDBytes); err != nil {
		return err
	}
	if err := ValidateDeviceIdentity(value.Controller); err != nil {
		return err
	}
	return validatePermissions(value.Permissions)
}

func validateSessionAuthentication(authentication *roammandv1.SessionAuthentication) error {
	if authentication == nil || authentication.Payload == nil {
		return newError(ErrorMissingPayload)
	}
	switch payload := authentication.Payload.(type) {
	case *roammandv1.SessionAuthentication_Offer:
		value := payload.Offer
		return validateSessionAuthBase(value.ControllerDeviceId, value.HostDeviceId, value.SessionId,
			value.Nonce, value.IssuedAtUnixMs, value.ExpiresAtUnixMs, value.RequestedPermissions,
			value.OfferSha256, value.ControllerDtlsFingerprintSha256, value.Signature)
	case *roammandv1.SessionAuthentication_Answer:
		value := payload.Answer
		if err := validateSessionAuthBase(value.ControllerDeviceId, value.HostDeviceId, value.SessionId,
			value.Nonce, value.IssuedAtUnixMs, value.ExpiresAtUnixMs, value.RequestedPermissions,
			value.OfferSha256, value.ControllerDtlsFingerprintSha256, value.Signature); err != nil {
			return err
		}
		if err := validateLength(value.AnswerSha256, NonceOrHashBytes); err != nil {
			return err
		}
		return validateLength(value.HostDtlsFingerprintSha256, NonceOrHashBytes)
	case *roammandv1.SessionAuthentication_Reconnect:
		value := payload.Reconnect
		if err := validateSessionAuthBase(value.ControllerDeviceId, value.HostDeviceId, value.SessionId,
			value.Nonce, value.IssuedAtUnixMs, value.ExpiresAtUnixMs, value.RequestedPermissions,
			value.OfferSha256, value.ControllerDtlsFingerprintSha256, value.Signature); err != nil {
			return err
		}
		if err := validateLength(value.AnswerSha256, NonceOrHashBytes); err != nil {
			return err
		}
		return validateLength(value.HostDtlsFingerprintSha256, NonceOrHashBytes)
	default:
		return newError(ErrorMissingPayload)
	}
}

func validateSessionAuthBase(controllerID, hostID, sessionID, nonce []byte, issuedAt, expiresAt uint64,
	permissions []roammandv1.SessionPermission, offerHash, controllerFingerprint, signature []byte,
) error {
	checks := []struct {
		value    []byte
		expected int
	}{
		{controllerID, DeviceIDBytes}, {hostID, DeviceIDBytes}, {sessionID, SessionIDBytes},
		{nonce, NonceOrHashBytes}, {offerHash, NonceOrHashBytes},
		{controllerFingerprint, NonceOrHashBytes}, {signature, SignatureBytes},
	}
	for _, check := range checks {
		if err := validateLength(check.value, check.expected); err != nil {
			return err
		}
	}
	if err := validatePermissions(permissions); err != nil {
		return err
	}
	if expiresAt < issuedAt {
		return newError(ErrorInvalidLifetime)
	}
	return nil
}

func validatePermissions(values []roammandv1.SessionPermission) error {
	seen := make(map[int32]struct{})
	for _, value := range values {
		key := int32(value)
		if err := validateEnum(key, roammandv1.SessionPermission_name); err != nil {
			return err
		}
		if _, exists := seen[key]; exists {
			return newError(ErrorDuplicateValue)
		}
		seen[key] = struct{}{}
	}
	return nil
}

func validateWebRTCNegotiation(negotiation *roammandv1.WebRtcNegotiation) error {
	if negotiation == nil || negotiation.Payload == nil {
		return newError(ErrorMissingPayload)
	}
	if err := validateLength(negotiation.SessionId, SessionIDBytes); err != nil {
		return err
	}
	switch payload := negotiation.Payload.(type) {
	case *roammandv1.WebRtcNegotiation_Description:
		if err := validateLength(payload.Description.DtlsFingerprintSha256, NonceOrHashBytes); err != nil {
			return err
		}
		if err := validateEnum(int32(payload.Description.Type), roammandv1.SessionDescriptionType_name); err != nil {
			return err
		}
		return validateUTF8Length(payload.Description.Sdp, MaxSDPUTF8Bytes)
	case *roammandv1.WebRtcNegotiation_IceCandidate:
		if err := validateUTF8Length(payload.IceCandidate.Candidate, MaxICECandidateUTF8Bytes); err != nil {
			return err
		}
		return validateUTF8Length(payload.IceCandidate.SdpMid, MaxSDPMidUTF8Bytes)
	case *roammandv1.WebRtcNegotiation_EndOfCandidates:
		return nil
	default:
		return newError(ErrorMissingPayload)
	}
}

func validateReliableEvent(envelope *roammandv1.ReliableInputEnvelope) error {
	switch value := envelope.Event.(type) {
	case *roammandv1.ReliableInputEnvelope_PointerButton:
		if err := validateEnum(int32(value.PointerButton.Button), roammandv1.PointerButton_name); err != nil {
			return err
		}
		return validateEnum(int32(value.PointerButton.Action), roammandv1.ButtonAction_name)
	case *roammandv1.ReliableInputEnvelope_Keyboard:
		return validateEnum(int32(value.Keyboard.Action), roammandv1.KeyboardAction_name)
	case *roammandv1.ReliableInputEnvelope_Text:
		return validateUTF8Length(value.Text.Text, MaxTextInputUTF8Bytes)
	case *roammandv1.ReliableInputEnvelope_SessionControl:
		return validateEnum(int32(value.SessionControl.Action), roammandv1.SessionControlAction_name)
	case *roammandv1.ReliableInputEnvelope_ReleaseAllInput:
		return nil
	default:
		return newError(ErrorMissingPayload)
	}
}

func validateUnifiedError(value *roammandv1.UnifiedError) error {
	if value == nil {
		return newError(ErrorMissingPayload)
	}
	if err := validateEnum(int32(value.Code), roammandv1.ErrorCode_name); err != nil {
		return err
	}
	if err := validateUTF8Length(value.MessageKey, MaxMessageKeyUTF8Bytes); err != nil {
		return err
	}
	if err := validateUTF8Length(value.RequestId, MaxRequestIDUTF8Bytes); err != nil {
		return err
	}
	switch details := value.Details.(type) {
	case *roammandv1.UnifiedError_Permission:
		return validateUTF8Length(details.Permission.Permission, MaxErrorDetailUTF8Bytes)
	case *roammandv1.UnifiedError_Codec:
		for _, codec := range details.Codec.SupportedCodecs {
			if err := validateUTF8Length(codec, MaxErrorDetailUTF8Bytes); err != nil {
				return err
			}
		}
	case *roammandv1.UnifiedError_Transport:
		return validateUTF8Length(details.Transport.Transport, MaxErrorDetailUTF8Bytes)
	}
	return nil
}

func validateProtocolVersion(version *roammandv1.ProtocolVersion) error {
	if version == nil || version.Major != ProtocolMajorVersion || version.Minor < MinimumProtocolMinorVersion {
		return newError(ErrorInvalidProtocolVersion)
	}
	return nil
}

func validatePrivilegedBridgeFrameHeader(version *roammandv1.ProtocolVersion, requestID string, sequence uint64) error {
	if err := validateProtocolVersion(version); err != nil {
		return err
	}
	if err := validateUTF8Length(requestID, MaxRequestIDUTF8Bytes); err != nil {
		return err
	}
	if sequence == 0 {
		return newError(ErrorInvalidState)
	}
	return nil
}

func validatePrivilegedSessionDescriptor(descriptor *roammandv1.PrivilegedSessionDescriptor) error {
	if descriptor == nil {
		return newError(ErrorMissingPayload)
	}
	if descriptor.Platform != roammandv1.DevicePlatform_DEVICE_PLATFORM_WINDOWS &&
		descriptor.Platform != roammandv1.DevicePlatform_DEVICE_PLATFORM_MACOS {
		return newError(ErrorInvalidEnum)
	}
	if err := validateEnum(int32(descriptor.DesktopKind), roammandv1.InteractiveDesktopKind_name); err != nil {
		return err
	}
	if descriptor.OsSessionId == 0 || descriptor.Generation == 0 {
		return newError(ErrorInvalidState)
	}
	return nil
}

func validateEnum(value int32, names map[int32]string) error {
	if value == 0 {
		return newError(ErrorInvalidEnum)
	}
	if _, exists := names[value]; !exists {
		return newError(ErrorInvalidEnum)
	}
	return nil
}

func validateRendezvousLifetime(issuedAt, expiresAt uint64) error {
	if expiresAt < issuedAt || expiresAt-issuedAt > PairingRendezvousLifetimeMS {
		return newError(ErrorInvalidLifetime)
	}
	return nil
}

func validateEncodedLength(encoded []byte, maximum int) error {
	if len(encoded) > maximum {
		return newError(ErrorMessageTooLarge)
	}
	return nil
}

func validateLength(value []byte, expected int) error {
	if len(value) != expected {
		return newError(ErrorInvalidLength)
	}
	return nil
}

func validateUTF8Length(value string, maximum int) error {
	if len([]byte(value)) > maximum {
		return newError(ErrorInvalidUTF8Length)
	}
	return nil
}

func newError(code ErrorCode) error {
	return &ValidationError{Code: code}
}
