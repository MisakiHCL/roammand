// SPDX-License-Identifier: AGPL-3.0-only

package service

import (
	"context"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	"github.com/MisakiHCL/roammand/services/signaling/internal/safelog"
	"github.com/MisakiHCL/roammand/services/signaling/internal/testclient"
)

func TestShutdownClosesConnectionsAndClearsEphemeralState(t *testing.T) {
	options := DefaultOptions()
	options.SweepInterval = 5 * time.Millisecond
	server := New(context.Background(), safelog.Discard(), options)
	httpServer := httptest.NewServer(server.Handler())
	defer httpServer.Close()
	endpoint := "ws" + strings.TrimPrefix(httpServer.URL, "http") + "/v1/connect"

	const clientCount = 8
	clients := make([]*testclient.Client, clientCount)
	for index := range clients {
		clients[index] = dialIntegrationClient(t, endpoint, httpServer.Client())
		registerIntegrationClient(t, clients[index], testDeviceBytes(byte(60+index)), "register")
	}
	if got := server.ActiveConnectionCount(); got != clientCount {
		t.Fatalf("active connections = %d, want %d", got, clientCount)
	}
	mustSendIntegrationFrame(t, clients[0], &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       "create-before-shutdown",
		Payload: &roammandv1.SignalingClientFrame_CreateRendezvous{
			CreateRendezvous: &roammandv1.CreatePairingRendezvous{
				RendezvousId: testRendezvousBytes(60),
				Kind:         roammandv1.PairingRendezvousKind_PAIRING_RENDEZVOUS_KIND_QR,
			},
		},
	})
	if created := mustReadIntegrationFrame(t, clients[0]).GetRendezvousCreated(); created == nil {
		t.Fatal("rendezvous creation response missing")
	}
	if got := server.RendezvousCount(); got != 1 {
		t.Fatalf("rendezvous before shutdown = %d, want 1", got)
	}

	shutdownContext, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := server.Shutdown(shutdownContext); err != nil {
		t.Fatal(err)
	}
	if got := server.ActiveConnectionCount(); got != 0 {
		t.Fatalf("active connections after shutdown = %d", got)
	}
	if got := server.PresenceCount(); got != 0 {
		t.Fatalf("presence after shutdown = %d", got)
	}
	if got := server.RendezvousCount(); got != 0 {
		t.Fatalf("rendezvous after shutdown = %d", got)
	}
}

func TestReconnectLoopLeavesNoRoutes(t *testing.T) {
	server := New(context.Background(), safelog.Discard(), DefaultOptions())
	httpServer := httptest.NewServer(server.Handler())
	endpoint := "ws" + strings.TrimPrefix(httpServer.URL, "http") + "/v1/connect"

	const workers = 4
	const iterations = 10
	var wait sync.WaitGroup
	for worker := 0; worker < workers; worker++ {
		worker := worker
		wait.Add(1)
		go func() {
			defer wait.Done()
			for iteration := 0; iteration < iterations; iteration++ {
				ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
				client, err := testclient.Dial(ctx, endpoint, httpServer.Client())
				if err == nil {
					deviceSeed := byte(100 + worker*iterations + iteration)
					_, err = client.Register(ctx, testDeviceBytes(deviceSeed), "reconnect")
					_ = client.CloseNow()
				}
				cancel()
				if err != nil {
					t.Errorf("worker %d iteration %d: %v", worker, iteration, err)
					return
				}
			}
		}()
	}
	wait.Wait()
	waitFor(t, 2*time.Second, func() bool { return server.PresenceCount() == 0 })

	httpServer.Close()
	shutdownContext, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := server.Shutdown(shutdownContext); err != nil {
		t.Fatal(err)
	}
}
