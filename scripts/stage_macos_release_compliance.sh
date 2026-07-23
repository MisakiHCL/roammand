#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly COPYRIGHT_HOLDER='ChengLong Hu'
readonly REPOSITORY_URL='https://github.com/MisakiHCL/roammand'
PACKAGE_DIR="$ROOT_DIR/dist/m8-macos"

while (($#)); do
  case "$1" in
    --package-dir)
      [[ $# -ge 2 ]] || {
        printf 'macOS compliance package directory is required\n' >&2
        exit 2
      }
      PACKAGE_DIR="$2"
      shift 2
      ;;
    *)
      printf 'unknown macOS compliance staging option: %s\n' "$1" >&2
      exit 2
      ;;
  esac
done

source_revision="${ROAMMAND_MACOS_SOURCE_REVISION:-}"
if [[ -z "$source_revision" ]]; then
  source_revision="$(git -C "$ROOT_DIR" rev-parse --verify 'HEAD^{commit}')"
fi
source_url="${ROAMMAND_MACOS_SOURCE_URL:-$REPOSITORY_URL/tree/$source_revision}"
readonly LICENSES_DIR="$PACKAGE_DIR/Library/Application Support/Roammand/licenses"

python3 "$ROOT_DIR/scripts/generate_macos_release_compliance.py" \
  --package-dir "$PACKAGE_DIR" \
  --output-dir "$LICENSES_DIR" \
  --source-revision "$source_revision" \
  --source-url "$source_url" \
  --copyright-holder "$COPYRIGHT_HOLDER"

printf 'macOS release compliance assets staged\n'
