// SPDX-License-Identifier: AGPL-3.0-only

package state

import (
	"testing"
	"time"
)

func TestTrafficLimiterEnforcesGlobalIPAndByteLimits(t *testing.T) {
	now := time.Unix(100, 0)

	t.Run("per IP frames", func(t *testing.T) {
		limiter := NewTrafficLimiter(time.Minute, 10, 100, 2, 100, 10)
		if !limiter.Allow("192.0.2.1", 1, now) || !limiter.Allow("192.0.2.1", 1, now) {
			t.Fatal("valid frames were rejected")
		}
		if limiter.Allow("192.0.2.1", 1, now) {
			t.Fatal("per-IP frame limit was exceeded")
		}
	})

	t.Run("global frames", func(t *testing.T) {
		limiter := NewTrafficLimiter(time.Minute, 2, 100, 10, 100, 10)
		if !limiter.Allow("192.0.2.1", 1, now) || !limiter.Allow("192.0.2.2", 1, now) {
			t.Fatal("valid frames were rejected")
		}
		if limiter.Allow("192.0.2.3", 1, now) {
			t.Fatal("global frame limit was exceeded")
		}
	})

	t.Run("per IP bytes", func(t *testing.T) {
		limiter := NewTrafficLimiter(time.Minute, 10, 100, 10, 3, 10)
		if !limiter.Allow("192.0.2.1", 2, now) {
			t.Fatal("valid bytes were rejected")
		}
		if limiter.Allow("192.0.2.1", 2, now) {
			t.Fatal("per-IP byte limit was exceeded")
		}
	})

	t.Run("global bytes", func(t *testing.T) {
		limiter := NewTrafficLimiter(time.Minute, 10, 3, 10, 100, 10)
		if !limiter.Allow("192.0.2.1", 2, now) {
			t.Fatal("valid bytes were rejected")
		}
		if limiter.Allow("192.0.2.2", 2, now) {
			t.Fatal("global byte limit was exceeded")
		}
	})
}

func TestTrafficLimiterIPCapacityFailsClosedAndSweeps(t *testing.T) {
	limiter := NewTrafficLimiter(time.Minute, 10, 100, 10, 100, 1)
	now := time.Unix(100, 0)
	if !limiter.Allow("192.0.2.1", 1, now) {
		t.Fatal("first IP was rejected")
	}
	if limiter.Allow("192.0.2.2", 1, now) {
		t.Fatal("new IP exceeded the window capacity")
	}
	if limiter.IPWindowCount() != 1 {
		t.Fatalf("IP window count = %d, want 1", limiter.IPWindowCount())
	}

	limiter.Sweep(now.Add(time.Minute))
	if !limiter.Allow("192.0.2.2", 1, now.Add(time.Minute)) {
		t.Fatal("IP capacity did not recover after sweep")
	}
}

func TestTrafficLimiterConsumesRejectedFramesAndResetsAtBoundary(t *testing.T) {
	limiter := NewTrafficLimiter(time.Minute, 10, 3, 10, 3, 10)
	now := time.Unix(100, 0)
	if limiter.Allow("192.0.2.1", 4, now) {
		t.Fatal("oversized traffic allowance was accepted")
	}
	if limiter.Allow("192.0.2.1", 1, now) {
		t.Fatal("rejected traffic did not saturate the current window")
	}
	if !limiter.Allow("192.0.2.1", 3, now.Add(time.Minute)) {
		t.Fatal("traffic window did not reset at its boundary")
	}
}
