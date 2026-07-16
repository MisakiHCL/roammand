// SPDX-License-Identifier: Apache-2.0

package canonical

import (
	"bytes"
	"encoding/hex"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"reflect"
	"runtime"
	"strconv"
	"testing"
)

type goldenFixture struct {
	Values map[string]string `json:"values"`
	Cases  []goldenCase      `json:"cases"`
}

type goldenCase struct {
	Name                  string   `json:"name"`
	Purpose               uint16   `json:"purpose"`
	Tags                  []uint16 `json:"tags"`
	ExpectedTranscriptHex string   `json:"expected_transcript_hex"`
	ExpectedSHA256Hex     string   `json:"expected_sha256_hex"`
}

type invalidFixture struct {
	Cases []invalidCase `json:"cases"`
}

type invalidCase struct {
	Name          string `json:"name"`
	ExpectedError string `json:"expected_error"`
	TranscriptHex string `json:"transcript_hex"`
	RepeatHex     string `json:"repeat_hex"`
	RepeatCount   int    `json:"repeat_count"`
}

func TestAllCanonicalTranscriptV1GoldenCasesMatch(t *testing.T) {
	fixture := loadFixture[goldenFixture](t, "canonical_transcript_v1.json")

	for _, vector := range fixture.Cases {
		t.Run(vector.Name, func(t *testing.T) {
			transcript := Transcript{Purpose: Purpose(vector.Purpose)}
			for _, tag := range vector.Tags {
				transcript.Fields = append(transcript.Fields, Field{
					Tag:   tag,
					Value: decodeHex(t, fixture.Values[tagKey(tag)]),
				})
			}

			encoded, err := Encode(transcript)
			if err != nil {
				t.Fatalf("Encode() error = %v", err)
			}
			if got := hex.EncodeToString(encoded); got != vector.ExpectedTranscriptHex {
				t.Fatalf("Encode() = %s, want %s", got, vector.ExpectedTranscriptHex)
			}
			digest := SHA256(encoded)
			if got := hex.EncodeToString(digest[:]); got != vector.ExpectedSHA256Hex {
				t.Fatalf("SHA256() = %s, want %s", got, vector.ExpectedSHA256Hex)
			}

			decoded, err := Decode(encoded)
			if err != nil {
				t.Fatalf("Decode() error = %v", err)
			}
			if !reflect.DeepEqual(decoded, transcript) {
				t.Fatalf("Decode() = %#v, want %#v", decoded, transcript)
			}
		})
	}
}

func TestAllInvalidCanonicalTranscriptV1CasesReturnStableErrors(t *testing.T) {
	fixture := loadFixture[invalidFixture](t, "canonical_transcript_v1_invalid.json")

	for _, vector := range fixture.Cases {
		t.Run(vector.Name, func(t *testing.T) {
			_, err := Decode(invalidBytes(t, vector))
			var transcriptError *TranscriptError
			if !errors.As(err, &transcriptError) {
				t.Fatalf("Decode() error = %v, want *TranscriptError", err)
			}
			if got := string(transcriptError.Code); got != vector.ExpectedError {
				t.Fatalf("Decode() error code = %q, want %q", got, vector.ExpectedError)
			}
		})
	}
}

func FuzzDecodeCanonicalTranscriptV1(f *testing.F) {
	golden := loadFixture[goldenFixture](f, "canonical_transcript_v1.json")
	for _, vector := range golden.Cases {
		f.Add(decodeHex(f, vector.ExpectedTranscriptHex))
	}
	invalid := loadFixture[invalidFixture](f, "canonical_transcript_v1_invalid.json")
	for _, vector := range invalid.Cases {
		f.Add(invalidBytes(f, vector))
	}

	f.Fuzz(func(t *testing.T, encoded []byte) {
		transcript, err := Decode(encoded)
		if err != nil {
			return
		}
		reencoded, err := Encode(transcript)
		if err != nil {
			t.Fatalf("Encode(Decode(input)) error = %v", err)
		}
		if !bytes.Equal(reencoded, encoded) {
			t.Fatalf("Encode(Decode(input)) did not preserve canonical bytes")
		}
	})
}

type testHelper interface {
	Helper()
	Fatal(args ...any)
	Fatalf(format string, args ...any)
}

func loadFixture[T any](t testHelper, name string) T {
	t.Helper()
	_, filename, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("runtime.Caller() failed")
	}
	path := filepath.Join(filepath.Dir(filename), "../../../conformance/protocol_vectors", name)
	contents, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("ReadFile(%q) error = %v", path, err)
	}

	var fixture T
	if err := json.Unmarshal(contents, &fixture); err != nil {
		t.Fatalf("Unmarshal(%q) error = %v", path, err)
	}
	return fixture
}

func invalidBytes(t testHelper, vector invalidCase) []byte {
	t.Helper()
	if vector.TranscriptHex != "" {
		return decodeHex(t, vector.TranscriptHex)
	}
	return bytes.Repeat(decodeHex(t, vector.RepeatHex), vector.RepeatCount)
}

func decodeHex(t testHelper, value string) []byte {
	t.Helper()
	decoded, err := hex.DecodeString(value)
	if err != nil {
		t.Fatalf("DecodeString() error = %v", err)
	}
	return decoded
}

func tagKey(tag uint16) string {
	return strconv.FormatUint(uint64(tag), 10)
}
