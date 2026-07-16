// SPDX-License-Identifier: AGPL-3.0-only

package testclient

import (
	"context"
	"errors"
	"fmt"
	"net/http"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	validation "github.com/MisakiHCL/roammand/gen/go/validation"
	"github.com/MisakiHCL/roammand/services/signaling/internal/transport"
	"github.com/coder/websocket"
	"google.golang.org/protobuf/proto"
)

const readLimitMargin = 1024

type Client struct {
	connection *websocket.Conn
}

type PublicError struct {
	Code roammandv1.ErrorCode
}

func (protocolError PublicError) Error() string {
	return fmt.Sprintf("signaling request failed: %s", protocolError.Code.String())
}

func Dial(ctx context.Context, endpoint string, httpClient *http.Client) (*Client, error) {
	connection, _, err := websocket.Dial(ctx, endpoint, &websocket.DialOptions{
		HTTPClient:      httpClient,
		Subprotocols:    []string{transport.WebSocketSubprotocol},
		CompressionMode: websocket.CompressionDisabled,
	})
	if err != nil {
		return nil, err
	}
	if connection.Subprotocol() != transport.WebSocketSubprotocol {
		_ = connection.Close(websocket.StatusPolicyViolation, "subprotocol required")
		return nil, errors.New("signaling server did not select the required subprotocol")
	}
	connection.SetReadLimit(int64(validation.MaxSignalingServiceFrameBytes + readLimitMargin))
	return &Client{connection: connection}, nil
}

func (client *Client) Send(ctx context.Context, frame *roammandv1.SignalingClientFrame) error {
	encoded, err := proto.Marshal(frame)
	if err != nil {
		return err
	}
	return client.connection.Write(ctx, websocket.MessageBinary, encoded)
}

func (client *Client) Read(ctx context.Context) (*roammandv1.SignalingServerFrame, error) {
	messageType, encoded, err := client.connection.Read(ctx)
	if err != nil {
		return nil, err
	}
	if messageType != websocket.MessageBinary {
		return nil, errors.New("signaling server sent a non-binary frame")
	}
	frame := &roammandv1.SignalingServerFrame{}
	if err := proto.Unmarshal(encoded, frame); err != nil {
		return nil, err
	}
	if protocolError := frame.GetError(); protocolError != nil {
		return nil, PublicError{Code: protocolError.GetCode()}
	}
	return frame, nil
}

func (client *Client) Register(
	ctx context.Context,
	deviceID []byte,
	requestID string,
) (*roammandv1.RegistrationAccepted, error) {
	err := client.Send(ctx, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       requestID,
		Payload: &roammandv1.SignalingClientFrame_Register{
			Register: &roammandv1.RegisterDevice{DeviceId: deviceID},
		},
	})
	if err != nil {
		return nil, err
	}
	frame, err := client.Read(ctx)
	if err != nil {
		return nil, err
	}
	if frame.GetRequestId() != requestID || frame.GetRegistered() == nil {
		return nil, errors.New("signaling registration response did not match request")
	}
	return frame.GetRegistered(), nil
}

func (client *Client) QueryPresence(
	ctx context.Context,
	deviceID []byte,
	requestID string,
) (*roammandv1.PresenceResult, error) {
	err := client.Send(ctx, &roammandv1.SignalingClientFrame{
		ProtocolVersion: protocolVersion(),
		RequestId:       requestID,
		Payload: &roammandv1.SignalingClientFrame_PresenceQuery{
			PresenceQuery: &roammandv1.PresenceQuery{DeviceId: deviceID},
		},
	})
	if err != nil {
		return nil, err
	}
	frame, err := client.Read(ctx)
	if err != nil {
		return nil, err
	}
	if frame.GetRequestId() != requestID || frame.GetPresenceResult() == nil {
		return nil, errors.New("signaling presence response did not match request")
	}
	return frame.GetPresenceResult(), nil
}

func (client *Client) Close(code websocket.StatusCode, reason string) error {
	return client.connection.Close(code, reason)
}

func (client *Client) CloseNow() error {
	return client.connection.CloseNow()
}

func protocolVersion() *roammandv1.ProtocolVersion {
	return &roammandv1.ProtocolVersion{Major: 1, Minor: 0}
}
