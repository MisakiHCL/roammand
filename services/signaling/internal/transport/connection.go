// SPDX-License-Identifier: AGPL-3.0-only

package transport

import (
	"context"
	"errors"
	"io"
	"sync"
	"sync/atomic"
	"time"

	"github.com/coder/websocket"
)

const (
	WebSocketSubprotocol       = "roammand-signaling.v1.protobuf"
	LegacyWebSocketSubprotocol = "personal-remote-signaling.v1.protobuf"

	readLimitMargin int64 = 1024
	readLimitProbe  int64 = 1
	writeTimeout          = 5 * time.Second
)

var (
	ErrUnsupportedMessageType     = errors.New("unsupported websocket message type")
	ErrMessageTooLarge            = errors.New("websocket message exceeds application limit")
	ErrMessageReadTimeout         = errors.New("websocket message read timed out")
	ErrInFlightReadBudgetExceeded = errors.New("in-flight read byte budget exceeded")
	ErrOutboundByteBudgetExceeded = errors.New("outbound byte budget exceeded")
)

type Connection struct {
	socket                       *websocket.Conn
	outbound                     chan outboundMessage
	outboundSlots                chan struct{}
	outboundBudgets              []ByteReservationBudget
	connectionOutboundBudget     *ByteBudget
	inFlightReadBudgets          []ByteReservationBudget
	connectionInFlightReadBudget *ByteBudget
	done                         chan struct{}
	closeOnce                    sync.Once
	queueMu                      sync.Mutex
	closed                       bool
	maxFrameBytes                int
	messageReadTimeout           time.Duration
	inFlightReadReservation      int64
}

type outboundMessage struct {
	encoded     []byte
	result      chan error
	reservation int64
}

type ConnectionConfig struct {
	OutboundQueueCapacity     int
	MaxFrameBytes             int
	MaxOutboundBytes          int64
	SharedOutboundBudgets     []ByteReservationBudget
	MessageReadTimeout        time.Duration
	MaxInFlightReadBytes      int64
	SharedInFlightReadBudgets []ByteReservationBudget
}

func NewConnection(socket *websocket.Conn, config ConnectionConfig) *Connection {
	if config.OutboundQueueCapacity <= 0 {
		panic("outbound queue capacity must be positive")
	}
	if config.MaxFrameBytes <= 0 {
		panic("maximum frame size must be positive")
	}
	if config.MessageReadTimeout <= 0 {
		panic("message read timeout must be positive")
	}
	inFlightReadReservation := int64(config.MaxFrameBytes) + readLimitProbe
	if config.MaxInFlightReadBytes < inFlightReadReservation {
		panic("in-flight read byte budget must cover one maximum-size message")
	}
	connectionOutboundBudget := NewByteBudget(config.MaxOutboundBytes)
	outboundBudgets := make([]ByteReservationBudget, 1, 1+len(config.SharedOutboundBudgets))
	outboundBudgets[0] = connectionOutboundBudget
	outboundBudgets = append(outboundBudgets, config.SharedOutboundBudgets...)
	connectionInFlightReadBudget := NewByteBudget(config.MaxInFlightReadBytes)
	inFlightReadBudgets := make(
		[]ByteReservationBudget,
		1,
		1+len(config.SharedInFlightReadBudgets),
	)
	inFlightReadBudgets[0] = connectionInFlightReadBudget
	inFlightReadBudgets = append(inFlightReadBudgets, config.SharedInFlightReadBudgets...)
	outboundSlots := make(chan struct{}, config.OutboundQueueCapacity)
	for range config.OutboundQueueCapacity {
		outboundSlots <- struct{}{}
	}
	socket.SetReadLimit(int64(config.MaxFrameBytes) + readLimitMargin)
	return &Connection{
		socket:                       socket,
		outbound:                     make(chan outboundMessage, config.OutboundQueueCapacity),
		outboundSlots:                outboundSlots,
		outboundBudgets:              outboundBudgets,
		connectionOutboundBudget:     connectionOutboundBudget,
		inFlightReadBudgets:          inFlightReadBudgets,
		connectionInFlightReadBudget: connectionInFlightReadBudget,
		done:                         make(chan struct{}),
		maxFrameBytes:                config.MaxFrameBytes,
		messageReadTimeout:           config.MessageReadTimeout,
		inFlightReadReservation:      inFlightReadReservation,
	}
}

func (connection *Connection) Read(ctx context.Context) ([]byte, error) {
	readContext, cancelRead := context.WithCancel(ctx)
	messageType, reader, err := connection.socket.Reader(readContext)
	if err != nil {
		cancelRead()
		return nil, err
	}
	if messageType != websocket.MessageBinary {
		cancelRead()
		return nil, ErrUnsupportedMessageType
	}
	if !reserveBytes(connection.inFlightReadBudgets, connection.inFlightReadReservation) {
		cancelRead()
		return nil, ErrInFlightReadBudgetExceeded
	}
	defer releaseBytes(connection.inFlightReadBudgets, connection.inFlightReadReservation)

	var timedOut atomic.Bool
	timer := time.AfterFunc(connection.messageReadTimeout, func() {
		timedOut.Store(true)
		cancelRead()
	})
	defer timer.Stop()
	defer cancelRead()

	encoded, err := readBoundedBinary(messageType, reader, connection.maxFrameBytes)
	if err != nil && timedOut.Load() && ctx.Err() == nil {
		return nil, ErrMessageReadTimeout
	}
	return encoded, err
}

