#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DEFAULT_OUTPUT="$ROOT_DIR/apps/client_flutter/apple/Signing.local.xcconfig"

mode="write"
team_id=""
bundle_id=""
output="$DEFAULT_OUTPUT"

usage() {
  printf '%s\n' \
    'usage: configure_apple_signing.sh --team-id TEAM --bundle-id ID [--output FILE]' \
    '       configure_apple_signing.sh --check [--output FILE]' >&2
}

require_value() {
  if (($# < 2)); then
    usage
    exit 2
  fi
}

validate_values() {
  local candidate_team="$1"
  local candidate_bundle="$2"
  if [[ ! "$candidate_team" =~ ^[A-Z0-9]{10}$ ]]; then
    printf 'Apple Team ID must be exactly 10 uppercase letters or digits\n' >&2
    return 1
  fi
  if [[ ! "$candidate_bundle" =~ ^[A-Za-z0-9][A-Za-z0-9-]*(\.[A-Za-z0-9][A-Za-z0-9-]*)+$ ]]; then
    printf 'Apple bundle ID must be a reverse-DNS identifier\n' >&2
    return 1
  fi
}

read_setting() {
  local key="$1"
  awk -v key="$key" '
    $1 == key && $2 == "=" && NF == 3 { count += 1; value = $3 }
    END { if (count != 1) exit 1; print value }
  ' "$output"
}

while (($#)); do
  case "$1" in
    --check)
      mode="check"
      shift
      ;;
    --team-id)
      require_value "$@"
      team_id="$2"
      shift 2
      ;;
    --bundle-id)
      require_value "$@"
      bundle_id="$2"
      shift 2
      ;;
    --output)
      require_value "$@"
      output="$2"
      shift 2
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ "$mode" == "check" ]]; then
  if [[ -n "$team_id$bundle_id" || ! -f "$output" ]]; then
    printf 'Apple signing check requires one existing local configuration\n' >&2
    exit 1
  fi
  team_id="$(read_setting ROAMMAND_APPLE_TEAM_ID)" || {
    printf 'local Apple signing file must define ROAMMAND_APPLE_TEAM_ID exactly once\n' >&2
    exit 1
  }
  bundle_id="$(read_setting ROAMMAND_APPLE_BUNDLE_ID)" || {
    printf 'local Apple signing file must define ROAMMAND_APPLE_BUNDLE_ID exactly once\n' >&2
    exit 1
  }
  validate_values "$team_id" "$bundle_id"
  printf 'local Apple signing configuration is valid: %s\n' "$output"
  exit 0
fi

if [[ -z "$team_id" || -z "$bundle_id" ]]; then
  usage
  exit 2
fi
validate_values "$team_id" "$bundle_id"

if [[ "$output" == "$DEFAULT_OUTPUT" ]] && ! git -C "$ROOT_DIR" check-ignore -q "$output"; then
  printf 'refusing to write Apple identity to a tracked path\n' >&2
  exit 1
fi

install -d -m 0700 "$(dirname "$output")"
umask 077
temporary="$(mktemp "$output.XXXXXX")"
trap 'rm -f "$temporary"' EXIT
printf '%s\n' \
  '// Local-only Apple signing identity. This file is intentionally ignored.' \
  "ROAMMAND_APPLE_TEAM_ID = $team_id" \
  "ROAMMAND_APPLE_BUNDLE_ID = $bundle_id" >"$temporary"
chmod 0600 "$temporary"
mv "$temporary" "$output"
trap - EXIT
printf 'wrote local Apple signing configuration: %s\n' "$output"
