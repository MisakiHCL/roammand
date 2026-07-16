// SPDX-License-Identifier: AGPL-3.0-only

package protocol

import (
	"testing"

	roammandv1 "github.com/MisakiHCL/roammand/gen/go/roammand/v1"
)

func TestSignalingCompilesAgainstGeneratedProtocolTypes(t *testing.T) {
	version := roammandv1.ProtocolVersion{Major: 1, Minor: 0}

	if version.Major != 1 || version.Minor != 0 {
		t.Fatalf("unexpected protocol version: major=%d minor=%d", version.Major, version.Minor)
	}
}
