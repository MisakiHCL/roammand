#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SMOKE_SCRIPT="$ROOT_DIR/scripts/run_m5_smoke.sh"
readonly LIFECYCLE_SCRIPT="$ROOT_DIR/scripts/check_m5_lifecycle.sh"

for script in "$SMOKE_SCRIPT" "$LIFECYCLE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    printf 'missing executable M5 script: %s\n' "$script" >&2
    exit 1
  fi
done

output="$($SMOKE_SCRIPT --validate-only)"
for expected in \
  'READY automated M5 pairing checks' \
  'SKIP real camera: physical mobile device required' \
  'SKIP real-machine pairing: two physical machines required' \
  'SKIP protected storage: physical Keychain/Keystore verification required' \
  'SKIP deployed WSS: certificate-backed endpoint required' \
  'SKIP TURN: deployment credentials required'; do
  if [[ "$output" != *"$expected"* ]]; then
    printf 'missing M5 smoke status: %s\n' "$expected" >&2
    exit 1
  fi
done

if rg -n "import .*m4_maintenance\.dart" \
  "$ROOT_DIR/apps/client_flutter/lib" >/dev/null; then
  printf 'product pairing UI depends on a maintenance descriptor path\n' >&2
  exit 1
fi
rg -q "host-connection-descriptor.*findsNothing" \
  "$ROOT_DIR/apps/client_flutter/test/desktop_home_page_test.dart"

rg -q 'pairingRendezvousLifetimeMs = 120000' \
  "$ROOT_DIR/gen/dart/lib/src/protocol_limits.dart"
rg -q '^test-m5:' "$ROOT_DIR/Makefile"
rg -q '^test-m5-lifecycle:' "$ROOT_DIR/Makefile"

printf 'M5 smoke contract ok\n'
