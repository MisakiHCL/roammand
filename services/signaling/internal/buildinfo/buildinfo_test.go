// SPDX-License-Identifier: AGPL-3.0-only

package buildinfo

import "testing"

func TestServiceNameIsStable(t *testing.T) {
	if ServiceName != "roammand-signaling" {
		t.Fatalf("unexpected service name: %q", ServiceName)
	}
}
