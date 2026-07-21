// SPDX-License-Identifier: AGPL-3.0-only

package service

import "time"

type inboundWindow struct {
	startedAt time.Time
	frames    int
	bytes     int64
}

func (server *Server) allowInbound(
	connection *clientConnection,
	frameBytes int,
	now time.Time,
) bool {
	sharedAllowed := server.inboundLimiter.Allow(connection.remoteIP, frameBytes, now)
	limits := server.options.InboundLimits
	window := connection.inbound
	if window.startedAt.IsZero() || !now.Before(window.startedAt.Add(limits.Window)) {
		window = inboundWindow{startedAt: now}
	}
	connectionAllowed := window.frames < limits.FramesPerConnection &&
		int64(frameBytes) <= limits.BytesPerConnection-window.bytes
	if window.frames < limits.FramesPerConnection {
		window.frames++
	}
	bytes := int64(frameBytes)
	if bytes >= limits.BytesPerConnection-window.bytes {
		window.bytes = limits.BytesPerConnection
	} else {
		window.bytes += bytes
	}
	connection.inbound = window
	return sharedAllowed && connectionAllowed
}
