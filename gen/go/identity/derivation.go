// SPDX-License-Identifier: Apache-2.0

package identity

import (
	"crypto/sha256"
	"errors"
)

const (
	// Protocol V1 domain; changing it would rotate every existing device ID.
	identityDerivationDomain = "personal-remote-device-id-v1"
	ed25519Algorithm         = uint16(1)
	ed25519PublicKeyBytes    = 32
)

var ErrInvalidPublicKeyLength = errors.New("invalid public key length")

func DeriveDeviceIDV1(publicKey []byte) ([sha256.Size]byte, error) {
	if len(publicKey) != ed25519PublicKeyBytes {
		return [sha256.Size]byte{}, ErrInvalidPublicKeyLength
	}

	input := make([]byte, 0, len(identityDerivationDomain)+1+2+len(publicKey))
	input = append(input, identityDerivationDomain...)
	input = append(input, 0)
	input = append(input, byte(ed25519Algorithm>>8), byte(ed25519Algorithm))
	input = append(input, publicKey...)
	return sha256.Sum256(input), nil
}
