#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SMOKE_SCRIPT="$ROOT_DIR/scripts/run_m4_smoke.sh"
readonly VALID_DESCRIPTOR='{"version":1,"signaling":"wss://signal.example.test/v1/connect","deviceId":"ivxT32c4VGFn8oH/USdvvVVKmnitai4jhsmUUU0HQ24=","publicKey":"AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=","displayName":"Test Host","platform":"macos"}'

run_clean() {
  env \
    -u ROAMMAND_M4_SIGNALING_ENDPOINT \
    -u ROAMMAND_M4_HOST_DESCRIPTOR \
    -u ROAMMAND_ALLOW_INSECURE_LAN_SIGNALING \
    -u ROAMMAND_ICE_TRANSPORT_POLICY \
    -u ROAMMAND_TURN_URLS \
    -u ROAMMAND_TURN_USERNAME \
    -u ROAMMAND_TURN_PASSWORD \
    "$@"
}

output="$(run_clean "$SMOKE_SCRIPT" --validate-only)"
if [[ "$output" != *"SKIP real-machine: configuration not supplied"* || \
      "$output" != *"SKIP TURN: configuration not supplied"* ]]; then
  printf 'missing clean SKIP result\n' >&2
  exit 1
fi

if run_clean env ROAMMAND_M4_SIGNALING_ENDPOINT='wss://signal.example.test/v1/connect' \
  "$SMOKE_SCRIPT" --validate-only >/dev/null 2>&1; then
  printf 'partial real-machine configuration unexpectedly passed\n' >&2
  exit 1
fi

if run_clean env ROAMMAND_TURN_USERNAME='partial' \
  "$SMOKE_SCRIPT" --validate-only >/dev/null 2>&1; then
  printf 'partial TURN configuration unexpectedly passed\n' >&2
  exit 1
fi

output="$(run_clean env \
  ROAMMAND_M4_SIGNALING_ENDPOINT='wss://signal.example.test/v1/connect' \
  ROAMMAND_M4_HOST_DESCRIPTOR="$VALID_DESCRIPTOR" \
  ROAMMAND_ICE_TRANSPORT_POLICY='relay' \
  ROAMMAND_TURN_URLS='turns:turn.example.test:5349' \
  ROAMMAND_TURN_USERNAME='test-user' \
  ROAMMAND_TURN_PASSWORD='test-password' \
  "$SMOKE_SCRIPT" --validate-only)"
if [[ "$output" != *"READY real-machine: configuration valid"* || \
      "$output" != *"READY TURN: relay configuration valid"* ]]; then
  printf 'valid smoke configuration did not become READY\n' >&2
  exit 1
fi

printf 'M4 smoke configuration contract ok\n'
