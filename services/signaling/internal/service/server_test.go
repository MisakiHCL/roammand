// SPDX-License-Identifier: AGPL-3.0-only

package service

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"testing"
	"time"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	validation "github.com/MisakiHCL/roammand/gen/go/validation"
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
