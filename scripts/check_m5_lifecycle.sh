#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly CYCLE_TEST='one_active_pairing_cancel_shutdown_and_debug_output_are_sanitized'

cd "$ROOT_DIR"

cargo test -p roammand-host-agent \
  --test pairing --test signaling_client --test service --test process_lifecycle

for cycle in $(seq 1 10); do
  cargo test -q -p roammand-host-agent --test pairing "$CYCLE_TEST"
  printf 'M5 cancel/retry lifecycle cycle %d/10 passed\n' "$cycle"
done

(
  cd services/signaling
  go test ./internal/service -run \
    'TestPairing|TestWSSIntegrationPairingSessionDisconnectAndReconnect|TestReconnectLoopLeavesNoRoutes'
)

(
  cd apps/client_flutter
  flutter test \
    test/controller_pairing_engine_test.dart \
    test/pairing_signaling_client_test.dart \
    test/host_pairing_ui_test.dart \
    test/desktop_pairing_dialog_test.dart \
    test/mobile_pairing_page_test.dart \
    test/mobile_identity_store_test.dart \
    test/trusted_host_repository_test.dart
)

printf 'M5 lifecycle checks passed\n'
