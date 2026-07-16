#!/usr/bin/env bash
set -euo pipefail

require_version() {
  local expected="$1"
  local actual
  shift

  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'missing tool: %s\n' "$1" >&2
    exit 1
  fi

  actual="$("$@" 2>&1)"
  if [[ "$actual" != *"$expected"* ]]; then
    printf 'unexpected %s version: %s (expected %s)\n' \
      "$1" "$actual" "$expected" >&2
    exit 1
  fi
}

require_version "3.44.0" flutter --version
require_version "go1.26.5" go version
require_version "1.97.0" rustc --version
require_version "1.97.0" cargo --version
require_version "1.69.0" buf --version

for required_command in protoc git make rg curl unzip; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'missing tool: %s\n' "$required_command" >&2
    exit 1
  fi
done

if ! command -v shasum >/dev/null 2>&1 && ! command -v sha256sum >/dev/null 2>&1; then
  printf 'missing tool: shasum or sha256sum\n' >&2
  exit 1
fi

printf 'toolchain ok\n'
