#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_scenario() {
  scenario="$1"
  shift
  echo "M7 smoke scenario: $scenario"
  "$@"
}

run_scenario direct-and-turn bash -c \
  'cd "$1/apps/client_flutter" && flutter test test/peer_session_test.dart --plain-name "initializes renderer, peer, exact channels, codecs and ICE policy"' \
  _ "$repo_root"
run_scenario transient-recovery bash -c \
  'cd "$1/apps/client_flutter" && flutter test test/remote_desktop_controller_test.dart --plain-name "reconnects with a fresh signed offer and Host reconnect proof"' \
  _ "$repo_root"
run_scenario host-restart bash -c \
  'cd "$1/apps/client_flutter" && flutter test test/remote_desktop_controller_test.dart --plain-name "recovers signaling and accepts a full Host restart answer"' \
  _ "$repo_root"
run_scenario thirty-second-failure bash -c \
  'cd "$1/apps/client_flutter" && flutter test test/remote_desktop_controller_test.dart --plain-name "stops automatic recovery after the exact thirty-second window"' \
  _ "$repo_root"
run_scenario busy-session bash -c \
  'cd "$1" && cargo test -p roammand-host-agent --test remote_session keeps_first_session_and_returns_busy_to_a_second_controller -- --exact' \
  _ "$repo_root"
run_scenario revocation bash -c \
  'cd "$1" && cargo test -p roammand-host-agent --test revocation revocation_persists_then_terminates_matching_sessions_and_broadcasts -- --exact' \
  _ "$repo_root"
run_scenario permissions bash -c \
  'cd "$1" && cargo test -p roammand-host-webrtc --test input rejects_wrong_session_coordinates_usage_and_missing_permission -- --exact' \
  _ "$repo_root"
run_scenario ten-lifecycle-cycles bash -c \
  'cd "$1" && cargo test -p roammand-host-webrtc --test lifecycle ten_connect_close_cycles_release_every_resource -- --exact' \
  _ "$repo_root"
run_scenario signaling-reconnect bash -c \
  'cd "$1/services/signaling" && go test ./internal/service -run "^TestReconnectLoopLeavesNoRoutes$" -count=1' \
  _ "$repo_root"

echo "M7 smoke scenarios passed"
