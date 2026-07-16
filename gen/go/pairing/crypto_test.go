// SPDX-License-Identifier: Apache-2.0

package pairing

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"reflect"
	"runtime"
	"strings"
	"testing"
)

type pairingVector struct {
	ControllerDeviceIDHex         string    `json:"controller_device_id_hex"`
	HostDeviceIDHex               string    `json:"host_device_id_hex"`
	RendezvousIDHex               string    `json:"rendezvous_id_hex"`
	ControllerX25519PrivateKeyHex string    `json:"controller_x25519_private_key_hex"`
	ControllerX25519PublicKeyHex  string    `json:"controller_x25519_public_key_hex"`
	HostX25519PrivateKeyHex       string    `json:"host_x25519_private_key_hex"`
	HostX25519PublicKeyHex        string    `json:"host_x25519_public_key_hex"`
	X25519SharedSecretHex         string    `json:"x25519_shared_secret_hex"`
	CanonicalTranscriptHex        string    `json:"canonical_transcript_hex"`
	TranscriptSHA256Hex           string    `json:"transcript_sha256_hex"`
	SASIndexes                    [4]uint16 `json:"sas_indexes"`
	SASWords                      [4]string `json:"sas_words"`
	WordlistSHA256Hex             string    `json:"wordlist_sha256_hex"`
	ControllerToHostKeyHex        string    `json:"controller_to_host_key_hex"`
	HostToControllerKeyHex        string    `json:"host_to_controller_key_hex"`
	Sequence                      uint64    `json:"sequence"`
	NonceHex                      string    `json:"nonce_hex"`
	AADHex                        string    `json:"aad_hex"`
	PlaintextHex                  string    `json:"plaintext_hex"`
	CiphertextAndTagHex           string    `json:"ciphertext_and_tag_hex"`
}

func TestPairingCryptoV1MapsFirst44DigestBitsToFourIndexes(t *testing.T) {
	digest, err := hex.DecodeString("f89f31c4716edbcff1d8a4ad5fbe1161730b022cf28770146e481a06ef5981c6")
	if err != nil {
		t.Fatal(err)
	}

	indexes, err := SASIndexes(digest)
	if err != nil {
		t.Fatal(err)
	}
	if want := [4]uint16{1988, 1996, 904, 1814}; !reflect.DeepEqual(indexes, want) {
		t.Fatalf("SAS indexes = %v, want %v", indexes, want)
	}
}

func TestPairingCryptoV1RejectsInvalidDigestAndSequence(t *testing.T) {
	if _, err := SASIndexes(make([]byte, 31)); !errors.Is(err, ErrInvalidLength) {
		t.Fatalf("short digest error = %v, want %v", err, ErrInvalidLength)
	}
	if _, err := Nonce(DirectionControllerToHost, 0); !errors.Is(err, ErrInvalidSequence) {
		t.Fatalf("zero sequence error = %v, want %v", err, ErrInvalidSequence)
	}
	if _, err := Nonce(DirectionControllerToHost, uint64(^uint64(0)>>1)+1); !errors.Is(err, ErrInvalidSequence) {
		t.Fatalf("oversized sequence error = %v, want %v", err, ErrInvalidSequence)
	}
	if _, err := X25519SharedSecret(make([]byte, 32), make([]byte, 32)); !errors.Is(err, ErrInvalidPublicKey) {
		t.Fatalf("low-order public key error = %v, want %v", err, ErrInvalidPublicKey)
	}
}

