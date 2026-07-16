// SPDX-License-Identifier: AGPL-3.0-only

package service

import (
	"context"
	"errors"
	"io"
	"net"
	"net/http"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	validation "github.com/MisakiHCL/roammand/gen/go/validation"
	"github.com/MisakiHCL/roammand/services/signaling/internal/config"
	"github.com/MisakiHCL/roammand/services/signaling/internal/safelog"
	"github.com/MisakiHCL/roammand/services/signaling/internal/state"
	"github.com/MisakiHCL/roammand/services/signaling/internal/transport"
	"github.com/coder/websocket"
	"google.golang.org/protobuf/proto"
)

const (
	WebSocketSubprotocol       = transport.WebSocketSubprotocol
	LegacyWebSocketSubprotocol = transport.LegacyWebSocketSubprotocol
)

type Options struct {
	Now                         func() time.Time
	RegistrationTimeout         time.Duration
	PresenceTimeout             time.Duration
	SweepInterval               time.Duration
	RendezvousTTL               time.Duration
	RateLimitWindow             time.Duration
	PairingAttemptsPerIP        int
	PairingAttemptsPerLookupKey int
	OutboundQueueCapacity       int
	MaxFrameBytes               int
}

func DefaultOptions() Options {
	return Options{
		Now:                         time.Now,
		RegistrationTimeout:         config.RegistrationTimeout,
		PresenceTimeout:             config.PresenceTimeout,
		SweepInterval:               config.SweepInterval,
		RendezvousTTL:               config.RendezvousTTL,
		RateLimitWindow:             config.RateLimitWindow,
		PairingAttemptsPerIP:        config.PairingAttemptsPerIP,
		PairingAttemptsPerLookupKey: config.PairingAttemptsPerLookupKey,
		OutboundQueueCapacity:       config.OutboundQueueCapacity,
		MaxFrameBytes:               validation.MaxSignalingServiceFrameBytes,
	}
}

type Server struct {
	ctx        context.Context
	cancel     context.CancelFunc
	logger     *safelog.Logger
	options    Options
	mux        *http.ServeMux
	presence   *state.PresenceRegistry
	rendezvous *state.RendezvousStore
	limiter    *state.FixedWindowLimiter
	nextToken  atomic.Uint64

	activeMu sync.Mutex
	active   map[*clientConnection]struct{}
	wait     sync.WaitGroup
}

type clientConnection struct {
	transport  *transport.Connection
	token      uint64
	remoteIP   string
	registered atomic.Bool
	deviceID   state.DeviceID
}

func New(ctx context.Context, logger *safelog.Logger, options Options) *Server {
	serverContext, cancel := context.WithCancel(ctx)
	if logger == nil {
		logger = safelog.Discard()
	}
	server := &Server{
		ctx:        serverContext,
		cancel:     cancel,
		logger:     logger,
		options:    options,
		mux:        http.NewServeMux(),
		presence:   state.NewPresenceRegistry(),
		rendezvous: state.NewRendezvousStore(),
		limiter: state.NewFixedWindowLimiter(
			options.RateLimitWindow,
			options.PairingAttemptsPerIP,
			options.PairingAttemptsPerLookupKey,
		),
		active: make(map[*clientConnection]struct{}),
	}
	server.mux.HandleFunc("/healthz", server.handleHealth)
	server.mux.HandleFunc("/v1/connect", server.handleConnect)
	server.wait.Add(1)
	go server.runSweeper()
	return server
}

func (server *Server) Handler() http.Handler {
	return server.mux
}

func (server *Server) PresenceCount() int {
	return server.presence.Len()
}

func (server *Server) RendezvousCount() int {
	return server.rendezvous.Len()
}

func (server *Server) ActiveConnectionCount() int {
	server.activeMu.Lock()
	defer server.activeMu.Unlock()
	return len(server.active)
}

func (server *Server) Sweep(now time.Time) {
	removedRendezvous := server.rendezvous.Sweep(now)
	for _, rendezvous := range removedRendezvous {
		server.notifyRendezvousClosed(
			rendezvous,
			roammandv1.PairingRendezvousCompletion_PAIRING_RENDEZVOUS_COMPLETION_EXPIRED,
			nil,
		)
	}
	expired := server.presence.ExpireBefore(now.Add(-server.options.PresenceTimeout))
	for _, route := range expired {
		if route.Close != nil {
			route.Close()
		}
	}
	server.limiter.Sweep(now)
}

