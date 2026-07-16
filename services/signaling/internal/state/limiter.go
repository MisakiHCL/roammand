// SPDX-License-Identifier: AGPL-3.0-only

package state

import (
	"crypto/sha256"
	"sync"
	"time"
)

type LimitDecision struct {
	Allowed    bool
	RetryAfter time.Duration
}

type windowCounter struct {
	startedAt time.Time
	count     int
}

type FixedWindowLimiter struct {
	mu            sync.Mutex
	window        time.Duration
	maxPerIP      int
	maxPerLookup  int
	ipWindows     map[string]windowCounter
	lookupWindows map[[sha256.Size]byte]windowCounter
}

func NewFixedWindowLimiter(
	window time.Duration,
	maxPerIP int,
	maxPerLookup int,
) *FixedWindowLimiter {
	return &FixedWindowLimiter{
		window:        window,
		maxPerIP:      maxPerIP,
		maxPerLookup:  maxPerLookup,
		ipWindows:     make(map[string]windowCounter),
		lookupWindows: make(map[[sha256.Size]byte]windowCounter),
	}
}

func (limiter *FixedWindowLimiter) Allow(
	ip string,
	lookupKey [sha256.Size]byte,
	now time.Time,
) LimitDecision {
	limiter.mu.Lock()
	defer limiter.mu.Unlock()

	ipCounter := limiter.currentCounter(limiter.ipWindows[ip], now)
	lookupCounter := limiter.currentCounter(limiter.lookupWindows[lookupKey], now)

	retryAfter := time.Duration(0)
	if ipCounter.count >= limiter.maxPerIP {
		retryAfter = maxDuration(retryAfter, ipCounter.startedAt.Add(limiter.window).Sub(now))
	}
	if lookupCounter.count >= limiter.maxPerLookup {
		retryAfter = maxDuration(
			retryAfter,
			lookupCounter.startedAt.Add(limiter.window).Sub(now),
		)
	}
	if retryAfter > 0 {
		return LimitDecision{RetryAfter: retryAfter}
	}

	ipCounter.count++
	lookupCounter.count++
	limiter.ipWindows[ip] = ipCounter
	limiter.lookupWindows[lookupKey] = lookupCounter
	return LimitDecision{Allowed: true}
}

func (limiter *FixedWindowLimiter) Sweep(now time.Time) {
	limiter.mu.Lock()
	defer limiter.mu.Unlock()

	for key, counter := range limiter.ipWindows {
		if !now.Before(counter.startedAt.Add(limiter.window)) {
			delete(limiter.ipWindows, key)
		}
	}
	for key, counter := range limiter.lookupWindows {
		if !now.Before(counter.startedAt.Add(limiter.window)) {
			delete(limiter.lookupWindows, key)
		}
	}
}

func (limiter *FixedWindowLimiter) WindowCounts() (int, int) {
	limiter.mu.Lock()
	defer limiter.mu.Unlock()
	return len(limiter.ipWindows), len(limiter.lookupWindows)
}

func (limiter *FixedWindowLimiter) currentCounter(
	counter windowCounter,
	now time.Time,
) windowCounter {
	if counter.startedAt.IsZero() || !now.Before(counter.startedAt.Add(limiter.window)) {
		return windowCounter{startedAt: now}
	}
	return counter
}

func LookupKeyFromRendezvousID(id RendezvousID) [sha256.Size]byte {
	encoded := append([]byte("roammand-rendezvous-id:"), id[:]...)
	return sha256.Sum256(encoded)
}

func LookupKeyFromPairingCode(pairingCode string) [sha256.Size]byte {
	return pairingCodeHash(pairingCode)
}

func maxDuration(left time.Duration, right time.Duration) time.Duration {
	if left > right {
		return left
	}
	return right
}
