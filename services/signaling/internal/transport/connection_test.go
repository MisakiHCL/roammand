// SPDX-License-Identifier: AGPL-3.0-only

package transport

import (
	"bytes"
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/coder/websocket"
)

func TestConnectionReadsBinaryMessages(t *testing.T) {
	clientSocket, serverSocket := socketPair(t)
	connection := NewConnection(serverSocket, 2, 64)
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
	connection := NewConnection(serverSocket, 2, 64)
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
	connection := NewConnection(serverSocket, 2, 4)
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
	connection := NewConnection(serverSocket, 1, 64)

	if !connection.TrySend([]byte{1}) {
		t.Fatal("first message was rejected")
	}
	if connection.TrySend([]byte{2}) {
		t.Fatal("second message was accepted into full queue")
	}
}

func TestConnectionWriterPreservesMessageOrder(t *testing.T) {
	clientSocket, serverSocket := socketPair(t)
	connection := NewConnection(serverSocket, 2, 64)
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
	cancel()
	select {
	case <-writerDone:
	case <-time.After(time.Second):
		t.Fatal("writer did not stop after cancellation")
	}
}

func TestConnectionCloseNowIsIdempotent(t *testing.T) {
	_, serverSocket := socketPair(t)
	connection := NewConnection(serverSocket, 1, 64)

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
