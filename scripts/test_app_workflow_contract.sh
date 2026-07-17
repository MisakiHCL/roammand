#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TARGETS=(
  help
  bootstrap
  app-check
  app-run-macos
  app-run-ios
  app-build-macos
  app-build-ios-simulator
  app-build-android
  package-macos
  test-product
)
readonly STEP_TARGETS=(
  bootstrap-steps
  app-check-steps
  test-product-steps
)

cd "$ROOT_DIR"

for target in "${TARGETS[@]}"; do
  rg --quiet "^${target}:" Makefile || {
    printf 'missing product workflow target: %s\n' "$target" >&2
    exit 1
  }
done

for target in "${STEP_TARGETS[@]}"; do
  rg --quiet "^${target}:" Makefile || {
    printf 'missing quiet workflow step target: %s\n' "$target" >&2
    exit 1
  }
done

rg --quiet '^FLUTTER_ARGS \?=' Makefile || {
  printf 'missing optional Flutter argument passthrough\n' >&2
  exit 1
}

rg --quiet '^app-run-macos: app-prepare-host-macos$' Makefile || {
  printf 'macOS development app does not prepare its managed Host Agent\n' >&2
  exit 1
}

rg --quiet 'ROAMMAND_HOST_AGENT_EXECUTABLE=' Makefile || {
  printf 'macOS development app does not receive the managed Agent path\n' >&2
  exit 1
}

rg --quiet '^VERBOSE \?= 0$' Makefile || {
  printf 'missing quiet workflow default\n' >&2
  exit 1
}

readonly QUIET_RUNNER="$ROOT_DIR/scripts/run_quiet_workflow.sh"
if [[ ! -x "$QUIET_RUNNER" ]]; then
  printf 'quiet workflow runner is not executable\n' >&2
  exit 1
fi

success_output="$(
  "$QUIET_RUNNER" sample-success bash -c \
    'printf "hidden success detail\\n"; exit 0'
)"
if [[ "$success_output" != '[PASS] sample-success completed in '* ]] || \
  [[ "$success_output" == *'hidden success detail'* ]]; then
  printf 'quiet workflow runner exposed successful command output\n' >&2
  exit 1
fi

set +e
failure_output="$(
  "$QUIET_RUNNER" sample-failure bash -c \
    'printf "useful failure detail\\n" >&2; exit 9' 2>&1
)"
failure_status="$?"
set -e

if [[ "$failure_status" -ne 9 ]] || \
  [[ "$failure_output" != *'[FAIL] sample-failure failed after '* ]] || \
  [[ "$failure_output" != *'useful failure detail'* ]] || \
  [[ "$failure_output" != *'Full log: '* ]] || \
  [[ "$failure_output" != *'make sample-failure VERBOSE=1'* ]]; then
  printf 'quiet workflow runner did not report failure clearly\n' >&2
  exit 1
fi

failure_log="$(
  printf '%s\n' "$failure_output" | sed -n 's/^Full log: //p'
)"
if [[ -z "$failure_log" ]] || [[ ! -f "$failure_log" ]]; then
  printf 'quiet workflow runner did not preserve the failed log\n' >&2
  exit 1
fi
rm -f "$failure_log"

printf 'app workflow contract ok\n'
