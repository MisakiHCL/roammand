#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/roammand-brand.XXXXXX")"
trap 'rm -rf "$TEMP_DIR"' EXIT

command -v qlmanage >/dev/null || {
  printf 'qlmanage is required to render the SVG source on macOS.\n' >&2
  exit 1
}
python3 -c 'import PIL' 2>/dev/null || {
  printf 'Python Pillow is required to resize PNG and ICO assets.\n' >&2
  exit 1
}

qlmanage -t -s 1024 -o "$TEMP_DIR" \
  "$ROOT_DIR/brand/roammand-app-icon.svg" >/dev/null 2>&1
qlmanage -t -s 1024 -o "$TEMP_DIR" \
  "$ROOT_DIR/brand/roammand-tray-template.svg" >/dev/null 2>&1

python3 "$ROOT_DIR/scripts/render_brand_assets.py" \
  --app-icon "$TEMP_DIR/roammand-app-icon.svg.png" \
  --tray-icon "$TEMP_DIR/roammand-tray-template.svg.png" \
  --root "$ROOT_DIR"

printf 'Roammand brand assets rendered.\n'
