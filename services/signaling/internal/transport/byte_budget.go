// SPDX-License-Identifier: AGPL-3.0-only

package transport

import "sync"

// ByteReservationBudget is a concurrency-safe byte reservation shared by one
// or more connections.
type ByteReservationBudget interface {
	TryReserve(bytes int64) bool
	Release(bytes int64)
}

// ByteBudget implements a fixed, concurrency-safe byte limit.
type ByteBudget struct {
	mu    sync.Mutex
	limit int64
	used  int64
}

func NewByteBudget(limit int64) *ByteBudget {
	if limit <= 0 {
		panic("byte budget must be positive")
	}
	return &ByteBudget{limit: limit}
}

func (budget *ByteBudget) TryReserve(bytes int64) bool {
	if bytes < 0 {
		return false
	}
	budget.mu.Lock()
	defer budget.mu.Unlock()
	if bytes > budget.limit-budget.used {
		return false
	}
	budget.used += bytes
	return true
}

func (budget *ByteBudget) Release(bytes int64) {
	budget.mu.Lock()
	defer budget.mu.Unlock()
	if bytes < 0 || bytes > budget.used {
		panic("byte budget release exceeds reservation")
	}
	budget.used -= bytes
}

func (budget *ByteBudget) UsedBytes() int64 {
	budget.mu.Lock()
	defer budget.mu.Unlock()
	return budget.used
}
