#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -u

if [[ "$#" -lt 2 ]]; then
  printf 'usage: %s <workflow> <command> [args...]\n' "$0" >&2
  exit 64
fi

readonly WORKFLOW="$1"
shift

readonly LOG_FILE="$(mktemp "${TMPDIR:-/tmp}/roammand-${WORKFLOW}.log.XXXXXX")"
readonly START_SECONDS="$SECONDS"
KEEP_LOG=0

cleanup() {
  if [[ "$KEEP_LOG" -eq 0 ]]; then
    rm -f "$LOG_FILE"
  fi
}
trap cleanup EXIT

if "$@" >"$LOG_FILE" 2>&1; then
  printf '[PASS] %s completed in %ss\n' \
    "$WORKFLOW" "$((SECONDS - START_SECONDS))"
else
  readonly STATUS="$?"
  KEEP_LOG=1
  printf '[FAIL] %s failed after %ss\n' \
    "$WORKFLOW" "$((SECONDS - START_SECONDS))" >&2
  printf '%s\n' '--- last 40 log lines ---' >&2
  tail -n 40 "$LOG_FILE" >&2
  printf '%s\n' '--- end of log ---' >&2
  printf 'Full log: %s\n' "$LOG_FILE" >&2
  printf 'Run again with full output: make %s VERBOSE=1\n' "$WORKFLOW" >&2
  exit "$STATUS"
fi
