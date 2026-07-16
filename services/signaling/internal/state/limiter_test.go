// SPDX-License-Identifier: AGPL-3.0-only

package state

import (
	"fmt"
	"testing"
	"time"
)

func TestLimiterRejectsThirtyFirstAttemptFromIP(t *testing.T) {
	limiter := NewFixedWindowLimiter(time.Minute, 30, 5)
	now := time.Unix(100, 0)

	for attempt := 0; attempt < 30; attempt++ {
		key := LookupKeyFromPairingCode(fmt.Sprintf("CODE%04d", attempt))
		decision := limiter.Allow("192.0.2.1", key, now)
		if !decision.Allowed {
			t.Fatalf("attempt %d rejected with retry %s", attempt+1, decision.RetryAfter)
		}
	}
	decision := limiter.Allow("192.0.2.1", LookupKeyFromPairingCode("LASTCODE"), now)
	if decision.Allowed || decision.RetryAfter != time.Minute {
		t.Fatalf("decision = %+v, want denied for one minute", decision)
	}
}

func TestLimiterRejectsSixthAttemptForLookup(t *testing.T) {
	limiter := NewFixedWindowLimiter(time.Minute, 30, 5)
	now := time.Unix(100, 0)
	key := LookupKeyFromRendezvousID(testRendezvousID(1))

	for attempt := 0; attempt < 5; attempt++ {
		decision := limiter.Allow(fmt.Sprintf("192.0.2.%d", attempt+1), key, now)
		if !decision.Allowed {
			t.Fatalf("attempt %d rejected with retry %s", attempt+1, decision.RetryAfter)
		}
	}
	decision := limiter.Allow("192.0.2.99", key, now.Add(10*time.Second))
	if decision.Allowed || decision.RetryAfter != 50*time.Second {
		t.Fatalf("decision = %+v, want denied for 50 seconds", decision)
	}
}

func TestLimiterResetsAndSweepsExpiredWindows(t *testing.T) {
	limiter := NewFixedWindowLimiter(time.Minute, 1, 1)
	now := time.Unix(100, 0)
	key := LookupKeyFromPairingCode("ABCDEFGH")

	if !limiter.Allow("192.0.2.1", key, now).Allowed {
		t.Fatal("first attempt was rejected")
	}
	if !limiter.Allow("192.0.2.1", key, now.Add(time.Minute)).Allowed {
		t.Fatal("attempt was not allowed after window reset")
	}
	limiter.Sweep(now.Add(2 * time.Minute))
	ipWindows, lookupWindows := limiter.WindowCounts()
	if ipWindows != 0 || lookupWindows != 0 {
		t.Fatalf("window counts = (%d, %d), want zero", ipWindows, lookupWindows)
	}
}
