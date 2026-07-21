// SPDX-License-Identifier: AGPL-3.0-only

package state

import (
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"
)

const (
	testMaxRendezvousPerHost = 8
	testMaxRendezvous        = 64
)

func TestRendezvousCodeJoinStoresOnlyHash(t *testing.T) {
	store := newTestRendezvousStore(testMaxRendezvousPerHost)
	now := time.Unix(100, 0)
	created := Rendezvous{
		ID:        testRendezvousID(1),
		Kind:      PairingKindDesktopCode,
		Host:      testDeviceID(1),
		ExpiresAt: now.Add(2 * time.Minute),
	}

	if _, err := store.Create(created, "ABCDEFGH", now); err != nil {
		t.Fatal(err)
	}
	joined, err := store.JoinByCode("abcdefgh", testDeviceID(2), now)
	if err != nil {
		t.Fatal(err)
	}
	if joined.Controller == nil || *joined.Controller != testDeviceID(2) {
		t.Fatalf("controller = %v, want device 2", joined.Controller)
	}
	store.mu.RLock()
	snapshot := fmt.Sprintf("%+v", store.byID)
	store.mu.RUnlock()
	if strings.Contains(snapshot, "ABCDEFGH") {
		t.Fatal("rendezvous state retained plaintext pairing code")
	}
}

func TestRendezvousExpiresAfterExactlyTwoMinutes(t *testing.T) {
	store := newTestRendezvousStore(testMaxRendezvousPerHost)
	now := time.Unix(100, 0)
	rendezvous := Rendezvous{
		ID:        testRendezvousID(2),
		Kind:      PairingKindQR,
		Host:      testDeviceID(1),
		ExpiresAt: now.Add(2 * time.Minute),
	}

	if _, err := store.Create(rendezvous, "", now); err != nil {
		t.Fatal(err)
	}
	removed := store.Sweep(now.Add(2 * time.Minute))
	if len(removed) != 1 || removed[0].ID != rendezvous.ID {
		t.Fatalf("removed = %+v, want rendezvous 2", removed)
	}
	if store.Len() != 0 {
		t.Fatalf("store length = %d, want 0", store.Len())
	}
}

func TestExpiredLookupLeavesRendezvousForSweepNotification(t *testing.T) {
	store := newTestRendezvousStore(testMaxRendezvousPerHost)
	now := time.Unix(100, 0)
	rendezvous := Rendezvous{
		ID:        testRendezvousID(24),
		Kind:      PairingKindQR,
		Host:      testDeviceID(1),
		ExpiresAt: now.Add(time.Second),
	}
	if _, err := store.Create(rendezvous, "", now); err != nil {
		t.Fatal(err)
	}
	if _, err := store.JoinByID(rendezvous.ID, testDeviceID(2), now); err != nil {
		t.Fatal(err)
	}

	expiresAt := now.Add(time.Second)
	if _, _, err := store.Peer(rendezvous.ID, rendezvous.Host, expiresAt); !errors.Is(err, ErrRendezvousNotFound) {
		t.Fatalf("expired peer lookup error = %v, want %v", err, ErrRendezvousNotFound)
	}
	if store.Len() != 1 {
		t.Fatal("expired lookup removed rendezvous before the notifying sweep")
	}
	removed := store.Sweep(expiresAt)
	if len(removed) != 1 || removed[0].ID != rendezvous.ID || store.Len() != 0 {
		t.Fatalf("sweep removed=%+v remaining=%d", removed, store.Len())
	}
}

func TestRendezvousAllowsOneDistinctController(t *testing.T) {
	store := newTestRendezvousStore(testMaxRendezvousPerHost)
	now := time.Unix(100, 0)
	id := testRendezvousID(3)
	host := testDeviceID(1)
	if _, err := store.Create(Rendezvous{
		ID: id, Kind: PairingKindQR, Host: host, ExpiresAt: now.Add(time.Minute),
	}, "", now); err != nil {
		t.Fatal(err)
	}

	if _, err := store.JoinByID(id, host, now); !errors.Is(err, ErrRendezvousSelfJoin) {
		t.Fatalf("self join error = %v, want %v", err, ErrRendezvousSelfJoin)
	}
	if _, err := store.JoinByID(id, testDeviceID(2), now); err != nil {
		t.Fatal(err)
	}
	if _, err := store.JoinByID(id, testDeviceID(3), now); !errors.Is(err, ErrRendezvousFull) {
		t.Fatalf("second controller error = %v, want %v", err, ErrRendezvousFull)
	}
}

