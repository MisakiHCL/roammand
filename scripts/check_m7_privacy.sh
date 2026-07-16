#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail() {
  echo "M7 privacy check failed: $1" >&2
  exit 1
}

[[ -f services/signaling/internal/safelog/safelog.go ]] || fail "typed signaling logger is missing"
rg -q 'impl fmt::Debug for SignalingEvent' crates/host-agent/src/signaling.rs || fail "SignalingEvent Debug is not redacted"
rg -q 'impl fmt::Debug for VerifiedSessionOffer' crates/host-agent/src/session_auth.rs || fail "VerifiedSessionOffer Debug is not redacted"
rg -q 'impl fmt::Debug for PeerIceCandidate' crates/host-webrtc/src/peer.rs || fail "PeerIceCandidate Debug is not redacted"
rg -q 'impl fmt::Debug for PeerAnswer' crates/host-webrtc/src/peer.rs || fail "PeerAnswer Debug is not redacted"

if rg -n '"%s failed: %v|ErrorLog:[[:space:]]+log\.New' services/signaling/cmd/signaling/main.go; then
  fail "raw signaling errors can reach stderr"
fi

rg -q "'raw_webrtc_stats'" apps/client_flutter/lib/diagnostics/diagnostics_model.dart || fail "raw WebRTC stats exclusion is missing"
rg -q "'input_content_and_coordinates'" apps/client_flutter/lib/diagnostics/diagnostics_model.dart || fail "input exclusion is missing"

echo "M7 privacy checks passed"
