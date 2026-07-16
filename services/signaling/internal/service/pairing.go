// SPDX-License-Identifier: AGPL-3.0-only

package service

import (
	"errors"
	"strings"
	"time"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	validation "github.com/MisakiHCL/roammand/gen/go/validation"
	"github.com/MisakiHCL/roammand/services/signaling/internal/state"
	"google.golang.org/protobuf/proto"
)

func (server *Server) handleCreateRendezvous(
	connection *clientConnection,
	requestID string,
	request *roammandv1.CreatePairingRendezvous,
) bool {
	rendezvousID, valid := state.RendezvousIDFromBytes(request.GetRendezvousId())
	if !valid {
		return server.sendFrame(connection, publicError(
			roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST,
			requestID,
			0,
		))
	}
	kind, valid := pairingKind(request.GetKind())
	if !valid || !validCreatePairingCode(kind, request.GetPairingCode()) {
		return server.sendFrame(connection, publicError(
			roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST,
			requestID,
			0,
		))
	}
	now := server.options.Now()
	rendezvous := state.Rendezvous{
		ID:        rendezvousID,
		Kind:      kind,
		Host:      connection.deviceID,
		ExpiresAt: now.Add(server.options.RendezvousTTL),
	}
	if err := server.rendezvous.Create(rendezvous, request.GetPairingCode()); err != nil {
		return server.sendPairingError(connection, requestID, err, 0)
	}
	frame := baseServerFrame(requestID)
	frame.Payload = &roammandv1.SignalingServerFrame_RendezvousCreated{
		RendezvousCreated: &roammandv1.PairingRendezvousCreated{
			RendezvousId:    rendezvousID.Bytes(),
			Kind:            request.GetKind(),
			ExpiresAtUnixMs: unixMilliseconds(rendezvous.ExpiresAt),
		},
	}
	return server.sendFrame(connection, frame)
}

func (server *Server) handleJoinRendezvous(
	connection *clientConnection,
	requestID string,
	request *roammandv1.JoinPairingRendezvous,
) bool {
	now := server.options.Now()
	var (
		rendezvous state.Rendezvous
		joinErr    error
		lookupKey  [32]byte
	)
	switch lookup := request.GetLookup().(type) {
	case *roammandv1.JoinPairingRendezvous_RendezvousId:
		id, valid := state.RendezvousIDFromBytes(lookup.RendezvousId)
		if !valid {
			return server.sendFrame(connection, publicError(
				roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST,
				requestID,
				0,
			))
		}
		lookupKey = state.LookupKeyFromRendezvousID(id)
		decision := server.limiter.Allow(connection.remoteIP, lookupKey, now)
		if !decision.Allowed {
			return server.sendPairingError(
				connection,
				requestID,
				roammandv1.ErrorCode_ERROR_CODE_PAIRING_RATE_LIMITED,
				decision.RetryAfter,
			)
		}
		rendezvous, joinErr = server.rendezvous.JoinByID(id, connection.deviceID, now)
	case *roammandv1.JoinPairingRendezvous_PairingCode:
		pairingCode := strings.ToUpper(strings.TrimSpace(lookup.PairingCode))
		if !validPairingCode(pairingCode) {
			return server.sendFrame(connection, publicError(
				roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST,
				requestID,
				0,
			))
		}
		lookupKey = state.LookupKeyFromPairingCode(pairingCode)
		decision := server.limiter.Allow(connection.remoteIP, lookupKey, now)
		if !decision.Allowed {
			return server.sendPairingError(
				connection,
				requestID,
				roammandv1.ErrorCode_ERROR_CODE_PAIRING_RATE_LIMITED,
				decision.RetryAfter,
			)
		}
		rendezvous, joinErr = server.rendezvous.JoinByCode(pairingCode, connection.deviceID, now)
	default:
		return server.sendFrame(connection, publicError(
			roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST,
			requestID,
			0,
		))
	}
	if joinErr != nil {
		return server.sendPairingError(connection, requestID, joinErr, 0)
	}

	hostJoined := rendezvousJoinedFrame("", rendezvous, connection.deviceID)
	if !server.sendToDevice(rendezvous.Host, hostJoined) {
		_, _ = server.rendezvous.Complete(rendezvous.ID, rendezvous.Host, now)
		return server.sendFrame(connection, publicError(
			roammandv1.ErrorCode_ERROR_CODE_DEVICE_OFFLINE,
			requestID,
			0,
		))
	}
	return server.sendFrame(
		connection,
		rendezvousJoinedFrame(requestID, rendezvous, rendezvous.Host),
	)
}

