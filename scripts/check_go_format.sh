#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly GO_TREES=(
  "$ROOT_DIR/gen/go"
  "$ROOT_DIR/services/signaling"
)

for tree in "${GO_TREES[@]}"; do
  unformatted="$(gofmt -l "$tree")"
  if [[ -n "$unformatted" ]]; then
    printf 'unformatted Go files:\n%s\n' "$unformatted" >&2
    exit 1
  fi
done

printf 'Go formatting ok\n'
