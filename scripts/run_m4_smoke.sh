#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly PACKAGE_CONFIG="$ROOT_DIR/apps/client_flutter/.dart_tool/package_config.json"

case "${1:-}" in
  '') validate_only=0 ;;
  --validate-only) validate_only=1 ;;
  *)
    printf 'usage: %s [--validate-only]\n' "$0" >&2
    exit 2
    ;;
esac

if [[ ! -f "$PACKAGE_CONFIG" ]]; then
  (cd "$ROOT_DIR/apps/client_flutter" && flutter pub get >/dev/null)
fi

dart --packages="$PACKAGE_CONFIG" \
  "$ROOT_DIR/scripts/validate_m4_smoke_config.dart"

if [[ "$validate_only" -eq 1 ]]; then
  exit 0
fi

"$ROOT_DIR/scripts/check_m4_lifecycle.sh"

(
  cd "$ROOT_DIR/services/signaling"
  go test ./internal/service -run \
    'TestWSSIntegrationPairingSessionDisconnectAndReconnect|TestSessionRoutingPreservesOpaqueBytesAndAddsSender|TestReconnectLoopLeavesNoRoutes'
)

case "$(uname -s)" in
  Darwin)
    (cd "$ROOT_DIR/apps/client_flutter" && flutter build macos --debug)
    ;;
  MINGW*|MSYS*|CYGWIN*)
    (cd "$ROOT_DIR/apps/client_flutter" && flutter build windows --debug)
    ;;
  *)
    printf 'SKIP desktop debug build: unsupported build host\n'
    ;;
esac

printf 'M4 automated smoke checks passed\n'
