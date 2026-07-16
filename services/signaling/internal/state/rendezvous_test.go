// SPDX-License-Identifier: AGPL-3.0-only

package state

import (
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"
)

func TestRendezvousCodeJoinStoresOnlyHash(t *testing.T) {
	store := NewRendezvousStore()
	now := time.Unix(100, 0)
	created := Rendezvous{
		ID:        testRendezvousID(1),
		Kind:      PairingKindDesktopCode,
		Host:      testDeviceID(1),
		ExpiresAt: now.Add(2 * time.Minute),
	}

	if err := store.Create(created, "ABCDEFGH"); err != nil {
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
	store := NewRendezvousStore()
	now := time.Unix(100, 0)
	rendezvous := Rendezvous{
		ID:        testRendezvousID(2),
		Kind:      PairingKindQR,
		Host:      testDeviceID(1),
		ExpiresAt: now.Add(2 * time.Minute),
	}

	if err := store.Create(rendezvous, ""); err != nil {
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

func TestRendezvousAllowsOneDistinctController(t *testing.T) {
	store := NewRendezvousStore()
	now := time.Unix(100, 0)
	id := testRendezvousID(3)
	host := testDeviceID(1)
	if err := store.Create(Rendezvous{
		ID: id, Kind: PairingKindQR, Host: host, ExpiresAt: now.Add(time.Minute),
	}, ""); err != nil {
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
	store := NewRendezvousStore()
	now := time.Unix(100, 0)
	id := testRendezvousID(4)
	host := testDeviceID(1)
	controller := testDeviceID(2)
	if err := store.Create(Rendezvous{
		ID: id, Kind: PairingKindQR, Host: host, ExpiresAt: now.Add(time.Minute),
	}, ""); err != nil {
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
	store := NewRendezvousStore()
	now := time.Unix(100, 0)
	host := testDeviceID(1)
	controller := testDeviceID(2)
	for seed := byte(5); seed < 7; seed++ {
		id := testRendezvousID(seed)
		if err := store.Create(Rendezvous{
			ID: id, Kind: PairingKindQR, Host: host, ExpiresAt: now.Add(time.Minute),
		}, ""); err != nil {
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

func testRendezvousID(seed byte) RendezvousID {
	var id RendezvousID
	for index := range id {
		id[index] = seed
	}
	return id
}