func TestPairingCryptoV1MatchesSharedGoldenVector(t *testing.T) {
	vector := loadPairingVector(t)
	wordBytes := readFixture(t, "wordlists", "bip39-english.txt")
	words := strings.Fields(string(wordBytes))
	transcript := decodeVectorHex(t, vector.CanonicalTranscriptHex)
	transcriptHash := sha256.Sum256(transcript)
	controllerPrivate := decodeVectorHex(t, vector.ControllerX25519PrivateKeyHex)
	hostPrivate := decodeVectorHex(t, vector.HostX25519PrivateKeyHex)

	if got := hex.EncodeToString(transcriptHash[:]); got != vector.TranscriptSHA256Hex {
		t.Fatalf("transcript SHA-256 = %s, want %s", got, vector.TranscriptSHA256Hex)
	}
	controllerPublic, err := X25519PublicKey(controllerPrivate)
	if err != nil {
		t.Fatal(err)
	}
	if got := hex.EncodeToString(controllerPublic); got != vector.ControllerX25519PublicKeyHex {
		t.Fatalf("controller public key = %s, want %s", got, vector.ControllerX25519PublicKeyHex)
	}
	hostPublic, err := X25519PublicKey(hostPrivate)
	if err != nil {
		t.Fatal(err)
	}
	if got := hex.EncodeToString(hostPublic); got != vector.HostX25519PublicKeyHex {
		t.Fatalf("host public key = %s, want %s", got, vector.HostX25519PublicKeyHex)
	}
	shared, err := X25519SharedSecret(controllerPrivate, hostPublic)
	if err != nil {
		t.Fatal(err)
	}
	if got := hex.EncodeToString(shared); got != vector.X25519SharedSecretHex {
		t.Fatalf("shared secret = %s, want %s", got, vector.X25519SharedSecretHex)
	}
	indexes, err := SASIndexes(transcriptHash[:])
	if err != nil || indexes != vector.SASIndexes {
		t.Fatalf("SAS indexes = %v, %v; want %v", indexes, err, vector.SASIndexes)
	}
	sasWords, err := SASWords(transcriptHash[:], words)
	if err != nil || sasWords != vector.SASWords {
		t.Fatalf("SAS words = %v, %v; want %v", sasWords, err, vector.SASWords)
	}
	wordHash := sha256.Sum256(wordBytes)
	if got := hex.EncodeToString(wordHash[:]); got != vector.WordlistSHA256Hex {
		t.Fatalf("wordlist SHA-256 = %s, want %s", got, vector.WordlistSHA256Hex)
	}

	keys, err := DeriveKeys(shared, transcriptHash[:])
	if err != nil {
		t.Fatal(err)
	}
	if got := hex.EncodeToString(keys.ControllerToHost[:]); got != vector.ControllerToHostKeyHex {
		t.Fatalf("Controller-to-Host key = %s, want %s", got, vector.ControllerToHostKeyHex)
	}
	if got := hex.EncodeToString(keys.HostToController[:]); got != vector.HostToControllerKeyHex {
		t.Fatalf("Host-to-Controller key = %s, want %s", got, vector.HostToControllerKeyHex)
	}
	nonce, err := Nonce(DirectionControllerToHost, vector.Sequence)
	if err != nil {
		t.Fatal(err)
	}
	aad, err := AAD(
		DirectionControllerToHost,
		vector.Sequence,
		decodeVectorHex(t, vector.RendezvousIDHex),
		decodeVectorHex(t, vector.ControllerDeviceIDHex),
		decodeVectorHex(t, vector.HostDeviceIDHex),
	)
	if err != nil {
		t.Fatal(err)
	}
	if got := hex.EncodeToString(nonce[:]); got != vector.NonceHex {
		t.Fatalf("nonce = %s, want %s", got, vector.NonceHex)
	}
	if got := hex.EncodeToString(aad); got != vector.AADHex {
		t.Fatalf("AAD = %s, want %s", got, vector.AADHex)
	}
	plaintext := decodeVectorHex(t, vector.PlaintextHex)
	sealed, err := Seal(keys.ControllerToHost[:], DirectionControllerToHost, vector.Sequence, aad, plaintext)
	if err != nil {
		t.Fatal(err)
	}
	if got := hex.EncodeToString(sealed); got != vector.CiphertextAndTagHex {
		t.Fatalf("ciphertext = %s, want %s", got, vector.CiphertextAndTagHex)
	}
	opened, err := Open(keys.ControllerToHost[:], DirectionControllerToHost, vector.Sequence, aad, sealed)
	if err != nil || !reflect.DeepEqual(opened, plaintext) {
		t.Fatalf("opened = %x, %v; want %x", opened, err, plaintext)
	}
}

