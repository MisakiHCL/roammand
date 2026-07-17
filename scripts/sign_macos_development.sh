#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SIGNING_CONFIG="$ROOT_DIR/apps/client_flutter/apple/Signing.local.xcconfig"
readonly DEFAULT_IDENTIFIER="dev.roammand.host-agent"

binary="${1:-}"
identifier="${2:-$DEFAULT_IDENTIFIER}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf 'macOS development signing is only supported on Darwin\n' >&2
  exit 2
fi
if [[ -z "$binary" || ! -f "$binary" || ! -x "$binary" ]]; then
  printf 'usage: sign_macos_development.sh EXECUTABLE [IDENTIFIER]\n' >&2
  exit 2
fi
if [[ ! "$identifier" =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ ]]; then
  printf 'development signing identifier is invalid\n' >&2
  exit 2
fi

if [[ ! -f "$SIGNING_CONFIG" ]]; then
  printf '%s\n' \
    'warning: no local Apple signing configuration; rebuilt Debug Agent may prompt for Keychain access' >&2
  exit 0
fi

team_id="$(awk '
  $1 == "ROAMMAND_APPLE_TEAM_ID" && $2 == "=" && NF == 3 {
    count += 1
    value = $3
  }
  END {
    if (count != 1) exit 1
    print value
  }
' "$SIGNING_CONFIG")" || {
  printf 'local Apple signing configuration has no unique Team ID\n' >&2
  exit 1
}
if [[ ! "$team_id" =~ ^[A-Z0-9]{10}$ ]]; then
  printf 'local Apple signing configuration has an invalid Team ID\n' >&2
  exit 1
fi

identities="$(security find-identity -v -p codesigning)"
identity_hash="$(printf '%s\n' "$identities" | awk -v team="$team_id" '
  /"Apple Development:/ && index($0, "(" team ")") > 0 {
    if ($2 ~ /^[0-9A-Fa-f]{40}$/) {
      print $2
      exit
    }
  }
')"
if [[ -z "$identity_hash" ]]; then
  development_identity_count="$(printf '%s\n' "$identities" | awk '
    /"Apple Development:/ && $2 ~ /^[0-9A-Fa-f]{40}$/ { count += 1 }
    END { print count + 0 }
  ')"
  if [[ "$development_identity_count" -eq 0 ]]; then
    printf '%s\n' \
      'warning: no Apple Development identity; rebuilt Debug Agent may prompt for Keychain access' >&2
    exit 0
  fi
  if [[ "$development_identity_count" -ne 1 ]]; then
    printf '%s\n' \
      'no unique Apple Development identity matches the configured Team ID' >&2
    exit 1
  fi
  identity_hash="$(printf '%s\n' "$identities" | awk '
    /"Apple Development:/ && $2 ~ /^[0-9A-Fa-f]{40}$/ {
      print $2
      exit
    }
  ')"
  printf '%s\n' \
    'warning: the sole Apple Development identity does not match the configured Team ID; using it only for the local Debug Agent' >&2
fi

codesign \
  --force \
  --sign "$identity_hash" \
  --identifier "$identifier" \
  --timestamp=none \
  "$binary"
codesign --verify --strict "$binary"
printf 'signed macOS development executable with a stable Apple Development identity\n'