func TestRendezvousPeerAndHostOnlyCompletion(t *testing.T) {
	store := newTestRendezvousStore(testMaxRendezvousPerHost)
	now := time.Unix(100, 0)
	id := testRendezvousID(4)
	host := testDeviceID(1)
	controller := testDeviceID(2)
	if _, err := store.Create(Rendezvous{
		ID: id, Kind: PairingKindQR, Host: host, ExpiresAt: now.Add(time.Minute),
	}, "", now); err != nil {
		t.Fatal(err)
	}
	if _, err := store.JoinByID(id, controller, now); err != nil {
		t.Fatal(err)
	}

	peer, _, err := store.Peer(id, host, now)
	if err != nil || peer != controller {
		t.Fatalf("host peer = (%v, %v), want controller", peer, err)
	}
	peer, _, err = store.Peer(id, controller, now)
	if err != nil || peer != host {
		t.Fatalf("controller peer = (%v, %v), want host", peer, err)
	}
	if _, _, err := store.Peer(id, testDeviceID(3), now); !errors.Is(err, ErrRendezvousNotMember) {
		t.Fatalf("non-member error = %v, want %v", err, ErrRendezvousNotMember)
	}
	if _, err := store.Complete(id, controller, now); !errors.Is(err, ErrRendezvousNotHost) {
		t.Fatalf("controller completion error = %v, want %v", err, ErrRendezvousNotHost)
	}
	if _, err := store.Complete(id, host, now); err != nil {
		t.Fatal(err)
	}
	if store.Len() != 0 {
		t.Fatalf("store length = %d, want 0 after completion", store.Len())
	}
}

func TestRendezvousDisconnectRemovesMemberSessions(t *testing.T) {
	store := newTestRendezvousStore(testMaxRendezvousPerHost)
	now := time.Unix(100, 0)
	host := testDeviceID(1)
	controller := testDeviceID(2)
	for seed := byte(5); seed < 7; seed++ {
		id := testRendezvousID(seed)
		if _, err := store.Create(Rendezvous{
			ID: id, Kind: PairingKindQR, Host: host, ExpiresAt: now.Add(time.Minute),
		}, "", now); err != nil {
			t.Fatal(err)
		}
		if _, err := store.JoinByID(id, controller, now); err != nil {
			t.Fatal(err)
		}
	}

	removed := store.RemoveForDevice(controller)
	if len(removed) != 2 || store.Len() != 0 {
		t.Fatalf("removed=%d remaining=%d, want 2 and 0", len(removed), store.Len())
	}
}

func TestRendezvousLimitsActiveEntriesPerHostAndReleasesCapacity(t *testing.T) {
	const maxPerHost = 2
	store := newTestRendezvousStore(maxPerHost)
	now := time.Unix(100, 0)
	host := testDeviceID(1)
	otherHost := testDeviceID(2)

	create := func(idSeed byte, owner DeviceID) error {
		_, err := store.Create(Rendezvous{
			ID:        testRendezvousID(idSeed),
			Kind:      PairingKindQR,
			Host:      owner,
			ExpiresAt: now.Add(time.Minute),
		}, "", now)
		return err
	}
	if err := create(10, host); err != nil {
		t.Fatal(err)
	}
	if err := create(11, host); err != nil {
		t.Fatal(err)
	}
	if err := create(12, host); !errors.Is(err, ErrRendezvousLimit) {
		t.Fatalf("third rendezvous error = %v, want %v", err, ErrRendezvousLimit)
	}
	if err := create(13, otherHost); err != nil {
		t.Fatalf("other host was affected by limit: %v", err)
	}

	if _, err := store.Complete(testRendezvousID(10), host, now); err != nil {
		t.Fatal(err)
	}
	if err := create(12, host); err != nil {
		t.Fatalf("released capacity was not reusable: %v", err)
	}
}

