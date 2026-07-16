// SPDX-License-Identifier: AGPL-3.0-only

package service

import (
	"time"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	"github.com/MisakiHCL/roammand/services/signaling/internal/state"
)

func (server *Server) handleFrame(
	connection *clientConnection,
	frame *roammandv1.SignalingClientFrame,
) bool {
	if !connection.registered.Load() {
		registration := frame.GetRegister()
		if registration == nil {
			return server.sendFrame(connection, publicError(
				roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST,
				frame.RequestId,
				0,
			))
		}
		return server.handleRegistration(connection, frame.RequestId, registration)
	}

	switch payload := frame.Payload.(type) {
	case *roammandv1.SignalingClientFrame_Register:
		return server.sendFrame(connection, publicError(
			roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST,
			frame.RequestId,
			0,
		))
	case *roammandv1.SignalingClientFrame_Heartbeat:
		return server.handleHeartbeat(connection, frame.RequestId)
	case *roammandv1.SignalingClientFrame_PresenceQuery:
		return server.handlePresenceQuery(connection, frame.RequestId, payload.PresenceQuery)
	case *roammandv1.SignalingClientFrame_CreateRendezvous:
		return server.handleCreateRendezvous(connection, frame.RequestId, payload.CreateRendezvous)
	case *roammandv1.SignalingClientFrame_JoinRendezvous:
		return server.handleJoinRendezvous(connection, frame.RequestId, payload.JoinRendezvous)
	case *roammandv1.SignalingClientFrame_RelayPairing:
		return server.handleRelayPairing(connection, frame.RequestId, payload.RelayPairing)
	case *roammandv1.SignalingClientFrame_CompleteRendezvous:
		return server.handleCompleteRendezvous(
			connection,
			frame.RequestId,
			payload.CompleteRendezvous,
		)
	case *roammandv1.SignalingClientFrame_RelaySession:
		return server.handleRelaySession(connection, frame.RequestId, payload.RelaySession)
	default:
		return server.sendFrame(connection, publicError(
			roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST,
			frame.RequestId,
			0,
		))
	}
}

func (server *Server) handleRegistration(
	connection *clientConnection,
	requestID string,
	registration *roammandv1.RegisterDevice,
) bool {
	deviceID, valid := state.DeviceIDFromBytes(registration.GetDeviceId())
	if !valid {
		return server.sendFrame(connection, publicError(
			roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST,
			requestID,
			0,
		))
	}
	now := server.options.Now()
	registered := server.presence.Register(deviceID, state.Route{
		Token: connection.token,
		Send:  connection.transport.TrySend,
		Close: connection.transport.CloseNow,
	}, now)
	if !registered {
		return server.sendFrame(connection, publicError(
			roammandv1.ErrorCode_ERROR_CODE_DEVICE_BUSY,
			requestID,
			0,
		))
	}
	connection.deviceID = deviceID
	connection.registered.Store(true)
	frame := baseServerFrame(requestID)
	frame.Payload = &roammandv1.SignalingServerFrame_Registered{
		Registered: &roammandv1.RegistrationAccepted{
			DeviceId:                deviceID.Bytes(),
			PresenceExpiresAtUnixMs: unixMilliseconds(now.Add(server.options.PresenceTimeout)),
		},
	}
	return server.sendFrame(connection, frame)
}

func (server *Server) handleHeartbeat(
	connection *clientConnection,
	requestID string,
) bool {
	now := server.options.Now()
	if !server.presence.Touch(connection.deviceID, connection.token, now) {
		connection.transport.CloseNow()
		return false
	}
	frame := baseServerFrame(requestID)
	frame.Payload = &roammandv1.SignalingServerFrame_HeartbeatAcknowledged{
		HeartbeatAcknowledged: &roammandv1.HeartbeatAcknowledged{
			ServerTimeUnixMs:        unixMilliseconds(now),
			PresenceExpiresAtUnixMs: unixMilliseconds(now.Add(server.options.PresenceTimeout)),
		},
	}
	return server.sendFrame(connection, frame)
}

func (server *Server) handlePresenceQuery(
	connection *clientConnection,
	requestID string,
	query *roammandv1.PresenceQuery,
) bool {
	deviceID, valid := state.DeviceIDFromBytes(query.GetDeviceId())
	if !valid {
		return server.sendFrame(connection, publicError(
			roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST,
			requestID,
			0,
		))
	}
	route, online := server.presence.Lookup(deviceID)
	if online && server.options.Now().Sub(route.LastSeen) > server.options.PresenceTimeout {
		online = false
	}
	frame := baseServerFrame(requestID)
	frame.Payload = &roammandv1.SignalingServerFrame_PresenceResult{
		PresenceResult: &roammandv1.PresenceResult{
			DeviceId: deviceID.Bytes(),
			Online:   online,
		},
	}
	return server.sendFrame(connection, frame)
}

func unixMilliseconds(value time.Time) uint64 {
	return uint64(value.UnixMilli())
}
