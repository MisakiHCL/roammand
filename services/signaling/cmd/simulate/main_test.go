// SPDX-License-Identifier: AGPL-3.0-only

package main

import (
	"bytes"
	"context"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/MisakiHCL/roammand/services/signaling/internal/safelog"
	"github.com/MisakiHCL/roammand/services/signaling/internal/service"
)

func TestRunCompletesWSSSimulationWithStableNonSensitiveOutput(t *testing.T) {
	server := service.New(
		context.Background(),
		safelog.Discard(),
		service.DefaultOptions(),
	)
	httpServer := httptest.NewTLSServer(server.Handler())
	defer httpServer.Close()
	defer func() {
		shutdownContext, cancel := context.WithTimeout(context.Background(), time.Second)
		defer cancel()
		if err := server.Shutdown(shutdownContext); err != nil {
			t.Errorf("shutdown: %v", err)
		}
	}()
	endpoint := "wss" + strings.TrimPrefix(httpServer.URL, "https") + "/v1/connect"
	var output bytes.Buffer

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := run(ctx, endpoint, httpServer.Client(), &output); err != nil {
		t.Fatal(err)
	}

	want := strings.Join([]string{
		"host registered",
		"controller registered",
		"host presence online",
		"rendezvous joined",
		"opaque pairing exchange complete",
		"opaque session route complete",
		"simulation passed",
		"",
	}, "\n")
	if got := output.String(); got != want {
		t.Fatalf("output = %q, want %q", got, want)
	}
}
