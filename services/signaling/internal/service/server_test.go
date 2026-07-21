// SPDX-License-Identifier: AGPL-3.0-only

package service

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"net/netip"
	"strings"
	"sync"
	"testing"
	"time"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	validation "github.com/MisakiHCL/roammand/gen/go/validation"
	"github.com/MisakiHCL/roammand/services/signaling/internal/config"
	"github.com/MisakiHCL/roammand/services/signaling/internal/safelog"
	"github.com/coder/websocket"
	"google.golang.org/protobuf/proto"
)

func TestHealthz(t *testing.T) {
	testServer := newServiceTestServer(t, DefaultOptions())
	response, err := http.Get(testServer.http.URL + "/healthz")
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	body, err := io.ReadAll(response.Body)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != http.StatusOK || string(body) != "ok\n" {
		t.Fatalf("health response = (%d, %q)", response.StatusCode, body)
	}
	if response.Header.Get("Cache-Control") != "no-store" ||
		response.Header.Get("X-Content-Type-Options") != "nosniff" {
		t.Fatalf("health security headers = %v", response.Header)
	}
}

func TestHealthzRejectsOtherMethodsWithAllowHeader(t *testing.T) {
	testServer := newServiceTestServer(t, DefaultOptions())
	request, err := http.NewRequest(http.MethodPost, testServer.http.URL+"/healthz", nil)
	if err != nil {
		t.Fatal(err)
	}
	response, err := testServer.http.Client().Do(request)
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusMethodNotAllowed ||
		response.Header.Get("Allow") != http.MethodGet {
		t.Fatalf("health response = (%d, allow=%q)", response.StatusCode, response.Header.Get("Allow"))
	}
}

func TestHealthzIsUnavailableAfterShutdownBegins(t *testing.T) {
	testServer := newServiceTestServer(t, DefaultOptions())
	shutdownContext, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	if err := testServer.service.Shutdown(shutdownContext); err != nil {
		t.Fatal(err)
	}
	response, err := testServer.http.Client().Get(testServer.http.URL + "/healthz")
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("health status after shutdown = %d", response.StatusCode)
	}
}

func TestConnectRequiresProtobufSubprotocol(t *testing.T) {
	testServer := newServiceTestServer(t, DefaultOptions())
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	connection, response, err := websocket.Dial(ctx, testServer.websocketURL(), nil)
	if connection != nil {
		_ = connection.CloseNow()
	}
	if err == nil || response == nil || response.StatusCode != http.StatusBadRequest {
		t.Fatalf("Dial = (response=%v, err=%v), want HTTP 400", response, err)
	}
}

func TestConnectAcceptsLegacyProtobufSubprotocol(t *testing.T) {
	testServer := newServiceTestServer(t, DefaultOptions())
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	connection, _, err := websocket.Dial(
		ctx,
		testServer.websocketURL(),
		&websocket.DialOptions{Subprotocols: []string{LegacyWebSocketSubprotocol}},
	)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = connection.CloseNow() })
	if got := connection.Subprotocol(); got != LegacyWebSocketSubprotocol {
		t.Fatalf("subprotocol = %q, want %q", got, LegacyWebSocketSubprotocol)
	}
}

func TestConnectLimitsGlobalConcurrencyAndReleasesCapacity(t *testing.T) {
	options := DefaultOptions()
	options.MaxConnections = 1
	testServer := newServiceTestServer(t, options)
	first := testServer.dial(t)
	waitFor(t, time.Second, func() bool {
		return testServer.service.ActiveConnectionCount() == 1 &&
			testServer.service.connectionCountForIP("203.0.113.10") == 0
	})

	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	second, response, err := websocket.Dial(
		ctx,
		testServer.websocketURL(),
		&websocket.DialOptions{Subprotocols: []string{WebSocketSubprotocol}},
	)
	if response != nil {
		defer response.Body.Close()
	}
	if second != nil {
		_ = second.CloseNow()
	}
	if err == nil || response == nil || response.StatusCode != http.StatusServiceUnavailable {
		t.Fatalf("second Dial = (response=%v, err=%v), want HTTP 503", response, err)
	}

	if err := first.CloseNow(); err != nil {
		t.Fatal(err)
	}
	waitFor(t, time.Second, func() bool {
		return testServer.service.ActiveConnectionCount() == 0 &&
			len(testServer.service.connectionSlots) == 0
	})
	third := testServer.dial(t)
	waitFor(t, time.Second, func() bool {
		return testServer.service.ActiveConnectionCount() == 1
	})
	if err := third.CloseNow(); err != nil {
		t.Fatal(err)
	}
}

