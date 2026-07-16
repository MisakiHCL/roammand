// SPDX-License-Identifier: Apache-2.0

package validation

import (
	"errors"
	"strings"
	"testing"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	"google.golang.org/protobuf/proto"
)

func TestAcceptsConnectedWith16ByteSessionID(t *testing.T) {
	status := &roammandv1.SessionStatus{
		SessionId: bytesOfLength(16),
		State:     roammandv1.SessionState_SESSION_STATE_CONNECTED,
	}

	if err := ValidateSessionStatus(status); err != nil {
		t.Fatalf("ValidateSessionStatus() error = %v", err)
	}
}

func TestRejectsUnknownNumericSessionState(t *testing.T) {
	status := &roammandv1.SessionStatus{
		SessionId: bytesOfLength(16),
		State:     roammandv1.SessionState(99),
	}

	requireErrorCode(t, ValidateSessionStatus(status), ErrorInvalidEnum)
}

func TestRejectsFailedWithoutUnifiedError(t *testing.T) {
	status := &roammandv1.SessionStatus{
		SessionId: bytesOfLength(16),
		State:     roammandv1.SessionState_SESSION_STATE_FAILED,
	}

	requireErrorCode(t, ValidateSessionStatus(status), ErrorInvalidState)
}

func TestRejectsActiveStateWithout16ByteSessionID(t *testing.T) {
	status := &roammandv1.SessionStatus{
		State: roammandv1.SessionState_SESSION_STATE_CONNECTING,
	}

	requireErrorCode(t, ValidateSessionStatus(status), ErrorInvalidLength)
}

func TestValidatesRemoteSessionStatusPeerBinding(t *testing.T) {
	idle := &roammandv1.RemoteSessionStatusSnapshot{
		SessionStatus: &roammandv1.SessionStatus{
			State: roammandv1.SessionState_SESSION_STATE_IDLE,
		},
	}
	connected := &roammandv1.RemoteSessionStatusSnapshot{
		SessionStatus: &roammandv1.SessionStatus{
			SessionId: bytesOfLength(16),
			State:     roammandv1.SessionState_SESSION_STATE_CONNECTED,
		},
		ControllerDeviceId: bytesOfLength(32),
	}

	if err := ValidateRemoteSessionStatusSnapshot(idle); err != nil {
		t.Fatalf("ValidateRemoteSessionStatusSnapshot(idle) error = %v", err)
	}
	idle.ControllerDeviceId = bytesOfLength(32)
	requireErrorCode(t, ValidateRemoteSessionStatusSnapshot(idle), ErrorInvalidState)
	connected.ControllerDeviceId = bytesOfLength(31)
	requireErrorCode(t, ValidateRemoteSessionStatusSnapshot(connected), ErrorInvalidLength)
}

func TestRejectsOversizedSignalingBeforeDecoding(t *testing.T) {
	_, err := DecodeAndValidateSignalingEnvelope(make([]byte, MaxSignalingEnvelopeBytes+1))
	requireErrorCode(t, err, ErrorMessageTooLarge)
}

func TestRejects129ByteDeviceDisplayName(t *testing.T) {
	identity := validIdentity()
	identity.DisplayName = strings.Repeat("x", 129)

	requireErrorCode(t, ValidateDeviceIdentity(identity), ErrorInvalidUTF8Length)
}

func TestRejectsQRRendezvousLifetimeAboveTwoMinutes(t *testing.T) {
	envelope := validSignalingEnvelope()
	envelope.Payload = &roammandv1.SignalingEnvelope_Pairing{
		Pairing: &roammandv1.PairingMessage{
			Payload: &roammandv1.PairingMessage_QrRendezvous{
				QrRendezvous: &roammandv1.QrPairingRendezvous{
					RendezvousId:                   bytesOfLength(16),
					HostIdentity:                   validIdentity(),
					HostPublicKeyFingerprintSha256: bytesOfLength(32),
					HostEphemeralPublicKey:         bytesOfLength(32),
					SignalingEndpoint:              "wss://signal.example.test",
					IssuedAtUnixMs:                 1_000,
					ExpiresAtUnixMs:                121_001,
				},
			},
		},
	}

	_, err := DecodeAndValidateSignalingEnvelope(marshal(t, envelope))
	requireErrorCode(t, err, ErrorInvalidLifetime)
}

func TestRejectsOversizedReliableInputBeforeDecoding(t *testing.T) {
	_, err := DecodeAndValidateReliableInputEnvelope(make([]byte, MaxReliableInputEnvelopeBytes+1))
	requireErrorCode(t, err, ErrorMessageTooLarge)
}

func TestRejectsOversizedPointerFastBeforeDecoding(t *testing.T) {
	_, err := DecodeAndValidatePointerFastEnvelope(make([]byte, MaxPointerFastEnvelopeBytes+1))
	requireErrorCode(t, err, ErrorMessageTooLarge)
}

