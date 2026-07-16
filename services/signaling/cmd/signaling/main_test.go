// SPDX-License-Identifier: AGPL-3.0-only

package main

import (
	"bytes"
	"context"
	"errors"
	"io"
	"net/http"
	"strings"
	"sync"
	"testing"
	"time"
)

const logSecretSentinel = "PRIVATE_KEY_AND_CONFIG_VALUE_1642"

func TestRunServesHTTPAndStopsGracefully(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	output := newNotifyWriter()
	result := make(chan error, 1)
	go func() {
		result <- run(ctx, mapEnvironment(map[string]string{
			"SIGNALING_LISTEN_ADDR": "127.0.0.1:0",
			"IGNORED_SECRET":        "must-not-be-logged",
		}), output, io.Discard)
	}()

	select {
	case <-output.written:
	case <-time.After(2 * time.Second):
		t.Fatal("server did not report readiness")
	}
	line := strings.TrimSpace(output.String())
	const prefix = "roammand-signaling listening on "
	if !strings.HasPrefix(line, prefix+"ws://127.0.0.1:") || strings.Contains(line, "must-not-be-logged") {
		t.Fatalf("startup output = %q", line)
	}
	endpoint := strings.TrimPrefix(line, prefix)
	healthURL := strings.TrimSuffix(strings.Replace(endpoint, "ws://", "http://", 1), "/v1/connect") + "/healthz"
	client := &http.Client{Timeout: time.Second}
	response, err := client.Get(healthURL)
	if err != nil {
		t.Fatal(err)
	}
	_ = response.Body.Close()
	if response.StatusCode != http.StatusOK {
		t.Fatalf("health status = %d", response.StatusCode)
	}

	cancel()
	select {
	case err := <-result:
		if err != nil {
			t.Fatal(err)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("server did not stop gracefully")
	}
}

func TestRunRejectsIncompleteTLSPairBeforeListening(t *testing.T) {
	err := run(context.Background(), mapEnvironment(map[string]string{
		"SIGNALING_LISTEN_ADDR":   "127.0.0.1:0",
		"SIGNALING_TLS_CERT_FILE": "certificate.pem",
	}), io.Discard, io.Discard)
	if err == nil || !strings.Contains(err.Error(), "SIGNALING_TLS_CERT_FILE and SIGNALING_TLS_KEY_FILE") {
		t.Fatalf("run error = %v", err)
	}
}

func TestRunFailureLogDoesNotExposeRawErrors(t *testing.T) {
	var stderr bytes.Buffer
	writeRunFailure(&stderr, errors.New(logSecretSentinel))

	output := stderr.String()
	if strings.Contains(output, logSecretSentinel) {
		t.Fatalf("startup log exposed raw error: %q", output)
	}
	if !strings.Contains(output, "event=service_failed") {
		t.Fatalf("startup log = %q", output)
	}
}

func mapEnvironment(values map[string]string) func(string) string {
	return func(key string) string { return values[key] }
}

type notifyWriter struct {
	mu      sync.Mutex
	buffer  bytes.Buffer
	written chan struct{}
	once    sync.Once
}

func newNotifyWriter() *notifyWriter {
	return &notifyWriter{written: make(chan struct{})}
}

func (writer *notifyWriter) Write(encoded []byte) (int, error) {
	writer.mu.Lock()
	defer writer.mu.Unlock()
	written, err := writer.buffer.Write(encoded)
	writer.once.Do(func() { close(writer.written) })
	return written, err
}

func (writer *notifyWriter) String() string {
	writer.mu.Lock()
	defer writer.mu.Unlock()
	return writer.buffer.String()
}
