// SPDX-License-Identifier: Apache-2.0

package roammandv1

import "testing"

func TestGeneratedProtocolVersionIsTypeSafe(t *testing.T) {
	version := ProtocolVersion{Major: 1, Minor: 0}

	if version.Major != 1 || version.Minor != 0 {
		t.Fatalf("unexpected protocol version: major=%d minor=%d", version.Major, version.Minor)
	}
}

func TestGeneratedSignalingServiceFramesAreTypeSafe(t *testing.T) {
	deviceID := make([]byte, 32)
	clientFrame := &SignalingClientFrame{
		ProtocolVersion: &ProtocolVersion{Major: 1, Minor: 0},
		RequestId:       "register-1",
		Payload: &SignalingClientFrame_Register{
			Register: &RegisterDevice{DeviceId: deviceID},
		},
	}
	serverFrame := &SignalingServerFrame{
		ProtocolVersion: &ProtocolVersion{Major: 1, Minor: 0},
		RequestId:       clientFrame.RequestId,
		Payload: &SignalingServerFrame_Registered{
			Registered: &RegistrationAccepted{DeviceId: deviceID},
		},
	}

	if got := clientFrame.GetRegister().GetDeviceId(); len(got) != 32 {
		t.Fatalf("registration device ID length = %d, want 32", len(got))
	}
	if got := serverFrame.GetRegistered().GetDeviceId(); len(got) != 32 {
		t.Fatalf("accepted device ID length = %d, want 32", len(got))
	}
}

func TestGeneratedLocalIPCFramesAreTypeSafe(t *testing.T) {
	clientFrame := &LocalIpcClientFrame{
		ProtocolVersion: &ProtocolVersion{Major: 1, Minor: 0},
		RequestId:       "status-1",
		Payload: &LocalIpcClientFrame_GetHostStatus{
			GetHostStatus: &GetHostStatusRequest{},
		},
	}

	if clientFrame.GetGetHostStatus() == nil {
		t.Fatal("local IPC status request is missing")
	}
}

func TestGeneratedRemoteSessionIPCTypesAreRoleSpecific(t *testing.T) {
	request := &LocalIpcClientFrame{
		ProtocolVersion: &ProtocolVersion{Major: 1, Minor: 0},
		RequestId:       "sign-offer-1",
		Payload: &LocalIpcClientFrame_SignSessionOffer{
			SignSessionOffer: &SignSessionOfferRequest{
				CanonicalTranscript: make([]byte, 128),
			},
		},
	}
	signature := &SessionOfferSignature{
		ControllerDeviceId:  make([]byte, 32),
		ControllerPublicKey: make([]byte, 32),
		Signature:           make([]byte, 64),
		TranscriptSha256:    make([]byte, 32),
	}
	snapshot := &RemoteSessionStatusSnapshot{
		SessionStatus: &SessionStatus{State: SessionState_SESSION_STATE_IDLE},
	}

	if request.GetSignSessionOffer() == nil {
		t.Fatal("generated request lost the role-specific offer-signing payload")
	}
	if got := len(signature.GetSignature()); got != 64 {
		t.Fatalf("signature length = %d, want 64", got)
	}
	if snapshot.GetSessionStatus().GetState() != SessionState_SESSION_STATE_IDLE {
		t.Fatal("generated snapshot lost the idle session state")
	}
	_ = &GetRemoteSessionStatusRequest{}
}

func TestGeneratedPairingAndHostTrustTypesAreRoleSpecific(t *testing.T) {
	hello := &ControllerPairingHello{
		RendezvousId:       make([]byte, 16),
		Identity:           &DeviceIdentity{DisplayName: "Controller"},
		EphemeralPublicKey: make([]byte, 32),
		TranscriptSha256:   make([]byte, 32),
		Signature:          make([]byte, 64),
	}
	envelope := &EncryptedPairingEnvelope{
		Direction:  PairingDirection_PAIRING_DIRECTION_CONTROLLER_TO_HOST,
		Sequence:   1,
		Ciphertext: make([]byte, 48),
	}
	request := &LocalIpcClientFrame{
		ProtocolVersion: &ProtocolVersion{Major: 1, Minor: 0},
		RequestId:       "pairing-sign-1",
		Payload: &LocalIpcClientFrame_SignPairingTranscript{
			SignPairingTranscript: &SignPairingTranscriptRequest{
				CanonicalTranscript: make([]byte, 256),
				Role:                PairingIdentityRole_PAIRING_IDENTITY_ROLE_CONTROLLER,
			},
		},
	}
	snapshot := &TrustedHostSnapshot{
		ProtocolVersion: &ProtocolVersion{Major: 1, Minor: 0},
		Bindings:        []*TrustedHostBinding{{}},
	}

	if got := len(hello.GetSignature()); got != 64 {
		t.Fatalf("pairing signature length = %d, want 64", got)
	}
	if envelope.GetSequence() != 1 {
		t.Fatal("pairing envelope lost its sequence")
	}
	if request.GetSignPairingTranscript() == nil {
		t.Fatal("generated request lost the pairing-signature payload")
	}
	if got := len(snapshot.GetBindings()); got != 1 {
		t.Fatalf("binding count = %d, want 1", got)
	}
}
