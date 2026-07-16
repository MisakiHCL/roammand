#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() { printf 'M8 privacy check failed: %s\n' "$1" >&2; exit 1; }

./scripts/check_public_boundary.sh >/dev/null
if rg -ni '^[[:space:]]*(bytes|string)[[:space:]]+(private_key|seed|grant_snapshot|pairing_secret)[[:space:]]*=' \
  schema/proto; then
  fail 'privileged or public schema carries long-term trust material'
fi
if rg -ni '(allow_unverified|skip_peer_auth|disable_peer_check|accept_any_helper)' \
  crates/privileged-bridge apps/client_flutter; then
  fail 'permissive Helper trust switch found'
fi
if rg -ni '(println!|eprintln!|tracing::[a-z]+!).*\b(sdp|ice|candidate|nonce|secret|input)\b' \
  crates/privileged-bridge crates/host-agent crates/host-webrtc; then
  fail 'sensitive bridge/session material may reach logs'
fi
rg -q --fixed-strings 'LeaseId([REDACTED; 16])' crates/privileged-bridge/src/lease.rs || fail 'lease identifiers are not redacted'
rg -q 'socket_path.*\[REDACTED\]' crates/privileged-bridge/src/macos/transport.rs || fail 'protected socket path is not redacted'

for package in dist/m8-macos dist/m8-windows; do
  [[ -d "$package" ]] || continue
  if find "$package" -type f \( -name '*.pem' -o -name '*.key' -o -name '*.p12' -o -name '*.pfx' \) -print -quit | rg -q .; then
    fail 'staged package contains credentials or certificates'
  fi
done

printf 'M8 privacy checks ok\n'