func TestConnectLimitsConcurrencyPerSourceIPAndPreservesFairness(t *testing.T) {
	options := DefaultOptions()
	options.MaxConnections = 3
	options.MaxConnectionsPerIP = 1
	options.TrustedProxyCIDRs = []netip.Prefix{netip.MustParsePrefix("127.0.0.0/8")}
	testServer := newServiceTestServer(t, options)
	dialFromIP := func(ip string) (*websocket.Conn, *http.Response, error) {
		ctx, cancel := context.WithTimeout(context.Background(), time.Second)
		defer cancel()
		return websocket.Dial(ctx, testServer.websocketURL(), &websocket.DialOptions{
			Subprotocols: []string{WebSocketSubprotocol},
			HTTPHeader:   http.Header{"X-Real-IP": []string{ip}},
		})
	}

	first, _, err := dialFromIP("203.0.113.10")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = first.CloseNow() })
	blocked, response, err := dialFromIP("203.0.113.10")
	if blocked != nil {
		_ = blocked.CloseNow()
	}
	if response != nil {
		defer response.Body.Close()
	}
	if err == nil || response == nil || response.StatusCode != http.StatusTooManyRequests {
		t.Fatalf("same-IP Dial = (response=%v, err=%v), want HTTP 429", response, err)
	}

	other, _, err := dialFromIP("203.0.113.11")
	if err != nil {
		t.Fatalf("different-IP Dial: %v", err)
	}
	t.Cleanup(func() { _ = other.CloseNow() })
	if err := first.CloseNow(); err != nil {
		t.Fatal(err)
	}
	waitFor(t, time.Second, func() bool {
		return testServer.service.ActiveConnectionCount() == 1 &&
			testServer.service.connectionCountForIP("203.0.113.10") == 0
	})
	replacement, _, err := dialFromIP("203.0.113.10")
	if err != nil {
		t.Fatalf("replacement Dial: %v", err)
	}
	_ = replacement.CloseNow()
}

func TestDefaultOutboundByteBudgetsAreHardBounded(t *testing.T) {
	options := DefaultOptions()
	if options.MaxOutboundBytes != config.DefaultGlobalOutboundByteBudget {
		t.Fatalf("global outbound budget = %d", options.MaxOutboundBytes)
	}
	if options.MaxOutboundBytesPerIP != config.DefaultPerIPOutboundByteBudget {
		t.Fatalf("per-IP outbound budget = %d", options.MaxOutboundBytesPerIP)
	}
	if options.MaxRendezvous != config.DefaultMaxRendezvous {
		t.Fatalf("global rendezvous capacity = %d", options.MaxRendezvous)
	}
	if options.InboundLimits.Window != config.InboundRateLimitWindow ||
		options.InboundLimits.FramesPerConnection != config.InboundFramesPerConnection ||
		options.InboundLimits.BytesPerConnection != config.InboundBytesPerConnection ||
		options.InboundLimits.FramesPerIP != config.InboundFramesPerIP ||
		options.InboundLimits.BytesPerIP != config.InboundBytesPerIP ||
		options.InboundLimits.FramesGlobal != config.InboundFramesGlobal ||
		options.InboundLimits.BytesGlobal != config.InboundBytesGlobal ||
		options.InboundLimits.IPWindowCapacity != config.InboundIPWindowCapacity {
		t.Fatalf("unexpected inbound limits: %+v", options.InboundLimits)
	}
	wantPerConnection := int64(validation.MaxSignalingServiceFrameBytes) *
		config.OutboundFrameBudgetPerConnection
	if options.MaxOutboundBytesPerConnection != wantPerConnection {
		t.Fatalf(
			"per-connection outbound budget = %d, want %d",
			options.MaxOutboundBytesPerConnection,
			wantPerConnection,
		)
	}
	wantInFlightPerConnection := int64(validation.MaxSignalingServiceFrameBytes) +
		config.InboundReadLimitProbeBytes
	if options.MessageReadTimeout != config.MessageReadTimeout ||
		options.MaxInFlightReadBytes != config.DefaultGlobalInFlightReadByteBudget ||
		options.MaxInFlightReadBytesPerIP != config.DefaultPerIPInFlightReadByteBudget ||
		options.MaxInFlightReadBytesPerConnection != wantInFlightPerConnection {
		t.Fatalf("unexpected in-flight read defaults: %+v", options)
	}
}

