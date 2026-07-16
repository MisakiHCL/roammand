#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

(
  cd "$repo_root/apps/client_flutter"
  flutter test \
    test/peer_session_test.dart \
    test/remote_desktop_controller_test.dart \
    test/retryable_remote_desktop_controller_test.dart
)
(
  cd "$repo_root"
  cargo test -p roammand-host-agent --test remote_session
  cargo test -p roammand-host-webrtc --test lifecycle
)
(
  cd "$repo_root/services/signaling"
  go test ./internal/service -run '^(TestReconnectLoopLeavesNoRoutes|TestWSSIntegrationPairingSessionDisconnectAndReconnect)$' -count=1
)

echo "M7 reconnect checks passed"
