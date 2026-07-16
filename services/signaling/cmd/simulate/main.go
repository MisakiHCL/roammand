// SPDX-License-Identifier: AGPL-3.0-only

package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"time"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	"github.com/MisakiHCL/roammand/services/signaling/internal/testclient"
)

const (
	defaultEndpoint   = "ws://127.0.0.1:8080/v1/connect"
	simulationTimeout = 15 * time.Second
)

func main() {
	parent, stop := signal.NotifyContext(context.Background(), os.Interrupt)
	defer stop()
	ctx, cancel := context.WithTimeout(parent, simulationTimeout)
	defer cancel()
	endpoint := strings.TrimSpace(os.Getenv("SIGNALING_ENDPOINT"))
	if endpoint == "" {
		endpoint = defaultEndpoint
	}
	if err := run(ctx, endpoint, http.DefaultClient, os.Stdout); err != nil {
		_, _ = fmt.Fprintf(os.Stderr, "simulation failed: %v\n", err)
		os.Exit(1)
	}
}

func run(ctx context.Context, endpoint string, httpClient *http.Client, output io.Writer) error {
	host, err := testclient.Dial(ctx, endpoint, httpClient)
	if err != nil {
		return fmt.Errorf("connect host: %w", err)
	}
	defer host.CloseNow()
	controller, err := testclient.Dial(ctx, endpoint, httpClient)
	if err != nil {
		return fmt.Errorf("connect controller: %w", err)
	}
	defer controller.CloseNow()

	hostID := simulationDeviceID("host")
	controllerID := simulationDeviceID("controller")
	if _, err := host.Register(ctx, hostID, "register-host"); err != nil {
		return fmt.Errorf("register host: %w", err)
	}
	writeStep(output, "host registered")
	if _, err := controller.Register(ctx, controllerID, "register-controller"); err != nil {
		return fmt.Errorf("register controller: %w", err)
	}
	writeStep(output, "controller registered")

	presence, err := controller.QueryPresence(ctx, hostID, "presence-host")
	if err != nil {
		return fmt.Errorf("query host presence: %w", err)
	}
	if !presence.GetOnline() {
		return errors.New("host is not online")
	}
	writeStep(output, "host presence online")

	rendezvousID := simulationRendezvousID()
	if err := host.Send(ctx, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       "create-rendezvous",
		Payload: &roammandv1.SignalingClientFrame_CreateRendezvous{
			CreateRendezvous: &roammandv1.CreatePairingRendezvous{
				RendezvousId: rendezvousID,
				Kind:         roammandv1.PairingRendezvousKind_PAIRING_RENDEZVOUS_KIND_QR,
			},
		},
	}); err != nil {
		return fmt.Errorf("create rendezvous: %w", err)
	}
	created, err := host.Read(ctx)
	if err != nil || created.GetRendezvousCreated() == nil {
		return fmt.Errorf("read rendezvous creation: %w", responseError(err))
	}
	if err := controller.Send(ctx, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       "join-rendezvous",
		Payload: &roammandv1.SignalingClientFrame_JoinRendezvous{
			JoinRendezvous: &roammandv1.JoinPairingRendezvous{
				Lookup: &roammandv1.JoinPairingRendezvous_RendezvousId{
					RendezvousId: rendezvousID,
				},
			},
		},
	}); err != nil {
		return fmt.Errorf("join rendezvous: %w", err)
	}
	controllerJoined, err := controller.Read(ctx)
	if err != nil || controllerJoined.GetRendezvousJoined() == nil {
		return fmt.Errorf("read controller join: %w", responseError(err))
	}
	hostJoined, err := host.Read(ctx)
	if err != nil || hostJoined.GetRendezvousJoined() == nil {
		return fmt.Errorf("read host join: %w", responseError(err))
	}
	writeStep(output, "rendezvous joined")

	hostPairing := []byte{0x00, 0xff, 0x51, 0x01}
	if err := relayPairing(ctx, host, rendezvousID, hostPairing, "pair-host"); err != nil {
		return err
	}
	if err := expectPairing(ctx, controller, hostID, hostPairing); err != nil {
		return err
	}
	controllerPairing := []byte("opaque-controller-pairing")
	if err := relayPairing(ctx, controller, rendezvousID, controllerPairing, "pair-controller"); err != nil {
		return err
	}
	if err := expectPairing(ctx, host, controllerID, controllerPairing); err != nil {
		return err
	}
	writeStep(output, "opaque pairing exchange complete")

	sessionEnvelope := []byte("opaque-session-negotiation")
	if err := controller.Send(ctx, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       "relay-session",
		Payload: &roammandv1.SignalingClientFrame_RelaySession{
			RelaySession: &roammandv1.RelaySessionEnvelope{
				RecipientDeviceId: hostID,
				OpaqueEnvelope:    sessionEnvelope,
			},
		},
	}); err != nil {
		return fmt.Errorf("relay session: %w", err)
	}
	routedSession, err := host.Read(ctx)
	if err != nil {
		return fmt.Errorf("read routed session: %w", err)
	}
	session := routedSession.GetRoutedSession()
	if session == nil || !bytes.Equal(session.GetSenderDeviceId(), controllerID) ||
		!bytes.Equal(session.GetOpaqueEnvelope(), sessionEnvelope) {
		return errors.New("routed session did not preserve sender and opaque bytes")
	}
	writeStep(output, "opaque session route complete")

	if err := host.Send(ctx, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       "complete-rendezvous",
		Payload: &roammandv1.SignalingClientFrame_CompleteRendezvous{
			CompleteRendezvous: &roammandv1.CompletePairingRendezvous{
				RendezvousId: rendezvousID,
				Completion:   roammandv1.PairingRendezvousCompletion_PAIRING_RENDEZVOUS_COMPLETION_SUCCEEDED,
			},
		},
	}); err != nil {
		return fmt.Errorf("complete rendezvous: %w", err)
	}
	for name, client := range map[string]*testclient.Client{"host": host, "controller": controller} {
		frame, readErr := client.Read(ctx)
		if readErr != nil || frame.GetRendezvousClosed() == nil {
			return fmt.Errorf("read %s completion: %w", name, responseError(readErr))
		}
	}
	writeStep(output, "simulation passed")
	return nil
}

