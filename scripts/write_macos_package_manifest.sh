#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly PACKAGE_DIR="${1:-}"
if [[ -z "$PACKAGE_DIR" || ! -d "$PACKAGE_DIR" || "$PACKAGE_DIR" == "/" ]]; then
  printf 'macOS package directory required\n' >&2
  exit 2
fi

readonly SUPPORT_DIR="$PACKAGE_DIR/Library/Application Support/Roammand"
readonly MANIFEST="$SUPPORT_DIR/install-manifest.sha256"
install -d -m 0755 "$SUPPORT_DIR"

temporary="$(mktemp "$SUPPORT_DIR/install-manifest.sha256.XXXXXX")"
trap 'rm -f "$temporary"' EXIT
(
  cd "$PACKAGE_DIR"
  find . -type f \
    ! -path './.roammand-package-output' \
    ! -path './Library/Application Support/Roammand/install-manifest.sha256' \
    ! -path './Library/Application Support/Roammand/install-manifest.sha256.*' \
    -print | LC_ALL=C sort | sed 's#^\./##' | while IFS= read -r file; do
      shasum -a 256 "$file"
    done
) >"$temporary"
chmod 0644 "$temporary"
mv "$temporary" "$MANIFEST"
trap - EXIT

printf 'macOS package manifest updated\n'
