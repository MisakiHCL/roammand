// SPDX-License-Identifier: AGPL-3.0-only

package service

import "github.com/MisakiHCL/roammand/services/signaling/internal/transport"

type sourceIPUsage struct {
	connections       int
	outboundBytes     int64
	inFlightReadBytes int64
}

type sourceIPOutboundBudget struct {
	server   *Server
	remoteIP string
}

type sourceIPInFlightReadBudget struct {
	server   *Server
	remoteIP string
}

type sourceIPBudgets struct {
	outbound     transport.ByteReservationBudget
	inFlightRead transport.ByteReservationBudget
}

func (server *Server) acquireIPConnection(
	remoteIP string,
) (sourceIPBudgets, bool) {
	server.sourceIPMu.Lock()
	defer server.sourceIPMu.Unlock()
	usage := server.sourceIPs[remoteIP]
	if usage == nil {
		usage = &sourceIPUsage{}
		server.sourceIPs[remoteIP] = usage
	}
	if usage.connections >= server.options.MaxConnectionsPerIP {
		return sourceIPBudgets{}, false
	}
	usage.connections++
	return sourceIPBudgets{
		outbound:     &sourceIPOutboundBudget{server: server, remoteIP: remoteIP},
		inFlightRead: &sourceIPInFlightReadBudget{server: server, remoteIP: remoteIP},
	}, true
}

func (server *Server) releaseIPConnection(remoteIP string) {
	server.sourceIPMu.Lock()
	defer server.sourceIPMu.Unlock()
	usage := server.sourceIPs[remoteIP]
	if usage == nil || usage.connections <= 0 {
		panic("source IP connection release exceeds reservation")
	}
	usage.connections--
	server.deleteIdleSourceIPLocked(remoteIP, usage)
}

func (budget *sourceIPOutboundBudget) TryReserve(bytes int64) bool {
	if bytes < 0 {
		return false
	}
	budget.server.sourceIPMu.Lock()
	defer budget.server.sourceIPMu.Unlock()
	usage := budget.server.sourceIPs[budget.remoteIP]
	if usage == nil || usage.connections <= 0 ||
		bytes > budget.server.options.MaxOutboundBytesPerIP-usage.outboundBytes {
		return false
	}
	usage.outboundBytes += bytes
	return true
}

func (budget *sourceIPOutboundBudget) Release(bytes int64) {
	budget.server.sourceIPMu.Lock()
	defer budget.server.sourceIPMu.Unlock()
	usage := budget.server.sourceIPs[budget.remoteIP]
	if bytes < 0 || usage == nil || bytes > usage.outboundBytes {
		panic("source IP outbound byte release exceeds reservation")
	}
	usage.outboundBytes -= bytes
	budget.server.deleteIdleSourceIPLocked(budget.remoteIP, usage)
}

func (budget *sourceIPInFlightReadBudget) TryReserve(bytes int64) bool {
	if bytes < 0 {
		return false
	}
	budget.server.sourceIPMu.Lock()
	defer budget.server.sourceIPMu.Unlock()
	usage := budget.server.sourceIPs[budget.remoteIP]
	if usage == nil || usage.connections <= 0 ||
		bytes > budget.server.options.MaxInFlightReadBytesPerIP-usage.inFlightReadBytes {
		return false
	}
	usage.inFlightReadBytes += bytes
	return true
}

func (budget *sourceIPInFlightReadBudget) Release(bytes int64) {
	budget.server.sourceIPMu.Lock()
	defer budget.server.sourceIPMu.Unlock()
	usage := budget.server.sourceIPs[budget.remoteIP]
	if bytes < 0 || usage == nil || bytes > usage.inFlightReadBytes {
		panic("source IP in-flight read byte release exceeds reservation")
	}
	usage.inFlightReadBytes -= bytes
	budget.server.deleteIdleSourceIPLocked(budget.remoteIP, usage)
}

func (server *Server) deleteIdleSourceIPLocked(remoteIP string, usage *sourceIPUsage) {
	if usage.connections == 0 && usage.outboundBytes == 0 && usage.inFlightReadBytes == 0 {
		delete(server.sourceIPs, remoteIP)
	}
}

func (server *Server) connectionCountForIP(remoteIP string) int {
	server.sourceIPMu.Lock()
	defer server.sourceIPMu.Unlock()
	usage := server.sourceIPs[remoteIP]
	if usage == nil {
		return 0
	}
	return usage.connections
}

func (server *Server) outboundBytesForIP(remoteIP string) int64 {
	server.sourceIPMu.Lock()
	defer server.sourceIPMu.Unlock()
	usage := server.sourceIPs[remoteIP]
	if usage == nil {
		return 0
	}
	return usage.outboundBytes
}

func (server *Server) inFlightReadBytesForIP(remoteIP string) int64 {
	server.sourceIPMu.Lock()
	defer server.sourceIPMu.Unlock()
	usage := server.sourceIPs[remoteIP]
	if usage == nil {
		return 0
	}
	return usage.inFlightReadBytes
}
