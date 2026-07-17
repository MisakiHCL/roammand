#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/apple_signing_common.sh
source "$ROOT_DIR/scripts/apple_signing_common.sh"

PACKAGE="$ROOT_DIR/dist/apple-release/Roammand.pkg"
KEYCHAIN_PROFILE="${ROAMMAND_NOTARY_KEYCHAIN_PROFILE:-roammand-notary}"

while (($#)); do
  case "$1" in
    --package) PACKAGE="$2"; shift 2 ;;
    --keychain-profile) KEYCHAIN_PROFILE="$2"; shift 2 ;;
    *) printf 'unknown macOS notarization option\n' >&2; exit 2 ;;
  esac
done

apple_require_macos
apple_load_signing_config
if [[ ! -f "$PACKAGE" || "$PACKAGE" != *.pkg ]]; then
  printf 'signed macOS installer package required\n' >&2
  exit 2
fi
if [[ ! "$KEYCHAIN_PROFILE" =~ ^[A-Za-z0-9._-]+$ ]]; then
  printf 'notarytool Keychain profile name is invalid\n' >&2
  exit 2
fi
apple_verify_installer_signature "$PACKAGE" || {
  printf 'macOS installer signature verification failed\n' >&2
  exit 1
}

if ! submission="$(xcrun notarytool submit "$PACKAGE" \
  --keychain-profile "$KEYCHAIN_PROFILE" \
  --wait --timeout 2h --output-format json 2>/dev/null)"; then
  printf 'Apple notarization submission failed\n' >&2
  exit 1
fi
status="$(printf '%s' "$submission" | \
  plutil -extract status raw -o - -- - 2>/dev/null || true)"
if [[ "$status" != "Accepted" ]]; then
  submission_id="$(printf '%s' "$submission" | \
    plutil -extract id raw -o - -- - 2>/dev/null || true)"
  if [[ "$submission_id" =~ ^[A-Fa-f0-9-]{36}$ ]]; then
    readonly LOG_PATH="$ROOT_DIR/dist/apple-release/notarization-log.json"
    xcrun notarytool log "$submission_id" \
      --keychain-profile "$KEYCHAIN_PROFILE" "$LOG_PATH" >/dev/null 2>&1 || true
    printf 'Apple notarization was not accepted; inspect the ignored notarization log\n' >&2
  else
    printf 'Apple notarization returned an unreadable response\n' >&2
  fi
  exit 1
fi

if ! stapler_output="$(xcrun stapler staple "$PACKAGE" 2>&1)"; then
  printf 'notarization ticket stapling failed\n' >&2
  exit 1
fi
if ! validate_output="$(xcrun stapler validate "$PACKAGE" 2>&1)"; then
  printf 'notarization ticket validation failed\n' >&2
  exit 1
fi
if ! assessment_output="$(spctl --assess --type install "$PACKAGE" 2>&1)"; then
  printf 'Gatekeeper installer assessment failed\n' >&2
  exit 1
fi

printf 'macOS installer notarized, stapled, and accepted by Gatekeeper\n'
