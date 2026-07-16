#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "${1:-}" in
  '') validate_only=0 ;;
  --validate-only) validate_only=1 ;;
  *)
    printf 'usage: %s [--validate-only]\n' "$0" >&2
    exit 2
    ;;
esac

printf 'READY automated M6 mobile control checks\n'
printf 'SKIP matrix: iPhone -> Windows Host\n'
printf 'SKIP matrix: iPhone -> macOS Host\n'
printf 'SKIP matrix: iPad -> Windows Host\n'
printf 'SKIP matrix: iPad -> macOS Host\n'
printf 'SKIP matrix: Android phone -> Windows Host\n'
printf 'SKIP matrix: Android phone -> macOS Host\n'
printf 'SKIP matrix: Android tablet -> Windows Host\n'
printf 'SKIP matrix: Android tablet -> macOS Host\n'
printf 'SKIP direct ICE: two physical networks required\n'
printf 'SKIP TURN: deployment credentials required\n'

if [[ "$validate_only" -eq 1 ]]; then
  exit 0
fi

cd "$ROOT_DIR"

./scripts/check_m6_lifecycle.sh

case "$(uname -s)" in
  Darwin)
    (cd apps/client_flutter && flutter build ios --simulator --debug)
    ;;
  Linux)
    (cd apps/client_flutter && flutter build apk --debug)
    ;;
  *)
    printf 'SKIP mobile debug build: unsupported build host\n'
    ;;
esac

printf 'M6 automated smoke checks passed\n'
