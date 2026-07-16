// SPDX-License-Identifier: AGPL-3.0-only

package service

import (
	"bytes"
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	"github.com/MisakiHCL/roammand/services/signaling/internal/safelog"
	"github.com/MisakiHCL/roammand/services/signaling/internal/testclient"
	"github.com/coder/websocket"
)

func TestWSSIntegrationPairingSessionDisconnectAndReconnect(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	server := New(ctx, safelog.Discard(), DefaultOptions())
	httpServer := httptest.NewTLSServer(server.Handler())
	t.Cleanup(func() {
		httpServer.Close()
		shutdownContext, shutdownCancel := context.WithTimeout(context.Background(), time.Second)
		defer shutdownCancel()
		if err := server.Shutdown(shutdownContext); err != nil {
			t.Errorf("shutdown: %v", err)
		}
	})

	wssURL := "wss" + strings.TrimPrefix(httpServer.URL, "https") + "/v1/connect"
	host := dialIntegrationClient(t, wssURL, httpServer.Client())
	controller := dialIntegrationClient(t, wssURL, httpServer.Client())
	hostID := testDeviceBytes(40)
	controllerID := testDeviceBytes(41)
	registerIntegrationClient(t, host, hostID, "register-host")
	registerIntegrationClient(t, controller, controllerID, "register-controller")

	presence, err := controller.QueryPresence(testContext(t), hostID, "presence-host")
	if err != nil || !presence.GetOnline() {
		t.Fatalf("host presence = (%+v, %v)", presence, err)
	}

	rendezvousID := testRendezvousBytes(40)
	mustSendIntegrationFrame(t, host, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       "create",
		Payload: &roammandv1.SignalingClientFrame_CreateRendezvous{
			CreateRendezvous: &roammandv1.CreatePairingRendezvous{
				RendezvousId: rendezvousID,
				Kind:         roammandv1.PairingRendezvousKind_PAIRING_RENDEZVOUS_KIND_QR,
			},
		},
	})
	if created := mustReadIntegrationFrame(t, host).GetRendezvousCreated(); created == nil {
		t.Fatal("rendezvous creation response missing")
	}
	mustSendIntegrationFrame(t, controller, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       "join",
		Payload: &roammandv1.SignalingClientFrame_JoinRendezvous{
			JoinRendezvous: &roammandv1.JoinPairingRendezvous{
				Lookup: &roammandv1.JoinPairingRendezvous_RendezvousId{
					RendezvousId: rendezvousID,
				},
			},
		},
	})
	if joined := mustReadIntegrationFrame(t, controller).GetRendezvousJoined(); joined == nil {
		t.Fatal("controller join response missing")
	}
	if joined := mustReadIntegrationFrame(t, host).GetRendezvousJoined(); joined == nil {
		t.Fatal("host join notification missing")
	}

	hostPairing := []byte{0xff, 0x00, 0x71, 0x01}
	mustRelayPairingIntegration(t, host, rendezvousID, hostPairing, "pair-host")
	assertIntegrationPairing(t, mustReadIntegrationFrame(t, controller), hostID, hostPairing)
	controllerPairing := []byte("opaque-controller-pairing")
	mustRelayPairingIntegration(t, controller, rendezvousID, controllerPairing, "pair-controller")
	assertIntegrationPairing(t, mustReadIntegrationFrame(t, host), controllerID, controllerPairing)

	mustSendIntegrationFrame(t, host, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       "complete",
		Payload: &roammandv1.SignalingClientFrame_CompleteRendezvous{
			CompleteRendezvous: &roammandv1.CompletePairingRendezvous{
				RendezvousId: rendezvousID,
				Completion:   roammandv1.PairingRendezvousCompletion_PAIRING_RENDEZVOUS_COMPLETION_SUCCEEDED,
			},
		},
	})
	if closed := mustReadIntegrationFrame(t, host).GetRendezvousClosed(); closed == nil {
		t.Fatal("host completion response missing")
	}
	if closed := mustReadIntegrationFrame(t, controller).GetRendezvousClosed(); closed == nil {
		t.Fatal("controller completion notification missing")
	}

	firstSession := []byte("opaque-session-before-reconnect")
	mustRelaySessionIntegration(t, controller, hostID, firstSession, "session-first")
	assertIntegrationSession(t, mustReadIntegrationFrame(t, host), controllerID, firstSession)

	if err := host.Close(websocket.StatusNormalClosure, ""); err != nil {
		t.Fatal(err)
	}
	waitFor(t, time.Second, func() bool { return server.PresenceCount() == 1 })
	presence, err = controller.QueryPresence(testContext(t), hostID, "presence-offline")
	if err != nil || presence.GetOnline() {
		t.Fatalf("offline host presence = (%+v, %v)", presence, err)
	}

	reconnectedHost := dialIntegrationClient(t, wssURL, httpServer.Client())
	registerIntegrationClient(t, reconnectedHost, hostID, "register-host-reconnected")
	secondSession := []byte("opaque-session-after-reconnect")
	mustRelaySessionIntegration(t, controller, hostID, secondSession, "session-second")
	assertIntegrationSession(t, mustReadIntegrationFrame(t, reconnectedHost), controllerID, secondSession)
}

