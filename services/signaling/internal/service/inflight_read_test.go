// SPDX-License-Identifier: AGPL-3.0-only

package service

import (
	"bufio"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"testing"
	"time"
)

const (
	testFrameBytes          = 64
	testReadReservation     = testFrameBytes + 1
	testPartialFramePayload = 32
)

func TestIncompleteMessageTimesOutAndReleasesAllReadBudgets(t *testing.T) {
	options := inFlightReadTestOptions()
	options.MessageReadTimeout = 300 * time.Millisecond
	testServer := newServiceTestServer(t, options)
	client := dialRawWebSocket(t, testServer)

	writePartialBinaryFrame(t, client, testPartialFramePayload, []byte{1})
	waitFor(t, time.Second, func() bool {
		return testServer.service.globalInFlightReadBudget.UsedBytes() == testReadReservation &&
			testServer.service.inFlightReadBytesForIP("127.0.0.1") == testReadReservation &&
			activeInFlightReadBytes(testServer.service) == testReadReservation
	})

	waitFor(t, 2*time.Second, func() bool {
		return testServer.service.globalInFlightReadBudget.UsedBytes() == 0 &&
			testServer.service.inFlightReadBytesForIP("127.0.0.1") == 0 &&
			testServer.service.ActiveConnectionCount() == 0
	})
}

func TestConcurrentIncompleteMessagesRespectGlobalReadBudgetAndRollback(t *testing.T) {
	options := inFlightReadTestOptions()
	options.MessageReadTimeout = 2 * time.Second
	options.MaxConnections = 2
	options.MaxConnectionsPerIP = 2
	options.MaxInFlightReadBytes = testReadReservation
	options.MaxInFlightReadBytesPerIP = 2 * testReadReservation
	testServer := newServiceTestServer(t, options)

	first := dialRawWebSocket(t, testServer)
	writePartialBinaryFrame(t, first, testPartialFramePayload, []byte{1})
	waitFor(t, time.Second, func() bool {
		return testServer.service.globalInFlightReadBudget.UsedBytes() == testReadReservation
	})

	second := dialRawWebSocket(t, testServer)
	waitFor(t, time.Second, func() bool {
		return testServer.service.ActiveConnectionCount() == 2
	})
	writePartialBinaryFrame(t, second, testPartialFramePayload, []byte{2})
	waitFor(t, time.Second, func() bool {
		return testServer.service.ActiveConnectionCount() == 1 &&
			testServer.service.globalInFlightReadBudget.UsedBytes() == testReadReservation &&
			testServer.service.inFlightReadBytesForIP("127.0.0.1") == testReadReservation &&
			activeInFlightReadBytes(testServer.service) == testReadReservation
	})

	if err := first.Close(); err != nil {
		t.Fatal(err)
	}
	waitFor(t, time.Second, func() bool {
		return testServer.service.ActiveConnectionCount() == 0 &&
			testServer.service.globalInFlightReadBudget.UsedBytes() == 0 &&
			testServer.service.inFlightReadBytesForIP("127.0.0.1") == 0
	})
}

func inFlightReadTestOptions() Options {
	options := DefaultOptions()
	options.MaxFrameBytes = testFrameBytes
	options.MaxInFlightReadBytes = 2 * testReadReservation
	options.MaxInFlightReadBytesPerIP = 2 * testReadReservation
	options.MaxInFlightReadBytesPerConnection = testReadReservation
	return options
}

func dialRawWebSocket(t *testing.T, server *serviceTestServer) net.Conn {
	t.Helper()
	endpoint, err := url.Parse(server.http.URL)
	if err != nil {
		t.Fatal(err)
	}
	connection, err := net.DialTimeout("tcp", endpoint.Host, time.Second)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = connection.Close() })
	request := fmt.Sprintf(
		"GET /v1/connect HTTP/1.1\r\n"+
			"Host: %s\r\n"+
			"Upgrade: websocket\r\n"+
			"Connection: Upgrade\r\n"+
			"Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n"+
			"Sec-WebSocket-Version: 13\r\n"+
			"Sec-WebSocket-Protocol: %s\r\n\r\n",
		endpoint.Host,
		WebSocketSubprotocol,
	)
	if _, err := connection.Write([]byte(request)); err != nil {
		t.Fatal(err)
	}
	response, err := http.ReadResponse(bufio.NewReader(connection), &http.Request{
		Method: http.MethodGet,
	})
	if err != nil {
		t.Fatal(err)
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusSwitchingProtocols {
		t.Fatalf("websocket upgrade status = %d", response.StatusCode)
	}
	return connection
}

func writePartialBinaryFrame(
	t *testing.T,
	connection net.Conn,
	declaredPayloadBytes byte,
	payloadPrefix []byte,
) {
	t.Helper()
	if len(payloadPrefix) >= int(declaredPayloadBytes) || declaredPayloadBytes > 125 {
		t.Fatal("partial frame test requires a short, incomplete payload")
	}
	mask := [4]byte{1, 2, 3, 4}
	frame := make([]byte, 0, 2+len(mask)+len(payloadPrefix))
	frame = append(frame, 0x82, 0x80|declaredPayloadBytes)
	frame = append(frame, mask[:]...)
	for index, value := range payloadPrefix {
		frame = append(frame, value^mask[index%len(mask)])
	}
	if _, err := connection.Write(frame); err != nil {
		t.Fatal(err)
	}
}

func activeInFlightReadBytes(server *Server) int64 {
	server.activeMu.Lock()
	defer server.activeMu.Unlock()
	var used int64
	for connection := range server.active {
		used += connection.transport.InFlightReadBytes()
	}
	return used
}
