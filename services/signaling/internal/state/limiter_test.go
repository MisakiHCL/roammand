// SPDX-License-Identifier: AGPL-3.0-only

package state

import (
	"crypto/sha256"
	"fmt"
	"testing"
	"time"
)

const testLimiterEntryCapacity = 128

func TestLimiterRejectsThirtyFirstAttemptFromIP(t *testing.T) {
	limiter := newTestLimiter(time.Minute, 30, 5)
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
	limiter := newTestLimiter(time.Minute, 30, 5)
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
	limiter := newTestLimiter(time.Minute, 1, 1)
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

func TestLimiterCreateAndJoinShareIPBudget(t *testing.T) {
	limiter := newTestLimiter(time.Minute, 2, 5)
	now := time.Unix(100, 0)
	ip := "192.0.2.1"
	if !limiter.AllowIP(ip, now).Allowed {
		t.Fatal("create attempt was rejected")
	}
	if !limiter.Allow(ip, LookupKeyFromPairingCode("ABCDEFGH"), now).Allowed {
		t.Fatal("join attempt was rejected")
	}
	decision := limiter.AllowIP(ip, now)
	if decision.Allowed || decision.RetryAfter != time.Minute {
		t.Fatalf("shared IP decision = %+v", decision)
	}
}

func TestLimiterEntryCapFailsClosedWithoutGrowingMaps(t *testing.T) {
	limiter := NewFixedWindowLimiter(time.Minute, 30, 5, 1, 1)
	now := time.Unix(100, 0)
	firstKey := LookupKeyFromPairingCode("ABCDEFGH")
	if !limiter.Allow("192.0.2.1", firstKey, now).Allowed {
		t.Fatal("first attempt was rejected")
	}
	for _, attempt := range []struct {
		ip  string
		key [sha256.Size]byte
	}{
		{ip: "192.0.2.2", key: firstKey},
		{ip: "192.0.2.1", key: LookupKeyFromPairingCode("BCDEFGHA")},
	} {
		decision := limiter.Allow(attempt.ip, attempt.key, now)
		if decision.Allowed || decision.RetryAfter != time.Minute {
			t.Fatalf("capacity decision = %+v", decision)
		}
	}
	if ipWindows, lookups := limiter.WindowCounts(); ipWindows != 1 || lookups != 1 {
		t.Fatalf("window counts = (%d, %d), want (1, 1)", ipWindows, lookups)
	}

	limiter.Sweep(now.Add(time.Minute))
	if !limiter.Allow(
		"192.0.2.2",
		LookupKeyFromPairingCode("BCDEFGHA"),
		now.Add(time.Minute),
	).Allowed {
		t.Fatal("capacity did not recover after expired windows were swept")
	}
}

func newTestLimiter(window time.Duration, maxPerIP int, maxPerLookup int) *FixedWindowLimiter {
	return NewFixedWindowLimiter(
		window,
		maxPerIP,
		maxPerLookup,
		testLimiterEntryCapacity,
		testLimiterEntryCapacity,
	)
}