func TestSourceIPByteBudgetsAreSharedAndReleased(t *testing.T) {
	options := DefaultOptions()
	options.MaxConnectionsPerIP = 2
	options.MaxOutboundBytesPerIP = 8
	options.MaxInFlightReadBytesPerIP = 8
	testServer := newServiceTestServer(t, options)
	const remoteIP = "198.51.100.42"

	first, acquired := testServer.service.acquireIPConnection(remoteIP)
	if !acquired {
		t.Fatal("first source-IP connection was rejected")
	}
	second, acquired := testServer.service.acquireIPConnection(remoteIP)
	if !acquired {
		t.Fatal("second source-IP connection was rejected")
	}
	if !first.outbound.TryReserve(5) || !second.outbound.TryReserve(3) {
		t.Fatal("valid source-IP byte reservations were rejected")
	}
	if second.outbound.TryReserve(1) {
		t.Fatal("source-IP byte budget allowed an over-limit reservation")
	}
	if !first.inFlightRead.TryReserve(5) || !second.inFlightRead.TryReserve(3) {
		t.Fatal("valid source-IP in-flight read reservations were rejected")
	}
	if second.inFlightRead.TryReserve(1) {
		t.Fatal("source-IP in-flight read budget allowed an over-limit reservation")
	}
	if got := testServer.service.outboundBytesForIP(remoteIP); got != 8 {
		t.Fatalf("source-IP outbound bytes = %d, want 8", got)
	}

	// Reservations can outlive the HTTP handler briefly while a socket write is
	// being interrupted, so the source-IP entry remains until both counters hit zero.
	testServer.service.releaseIPConnection(remoteIP)
	testServer.service.releaseIPConnection(remoteIP)
	if got := testServer.service.connectionCountForIP(remoteIP); got != 0 {
		t.Fatalf("source-IP connection count = %d, want 0", got)
	}
	if got := testServer.service.outboundBytesForIP(remoteIP); got != 8 {
		t.Fatalf("source-IP outbound bytes after disconnect = %d, want 8", got)
	}
	if got := testServer.service.inFlightReadBytesForIP(remoteIP); got != 8 {
		t.Fatalf("source-IP in-flight read bytes after disconnect = %d, want 8", got)
	}
	first.outbound.Release(5)
	second.outbound.Release(3)

	testServer.service.sourceIPMu.Lock()
	_, retained := testServer.service.sourceIPs[remoteIP]
	testServer.service.sourceIPMu.Unlock()
	if !retained {
		t.Fatal("source-IP entry was deleted with an active in-flight read reservation")
	}
	first.inFlightRead.Release(5)
	second.inFlightRead.Release(3)

	testServer.service.sourceIPMu.Lock()
	_, retained = testServer.service.sourceIPs[remoteIP]
	testServer.service.sourceIPMu.Unlock()
	if retained {
		t.Fatal("idle source-IP budget entry was retained")
	}
}

