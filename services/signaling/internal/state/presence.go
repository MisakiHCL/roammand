// SPDX-License-Identifier: AGPL-3.0-only

package state

import (
	"sync"
	"time"
)

type Route struct {
	Token    uint64
	Send     func([]byte) bool
	Close    func()
	LastSeen time.Time
}

type PresenceRegistry struct {
	mu     sync.RWMutex
	routes map[DeviceID]Route
}

func NewPresenceRegistry() *PresenceRegistry {
	return &PresenceRegistry{routes: make(map[DeviceID]Route)}
}

func (registry *PresenceRegistry) Register(id DeviceID, route Route, now time.Time) bool {
	registry.mu.Lock()
	defer registry.mu.Unlock()

	if _, exists := registry.routes[id]; exists {
		return false
	}
	route.LastSeen = now
	registry.routes[id] = route
	return true
}

func (registry *PresenceRegistry) Touch(id DeviceID, token uint64, now time.Time) bool {
	registry.mu.Lock()
	defer registry.mu.Unlock()

	route, exists := registry.routes[id]
	if !exists || route.Token != token {
		return false
	}
	route.LastSeen = now
	registry.routes[id] = route
	return true
}

func (registry *PresenceRegistry) Lookup(id DeviceID) (Route, bool) {
	registry.mu.RLock()
	defer registry.mu.RUnlock()

	route, exists := registry.routes[id]
	return route, exists
}

func (registry *PresenceRegistry) Remove(id DeviceID, token uint64) bool {
	registry.mu.Lock()
	defer registry.mu.Unlock()

	route, exists := registry.routes[id]
	if !exists || route.Token != token {
		return false
	}
	delete(registry.routes, id)
	return true
}

func (registry *PresenceRegistry) ExpireBefore(cutoff time.Time) []Route {
	registry.mu.Lock()
	defer registry.mu.Unlock()

	expired := make([]Route, 0)
	for id, route := range registry.routes {
		if !route.LastSeen.Before(cutoff) {
			continue
		}
		expired = append(expired, route)
		delete(registry.routes, id)
	}
	return expired
}

func (registry *PresenceRegistry) Len() int {
	registry.mu.RLock()
	defer registry.mu.RUnlock()
	return len(registry.routes)
}