func relayPairing(
	ctx context.Context,
	client *testclient.Client,
	rendezvousID []byte,
	opaque []byte,
	requestID string,
) error {
	if err := client.Send(ctx, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       requestID,
		Payload: &roammandv1.SignalingClientFrame_RelayPairing{
			RelayPairing: &roammandv1.RelayPairingEnvelope{
				RendezvousId:   rendezvousID,
				OpaqueEnvelope: opaque,
			},
		},
	}); err != nil {
		return fmt.Errorf("relay pairing: %w", err)
	}
	return nil
}

func expectPairing(ctx context.Context, client *testclient.Client, senderID, opaque []byte) error {
	frame, err := client.Read(ctx)
	if err != nil {
		return fmt.Errorf("read routed pairing: %w", err)
	}
	routed := frame.GetRoutedPairing()
	if routed == nil || !bytes.Equal(routed.GetSenderDeviceId(), senderID) ||
		!bytes.Equal(routed.GetOpaqueEnvelope(), opaque) {
		return errors.New("routed pairing did not preserve sender and opaque bytes")
	}
	return nil
}

func writeStep(output io.Writer, step string) {
	_, _ = fmt.Fprintln(output, step)
}

func responseError(err error) error {
	if err != nil {
		return err
	}
	return errors.New("unexpected signaling response")
}

func simulationDeviceID(role string) []byte {
	digest := sha256.Sum256([]byte("roammand-simulation-device:" + role))
	return digest[:]
}

func simulationRendezvousID() []byte {
	digest := sha256.Sum256([]byte("roammand-simulation-rendezvous"))
	return digest[:16]
}

func protocolVersion() *roammandv1.ProtocolVersion {
	return &roammandv1.ProtocolVersion{Major: 1, Minor: 0}
}
