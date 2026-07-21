// SPDX-License-Identifier: AGPL-3.0-only

package service

import (
	"unicode/utf8"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
	validation "github.com/MisakiHCL/roammand/gen/go/validation"
	"google.golang.org/protobuf/proto"
)

func decodeClientFrame(
	encoded []byte,
) (*roammandv1.SignalingClientFrame, roammandv1.ErrorCode) {
	frame := &roammandv1.SignalingClientFrame{}
	if err := (proto.UnmarshalOptions{DiscardUnknown: true}).Unmarshal(encoded, frame); err != nil {
		return frame, roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST
	}
	if frame.ProtocolVersion == nil ||
		frame.ProtocolVersion.Major != validation.ProtocolMajorVersion ||
		frame.ProtocolVersion.Minor < validation.MinimumProtocolMinorVersion {
		return frame, roammandv1.ErrorCode_ERROR_CODE_PROTOCOL_UNSUPPORTED
	}
	if frame.RequestId == "" ||
		!utf8.ValidString(frame.RequestId) ||
		len([]byte(frame.RequestId)) > validation.MaxRequestIDUTF8Bytes {
		return frame, roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST
	}
	if frame.Payload == nil {
		return frame, roammandv1.ErrorCode_ERROR_CODE_INVALID_REQUEST
	}
	return frame, roammandv1.ErrorCode_ERROR_CODE_UNSPECIFIED
}
