// SPDX-License-Identifier: AGPL-3.0-only

package service

import (
	"testing"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	validation "github.com/MisakiHCL/roammand/gen/go/validation"
	"google.golang.org/protobuf/proto"
)

func FuzzDecodeClientFrame(f *testing.F) {
	valid, err := proto.Marshal(&roammandv1.SignalingClientFrame{
		ProtocolVersion: &roammandv1.ProtocolVersion{
			Major: validation.ProtocolMajorVersion,
			Minor: validation.MinimumProtocolMinorVersion,
		},
		RequestId: "fuzz-valid",
		Payload: &roammandv1.SignalingClientFrame_Heartbeat{
			Heartbeat: &roammandv1.Heartbeat{},
		},
	})
	if err != nil {
		f.Fatal(err)
	}
	for _, seed := range [][]byte{
		nil,
		{0},
		{0xff, 0xff, 0xff, 0xff},
		valid,
		make([]byte, validation.MaxSignalingServiceFrameBytes),
	} {
		f.Add(seed)
	}

	f.Fuzz(func(t *testing.T, encoded []byte) {
		if len(encoded) > validation.MaxSignalingServiceFrameBytes {
			t.Skip()
		}
		frame, code := decodeClientFrame(encoded)
		if frame == nil {
			t.Fatal("decoder returned a nil frame")
		}
		switch code {
		case roammandv1.ErrorCode_ERROR_CODE_UNSPECIFIED:
			roundTrip, marshalErr := proto.Marshal(frame)
			if marshalErr != nil {
				t.Fatalf("valid frame does not marshal: %v", marshalErr)
			}
			decodedAgain, nextCode := decodeClientFrame(roundTrip)
			if nextCode != roammandv1.ErrorCode_ERROR_CODE_UNSPECIFIED ||
				!proto.Equal(frame, decodedAgain) {
				t.Fatalf("valid frame did not round trip: code=%v", nextCode)
			}
		case roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST,
			roammandv1.ErrorCode_ERROR_CODE_PROTOCOL_UNSUPPORTED:
		default:
			t.Fatalf("decoder returned an unstable error code: %v", code)
		}
	})
}
