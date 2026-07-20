// SPDX-License-Identifier: AGPL-3.0-only

package service

import (
	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	validation "github.com/MisakiHCL/roammand/gen/go/validation"
	"github.com/MisakiHCL/roammand/services/signaling/internal/state"
)

func (server *Server) handleRelaySession(
	connection *clientConnection,
	requestID string,
	request *roammandv1.RelaySessionEnvelope,
) bool {
	recipientID, valid := state.DeviceIDFromBytes(request.GetRecipientDeviceId())
	if !valid || len(request.GetOpaqueEnvelope()) == 0 ||
		len(request.GetOpaqueEnvelope()) > validation.MaxOpaqueSignalingEnvelopeBytes {
		return server.sendFrame(connection, publicError(
			roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST,
			requestID,
			0,
		))
	}
	frame := baseServerFrame("")
	frame.Payload = &roammandv1.SignalingServerFrame_RoutedSession{
		RoutedSession: &roammandv1.RoutedSessionEnvelope{
			SenderDeviceId: connection.deviceID.Bytes(),
			OpaqueEnvelope: request.GetOpaqueEnvelope(),
		},
	}
	if server.sendToDevice(recipientID, frame) {
		return true
	}
	return server.sendFrame(connection, publicError(
		roammandv1.ErrorCode_ERROR_CODE_DEVICE_OFFLINE,
		requestID,
		0,
	))
}