func readBoundedBinary(
	messageType websocket.MessageType,
	reader io.Reader,
	maxFrameBytes int,
) ([]byte, error) {
	if messageType != websocket.MessageBinary {
		return nil, ErrUnsupportedMessageType
	}
	encoded, err := io.ReadAll(io.LimitReader(reader, int64(maxFrameBytes)+readLimitProbe))
	if err != nil {
		if errors.Is(err, websocket.ErrMessageTooBig) {
			return nil, ErrMessageTooLarge
		}
		return nil, err
	}
	if len(encoded) > maxFrameBytes {
		return nil, ErrMessageTooLarge
	}
	return encoded, nil
}

func (connection *Connection) TrySend(encoded []byte) bool {
	select {
	case <-connection.done:
		return false
	case <-connection.outboundSlots:
	default:
		return false
	}
	return connection.enqueueWithReservedSlot(encoded, nil) == nil
}

func (connection *Connection) Send(ctx context.Context, encoded []byte) error {
	result := make(chan error, 1)
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-connection.done:
		return context.Canceled
	case <-connection.outboundSlots:
	}
	if err := connection.enqueueWithReservedSlot(encoded, result); err != nil {
		return err
	}

	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-connection.done:
		return context.Canceled
	case err := <-result:
		return err
	}
}

func (connection *Connection) RunWriter(ctx context.Context) error {
	defer connection.CloseNow()
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-connection.done:
			return nil
		case message := <-connection.outbound:
			connection.releaseOutboundSlot()
			select {
			case <-connection.done:
				connection.completeOutbound(message, context.Canceled)
				return nil
			default:
			}
			writeContext, cancel := context.WithTimeout(ctx, writeTimeout)
			err := connection.socket.Write(
				writeContext,
				websocket.MessageBinary,
				message.encoded,
			)
			cancel()
			connection.completeOutbound(message, err)
			if err != nil {
				return err
			}
		}
	}
}

func (connection *Connection) enqueueWithReservedSlot(
	encoded []byte,
	result chan error,
) error {
	connection.queueMu.Lock()
	defer connection.queueMu.Unlock()
	if connection.closed {
		connection.releaseOutboundSlot()
		return context.Canceled
	}
	reservation := int64(len(encoded))
	if !reserveBytes(connection.outboundBudgets, reservation) {
		connection.releaseOutboundSlot()
		return ErrOutboundByteBudgetExceeded
	}
	message := make([]byte, len(encoded))
	copy(message, encoded)
	connection.outbound <- outboundMessage{
		encoded:     message,
		result:      result,
		reservation: reservation,
	}
	return nil
}

func reserveBytes(budgets []ByteReservationBudget, bytes int64) bool {
	for index, budget := range budgets {
		if budget.TryReserve(bytes) {
			continue
		}
		for rollback := index - 1; rollback >= 0; rollback-- {
			budgets[rollback].Release(bytes)
		}
		return false
	}
	return true
}

func releaseBytes(budgets []ByteReservationBudget, bytes int64) {
	for index := len(budgets) - 1; index >= 0; index-- {
		budgets[index].Release(bytes)
	}
}

func (connection *Connection) completeOutbound(message outboundMessage, err error) {
	releaseBytes(connection.outboundBudgets, message.reservation)
	if message.result != nil {
		message.result <- err
	}
}

func (connection *Connection) releaseOutboundSlot() {
	connection.outboundSlots <- struct{}{}
}

func (connection *Connection) closeWith(closeSocket func()) {
	connection.closeOnce.Do(func() {
		connection.queueMu.Lock()
		connection.closed = true
		close(connection.done)
		for {
			select {
			case message := <-connection.outbound:
				connection.releaseOutboundSlot()
				connection.completeOutbound(message, context.Canceled)
			default:
				connection.queueMu.Unlock()
				closeSocket()
				return
			}
		}
	})
}

func (connection *Connection) Close(code websocket.StatusCode, reason string) {
	connection.closeWith(func() {
		_ = connection.socket.Close(code, reason)
	})
}

func (connection *Connection) CloseNow() {
	connection.closeWith(func() {
		_ = connection.socket.CloseNow()
	})
}

func (connection *Connection) Done() <-chan struct{} {
	return connection.done
}

func (connection *Connection) OutboundBytes() int64 {
	return connection.connectionOutboundBudget.UsedBytes()
}

func (connection *Connection) InFlightReadBytes() int64 {
	return connection.connectionInFlightReadBudget.UsedBytes()
}
