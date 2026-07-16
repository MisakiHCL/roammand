// SPDX-License-Identifier: AGPL-3.0-only

package safelog

import (
	"bytes"
	"strings"
	"testing"
	"time"
)

const secretSentinel = "TOKEN_KEY_SDP_CANDIDATE_7829"

func TestLoggerEmitsOnlyTypedFields(t *testing.T) {
	var output bytes.Buffer
	logger := New(&output)
	logger.Event(EventServiceFailed, Fields{
		Code:     CodeInternal,
		Count:    3,
		Duration: 1250 * time.Millisecond,
	})

	encoded := output.String()
	for _, expected := range []string{
		"event=service_failed",
		"code=internal",
		"count=3",
		"duration_ms=1250",
	} {
		if !strings.Contains(encoded, expected) {
			t.Fatalf("safe log %q does not contain %q", encoded, expected)
		}
	}
}

func TestHTTPErrorWriterDropsRawServerText(t *testing.T) {
	var output bytes.Buffer
	logger := New(&output)
	writer := logger.HTTPErrorWriter()
	if _, err := writer.Write([]byte("remote=192.0.2.44 " + secretSentinel)); err != nil {
		t.Fatal(err)
	}

	encoded := output.String()
	if !strings.Contains(encoded, "event=http_server_error") {
		t.Fatalf("safe log = %q", encoded)
	}
	for _, forbidden := range []string{secretSentinel, "192.0.2.44", "remote="} {
		if strings.Contains(encoded, forbidden) {
			t.Fatalf("safe log exposed %q: %q", forbidden, encoded)
		}
	}
}