func TestRemoteIPTrustsOnlyConfiguredDirectProxy(t *testing.T) {
	trusted := []netip.Prefix{netip.MustParsePrefix("127.0.0.0/8")}
	tests := map[string]struct {
		remote   string
		headers  []string
		trusted  []netip.Prefix
		expected string
	}{
		"trusted proxy": {
			remote: "127.0.0.1:42000", headers: []string{"198.51.100.24"}, trusted: trusted,
			expected: "198.51.100.24",
		},
		"untrusted sender": {
			remote: "203.0.113.9:42000", headers: []string{"198.51.100.24"}, trusted: trusted,
			expected: "203.0.113.9",
		},
		"multiple forwarded values": {
			remote: "127.0.0.1:42000", headers: []string{"198.51.100.24, 203.0.113.4"}, trusted: trusted,
			expected: "127.0.0.1",
		},
		"duplicate forwarded headers": {
			remote: "127.0.0.1:42000", headers: []string{"198.51.100.24", "203.0.113.4"}, trusted: trusted,
			expected: "127.0.0.1",
		},
		"invalid forwarded value": {
			remote: "127.0.0.1:42000", headers: []string{"not-an-ip"}, trusted: trusted,
			expected: "127.0.0.1",
		},
	}
	for name, test := range tests {
		t.Run(name, func(t *testing.T) {
			if actual := remoteIP(test.remote, test.headers, test.trusted); actual != test.expected {
				t.Fatalf("remoteIP() = %q, want %q", actual, test.expected)
			}
		})
	}
}

func TestShutdownRejectsNewConnectionsBeforeWaiting(t *testing.T) {
	server := New(context.Background(), safelog.Discard(), DefaultOptions())
	if !server.beginConnect() {
		t.Fatal("connection was not admitted before shutdown")
	}

	result := make(chan error, 1)
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), time.Second)
		defer cancel()
		result <- server.Shutdown(ctx)
	}()
	waitFor(t, time.Second, func() bool {
		server.lifecycleMu.Lock()
		defer server.lifecycleMu.Unlock()
		return server.shuttingDown
	})
	if server.beginConnect() {
		server.wait.Done()
		t.Fatal("connection was admitted after shutdown began")
	}
	server.wait.Done()

	select {
	case err := <-result:
		if err != nil {
			t.Fatal(err)
		}
	case <-time.After(time.Second):
		t.Fatal("shutdown did not finish after admitted connection completed")
	}
}

func TestRegistrationMustBeFirst(t *testing.T) {
	testServer := newServiceTestServer(t, DefaultOptions())
	client := testServer.dial(t)

	writeClientFrame(t, client, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       "presence-before-register",
		Payload: &roammandv1.SignalingClientFrame_PresenceQuery{
			PresenceQuery: &roammandv1.PresenceQuery{DeviceId: testDeviceBytes(1)},
		},
	})
	errorFrame := readServerFrame(t, client)
	if got := errorFrame.GetError().GetCode(); got != roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST {
		t.Fatalf("error code = %v", got)
	}

	registerClient(t, client, testDeviceBytes(2), "register-after-error")
}

func TestDuplicateLiveDeviceReturnsBusyAndCanReconnect(t *testing.T) {
	testServer := newServiceTestServer(t, DefaultOptions())
	first := testServer.dial(t)
	second := testServer.dial(t)
	deviceID := testDeviceBytes(3)
	registerClient(t, first, deviceID, "register-first")

	writeRegister(t, second, deviceID, "register-duplicate")
	busy := readServerFrame(t, second)
	if got := busy.GetError().GetCode(); got != roammandv1.ErrorCode_ERROR_CODE_DEVICE_BUSY {
		t.Fatalf("error code = %v", got)
	}

	_ = first.Close(websocket.StatusNormalClosure, "")
	waitFor(t, time.Second, func() bool { return testServer.service.PresenceCount() == 0 })
	registerClient(t, second, deviceID, "register-reconnect")
}

