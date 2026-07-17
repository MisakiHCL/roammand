#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/apple_signing_common.sh
source "$ROOT_DIR/scripts/apple_signing_common.sh"

PACKAGE_DIR="$ROOT_DIR/dist/m8-macos"
VERIFY_ONLY=false

while (($#)); do
  case "$1" in
    --package-dir) PACKAGE_DIR="$2"; shift 2 ;;
    --verify-only) VERIFY_ONLY=true; shift ;;
    *) printf 'unknown macOS signing option\n' >&2; exit 2 ;;
  esac
done

apple_require_macos
apple_load_signing_config

readonly APP="$PACKAGE_DIR/Applications/Roammand.app"
readonly HOST_AGENT="$PACKAGE_DIR/Library/PrivilegedHelperTools/roammand-host-agent"
readonly BRIDGE="$PACKAGE_DIR/Library/PrivilegedHelperTools/roammand-privileged-bridge"
readonly SESSION_AGENT="$PACKAGE_DIR/Library/PrivilegedHelperTools/roammand-session-agent"
readonly APP_ENTITLEMENTS="$ROOT_DIR/apps/client_flutter/macos/Runner/Release.entitlements"
readonly HOST_ENTITLEMENTS="$ROOT_DIR/packaging/macos/entitlements/host-agent.entitlements"
readonly BRIDGE_ENTITLEMENTS="$ROOT_DIR/packaging/macos/entitlements/privileged-bridge.entitlements"
readonly SESSION_ENTITLEMENTS="$ROOT_DIR/packaging/macos/entitlements/session-agent.entitlements"
readonly HOST_IDENTIFIER="$APPLE_BUNDLE_ID.host-agent"
readonly BRIDGE_IDENTIFIER="$APPLE_BUNDLE_ID.privileged-bridge"
readonly SESSION_IDENTIFIER="$APPLE_BUNDLE_ID.session-agent"

for path in "$APP" "$HOST_AGENT" "$BRIDGE" "$SESSION_AGENT"; do
  [[ -e "$path" ]] || { printf 'staged macOS code is missing\n' >&2; exit 1; }
done
plutil -lint "$APP_ENTITLEMENTS" "$HOST_ENTITLEMENTS" \
  "$BRIDGE_ENTITLEMENTS" "$SESSION_ENTITLEMENTS" >/dev/null

verify_release_signatures() {
  local framework
  local frameworks_root="$APP/Contents/Frameworks"

  if [[ -d "$frameworks_root" ]]; then
    for framework in "$frameworks_root"/*.framework; do
      [[ -e "$framework" ]] || continue
      apple_verify_code_signature "$framework" || return 1
    done
  fi
  apple_verify_code_signature "$APP" "$APPLE_BUNDLE_ID" || return 1
  apple_verify_code_signature "$HOST_AGENT" "$HOST_IDENTIFIER" || return 1
  apple_verify_code_signature "$BRIDGE" "$BRIDGE_IDENTIFIER" || return 1
  apple_verify_code_signature "$SESSION_AGENT" "$SESSION_IDENTIFIER" || return 1
  codesign --verify --deep --strict "$APP" >/dev/null 2>&1
}

if $VERIFY_ONLY; then
  verify_release_signatures || {
    printf 'macOS release signature verification failed\n' >&2
    exit 1
  }
  printf 'macOS release signatures ok\n'
  exit 0
fi

readonly APPLICATION_IDENTITY_HASH="$(
  apple_find_identity_hash 'Developer ID Application' codesigning
)"

sign_code() {
  local target="$1"
  local identifier="${2:-}"
  local entitlements="${3:-}"
  local output
  local arguments=(--force --sign "$APPLICATION_IDENTITY_HASH" --timestamp --options runtime)

  [[ -n "$identifier" ]] && arguments+=(--identifier "$identifier")
  [[ -n "$entitlements" ]] && arguments+=(--entitlements "$entitlements")
  if ! output="$(codesign "${arguments[@]}" "$target" 2>&1)"; then
    printf 'Developer ID Application signing failed\n' >&2
    return 1
  fi
}

readonly FRAMEWORKS_ROOT="$APP/Contents/Frameworks"
if [[ -d "$FRAMEWORKS_ROOT" ]]; then
  for framework in "$FRAMEWORKS_ROOT"/*.framework; do
    [[ -e "$framework" ]] || continue
    sign_code "$framework"
  done
  for library in "$FRAMEWORKS_ROOT"/*.dylib; do
    [[ -e "$library" ]] || continue
    sign_code "$library"
  done
fi

sign_code "$HOST_AGENT" "$HOST_IDENTIFIER" "$HOST_ENTITLEMENTS"
sign_code "$BRIDGE" "$BRIDGE_IDENTIFIER" "$BRIDGE_ENTITLEMENTS"
sign_code "$SESSION_AGENT" "$SESSION_IDENTIFIER" "$SESSION_ENTITLEMENTS"
sign_code "$APP" "$APPLE_BUNDLE_ID" "$APP_ENTITLEMENTS"

verify_release_signatures || {
  printf 'macOS release signature verification failed\n' >&2
  exit 1
}
"$ROOT_DIR/scripts/write_macos_package_manifest.sh" "$PACKAGE_DIR" >/dev/null
"$ROOT_DIR/scripts/check_m8_macos_package.sh" "$PACKAGE_DIR" >/dev/null

printf 'macOS staged code signed with Developer ID Application\n'