func TestRejectsSignalingAndInputEnvelopesWithoutOneofPayloads(t *testing.T) {
	signaling := validSignalingEnvelope()
	reliable := &roammandv1.ReliableInputEnvelope{
		ProtocolVersion: version(),
		SessionId:       bytesOfLength(16),
	}
	pointerFast := &roammandv1.PointerFastEnvelope{
		ProtocolVersion: version(),
		SessionId:       bytesOfLength(16),
	}

	_, err := DecodeAndValidateSignalingEnvelope(marshal(t, signaling))
	requireErrorCode(t, err, ErrorMissingPayload)
	_, err = DecodeAndValidateReliableInputEnvelope(marshal(t, reliable))
	requireErrorCode(t, err, ErrorMissingPayload)
	_, err = DecodeAndValidatePointerFastEnvelope(marshal(t, pointerFast))
	requireErrorCode(t, err, ErrorMissingPayload)
}

func TestAcceptsControlledPrivilegedBridgeStatus(t *testing.T) {
	status := &roammandv1.PrivilegedBridgeStatusSnapshot{
		State:                       roammandv1.PrivilegedBridgeState_PRIVILEGED_BRIDGE_STATE_CONTROLLED,
		InteractiveSession:          validPrivilegedSession(),
		HelperConnected:             true,
		ActiveControllerDisplayName: "My phone",
	}

	if err := ValidatePrivilegedBridgeStatusSnapshot(status); err != nil {
		t.Fatalf("ValidatePrivilegedBridgeStatusSnapshot() error = %v", err)
	}
}

func TestRejectsContradictoryPrivilegedBridgeStatus(t *testing.T) {
	status := &roammandv1.PrivilegedBridgeStatusSnapshot{
		State:              roammandv1.PrivilegedBridgeState_PRIVILEGED_BRIDGE_STATE_READY,
		InteractiveSession: validPrivilegedSession(),
	}

	requireErrorCode(t, ValidatePrivilegedBridgeStatusSnapshot(status), ErrorInvalidState)
}

func TestRejectsOversizedAndUnsequencedPrivilegedBridgeFrames(t *testing.T) {
	_, err := DecodeAndValidatePrivilegedBridgeClientFrame(make([]byte, MaxPrivilegedBridgeFrameBytes+1))
	requireErrorCode(t, err, ErrorMessageTooLarge)

	frame := &roammandv1.PrivilegedBridgeClientFrame{
		ProtocolVersion: version(),
		RequestId:       "lease-1",
		Payload: &roammandv1.PrivilegedBridgeClientFrame_AcquireLease{
			AcquireLease: &roammandv1.AcquirePrivilegedLeaseRequest{
				SessionId:             bytesOfLength(16),
				Generation:            1,
				Permissions:           []roammandv1.SessionPermission{roammandv1.SessionPermission_SESSION_PERMISSION_VIEW_SCREEN},
				ControllerDisplayName: "My phone",
			},
		},
	}

	_, err = DecodeAndValidatePrivilegedBridgeClientFrame(marshal(t, frame))
	requireErrorCode(t, err, ErrorInvalidState)
}

func requireErrorCode(t *testing.T, err error, want ErrorCode) {
	t.Helper()
	var validationError *ValidationError
	if !errors.As(err, &validationError) {
		t.Fatalf("error = %v, want *ValidationError", err)
	}
	if validationError.Code != want {
		t.Fatalf("error code = %q, want %q", validationError.Code, want)
	}
}

func marshal(t *testing.T, message proto.Message) []byte {
	t.Helper()
	encoded, err := proto.Marshal(message)
	if err != nil {
		t.Fatalf("proto.Marshal() error = %v", err)
	}
	return encoded
}

func version() *roammandv1.ProtocolVersion {
	return &roammandv1.ProtocolVersion{Major: 1, Minor: 0}
}

func validIdentity() *roammandv1.DeviceIdentity {
	return &roammandv1.DeviceIdentity{
		DeviceId:           bytesOfLength(32),
		PublicKeyAlgorithm: roammandv1.PublicKeyAlgorithm_PUBLIC_KEY_ALGORITHM_ED25519,
		PublicKey:          bytesOfLength(32),
		DisplayName:        "Host",
		Platform:           roammandv1.DevicePlatform_DEVICE_PLATFORM_MACOS,
	}
}

func validSignalingEnvelope() *roammandv1.SignalingEnvelope {
	return &roammandv1.SignalingEnvelope{
		ProtocolVersion:   version(),
		SenderDeviceId:    bytesOfLength(32),
		RecipientDeviceId: bytesOfLength(32),
		RequestId:         "request-1",
	}
}

func validPrivilegedSession() *roammandv1.PrivilegedSessionDescriptor {
	return &roammandv1.PrivilegedSessionDescriptor{
		Platform:    roammandv1.DevicePlatform_DEVICE_PLATFORM_MACOS,
		OsSessionId: 501,
		DesktopKind: roammandv1.InteractiveDesktopKind_INTERACTIVE_DESKTOP_KIND_NORMAL,
		Generation:  1,
	}
}

func bytesOfLength(length int) []byte {
	return make([]byte, length)
}
