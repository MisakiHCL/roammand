#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/apple_signing_common.sh
source "$ROOT_DIR/scripts/apple_signing_common.sh"

PACKAGE_DIR="$ROOT_DIR/dist/m8-macos"
OUTPUT="$ROOT_DIR/dist/apple-release/Roammand.pkg"

while (($#)); do
  case "$1" in
    --package-dir) PACKAGE_DIR="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    *) printf 'unknown macOS pkg option\n' >&2; exit 2 ;;
  esac
done

apple_require_macos
apple_load_signing_config
"$ROOT_DIR/scripts/sign_macos_release.sh" \
  --verify-only --package-dir "$PACKAGE_DIR" >/dev/null

raw_version="$(awk '$1 == "version:" && NF == 2 { print $2 }' \
  "$ROOT_DIR/apps/client_flutter/pubspec.yaml")"
package_version="${raw_version/+/.}"
if [[ ! "$package_version" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
  printf 'Flutter version is not valid for a macOS installer package\n' >&2
  exit 1
fi

readonly INSTALLER_IDENTITY_HASH="$(
  apple_find_identity_hash 'Developer ID Installer' basic
)"
readonly PACKAGE_IDENTIFIER="dev.roammand.pkg"
readonly PACKAGE_SCRIPTS="$ROOT_DIR/packaging/macos/scripts"
readonly PACKAGE_OUTPUT_MARKER_FILTER='(^|/)\.roammand-package-output$'

install -d -m 0755 "$(dirname "$OUTPUT")"
component_plist="$(mktemp -t roammand-pkg-components)"
cleanup_component_plist() {
  rm -f "$component_plist"
}
trap cleanup_component_plist EXIT

if ! pkgbuild --analyze \
  --root "$PACKAGE_DIR" \
  --filter "$PACKAGE_OUTPUT_MARKER_FILTER" \
  "$component_plist" >/dev/null; then
  printf 'macOS installer component analysis failed\n' >&2
  exit 1
fi
component_index=0
while plutil -extract "$component_index.RootRelativeBundlePath" raw \
  "$component_plist" >/dev/null 2>&1; do
  plutil -replace "$component_index.BundleIsRelocatable" -bool NO "$component_plist"
  if [[ "$(plutil -extract "$component_index.BundleIsRelocatable" raw \
    "$component_plist")" != "false" ]]; then
    printf 'macOS app bundle must not be relocatable\n' >&2
    exit 1
  fi
  component_index=$((component_index + 1))
done
if [[ "$component_index" -lt 1 ]]; then
  printf 'macOS installer must contain the app bundle\n' >&2
  exit 1
fi

rm -f "$OUTPUT"
if ! pkgbuild_output="$(pkgbuild \
  --root "$PACKAGE_DIR" \
  --filter "$PACKAGE_OUTPUT_MARKER_FILTER" \
  --component-plist "$component_plist" \
  --install-location / \
  --identifier "$PACKAGE_IDENTIFIER" \
  --version "$package_version" \
  --scripts "$PACKAGE_SCRIPTS" \
  --ownership recommended \
  --sign "$INSTALLER_IDENTITY_HASH" \
  "$OUTPUT" 2>&1)"; then
  printf 'Developer ID Installer package creation failed\n' >&2
  exit 1
fi

apple_verify_installer_signature "$OUTPUT" || {
  printf 'macOS installer signature verification failed\n' >&2
  exit 1
}

printf 'signed macOS installer package created\n'