func TestRendezvousLimitsGlobalEntriesAndReleasesCapacity(t *testing.T) {
	const maxTotal = 2
	store := NewRendezvousStore(testMaxRendezvousPerHost, maxTotal)
	now := time.Unix(100, 0)
	create := func(idSeed byte, hostSeed byte) error {
		_, err := store.Create(Rendezvous{
			ID:        testRendezvousID(idSeed),
			Kind:      PairingKindQR,
			Host:      testDeviceID(hostSeed),
			ExpiresAt: now.Add(time.Minute),
		}, "", now)
		return err
	}
	if err := create(14, 1); err != nil {
		t.Fatal(err)
	}
	if err := create(15, 2); err != nil {
		t.Fatal(err)
	}
	if err := create(16, 3); !errors.Is(err, ErrRendezvousCapacity) {
		t.Fatalf("capacity error = %v, want %v", err, ErrRendezvousCapacity)
	}
	if _, err := store.Complete(testRendezvousID(14), testDeviceID(1), now); err != nil {
		t.Fatal(err)
	}
	if err := create(16, 3); err != nil {
		t.Fatalf("released global capacity was not reusable: %v", err)
	}
}

func TestRendezvousMemberIndexRemovesOnlyMatchingDevice(t *testing.T) {
	store := newTestRendezvousStore(testMaxRendezvousPerHost)
	now := time.Unix(100, 0)
	for seed := byte(30); seed < 32; seed++ {
		if _, err := store.Create(Rendezvous{
			ID:        testRendezvousID(seed),
			Kind:      PairingKindQR,
			Host:      testDeviceID(seed),
			ExpiresAt: now.Add(time.Minute),
		}, "", now); err != nil {
			t.Fatal(err)
		}
		if _, err := store.JoinByID(testRendezvousID(seed), testDeviceID(seed+10), now); err != nil {
			t.Fatal(err)
		}
	}

	removed := store.RemoveForDevice(testDeviceID(40))
	if len(removed) != 1 || removed[0].ID != testRendezvousID(30) || store.Len() != 1 {
		t.Fatalf("removed=%+v remaining=%d", removed, store.Len())
	}
	if _, _, err := store.Peer(
		testRendezvousID(31),
		testDeviceID(31),
		now,
	); err != nil {
		t.Fatalf("unrelated rendezvous was removed: %v", err)
	}
}

func TestRendezvousCreateReleasesExpiredHostCapacityImmediately(t *testing.T) {
	store := newTestRendezvousStore(1)
	now := time.Unix(100, 0)
	host := testDeviceID(1)
	if _, err := store.Create(Rendezvous{
		ID:        testRendezvousID(20),
		Kind:      PairingKindQR,
		Host:      host,
		ExpiresAt: now.Add(time.Second),
	}, "", now); err != nil {
		t.Fatal(err)
	}

	later := now.Add(time.Second)
	removed, err := store.Create(Rendezvous{
		ID:        testRendezvousID(21),
		Kind:      PairingKindQR,
		Host:      host,
		ExpiresAt: later.Add(time.Minute),
	}, "", later)
	if err != nil {
		t.Fatalf("expired rendezvous still consumed host capacity: %v", err)
	}
	if len(removed) != 1 || removed[0].ID != testRendezvousID(20) {
		t.Fatalf("removed = %+v, want expired rendezvous 20", removed)
	}
	if store.Len() != 1 {
		t.Fatalf("store length = %d, want 1", store.Len())
	}
}

func TestRendezvousCreateReusesAnExpiredDesktopCode(t *testing.T) {
	store := newTestRendezvousStore(2)
	now := time.Unix(100, 0)
	if _, err := store.Create(Rendezvous{
		ID:        testRendezvousID(22),
		Kind:      PairingKindDesktopCode,
		Host:      testDeviceID(1),
		ExpiresAt: now.Add(time.Second),
	}, "ABCDEFGH", now); err != nil {
		t.Fatal(err)
	}

	later := now.Add(time.Second)
	removed, err := store.Create(Rendezvous{
		ID:        testRendezvousID(23),
		Kind:      PairingKindDesktopCode,
		Host:      testDeviceID(2),
		ExpiresAt: later.Add(time.Minute),
	}, "ABCDEFGH", later)
	if err != nil {
		t.Fatalf("expired desktop code was not reusable: %v", err)
	}
	if len(removed) != 1 || removed[0].ID != testRendezvousID(22) {
		t.Fatalf("removed = %+v, want expired rendezvous 22", removed)
	}
}

func testRendezvousID(seed byte) RendezvousID {
	var id RendezvousID
	for index := range id {
		id[index] = seed
	}
	return id
}

func newTestRendezvousStore(maxPerHost int) *RendezvousStore {
	return NewRendezvousStore(maxPerHost, testMaxRendezvous)
}