func dialIntegrationClient(t *testing.T, endpoint string, httpClient *http.Client) *testclient.Client {
	t.Helper()
	client, err := testclient.Dial(testContext(t), endpoint, httpClient)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = client.CloseNow() })
	return client
}

func registerIntegrationClient(t *testing.T, client *testclient.Client, deviceID []byte, requestID string) {
	t.Helper()
	registered, err := client.Register(testContext(t), deviceID, requestID)
	if err != nil || !bytes.Equal(registered.GetDeviceId(), deviceID) {
		t.Fatalf("register = (%+v, %v)", registered, err)
	}
}

func mustRelayPairingIntegration(
	t *testing.T,
	client *testclient.Client,
	rendezvousID []byte,
	opaque []byte,
	requestID string,
) {
	t.Helper()
	mustSendIntegrationFrame(t, client, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       requestID,
		Payload: &roammandv1.SignalingClientFrame_RelayPairing{
			RelayPairing: &roammandv1.RelayPairingEnvelope{
				RendezvousId:   rendezvousID,
				OpaqueEnvelope: opaque,
			},
		},
	})
}

func mustRelaySessionIntegration(
	t *testing.T,
	client *testclient.Client,
	recipientID []byte,
	opaque []byte,
	requestID string,
) {
	t.Helper()
	mustSendIntegrationFrame(t, client, &roammandv1.SignalingClientFrame{
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

func mustSendIntegrationFrame(t *testing.T, client *testclient.Client, frame *roammandv1.SignalingClientFrame) {
	t.Helper()
	if err := client.Send(testContext(t), frame); err != nil {
		t.Fatal(err)
	}
}

func mustReadIntegrationFrame(t *testing.T, client *testclient.Client) *roammandv1.SignalingServerFrame {
	t.Helper()
	frame, err := client.Read(testContext(t))
	if err != nil {
		t.Fatal(err)
	}
	return frame
}

func assertIntegrationPairing(t *testing.T, frame *roammandv1.SignalingServerFrame, sender, opaque []byte) {
	t.Helper()
	routed := frame.GetRoutedPairing()
	if routed == nil || !bytes.Equal(routed.GetSenderDeviceId(), sender) || !bytes.Equal(routed.GetOpaqueEnvelope(), opaque) {
		t.Fatalf("routed pairing = %+v", routed)
	}
}

func assertIntegrationSession(t *testing.T, frame *roammandv1.SignalingServerFrame, sender, opaque []byte) {
	t.Helper()
	routed := frame.GetRoutedSession()
	if routed == nil || !bytes.Equal(routed.GetSenderDeviceId(), sender) || !bytes.Equal(routed.GetOpaqueEnvelope(), opaque) {
		t.Fatalf("routed session = %+v", routed)
	}
}

func testContext(t *testing.T) context.Context {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	t.Cleanup(cancel)
	return ctx
}