func (server *Server) handleRelayPairing(
	connection *clientConnection,
	requestID string,
	request *roammandv1.RelayPairingEnvelope,
) bool {
	rendezvousID, valid := state.RendezvousIDFromBytes(request.GetRendezvousId())
	if !valid || len(request.GetOpaqueEnvelope()) == 0 ||
		len(request.GetOpaqueEnvelope()) > validation.MaxOpaqueSignalingEnvelopeBytes {
		return server.sendFrame(connection, publicError(
			roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST,
			requestID,
			0,
		))
	}
	peer, _, err := server.rendezvous.Peer(rendezvousID, connection.deviceID, server.options.Now())
	if err != nil {
		return server.sendPairingError(connection, requestID, err, 0)
	}
	frame := baseServerFrame("")
	frame.Payload = &roammandv1.SignalingServerFrame_RoutedPairing{
		RoutedPairing: &roammandv1.RoutedPairingEnvelope{
			RendezvousId:   rendezvousID.Bytes(),
			SenderDeviceId: connection.deviceID.Bytes(),
			OpaqueEnvelope: append([]byte(nil), request.GetOpaqueEnvelope()...),
		},
	}
	if server.sendToDevice(peer, frame) {
		return true
	}
	return server.sendFrame(connection, publicError(
		roammandv1.ErrorCode_ERROR_CODE_DEVICE_OFFLINE,
		requestID,
		0,
	))
}

func (server *Server) handleCompleteRendezvous(
	connection *clientConnection,
	requestID string,
	request *roammandv1.CompletePairingRendezvous,
) bool {
	rendezvousID, valid := state.RendezvousIDFromBytes(request.GetRendezvousId())
	if !valid ||
		(request.GetCompletion() != roammandv1.PairingRendezvousCompletion_PAIRING_RENDEZVOUS_COMPLETION_SUCCEEDED &&
			request.GetCompletion() != roammandv1.PairingRendezvousCompletion_PAIRING_RENDEZVOUS_COMPLETION_REJECTED) {
		return server.sendFrame(connection, publicError(
			roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST,
			requestID,
			0,
		))
	}
	rendezvous, err := server.rendezvous.Complete(
		rendezvousID,
		connection.deviceID,
		server.options.Now(),
	)
	if err != nil {
		return server.sendPairingError(connection, requestID, err, 0)
	}
	server.sendFrame(connection, rendezvousClosedFrame(requestID, rendezvous.ID, request.GetCompletion()))
	if rendezvous.Controller != nil {
		server.sendToDevice(
			*rendezvous.Controller,
			rendezvousClosedFrame("", rendezvous.ID, request.GetCompletion()),
		)
	}
	return true
}

