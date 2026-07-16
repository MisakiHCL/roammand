// SPDX-License-Identifier: AGPL-3.0-only

package service

import (
	"bytes"
	"testing"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	validation "github.com/MisakiHCL/roammand/gen/go/validation"
	"github.com/coder/websocket"
)

func TestSessionRoutingPreservesOpaqueBytesAndAddsSender(t *testing.T) {
	testServer := newServiceTestServer(t, DefaultOptions())
	controller := testServer.dial(t)
	host := testServer.dial(t)
	controllerID := testDeviceBytes(30)
	hostID := testDeviceBytes(31)
	registerClient(t, controller, controllerID, "register-controller")
	registerClient(t, host, hostID, "register-host")

	opaque := make([]byte, validation.MaxOpaqueSignalingEnvelopeBytes)
	for index := range opaque {
		opaque[index] = byte(index)
	}
	relaySession(t, controller, hostID, opaque, "relay-controller")
	assertRoutedSession(t, readServerFrame(t, host), controllerID, opaque)

	reverse := []byte("arbitrary bytes, not a protobuf message")
	relaySession(t, host, controllerID, reverse, "relay-host")
	assertRoutedSession(t, readServerFrame(t, controller), hostID, reverse)
}

func TestSessionRoutingReturnsOfflineForMissingDevice(t *testing.T) {
	testServer := newServiceTestServer(t, DefaultOptions())
	controller := testServer.dial(t)
	registerClient(t, controller, testDeviceBytes(32), "register-controller")

	relaySession(t, controller, testDeviceBytes(33), []byte{1}, "relay-offline")
	if got := readServerFrame(t, controller).GetError().GetCode(); got != roammandv1.ErrorCode_ERROR_CODE_DEVICE_OFFLINE {
		t.Fatalf("offline code = %v", got)
	}
}

func relaySession(t *testing.T, client *websocket.Conn, recipientID []byte, opaque []byte, requestID string) {
	t.Helper()
	writeClientFrame(t, client, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       requestID,
		Payload: &roammandv1.SignalingClientFrame_RelaySession{
			RelaySession: &roammandv1.RelaySessionEnvelope{
				RecipientDeviceId: recipientID,
				OpaqueEnvelope:    opaque,
			},
		},
	})
}

func assertRoutedSession(
	t *testing.T,
	frame *roammandv1.SignalingServerFrame,
	wantSender []byte,
	wantOpaque []byte,
) {
	t.Helper()
	routed := frame.GetRoutedSession()
	if routed == nil ||
		!bytes.Equal(routed.GetSenderDeviceId(), wantSender) ||
		!bytes.Equal(routed.GetOpaqueEnvelope(), wantOpaque) {
		t.Fatalf("routed session = %+v", routed)
	}
}