func TestPairingCryptoV1RejectsTamperedAuthenticatedData(t *testing.T) {
	key := make([]byte, 32)
	sealed, err := Seal(key, DirectionHostToController, 1, []byte{1, 2, 3}, []byte{4, 5, 6})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := Open(key, DirectionHostToController, 1, []byte{1, 2, 4}, sealed); !errors.Is(err, ErrAuthentication) {
		t.Fatalf("tampered AAD error = %v, want %v", err, ErrAuthentication)
	}
	for index := range sealed {
		tampered := append([]byte(nil), sealed...)
		tampered[index] ^= 1
		if _, err := Open(key, DirectionHostToController, 1, []byte{1, 2, 3}, tampered); !errors.Is(err, ErrAuthentication) {
			t.Fatalf("tampered ciphertext byte %d error = %v, want %v", index, err, ErrAuthentication)
		}
	}
}

func TestPairingCryptoV1RejectsDuplicateAndSkippedSequences(t *testing.T) {
	validator := NewSequenceValidator()
	if err := validator.Accept(1); err != nil {
		t.Fatal(err)
	}
	if err := validator.Accept(1); !errors.Is(err, ErrInvalidSequence) {
		t.Fatalf("duplicate sequence error = %v, want %v", err, ErrInvalidSequence)
	}
	if err := validator.Accept(3); !errors.Is(err, ErrInvalidSequence) {
		t.Fatalf("skipped sequence error = %v, want %v", err, ErrInvalidSequence)
	}
	if err := validator.Accept(2); err != nil {
		t.Fatal(err)
	}
	if validator.Next() != 3 {
		t.Fatalf("next sequence = %d, want 3", validator.Next())
	}
}

func TestPairingCryptoV1CoversWordListAndSizeBoundaries(t *testing.T) {
	words := strings.Fields(string(readFixture(t, "wordlists", "bip39-english.txt")))
	zero, err := SASWords(make([]byte, 32), words)
	if err != nil || zero != [4]string{"abandon", "abandon", "abandon", "abandon"} {
		t.Fatalf("zero digest words = %v, %v", zero, err)
	}
	ones, err := SASWords(bytesOf(0xff, 32), words)
	if err != nil || ones != [4]string{"zoo", "zoo", "zoo", "zoo"} {
		t.Fatalf("ones digest words = %v, %v", ones, err)
	}
	if _, err := Seal(make([]byte, 32), DirectionControllerToHost, 1, nil, make([]byte, maxPairingCiphertextBytes)); !errors.Is(err, ErrInvalidLength) {
		t.Fatalf("oversized plaintext error = %v, want %v", err, ErrInvalidLength)
	}
}

func loadPairingVector(t *testing.T) pairingVector {
	t.Helper()
	contents := readFixture(t, "protocol_vectors", "pairing_crypto_v1.json")
	var vector pairingVector
	if err := json.Unmarshal(contents, &vector); err != nil {
		t.Fatal(err)
	}
	return vector
}

func readFixture(t *testing.T, parts ...string) []byte {
	t.Helper()
	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("runtime.Caller failed")
	}
	pathParts := append([]string{filepath.Dir(filename), "../../../conformance"}, parts...)
	contents, err := os.ReadFile(filepath.Join(pathParts...))
	if err != nil {
		t.Fatal(err)
	}
	return contents
}

func decodeVectorHex(t *testing.T, value string) []byte {
	t.Helper()
	decoded, err := hex.DecodeString(value)
	if err != nil {
		t.Fatal(err)
	}
	return decoded
}

func bytesOf(value byte, length int) []byte {
	result := make([]byte, length)
	for index := range result {
		result[index] = value
	}
	return result
}
