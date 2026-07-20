// SPDX-License-Identifier: AGPL-3.0-only

package transport

import (
	"context"
	"errors"
	"sync"
	"time"

	"github.com/coder/websocket"
)

const (
	WebSocketSubprotocol       = "roammand-signaling.v1.protobuf"
	LegacyWebSocketSubprotocol = "personal-remote-signaling.v1.protobuf"

	readLimitMargin = 1024
	writeTimeout    = 5 * time.Second
)

var (
	ErrUnsupportedMessageType     = errors.New("unsupported websocket message type")
	ErrMessageTooLarge            = errors.New("websocket message exceeds application limit")
	ErrOutboundByteBudgetExceeded = errors.New("outbound byte budget exceeded")
)

type Connection struct {
	socket           *websocket.Conn
	outbound         chan outboundMessage
	outboundSlots    chan struct{}
	outboundBudgets  []OutboundByteBudget
	connectionBudget *ByteBudget
	done             chan struct{}
	closeOnce        sync.Once
	queueMu          sync.Mutex
	closed           bool
	maxFrameBytes    int
}

type outboundMessage struct {
	encoded     []byte
	result      chan error
	reservation int64
}

type ConnectionConfig struct {
	OutboundQueueCapacity int
	MaxFrameBytes         int
	MaxOutboundBytes      int64
	SharedOutboundBudgets []OutboundByteBudget
}

func NewConnection(socket *websocket.Conn, config ConnectionConfig) *Connection {
	if config.OutboundQueueCapacity <= 0 {
		panic("outbound queue capacity must be positive")
	}
	if config.MaxFrameBytes <= 0 {
		panic("maximum frame size must be positive")
	}
	connectionBudget := NewByteBudget(config.MaxOutboundBytes)
	outboundBudgets := make([]OutboundByteBudget, 1, 1+len(config.SharedOutboundBudgets))
	outboundBudgets[0] = connectionBudget
	outboundBudgets = append(outboundBudgets, config.SharedOutboundBudgets...)
	outboundSlots := make(chan struct{}, config.OutboundQueueCapacity)
	for range config.OutboundQueueCapacity {
		outboundSlots <- struct{}{}
	}
	socket.SetReadLimit(int64(config.MaxFrameBytes + readLimitMargin))
	return &Connection{
		socket:           socket,
		outbound:         make(chan outboundMessage, config.OutboundQueueCapacity),
		outboundSlots:    outboundSlots,
		outboundBudgets:  outboundBudgets,
		connectionBudget: connectionBudget,
		done:             make(chan struct{}),
		maxFrameBytes:    config.MaxFrameBytes,
	}
}

func (connection *Connection) Read(ctx context.Context) ([]byte, error) {
	messageType, encoded, err := connection.socket.Read(ctx)
	if err != nil {
		return nil, err
	}
	return boundedBinaryCopy(messageType, encoded, connection.maxFrameBytes)
}

func boundedBinaryCopy(
	messageType websocket.MessageType,
	encoded []byte,
	maxFrameBytes int,
) ([]byte, error) {
	if messageType != websocket.MessageBinary {
		return nil, ErrUnsupportedMessageType
	}
	if len(encoded) > maxFrameBytes {
		return nil, ErrMessageTooLarge
	}
	message := make([]byte, len(encoded))
	copy(message, encoded)
	return message, nil
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
	if !reserveOutboundBytes(connection.outboundBudgets, reservation) {
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

func reserveOutboundBytes(budgets []OutboundByteBudget, bytes int64) bool {
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

func (connection *Connection) completeOutbound(message outboundMessage, err error) {
	for index := len(connection.outboundBudgets) - 1; index >= 0; index-- {
		connection.outboundBudgets[index].Release(message.reservation)
	}
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
	return connection.connectionBudget.UsedBytes()
}