func (server *Server) Shutdown(ctx context.Context) error {
	server.cancel()
	server.activeMu.Lock()
	connections := make([]*clientConnection, 0, len(server.active))
	for connection := range server.active {
		connections = append(connections, connection)
	}
	server.activeMu.Unlock()
	for _, connection := range connections {
		connection.transport.CloseNow()
	}

	done := make(chan struct{})
	go func() {
		server.wait.Wait()
		close(done)
	}()
	select {
	case <-done:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

func (server *Server) handleHealth(writer http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet {
		writer.WriteHeader(http.StatusMethodNotAllowed)
		return
	}
	writer.Header().Set("Content-Type", "text/plain; charset=utf-8")
	writer.WriteHeader(http.StatusOK)
	_, _ = io.WriteString(writer, "ok\n")
}

func (server *Server) handleConnect(writer http.ResponseWriter, request *http.Request) {
	select {
	case <-server.ctx.Done():
		http.Error(writer, http.StatusText(http.StatusServiceUnavailable), http.StatusServiceUnavailable)
		return
	default:
	}
	if !requestOffersSubprotocol(request, WebSocketSubprotocol) &&
		!requestOffersSubprotocol(request, LegacyWebSocketSubprotocol) {
		http.Error(writer, http.StatusText(http.StatusBadRequest), http.StatusBadRequest)
		return
	}

	socket, err := websocket.Accept(writer, request, &websocket.AcceptOptions{
		Subprotocols: []string{
			WebSocketSubprotocol,
			LegacyWebSocketSubprotocol,
		},
		CompressionMode: websocket.CompressionDisabled,
	})
	if err != nil {
		return
	}
	if socket.Subprotocol() != WebSocketSubprotocol &&
		socket.Subprotocol() != LegacyWebSocketSubprotocol {
		_ = socket.Close(websocket.StatusPolicyViolation, "subprotocol required")
		return
	}

	connection := &clientConnection{
		transport: transport.NewConnection(
			socket,
			server.options.OutboundQueueCapacity,
			server.options.MaxFrameBytes,
		),
		token:    server.nextToken.Add(1),
		remoteIP: remoteIP(request.RemoteAddr),
	}
	server.activeMu.Lock()
	server.active[connection] = struct{}{}
	server.activeMu.Unlock()
	server.wait.Add(1)
	defer server.wait.Done()
	defer server.cleanupConnection(connection)

	connectionContext, cancel := context.WithCancel(server.ctx)
	defer cancel()
	writerDone := make(chan error, 1)
	go func() {
		writerDone <- connection.transport.RunWriter(connectionContext)
	}()
	registrationTimer := time.AfterFunc(server.options.RegistrationTimeout, func() {
		if !connection.registered.Load() {
			connection.transport.Close(websocket.StatusPolicyViolation, "registration required")
		}
	})
	defer registrationTimer.Stop()

	for {
		encoded, readErr := connection.transport.Read(connectionContext)
		if readErr != nil {
			if !errors.Is(readErr, context.Canceled) {
				server.handleReadError(connection, readErr)
			}
			break
		}
		frame, code := decodeClientFrame(encoded)
		if code != roammandv1.ErrorCode_ERROR_CODE_UNSPECIFIED {
			server.sendFrame(connection, publicError(code, frame.GetRequestId(), 0))
			continue
		}
		if server.handleFrame(connection, frame) && connection.registered.Load() {
			registrationTimer.Stop()
		}
	}
	cancel()
	connection.transport.CloseNow()
	select {
	case <-writerDone:
	case <-time.After(time.Second):
	}
}

func (server *Server) handleReadError(connection *clientConnection, err error) {
	var code roammandv1.ErrorCode
	switch {
	case errors.Is(err, transport.ErrUnsupportedMessageType):
		code = roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST
	case errors.Is(err, transport.ErrMessageTooLarge):
		code = roammandv1.ErrorCode_ERROR_CODE_MESSAGE_TOO_LARGE
	default:
		return
	}
	server.sendFrameAndWait(connection, publicError(code, "", 0))
}

func (server *Server) sendFrameAndWait(
	connection *clientConnection,
	frame *roammandv1.SignalingServerFrame,
) bool {
	encoded, err := proto.Marshal(frame)
	if err != nil {
		return false
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	return connection.transport.Send(ctx, encoded) == nil
}

func (server *Server) sendFrame(
	connection *clientConnection,
	frame *roammandv1.SignalingServerFrame,
) bool {
	encoded, err := proto.Marshal(frame)
	if err != nil {
		server.logger.Event(
			safelog.EventPublicFrameEncodeFailed,
			safelog.Fields{Code: safelog.CodeInternal},
		)
		connection.transport.CloseNow()
		return false
	}
	if connection.transport.TrySend(encoded) {
		return true
	}
	connection.transport.CloseNow()
	return false
}

func (server *Server) cleanupConnection(connection *clientConnection) {
	if connection.registered.Load() {
		server.presence.Remove(connection.deviceID, connection.token)
		removed := server.rendezvous.RemoveForDevice(connection.deviceID)
		for _, rendezvous := range removed {
			server.notifyRendezvousClosed(
				rendezvous,
				roammandv1.PairingRendezvousCompletion_PAIRING_RENDEZVOUS_COMPLETION_DISCONNECTED,
				&connection.deviceID,
			)
		}
	}
	server.activeMu.Lock()
	delete(server.active, connection)
	server.activeMu.Unlock()
	connection.transport.CloseNow()
}

func (server *Server) runSweeper() {
	defer server.wait.Done()
	ticker := time.NewTicker(server.options.SweepInterval)
	defer ticker.Stop()
	for {
		select {
		case <-server.ctx.Done():
			return
		case <-ticker.C:
			server.Sweep(server.options.Now())
		}
	}
}

func requestOffersSubprotocol(request *http.Request, required string) bool {
	for _, value := range request.Header.Values("Sec-WebSocket-Protocol") {
		for _, candidate := range strings.Split(value, ",") {
			if strings.EqualFold(strings.TrimSpace(candidate), required) {
				return true
			}
		}
	}
	return false
}

func remoteIP(remoteAddress string) string {
	host, _, err := net.SplitHostPort(remoteAddress)
	if err != nil {
		return remoteAddress
	}
	return host
}
