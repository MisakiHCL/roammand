#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SNAPSHOT_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/roammand-generation-check.XXXXXX")"
readonly DART_GENERATED="gen/dart/lib/src/generated"
readonly RUST_GENERATED="gen/rust/src/generated"
readonly GO_GENERATED="gen/go/roammand/v1"

cleanup() {
  rm -rf "$SNAPSHOT_ROOT"
}

snapshot_generated_outputs() {
  cp -R "$DART_GENERATED" "$SNAPSHOT_ROOT/dart"
  cp -R "$RUST_GENERATED" "$SNAPSHOT_ROOT/rust"
  mkdir -p "$SNAPSHOT_ROOT/go"
  find "$GO_GENERATED" -type f -name '*.pb.go' -exec cp {} "$SNAPSHOT_ROOT/go/" \;
}

compare_generated_outputs() {
  diff -ru "$SNAPSHOT_ROOT/dart" "$DART_GENERATED"
  diff -ru "$SNAPSHOT_ROOT/rust" "$RUST_GENERATED"

  local current_go
  current_go="$(mktemp -d "$SNAPSHOT_ROOT/current-go.XXXXXX")"
  find "$GO_GENERATED" -type f -name '*.pb.go' -exec cp {} "$current_go/" \;
  diff -ru "$SNAPSHOT_ROOT/go" "$current_go"
}

cd "$ROOT_DIR"
trap cleanup EXIT
snapshot_generated_outputs
if BUF_BIN=false ./scripts/generate_protocol.sh; then
  printf '%s\n' 'generation failure check expected the fake Buf command to fail' >&2
  exit 1
fi

compare_generated_outputs
printf '%s\n' 'generation failure atomicity ok'