func TestHeartbeatRenewsPresenceAndExpiredHostGoesOffline(t *testing.T) {
	clock := newTestClock(time.Unix(100, 0))
	options := DefaultOptions()
	options.Now = clock.Now
	options.SweepInterval = time.Hour
	testServer := newServiceTestServer(t, options)
	host := testServer.dial(t)
	controller := testServer.dial(t)
	hostID := testDeviceBytes(4)
	controllerID := testDeviceBytes(5)
	registerClient(t, host, hostID, "register-host")
	registerClient(t, controller, controllerID, "register-controller")

	queryPresence(t, controller, hostID, "presence-online", true)
	clock.Advance(30 * time.Second)
	writeClientFrame(t, controller, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       "heartbeat-controller",
		Payload: &roammandv1.SignalingClientFrame_Heartbeat{
			Heartbeat: &roammandv1.Heartbeat{},
		},
	})
	if ack := readServerFrame(t, controller).GetHeartbeatAcknowledged(); ack == nil {
		t.Fatal("heartbeat acknowledgement missing")
	}

	clock.Advance(16 * time.Second)
	testServer.service.Sweep(clock.Now())
	queryPresence(t, controller, hostID, "presence-offline", false)
}

func TestRegistrationTimeoutClosesConnection(t *testing.T) {
	options := DefaultOptions()
	options.RegistrationTimeout = 25 * time.Millisecond
	testServer := newServiceTestServer(t, options)
	client := testServer.dial(t)
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	_, _, err := client.Read(ctx)
	if websocket.CloseStatus(err) != websocket.StatusPolicyViolation {
		t.Fatalf("close error = %v, want policy violation", err)
	}
}

func TestInboundFrameLimitClosesConnectionWithRetryStatus(t *testing.T) {
	options := DefaultOptions()
	options.InboundLimits.FramesPerConnection = 1
	testServer := newServiceTestServer(t, options)
	client := testServer.dial(t)
	registerClient(t, client, testDeviceBytes(42), "register")

	writeClientFrame(t, client, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       "rate-limited-heartbeat",
		Payload: &roammandv1.SignalingClientFrame_Heartbeat{
			Heartbeat: &roammandv1.Heartbeat{},
		},
	})
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	_, _, err := client.Read(ctx)
	if websocket.CloseStatus(err) != websocket.StatusTryAgainLater {
		t.Fatalf("close error = %v, want try again later", err)
	}
}

func TestInboundLimitAlsoCoversWebSocketControlFrames(t *testing.T) {
	options := DefaultOptions()
	options.InboundLimits.FramesPerConnection = 1
	testServer := newServiceTestServer(t, options)
	client := testServer.dial(t)
	registerClient(t, client, testDeviceBytes(43), "register")

	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	pingResult := make(chan error, 1)
	go func() { pingResult <- client.Ping(ctx) }()
	_, _, err := client.Read(ctx)
	if websocket.CloseStatus(err) != websocket.StatusTryAgainLater {
		t.Fatalf("control-frame close error = %v, want try again later", err)
	}
	select {
	case <-pingResult:
	case <-ctx.Done():
		t.Fatal("ping did not finish after the connection closed")
	}
}

type serviceTestServer struct {
	service *Server
	http    *httptest.Server
}

func newServiceTestServer(t *testing.T, options Options) *serviceTestServer {
	t.Helper()
	ctx, cancel := context.WithCancel(context.Background())
	logger := safelog.Discard()
	service := New(ctx, logger, options)
	httpServer := httptest.NewServer(service.Handler())
	t.Cleanup(func() {
		httpServer.Close()
		cancel()
		shutdownContext, shutdownCancel := context.WithTimeout(context.Background(), time.Second)
		defer shutdownCancel()
		if err := service.Shutdown(shutdownContext); err != nil {
			t.Errorf("shutdown: %v", err)
		}
	})
	return &serviceTestServer{service: service, http: httpServer}
}

