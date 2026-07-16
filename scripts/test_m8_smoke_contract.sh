#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

fail() { printf 'M8 harness contract failed: %s\n' "$1" >&2; exit 1; }
readonly REQUIRED_SCRIPTS=(
  scripts/check_m8_bridge_contract.sh
  scripts/check_m8_privacy.sh
  scripts/run_m8_smoke.sh
  scripts/test_m8_macos_package.sh
  scripts/test_m8_windows_package.sh
)
for script in "${REQUIRED_SCRIPTS[@]}"; do
  [[ -x "$script" ]] || fail "$script is missing or not executable"
  bash -n "$script" || fail "$script has invalid syntax"
done

for scenario in \
  bridge-schema-auth-negative \
  route-migration \
  emergency-stop \
  protected-indicator \
  flutter-status-and-tray \
  macos-package \
  windows-package \
  ten-session-transitions \
  native-webrtc; do
  rg -q "$scenario" scripts/run_m8_smoke.sh Makefile || fail "missing scenario: $scenario"
done
for target in test-m8 test-m8-config test-m8-privacy; do
  rg -q "^${target}:" Makefile || fail "missing Make target: $target"
done
rg -q 'm8-privileged-bridge' .github/workflows/ci.yml || fail 'CI matrix is missing'
rg -q 'windows-latest' .github/workflows/ci.yml || fail 'Windows CI is missing'
rg -q 'macos-latest' .github/workflows/ci.yml || fail 'macOS CI is missing'

printf 'M8 harness contract ok\n'
