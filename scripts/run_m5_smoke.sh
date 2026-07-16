#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "${1:-}" in
  '') validate_only=0 ;;
  --validate-only) validate_only=1 ;;
  *)
    printf 'usage: %s [--validate-only]\n' "$0" >&2
    exit 2
    ;;
esac

printf 'READY automated M5 pairing checks\n'
printf 'SKIP real camera: physical mobile device required\n'
printf 'SKIP real-machine pairing: two physical machines required\n'
printf 'SKIP protected storage: physical Keychain/Keystore verification required\n'
printf 'SKIP deployed WSS: certificate-backed endpoint required\n'
printf 'SKIP TURN: deployment credentials required\n'

if [[ "$validate_only" -eq 1 ]]; then
  exit 0
fi

cd "$ROOT_DIR"

make test-conformance
./scripts/check_m5_lifecycle.sh

(
  cd services/signaling
  go test -race ./internal/service -run \
    'TestPairing|TestWSSIntegrationPairingSessionDisconnectAndReconnect|TestReconnectLoopLeavesNoRoutes'
)

case "$(uname -s)" in
  Darwin)
    (cd apps/client_flutter && flutter build macos --debug)
    ;;
  MINGW*|MSYS*|CYGWIN*)
    (cd apps/client_flutter && flutter build windows --debug)
    ;;
  *)
    printf 'SKIP desktop debug build: unsupported build host\n'
    ;;
esac

printf 'M5 automated smoke checks passed\n'