func (server *serviceTestServer) websocketURL() string {
	return "ws" + strings.TrimPrefix(server.http.URL, "http") + "/v1/connect"
}

func (server *serviceTestServer) dial(t *testing.T) *websocket.Conn {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	connection, _, err := websocket.Dial(ctx, server.websocketURL(), &websocket.DialOptions{
		Subprotocols: []string{WebSocketSubprotocol},
	})
	if err != nil {
		t.Fatal(err)
	}
	connection.SetReadLimit(int64(validation.MaxSignalingServiceFrameBytes + 1024))
	t.Cleanup(func() { _ = connection.CloseNow() })
	return connection
}

func registerClient(t *testing.T, client *websocket.Conn, deviceID []byte, requestID string) {
	t.Helper()
	writeRegister(t, client, deviceID, requestID)
	frame := readServerFrame(t, client)
	if frame.GetRegistered() == nil || frame.GetRequestId() != requestID {
		t.Fatalf("registration response = %+v", frame)
	}
}

func writeRegister(t *testing.T, client *websocket.Conn, deviceID []byte, requestID string) {
	t.Helper()
	writeClientFrame(t, client, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       requestID,
		Payload: &roammandv1.SignalingClientFrame_Register{
			Register: &roammandv1.RegisterDevice{DeviceId: deviceID},
		},
	})
}

func queryPresence(
	t *testing.T,
	client *websocket.Conn,
	deviceID []byte,
	requestID string,
	wantOnline bool,
) {
	t.Helper()
	writeClientFrame(t, client, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       requestID,
		Payload: &roammandv1.SignalingClientFrame_PresenceQuery{
			PresenceQuery: &roammandv1.PresenceQuery{DeviceId: deviceID},
		},
	})
	result := readServerFrame(t, client).GetPresenceResult()
	if result == nil || result.GetOnline() != wantOnline {
		t.Fatalf("presence result = %+v, want online=%v", result, wantOnline)
	}
}

func writeClientFrame(t *testing.T, client *websocket.Conn, frame *roammandv1.SignalingClientFrame) {
	t.Helper()
	encoded, err := proto.Marshal(frame)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	if err := client.Write(ctx, websocket.MessageBinary, encoded); err != nil {
		t.Fatal(err)
	}
}

func readServerFrame(t *testing.T, client *websocket.Conn) *roammandv1.SignalingServerFrame {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	messageType, encoded, err := client.Read(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if messageType != websocket.MessageBinary {
		t.Fatalf("message type = %v", messageType)
	}
	frame := &roammandv1.SignalingServerFrame{}
	if err := proto.Unmarshal(encoded, frame); err != nil {
		t.Fatal(err)
	}
	return frame
}

func protocolVersion() *roammandv1.ProtocolVersion {
	return &roammandv1.ProtocolVersion{Major: 1, Minor: 0}
}

func testDeviceBytes(seed byte) []byte {
	encoded := make([]byte, 32)
	for index := range encoded {
		encoded[index] = seed
	}
	return encoded
}

func waitFor(t *testing.T, timeout time.Duration, condition func() bool) {
	t.Helper()
	deadline := time.Now().Add(timeout)
	for !condition() {
		if time.Now().After(deadline) {
			t.Fatal("condition did not become true before timeout")
		}
		time.Sleep(time.Millisecond)
	}
}

type testClock struct {
	mu  sync.Mutex
	now time.Time
}

func newTestClock(now time.Time) *testClock {
	return &testClock{now: now}
}

func (clock *testClock) Now() time.Time {
	clock.mu.Lock()
	defer clock.mu.Unlock()
	return clock.now
}

func (clock *testClock) Advance(duration time.Duration) {
	clock.mu.Lock()
	defer clock.mu.Unlock()
	clock.now = clock.now.Add(duration)
}
