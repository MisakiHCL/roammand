// SPDX-License-Identifier: AGPL-3.0-only

package state

import (
	validation "github.com/MisakiHCL/roammand/gen/go/validation"
)

type DeviceID [validation.DeviceIDBytes]byte

type RendezvousID [validation.RendezvousIDBytes]byte

func DeviceIDFromBytes(encoded []byte) (DeviceID, bool) {
	var id DeviceID
	if len(encoded) != len(id) {
		return id, false
	}
	copy(id[:], encoded)
	return id, true
}

func RendezvousIDFromBytes(encoded []byte) (RendezvousID, bool) {
	var id RendezvousID
	if len(encoded) != len(id) {
		return id, false
	}
	copy(id[:], encoded)
	return id, true
}

func (id DeviceID) Bytes() []byte {
	encoded := make([]byte, len(id))
	copy(encoded, id[:])
	return encoded
}

func (id RendezvousID) Bytes() []byte {
	encoded := make([]byte, len(id))
	copy(encoded, id[:])
	return encoded
}
