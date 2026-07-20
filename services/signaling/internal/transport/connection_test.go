// SPDX-License-Identifier: AGPL-3.0-only

package transport

import (
	"bytes"
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/coder/websocket"
)

func TestConnectionReadsBinaryMessages(t *testing.T) {
	clientSocket, serverSocket := socketPair(t)
	connection := newTestConnection(serverSocket, 2, 64)
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	want := []byte{1, 2, 3}
	if err := clientSocket.Write(ctx, websocket.MessageBinary, want); err != nil {
		t.Fatal(err)
	}
	got, err := connection.Read(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(got, want) {
		t.Fatalf("message = %v, want %v", got, want)
	}
}

func TestConnectionRejectsTextMessages(t *testing.T) {
	clientSocket, serverSocket := socketPair(t)
	connection := newTestConnection(serverSocket, 2, 64)
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	if err := clientSocket.Write(ctx, websocket.MessageText, []byte("not protobuf")); err != nil {
		t.Fatal(err)
	}
	if _, err := connection.Read(ctx); !errors.Is(err, ErrUnsupportedMessageType) {
		t.Fatalf("Read error = %v, want %v", err, ErrUnsupportedMessageType)
	}
}

func TestConnectionRejectsOversizedApplicationMessage(t *testing.T) {
	clientSocket, serverSocket := socketPair(t)
	connection := newTestConnection(serverSocket, 2, 4)
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	if err := clientSocket.Write(ctx, websocket.MessageBinary, make([]byte, 5)); err != nil {
		t.Fatal(err)
	}
	if _, err := connection.Read(ctx); !errors.Is(err, ErrMessageTooLarge) {
		t.Fatalf("Read error = %v, want %v", err, ErrMessageTooLarge)
	}
}

func TestConnectionOutboundQueueIsBounded(t *testing.T) {
	_, serverSocket := socketPair(t)
	connection := newTestConnection(serverSocket, 1, 64)

	if !connection.TrySend([]byte{1}) {
		t.Fatal("first message was rejected")
	}
	if connection.TrySend([]byte{2}) {
		t.Fatal("second message was accepted into full queue")
	}
	if got := connection.OutboundBytes(); got != 1 {
		t.Fatalf("outbound bytes = %d, want 1", got)
	}
	connection.CloseNow()
	if got := connection.OutboundBytes(); got != 0 {
		t.Fatalf("outbound bytes after close = %d, want 0", got)
	}
}

func TestConnectionOutboundByteBudgetRejectsConcurrentEnqueueAndReleasesOnClose(t *testing.T) {
	_, serverSocket := socketPair(t)
	sharedBudget := NewByteBudget(64)
	connection := NewConnection(serverSocket, ConnectionConfig{
		OutboundQueueCapacity: 32,
		MaxFrameBytes:         64,
		MaxOutboundBytes:      8,
		SharedOutboundBudgets: []OutboundByteBudget{sharedBudget},
	})

	const attempts = 32
	start := make(chan struct{})
	var accepted atomic.Int64
	var wait sync.WaitGroup
	wait.Add(attempts)
	for range attempts {
		go func() {
			defer wait.Done()
			<-start
			if connection.TrySend([]byte{1, 2, 3}) {
				accepted.Add(1)
			}
		}()
	}
	close(start)
	wait.Wait()

	if got := accepted.Load(); got != 2 {
		t.Fatalf("accepted messages = %d, want 2", got)
	}
	if got := connection.OutboundBytes(); got != 6 {
		t.Fatalf("connection outbound bytes = %d, want 6", got)
	}
	if got := sharedBudget.UsedBytes(); got != 6 {
		t.Fatalf("shared outbound bytes = %d, want 6", got)
	}

	connection.CloseNow()
	if got := connection.OutboundBytes(); got != 0 {
		t.Fatalf("connection outbound bytes after close = %d, want 0", got)
	}
	if got := sharedBudget.UsedBytes(); got != 0 {
		t.Fatalf("shared outbound bytes after close = %d, want 0", got)
	}
}

func TestConnectionSharedBudgetRollsBackRejectedReservation(t *testing.T) {
	_, firstSocket := socketPair(t)
	_, secondSocket := socketPair(t)
	globalBudget := NewByteBudget(5)
	newConnection := func(socket *websocket.Conn) *Connection {
		return NewConnection(socket, ConnectionConfig{
			OutboundQueueCapacity: 2,
			MaxFrameBytes:         64,
			MaxOutboundBytes:      64,
			SharedOutboundBudgets: []OutboundByteBudget{globalBudget},
		})
	}
	first := newConnection(firstSocket)
	second := newConnection(secondSocket)

	if !first.TrySend([]byte{1, 2, 3}) {
		t.Fatal("first connection did not reserve shared budget")
	}
	if second.TrySend([]byte{4, 5, 6}) {
		t.Fatal("second connection exceeded shared budget")
	}
	if got := second.OutboundBytes(); got != 0 {
		t.Fatalf("rejected connection retained %d bytes", got)
	}
	if got := globalBudget.UsedBytes(); got != 3 {
		t.Fatalf("global outbound bytes = %d, want 3", got)
	}

	first.CloseNow()
	if !second.TrySend([]byte{4, 5, 6}) {
		t.Fatal("released shared budget was not reusable")
	}
	second.CloseNow()
	if got := globalBudget.UsedBytes(); got != 0 {
		t.Fatalf("global outbound bytes after close = %d, want 0", got)
	}
}

func TestConnectionCloseUnblocksPendingSendWithoutBudgetLeak(t *testing.T) {
	_, serverSocket := socketPair(t)
	sharedBudget := NewByteBudget(64)
	connection := NewConnection(serverSocket, ConnectionConfig{
		OutboundQueueCapacity: 1,
		MaxFrameBytes:         64,
		MaxOutboundBytes:      64,
		SharedOutboundBudgets: []OutboundByteBudget{sharedBudget},
	})
	if !connection.TrySend([]byte{1, 2, 3}) {
		t.Fatal("initial message was rejected")
	}

	result := make(chan error, 1)
	go func() {
		result <- connection.Send(context.Background(), []byte{4, 5, 6})
	}()
	connection.CloseNow()
	select {
	case err := <-result:
		if !errors.Is(err, context.Canceled) {
			t.Fatalf("Send error = %v, want context canceled", err)
		}
	case <-time.After(time.Second):
		t.Fatal("pending Send was not unblocked by close")
	}
	if got := connection.OutboundBytes(); got != 0 {
		t.Fatalf("connection outbound bytes after close = %d, want 0", got)
	}
	if got := sharedBudget.UsedBytes(); got != 0 {
		t.Fatalf("shared outbound bytes after close = %d, want 0", got)
	}
}

func TestConnectionWriterPreservesMessageOrder(t *testing.T) {
	clientSocket, serverSocket := socketPair(t)
	connection := newTestConnection(serverSocket, 2, 64)
	ctx, cancel := context.WithCancel(context.Background())
	writerDone := make(chan error, 1)
	go func() { writerDone <- connection.RunWriter(ctx) }()

	first := []byte{1}
	second := []byte{2}
	if !connection.TrySend(first) || !connection.TrySend(second) {
		t.Fatal("writer queue rejected messages")
	}
	readCtx, readCancel := context.WithTimeout(context.Background(), time.Second)
	defer readCancel()
	for index, want := range [][]byte{first, second} {
		messageType, got, err := clientSocket.Read(readCtx)
		if err != nil {
			t.Fatal(err)
		}
		if messageType != websocket.MessageBinary || !bytes.Equal(got, want) {
			t.Fatalf("message %d = (%v, %v), want binary %v", index, messageType, got, want)
		}
	}
	waitForZeroBudget(t, connection)
	cancel()
	select {
	case <-writerDone:
	case <-time.After(time.Second):
		t.Fatal("writer did not stop after cancellation")
	}
}

func TestConnectionWriterFailureReleasesActiveReservation(t *testing.T) {
	_, serverSocket := socketPair(t)
	sharedBudget := NewByteBudget(64)
	connection := NewConnection(serverSocket, ConnectionConfig{
		OutboundQueueCapacity: 1,
		MaxFrameBytes:         64,
		MaxOutboundBytes:      64,
		SharedOutboundBudgets: []OutboundByteBudget{sharedBudget},
	})
	if !connection.TrySend([]byte{1, 2, 3}) {
		t.Fatal("message was rejected")
	}
	if err := serverSocket.CloseNow(); err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	if err := connection.RunWriter(ctx); err == nil {
		t.Fatal("writer succeeded on a closed socket")
	}
	if got := connection.OutboundBytes(); got != 0 {
		t.Fatalf("connection outbound bytes after write failure = %d, want 0", got)
	}
	if got := sharedBudget.UsedBytes(); got != 0 {
		t.Fatalf("shared outbound bytes after write failure = %d, want 0", got)
	}
}

func TestConnectionCloseNowIsIdempotent(t *testing.T) {
	_, serverSocket := socketPair(t)
	connection := newTestConnection(serverSocket, 1, 64)

	connection.CloseNow()
	connection.CloseNow()
	if connection.TrySend([]byte{1}) {
		t.Fatal("closed connection accepted outbound message")
	}
}

func socketPair(t *testing.T) (*websocket.Conn, *websocket.Conn) {
	t.Helper()
	accepted := make(chan *websocket.Conn, 1)
	acceptErrors := make(chan error, 1)
	server := httptest.NewServer(http.HandlerFunc(func(writer http.ResponseWriter, request *http.Request) {
		socket, err := websocket.Accept(writer, request, nil)
		if err != nil {
			acceptErrors <- err
			return
		}
		accepted <- socket
	}))
	t.Cleanup(server.Close)

	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	endpoint := "ws" + strings.TrimPrefix(server.URL, "http")
	clientSocket, _, err := websocket.Dial(ctx, endpoint, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = clientSocket.CloseNow() })

	select {
	case serverSocket := <-accepted:
		t.Cleanup(func() { _ = serverSocket.CloseNow() })
		return clientSocket, serverSocket
	case err := <-acceptErrors:
		t.Fatal(err)
	case <-ctx.Done():
		t.Fatal(ctx.Err())
	}
	return nil, nil
}

func newTestConnection(
	socket *websocket.Conn,
	queueCapacity int,
	maxFrameBytes int,
) *Connection {
	return NewConnection(socket, ConnectionConfig{
		OutboundQueueCapacity: queueCapacity,
		MaxFrameBytes:         maxFrameBytes,
		MaxOutboundBytes:      int64(maxFrameBytes * 2),
	})
}

func waitForZeroBudget(t *testing.T, connection *Connection) {
	t.Helper()
	deadline := time.Now().Add(time.Second)
	for connection.OutboundBytes() != 0 {
		if time.Now().After(deadline) {
			t.Fatalf("outbound bytes remained at %d", connection.OutboundBytes())
		}
		time.Sleep(time.Millisecond)
	}
}
