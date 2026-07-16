#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly MANIFEST="$ROOT_DIR/scripts/libwebrtc-assets.sha256"
readonly EXPECTED_TAG="webrtc-24f6822-2"
readonly EXPECTED_ASSETS=(
  "webrtc-mac-arm64-release.zip"
  "webrtc-mac-x64-release.zip"
  "webrtc-win-x64-release.zip"
)
readonly EXPECTED_LOCKED_PACKAGES=(
  "libwebrtc"
  "livekit-protocol"
  "webrtc-sys"
  "webrtc-sys-build"
)
readonly EXPECTED_LOCKED_VERSIONS=(
  "0.3.27"
  "0.7.2"
  "0.3.25"
  "0.3.14"
)

locked_version() {
  local package="$1"
  awk -v package="$package" '
    $0 == "name = \"" package "\"" { found = 1; next }
    found && /^version = / {
      gsub(/^version = \"|\"$/, "")
      print
      exit
    }
    found && /^\[\[package\]\]/ { exit }
  ' "$ROOT_DIR/Cargo.lock"
}

if [[ ! -f "$MANIFEST" ]]; then
  printf 'missing libwebrtc asset manifest\n' >&2
  exit 1
fi

rows=()
while IFS= read -r row; do
  rows+=("$row")
done < <(awk '!/^#/ && NF { print $1 " " $2 " " $3 }' "$MANIFEST")
if [[ "${#rows[@]}" -ne "${#EXPECTED_ASSETS[@]}" ]]; then
  printf 'unexpected libwebrtc asset count: %s\n' "${#rows[@]}" >&2
  exit 1
fi

for index in "${!EXPECTED_ASSETS[@]}"; do
  read -r tag asset checksum <<<"${rows[$index]}"
  if [[ "$tag" != "$EXPECTED_TAG" || "$asset" != "${EXPECTED_ASSETS[$index]}" ]]; then
    printf 'unexpected libwebrtc asset row: %s\n' "${rows[$index]}" >&2
    exit 1
  fi
  if [[ ! "$checksum" =~ ^[0-9a-f]{64}$ ]]; then
    printf 'invalid libwebrtc SHA-256 for %s\n' "$asset" >&2
    exit 1
  fi
done

for index in "${!EXPECTED_LOCKED_PACKAGES[@]}"; do
  package="${EXPECTED_LOCKED_PACKAGES[$index]}"
  expected="${EXPECTED_LOCKED_VERSIONS[$index]}"
  actual="$(locked_version "$package")"
  if [[ "$actual" != "$expected" ]]; then
    printf 'unexpected %s lock version: expected %s, found %s\n' \
      "$package" "$expected" "${actual:-missing}" >&2
    exit 1
  fi
done

printf 'libwebrtc asset manifest ok\n'
