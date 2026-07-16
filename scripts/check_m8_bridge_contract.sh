#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() { printf 'M8 bridge contract failed: %s\n' "$1" >&2; exit 1; }

[[ -f schema/proto/roammand/v1/privileged_bridge.proto ]] || fail 'schema is missing'
rg -q 'message PrivilegedBridgeClientFrame' schema/proto/roammand/v1/privileged_bridge.proto || fail 'bounded client bridge frame is missing'
rg -q 'message PrivilegedBridgeServerFrame' schema/proto/roammand/v1/privileged_bridge.proto || fail 'bounded server bridge frame is missing'
rg -q 'EmergencyStopRemoteSessionRequest' schema/proto/roammand/v1/local_ipc.proto || fail 'local emergency stop is missing'
rg -q '^pub const RENEW_INTERVAL_MS: u64 = 5_000;' crates/privileged-bridge/src/lease.rs || fail 'lease renewal is not fixed at five seconds'
rg -q '^pub const LEASE_DURATION_MS: u64 = 15_000;' crates/privileged-bridge/src/lease.rs || fail 'lease expiry is not fixed at fifteen seconds'
rg -q 'MacAgentRouter' crates/privileged-bridge/src/macos/peer.rs || fail 'macOS route migration is missing'
rg -q 'ServiceControlAccept::SESSION_CHANGE' crates/privileged-bridge/src/bin/roammand-privileged-bridge.rs || fail 'Windows session notifications are missing'
rg -q 'authorize_send_sas' crates/privileged-bridge/src/windows/sas.rs || fail 'SendSAS authorization gate is missing'
rg -q 'RemoteCommandRejected' crates/privileged-bridge/src/indicator.rs || fail 'protected indicator remote rejection is missing'
rg -q 'tray_manager: 0.5.3' apps/client_flutter/pubspec.yaml || fail 'tray dependency is not pinned'
rg -q 'window_manager: 0.5.2' apps/client_flutter/pubspec.yaml || fail 'window dependency is not pinned'

printf 'M8 bridge contract ok\n'
