#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_scenario() {
  local name="$1"
  shift
  printf 'M8 smoke scenario: %s\n' "$name"
  "$@"
}

run_scenario bridge-schema-auth-negative bash -c \
  'cd "$1" && ./scripts/check_m8_bridge_contract.sh && cargo test -p roammand-privileged-bridge --test authentication --test framing --test peer_identity' \
  _ "$ROOT_DIR"
run_scenario route-migration bash -c \
  'cd "$1" && cargo test -p roammand-privileged-bridge --test proxy_peer --test macos_contract --test windows_contract && cargo test -p roammand-host-agent --test remote_session privileged_route_change_freezes_input_before_authenticated_reconnect -- --exact' \
  _ "$ROOT_DIR"
run_scenario emergency-stop bash -c \
  'cd "$1" && cargo test -p roammand-host-agent --test revocation local_emergency_stop_is_idempotent_and_preserves_permanent_grants -- --exact' \
  _ "$ROOT_DIR"
run_scenario protected-indicator bash -c \
  'cd "$1" && cargo test -p roammand-privileged-bridge --test indicator' \
  _ "$ROOT_DIR"
run_scenario flutter-status-and-tray bash -c \
  'cd "$1/apps/client_flutter" && flutter test test/privileged_bridge_presenter_test.dart test/host_status_page_test.dart test/host_tray_controller_test.dart test/desktop_app_root_test.dart' \
  _ "$ROOT_DIR"
run_scenario macos-package "$ROOT_DIR/scripts/test_m8_macos_package.sh"
run_scenario windows-package "$ROOT_DIR/scripts/test_m8_windows_package.sh"
run_scenario ten-session-transitions bash -c \
  'cd "$1" && cargo test -p roammand-privileged-bridge --test session_transitions && cargo test -p roammand-host-webrtc --test lifecycle ten_connect_close_cycles_release_every_resource -- --exact' \
  _ "$ROOT_DIR"
run_scenario privacy "$ROOT_DIR/scripts/check_m8_privacy.sh"
run_scenario native-webrtc make -C "$ROOT_DIR" test-native-webrtc

printf 'M8 smoke scenarios passed\n'
