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
	ErrUnsupportedMessageType = errors.New("unsupported websocket message type")
	ErrMessageTooLarge        = errors.New("websocket message exceeds application limit")
)

type Connection struct {
	socket        *websocket.Conn
	outbound      chan outboundMessage
	done          chan struct{}
	closeOnce     sync.Once
	maxFrameBytes int
}

type outboundMessage struct {
	encoded []byte
	result  chan error
}

func NewConnection(
	socket *websocket.Conn,
	queueCapacity int,
	maxFrameBytes int,
) *Connection {
	socket.SetReadLimit(int64(maxFrameBytes + readLimitMargin))
	return &Connection{
		socket:        socket,
		outbound:      make(chan outboundMessage, queueCapacity),
		done:          make(chan struct{}),
		maxFrameBytes: maxFrameBytes,
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
	default:
	}

	message := make([]byte, len(encoded))
	copy(message, encoded)
	select {
	case <-connection.done:
		return false
	case connection.outbound <- outboundMessage{encoded: message}:
		return true
	default:
		return false
	}
}

func (connection *Connection) Send(ctx context.Context, encoded []byte) error {
	message := make([]byte, len(encoded))
	copy(message, encoded)
	result := make(chan error, 1)
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-connection.done:
		return context.Canceled
	case connection.outbound <- outboundMessage{encoded: message, result: result}:
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
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-connection.done:
			return nil
		case message := <-connection.outbound:
			writeContext, cancel := context.WithTimeout(ctx, writeTimeout)
			err := connection.socket.Write(
				writeContext,
				websocket.MessageBinary,
				message.encoded,
			)
			cancel()
			if message.result != nil {
				message.result <- err
			}
			if err != nil {
				connection.CloseNow()
				return err
			}
		}
	}
}

func (connection *Connection) Close(code websocket.StatusCode, reason string) {
	connection.closeOnce.Do(func() {
		close(connection.done)
		_ = connection.socket.Close(code, reason)
	})
}

func (connection *Connection) CloseNow() {
	connection.closeOnce.Do(func() {
		close(connection.done)
		_ = connection.socket.CloseNow()
	})
}

func (connection *Connection) Done() <-chan struct{} {
	return connection.done
}