func (server *Server) sendPairingError(
	connection *clientConnection,
	requestID string,
	cause any,
	retryAfter time.Duration,
) bool {
	var code roammandv1.ErrorCode
	switch value := cause.(type) {
	case roammandv1.ErrorCode:
		code = value
	case error:
		switch {
		case errors.Is(value, state.ErrRendezvousNotFound):
			code = roammandv1.ErrorCode_ERROR_CODE_PAIRING_CODE_EXPIRED
		case errors.Is(value, state.ErrRendezvousInvalid),
			errors.Is(value, state.ErrRendezvousExists),
			errors.Is(value, state.ErrPairingCodeExists),
			errors.Is(value, state.ErrRendezvousFull),
			errors.Is(value, state.ErrRendezvousSelfJoin),
			errors.Is(value, state.ErrRendezvousNotMember),
			errors.Is(value, state.ErrRendezvousNotHost),
			errors.Is(value, state.ErrRendezvousNotJoined):
			code = roammandv1.ErrorCode_ERROR_CODE_PAIRING_REJECTED
		default:
			code = roammandv1.ErrorCode_ERROR_CODE_SERVER_UNAVAILABLE
		}
	default:
		code = roammandv1.ErrorCode_ERROR_CODE_SERVER_UNAVAILABLE
	}
	return server.sendFrame(connection, publicError(code, requestID, retryAfter))
}

func (server *Server) sendToDevice(
	deviceID state.DeviceID,
	frame *roammandv1.SignalingServerFrame,
) bool {
	route, online := server.presence.Lookup(deviceID)
	if !online {
		return false
	}
	encoded, err := proto.Marshal(frame)
	if err != nil {
		return false
	}
	if route.Send != nil && route.Send(encoded) {
		return true
	}
	if route.Close != nil {
		route.Close()
	}
	return false
}

func (server *Server) notifyRendezvousClosed(
	rendezvous state.Rendezvous,
	completion roammandv1.PairingRendezvousCompletion,
	excluded *state.DeviceID,
) {
	if excluded == nil || rendezvous.Host != *excluded {
		server.sendToDevice(
			rendezvous.Host,
			rendezvousClosedFrame("", rendezvous.ID, completion),
		)
	}
	if rendezvous.Controller != nil && (excluded == nil || *rendezvous.Controller != *excluded) {
		server.sendToDevice(
			*rendezvous.Controller,
			rendezvousClosedFrame("", rendezvous.ID, completion),
		)
	}
}

func pairingKind(kind roammandv1.PairingRendezvousKind) (state.PairingKind, bool) {
	switch kind {
	case roammandv1.PairingRendezvousKind_PAIRING_RENDEZVOUS_KIND_QR:
		return state.PairingKindQR, true
	case roammandv1.PairingRendezvousKind_PAIRING_RENDEZVOUS_KIND_DESKTOP_CODE:
		return state.PairingKindDesktopCode, true
	default:
		return 0, false
	}
}

func validCreatePairingCode(kind state.PairingKind, pairingCode string) bool {
	if kind == state.PairingKindQR {
		return pairingCode == ""
	}
	return validPairingCode(pairingCode) && pairingCode == strings.ToUpper(pairingCode)
}

func validPairingCode(pairingCode string) bool {
	if len(pairingCode) != validation.DesktopPairingCodeBytes {
		return false
	}
	for _, character := range []byte(pairingCode) {
		if !(character >= 'A' && character <= 'Z') && !(character >= '2' && character <= '7') {
			return false
		}
	}
	return true
}

func rendezvousJoinedFrame(
	requestID string,
	rendezvous state.Rendezvous,
	peer state.DeviceID,
) *roammandv1.SignalingServerFrame {
	frame := baseServerFrame(requestID)
	frame.Payload = &roammandv1.SignalingServerFrame_RendezvousJoined{
		RendezvousJoined: &roammandv1.PairingRendezvousJoined{
			RendezvousId:    rendezvous.ID.Bytes(),
			PeerDeviceId:    peer.Bytes(),
			ExpiresAtUnixMs: unixMilliseconds(rendezvous.ExpiresAt),
		},
	}
	return frame
}

func rendezvousClosedFrame(
	requestID string,
	rendezvousID state.RendezvousID,
	completion roammandv1.PairingRendezvousCompletion,
) *roammandv1.SignalingServerFrame {
	frame := baseServerFrame(requestID)
	frame.Payload = &roammandv1.SignalingServerFrame_RendezvousClosed{
		RendezvousClosed: &roammandv1.PairingRendezvousClosed{
			RendezvousId: rendezvousID.Bytes(),
			Completion:   completion,
		},
	}
	return frame
}
