#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/apple_signing_common.sh
source "$ROOT_DIR/scripts/apple_signing_common.sh"

apple_require_macos
apple_load_signing_config
apple_find_identity_hash 'Developer ID Application' codesigning >/dev/null
apple_find_identity_hash 'Developer ID Installer' basic >/dev/null

installed_targets="$(rustup target list --installed)"
for target in aarch64-apple-darwin x86_64-apple-darwin; do
  if ! printf '%s\n' "$installed_targets" | awk -v expected="$target" \
    '$0 == expected { found=1 } END { exit !found }'; then
    printf 'missing Rust target: %s\n' "$target" >&2
    exit 1
  fi
done

settings="$(
  cd "$ROOT_DIR/apps/client_flutter"
  xcodebuild -project macos/Runner.xcodeproj -scheme Runner \
    -configuration Release -sdk macosx -showBuildSettings 2>/dev/null
)"

read_setting() {
  local key="$1"
  printf '%s\n' "$settings" | awk -F= -v key="$key" '
    {
      candidate = $1
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", candidate)
      if (candidate == key) {
        value = $0
        sub(/^[^=]*=[[:space:]]*/, "", value)
        gsub(/[[:space:]]+$/, "", value)
        count += 1
      }
    }
    END { if (count == 1) print value }
  '
}

if [[ "$(read_setting DEVELOPMENT_TEAM)" != "$APPLE_TEAM_ID" ]] ||
  [[ "$(read_setting PRODUCT_BUNDLE_IDENTIFIER)" != "$APPLE_BUNDLE_ID" ]] ||
  [[ "$(read_setting ENABLE_HARDENED_RUNTIME)" != "YES" ]] ||
  [[ "$(read_setting MACOSX_DEPLOYMENT_TARGET)" != "14.4" ]]; then
  printf 'effective macOS Release signing settings are invalid\n' >&2
  exit 1
fi

printf 'Apple release preflight ok\n'
