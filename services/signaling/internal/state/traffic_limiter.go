// SPDX-License-Identifier: AGPL-3.0-only

package state

import (
	"sync"
	"time"
)

type trafficWindow struct {
	startedAt time.Time
	frames    int
	bytes     int64
}

// TrafficLimiter bounds inbound WebSocket traffic across the process and per
// source IP. Its source-IP map has an independent hard capacity and fails
// closed for new keys when full.
type TrafficLimiter struct {
	mu             sync.Mutex
	window         time.Duration
	maxFrames      int
	maxBytes       int64
	maxFramesPerIP int
	maxBytesPerIP  int64
	maxIPWindows   int
	global         trafficWindow
	ipWindows      map[string]trafficWindow
}

func NewTrafficLimiter(
	window time.Duration,
	maxFrames int,
	maxBytes int64,
	maxFramesPerIP int,
	maxBytesPerIP int64,
	maxIPWindows int,
) *TrafficLimiter {
	if window <= 0 || maxFrames <= 0 || maxBytes <= 0 ||
		maxFramesPerIP <= 0 || maxBytesPerIP <= 0 || maxIPWindows <= 0 {
		panic("traffic limiter values must be positive")
	}
	return &TrafficLimiter{
		window:         window,
		maxFrames:      maxFrames,
		maxBytes:       maxBytes,
		maxFramesPerIP: maxFramesPerIP,
		maxBytesPerIP:  maxBytesPerIP,
		maxIPWindows:   maxIPWindows,
		ipWindows:      make(map[string]trafficWindow),
	}
}

func (limiter *TrafficLimiter) Allow(ip string, frameBytes int, now time.Time) bool {
	if frameBytes < 0 {
		return false
	}
	limiter.mu.Lock()
	defer limiter.mu.Unlock()

	global := currentTrafficWindow(limiter.global, now, limiter.window)
	globalAllowed := trafficWithinLimit(
		global,
		frameBytes,
		limiter.maxFrames,
		limiter.maxBytes,
	)
	global = consumeTraffic(global, frameBytes, limiter.maxFrames, limiter.maxBytes)
	limiter.global = global

	ipWindow, exists := limiter.ipWindows[ip]
	if !exists && len(limiter.ipWindows) >= limiter.maxIPWindows {
		return false
	}
	ipWindow = currentTrafficWindow(ipWindow, now, limiter.window)
	ipAllowed := trafficWithinLimit(
		ipWindow,
		frameBytes,
		limiter.maxFramesPerIP,
		limiter.maxBytesPerIP,
	)
	ipWindow = consumeTraffic(
		ipWindow,
		frameBytes,
		limiter.maxFramesPerIP,
		limiter.maxBytesPerIP,
	)
	limiter.ipWindows[ip] = ipWindow
	return globalAllowed && ipAllowed
}

func (limiter *TrafficLimiter) Sweep(now time.Time) {
	limiter.mu.Lock()
	defer limiter.mu.Unlock()
	for ip, window := range limiter.ipWindows {
		if !now.Before(window.startedAt.Add(limiter.window)) {
			delete(limiter.ipWindows, ip)
		}
	}
	if !limiter.global.startedAt.IsZero() &&
		!now.Before(limiter.global.startedAt.Add(limiter.window)) {
		limiter.global = trafficWindow{}
	}
}

func (limiter *TrafficLimiter) IPWindowCount() int {
	limiter.mu.Lock()
	defer limiter.mu.Unlock()
	return len(limiter.ipWindows)
}

func currentTrafficWindow(
	window trafficWindow,
	now time.Time,
	duration time.Duration,
) trafficWindow {
	if window.startedAt.IsZero() || !now.Before(window.startedAt.Add(duration)) {
		return trafficWindow{startedAt: now}
	}
	return window
}

func trafficWithinLimit(
	window trafficWindow,
	frameBytes int,
	maxFrames int,
	maxBytes int64,
) bool {
	return window.frames < maxFrames && int64(frameBytes) <= maxBytes-window.bytes
}

func consumeTraffic(
	window trafficWindow,
	frameBytes int,
	maxFrames int,
	maxBytes int64,
) trafficWindow {
	if window.frames < maxFrames {
		window.frames++
	}
	bytes := int64(frameBytes)
	if bytes >= maxBytes-window.bytes {
		window.bytes = maxBytes
	} else {
		window.bytes += bytes
	}
	return window
}
