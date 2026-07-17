#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for asset in brand/roammand-mark.svg brand/roammand-app-icon.svg; do
  if rg -q 'rect .*fill="#11142D"' "$asset"; then
    printf 'controller screen must use the same open field as the workspace: %s\n' "$asset" >&2
    exit 1
  fi
  rg -q 'rect .*fill="none".*stroke="#F3F2FF"' "$asset" || {
    printf 'missing open controller screen: %s\n' "$asset" >&2
    exit 1
  }
done

rg -q 'M428 548H148' brand/roammand-mark.svg || {
  printf 'primary mark workspace does not tuck cleanly beneath the controller\n' >&2
  exit 1
}
rg -q 'M550 716H286' brand/roammand-app-icon.svg || {
  printf 'app icon workspace does not tuck cleanly beneath the controller\n' >&2
  exit 1
}

for asset in brand/roammand-mark.svg brand/roammand-app-icon.svg; do
  if rg -q 'circle cx="(238|390)" cy="(342|514)"' "$asset"; then
    printf 'connector must not use a separate endpoint dot: %s\n' "$asset" >&2
    exit 1
  fi
done

rg -q 'M238 342c84 0 116-56 210-56.*stroke="url\(#connector\)"' \
  brand/roammand-mark.svg || {
  printf 'primary mark connector is not a continuous signal gradient\n' >&2
  exit 1
}
rg -q 'M390 514c92 0 126-62 184-62.*stroke="url\(#connector\)"' \
  brand/roammand-app-icon.svg || {
  printf 'app icon connector is not a continuous signal gradient\n' >&2
  exit 1
}

if rg -q 'controller,[[:space:]]*$' apps/client_flutter/lib/design_system/roammand_brand_mark.dart && \
  rg -U -q 'controller,[[:space:]]*Paint\(\)[[:space:]]*\.\.style = PaintingStyle\.fill' \
    apps/client_flutter/lib/design_system/roammand_brand_mark.dart; then
  printf 'Flutter brand mark still fills the controller screen\n' >&2
  exit 1
fi

if rg -q 'canvas\.drawRRect\(workspace|1\.25 \* scale' \
  apps/client_flutter/lib/design_system/roammand_brand_mark.dart; then
  printf 'Flutter brand mark still uses protruding workspace or connector endpoints\n' >&2
  exit 1
fi

python3 - <<'PY'
from PIL import Image

image = Image.open(
    "apps/client_flutter/assets/brand/roammand_tray_template.png"
).convert("RGBA")
alpha = list(image.getchannel("A").getdata())
if image.size != (32, 32) or not any(value == 0 for value in alpha):
    raise SystemExit("macOS tray template must contain a transparent background")
if not any(value > 0 for value in alpha):
    raise SystemExit("macOS tray template must contain visible logo pixels")
if any(pixel[:3] != (0, 0, 0) for pixel in image.getdata() if pixel[3] > 0):
    raise SystemExit("macOS tray template must contain only black and clear pixels")
PY

printf 'Roammand brand asset contract ok\n'
