// SPDX-License-Identifier: Apache-2.0

package identity

import (
	"encoding/hex"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"runtime"
	"testing"
)

type goldenFixture struct {
	Cases []goldenCase `json:"cases"`
}

type goldenCase struct {
	Name                string `json:"name"`
	PublicKeyHex        string `json:"public_key_hex"`
	ExpectedDeviceIDHex string `json:"expected_device_id_hex"`
}

func TestIdentityDerivationV1MatchesEveryGoldenVector(t *testing.T) {
	fixture := loadFixture(t)

	for _, vector := range fixture.Cases {
		t.Run(vector.Name, func(t *testing.T) {
			publicKey := decodeHex(t, vector.PublicKeyHex)
			deviceID, err := DeriveDeviceIDV1(publicKey)
			if err != nil {
				t.Fatalf("DeriveDeviceIDV1() error = %v", err)
			}
			if got := hex.EncodeToString(deviceID[:]); got != vector.ExpectedDeviceIDHex {
				t.Fatalf("DeriveDeviceIDV1() = %s, want %s", got, vector.ExpectedDeviceIDHex)
			}
		})
	}
}

func TestIdentityDerivationV1RejectsNonEd25519KeyLengths(t *testing.T) {
	for _, length := range []int{31, 33} {
		_, err := DeriveDeviceIDV1(make([]byte, length))
		if !errors.Is(err, ErrInvalidPublicKeyLength) {
			t.Fatalf("DeriveDeviceIDV1(%d bytes) error = %v, want %v", length, err, ErrInvalidPublicKeyLength)
		}
	}
}

func loadFixture(t *testing.T) goldenFixture {
	t.Helper()
	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("runtime.Caller() failed")
	}
	path := filepath.Join(filepath.Dir(filename), "../../../conformance/protocol_vectors/identity_derivation_v1.json")
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("ReadFile(%q) error = %v", path, err)
	}

	var fixture goldenFixture
	if err := json.Unmarshal(contents, &fixture); err != nil {
		t.Fatalf("Unmarshal(%q) error = %v", path, err)
	}
	return fixture
}

func decodeHex(t *testing.T, value string) []byte {
	t.Helper()
	decoded, err := hex.DecodeString(value)
	if err != nil {
		t.Fatalf("DecodeString() error = %v", err)
	}
	return decoded
}
