#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DART_OUTPUT="$ROOT_DIR/gen/dart/lib/src/generated"
readonly RUST_OUTPUT="$ROOT_DIR/gen/rust/src/generated"
readonly GO_OUTPUT="$ROOT_DIR/gen/go/roammand/v1"
readonly BUF_BIN="${BUF_BIN:-buf}"
readonly BACKUP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/roammand-generation.XXXXXX")"
readonly DART_BACKUP="$BACKUP_ROOT/dart"
readonly RUST_BACKUP="$BACKUP_ROOT/rust"
readonly GO_BACKUP="$BACKUP_ROOT/go"

backup_outputs() {
  if [[ -d "$DART_OUTPUT" ]]; then
    cp -R "$DART_OUTPUT" "$DART_BACKUP"
  fi
  if [[ -d "$RUST_OUTPUT" ]]; then
    cp -R "$RUST_OUTPUT" "$RUST_BACKUP"
  fi
  mkdir -p "$GO_BACKUP"
  if [[ -d "$GO_OUTPUT" ]]; then
    while IFS= read -r -d '' generated_file; do
      cp "$generated_file" "$GO_BACKUP/$(basename "$generated_file")"
    done < <(find "$GO_OUTPUT" -type f -name '*.pb.go' -print0)
  fi
}

restore_outputs() {
  rm -rf "$DART_OUTPUT" "$RUST_OUTPUT"
  if [[ -d "$DART_BACKUP" ]]; then
    mv "$DART_BACKUP" "$DART_OUTPUT"
  fi
  if [[ -d "$RUST_BACKUP" ]]; then
    mv "$RUST_BACKUP" "$RUST_OUTPUT"
  fi
  if [[ -d "$GO_OUTPUT" ]]; then
    find "$GO_OUTPUT" -type f -name '*.pb.go' -delete
  else
    mkdir -p "$GO_OUTPUT"
  fi
  if [[ -d "$GO_BACKUP" ]]; then
    find "$GO_BACKUP" -type f -name '*.pb.go' -exec mv {} "$GO_OUTPUT"/ \;
  fi
}

cleanup() {
  local status="$?"
  if [[ "$status" -ne 0 ]]; then
    restore_outputs
  fi
  rm -rf "$BACKUP_ROOT"
  exit "$status"
}

prepend_spdx() {
  local file="$1"
  local temporary

  if head -n 1 "$file" | rg -q --fixed-strings 'SPDX-License-Identifier: Apache-2.0'; then
    return
  fi

  temporary="$(mktemp "${file}.XXXXXX")"
  {
    printf '%s\n\n' '// SPDX-License-Identifier: Apache-2.0'
    command cat "$file"
  } >"$temporary"
  mv "$temporary" "$file"
}

backup_outputs
trap cleanup EXIT

rm -rf "$DART_OUTPUT" "$RUST_OUTPUT"
if [[ -d "$GO_OUTPUT" ]]; then
  find "$GO_OUTPUT" -type f -name '*.pb.go' -delete
fi

cd "$ROOT_DIR"
"$BUF_BIN" generate

while IFS= read -r -d '' generated_file; do
  prepend_spdx "$generated_file"
done < <(find "$DART_OUTPUT" "$RUST_OUTPUT" -type f \( -name '*.dart' -o -name '*.rs' \) -print0)

trap - EXIT
rm -rf "$BACKUP_ROOT"
