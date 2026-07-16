#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly MANIFEST="$ROOT_DIR/scripts/libwebrtc-assets.sha256"
readonly RELEASE_BASE_URL="https://github.com/livekit/rust-sdks/releases/download"
readonly CACHE_ROOT="${ROAMMAND_WEBRTC_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/roammand/libwebrtc}"

detect_asset() {
  local system architecture
  system="$(uname -s)"
  architecture="$(uname -m)"
  case "$system:$architecture" in
    Darwin:arm64) printf 'webrtc-mac-arm64-release.zip\n' ;;
    Darwin:x86_64) printf 'webrtc-mac-x64-release.zip\n' ;;
    MINGW*:x86_64|MSYS*:x86_64|CYGWIN*:x86_64) printf 'webrtc-win-x64-release.zip\n' ;;
    *)
      printf 'unsupported native WebRTC host: %s/%s\n' "$system" "$architecture" >&2
      return 1
      ;;
  esac
}

verify_sha256() {
  local archive="$1" checksum="$2"
  if command -v shasum >/dev/null 2>&1; then
    printf '%s  %s\n' "$checksum" "$archive" | shasum -a 256 -c - >/dev/null
  elif command -v sha256sum >/dev/null 2>&1; then
    printf '%s  %s\n' "$checksum" "$archive" | sha256sum -c - >/dev/null
  else
    printf 'missing SHA-256 tool: shasum or sha256sum\n' >&2
    return 1
  fi
}

asset="${1:-$(detect_asset)}"
row="$(awk -v requested="$asset" '!/^#/ && $2 == requested { print $1 " " $2 " " $3 }' "$MANIFEST")"
if [[ -z "$row" ]]; then
  printf 'unrecognized libwebrtc asset: %s\n' "$asset" >&2
  exit 1
fi
read -r tag asset checksum <<<"$row"

archive_dir="$CACHE_ROOT/$tag/archives"
extract_dir="$CACHE_ROOT/$tag/${asset#webrtc-}"
extract_dir="${extract_dir%.zip}"
archive="$archive_dir/$asset"
case "$asset" in
  webrtc-win-*) native_library="$extract_dir/lib/webrtc.lib" ;;
  *) native_library="$extract_dir/lib/libwebrtc.a" ;;
esac
mkdir -p "$archive_dir" "$CACHE_ROOT/$tag"

if [[ ! -f "$archive" ]] || ! verify_sha256 "$archive" "$checksum"; then
  temporary="$archive.partial"
  rm -f "$temporary"
  curl --fail --location --proto '=https' --tlsv1.2 \
    "$RELEASE_BASE_URL/$tag/$asset" --output "$temporary"
  verify_sha256 "$temporary" "$checksum"
  mv "$temporary" "$archive"
fi

if [[ ! -f "$native_library" ]]; then
  rm -rf "$extract_dir"
  unzip -q "$archive" -d "$CACHE_ROOT/$tag"
fi

if [[ ! -f "$native_library" || ! -d "$extract_dir/include" ]]; then
  printf 'incomplete libwebrtc extraction for %s\n' "$asset" >&2
  exit 1
fi

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*) cygpath -m "$extract_dir" ;;
  *) printf '%s\n' "$extract_dir" ;;
esac
