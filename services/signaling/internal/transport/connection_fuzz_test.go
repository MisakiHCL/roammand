// SPDX-License-Identifier: AGPL-3.0-only

package transport

import (
	"bytes"
	"errors"
	"testing"

	"github.com/coder/websocket"
)

func FuzzReadBoundedBinary(f *testing.F) {
	f.Add(uint8(websocket.MessageBinary), uint16(1024), []byte("valid"))
	f.Add(uint8(websocket.MessageText), uint16(1024), []byte("text"))
	f.Add(uint8(websocket.MessageBinary), uint16(1), []byte{1, 2})

	f.Fuzz(func(t *testing.T, rawType uint8, rawLimit uint16, encoded []byte) {
		if len(encoded) > 8192 {
			t.Skip()
		}
		limit := int(rawLimit%4096) + 1
		messageType := websocket.MessageType(rawType)
		copied, err := readBoundedBinary(messageType, bytes.NewReader(encoded), limit)
		switch {
		case messageType != websocket.MessageBinary:
			if !errors.Is(err, ErrUnsupportedMessageType) || copied != nil {
				t.Fatalf("non-binary result = (%v, %v)", copied, err)
			}
		case len(encoded) > limit:
			if !errors.Is(err, ErrMessageTooLarge) || copied != nil {
				t.Fatalf("oversized result = (%v, %v)", copied, err)
			}
		default:
			if err != nil || string(copied) != string(encoded) {
				t.Fatalf("valid result = (%v, %v)", copied, err)
			}
			if len(encoded) != 0 {
				original := copied[0]
				encoded[0] ^= 0xff
				if copied[0] != original {
					t.Fatal("bounded copy aliases the WebSocket buffer")
				}
			}
		}
	})
}
