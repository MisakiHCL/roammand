#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SMOKE_SCRIPT="$ROOT_DIR/scripts/run_m6_smoke.sh"
readonly LIFECYCLE_SCRIPT="$ROOT_DIR/scripts/check_m6_lifecycle.sh"

for script in "$SMOKE_SCRIPT" "$LIFECYCLE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    printf 'missing executable M6 script: %s\n' "$script" >&2
    exit 1
  fi
done

output="$($SMOKE_SCRIPT --validate-only)"
for expected in \
  'READY automated M6 mobile control checks' \
  'SKIP matrix: iPhone -> Windows Host' \
  'SKIP matrix: iPhone -> macOS Host' \
  'SKIP matrix: iPad -> Windows Host' \
  'SKIP matrix: iPad -> macOS Host' \
  'SKIP matrix: Android phone -> Windows Host' \
  'SKIP matrix: Android phone -> macOS Host' \
  'SKIP matrix: Android tablet -> Windows Host' \
  'SKIP matrix: Android tablet -> macOS Host' \
  'SKIP direct ICE: two physical networks required' \
  'SKIP TURN: deployment credentials required'; do
  if [[ "$output" != *"$expected"* ]]; then
    printf 'missing M6 smoke status: %s\n' "$expected" >&2
    exit 1
  fi
done

if [[ "$(printf '%s\n' "$output" | rg -c '^SKIP matrix:')" -ne 8 ]]; then
  printf 'M6 physical matrix must contain exactly eight cells\n' >&2
  exit 1
fi

rg -q '^test-m6-config:' "$ROOT_DIR/Makefile"
rg -q '^test-m6-lifecycle:' "$ROOT_DIR/Makefile"
rg -q '^test-m6:' "$ROOT_DIR/Makefile"
rg -q 'make test-m6-config' "$ROOT_DIR/.github/workflows/ci.yml"
rg -q 'make test-m6-lifecycle' "$ROOT_DIR/.github/workflows/ci.yml"

printf 'M6 smoke contract ok\n'
