#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly PACKAGE_DIR="${1:-}"
[[ -n "$PACKAGE_DIR" && -d "$PACKAGE_DIR" ]] || { printf 'package directory required\n' >&2; exit 2; }
readonly MANIFEST="$PACKAGE_DIR/Library/Application Support/Roammand/install-manifest.sha256"

readonly REQUIRED=(
  "Applications/Roammand.app"
  "Library/PrivilegedHelperTools/roammand-host-agent"
  "Library/PrivilegedHelperTools/roammand-privileged-bridge"
  "Library/PrivilegedHelperTools/roammand-session-agent"
  "Library/LaunchDaemons/dev.roammand.PrivilegedBridge.plist"
  "Library/LaunchAgents/dev.roammand.SessionAgent.plist"
  "Library/Application Support/Roammand/uninstall-macos.sh"
  "Library/Application Support/Roammand/licenses/MPL-2.0.txt"
  "Library/Application Support/Roammand/licenses/Apache-2.0.txt"
)
for path in "${REQUIRED[@]}"; do
  [[ -e "$PACKAGE_DIR/$path" ]] || { printf 'missing staged macOS path: %s\n' "$path" >&2; exit 1; }
done
[[ -x "$PACKAGE_DIR/Library/Application Support/Roammand/uninstall-macos.sh" ]] || {
  printf 'staged macOS uninstaller is not executable\n' >&2
  exit 1
}
[[ ! -e "$PACKAGE_DIR/Library/LaunchAgents/dev.roammand.HostAgent.plist" ]] || {
  printf 'GUI-managed Host Agent must not be installed as a launchd job\n' >&2
  exit 1
}
[[ -f "$MANIFEST" ]] || { printf 'missing macOS package manifest\n' >&2; exit 1; }
(
  cd "$PACKAGE_DIR"
  shasum -a 256 -c "Library/Application Support/Roammand/install-manifest.sha256" >/dev/null
)
readonly PACKAGE_ROOT="$(realpath "$PACKAGE_DIR")"
readonly FRAMEWORKS_ROOT="$PACKAGE_ROOT/Applications/Roammand.app/Contents/Frameworks"
while IFS= read -r -d '' link; do
  target="$(readlink "$link")"
  link_parent="$(cd "$(dirname "$link")" && pwd -P)"
  link_absolute="$link_parent/$(basename "$link")"
  resolved="$(realpath "$link")"
  if [[ "$target" == /* || "$link_absolute" != "$FRAMEWORKS_ROOT/"* || "$resolved" != "$FRAMEWORKS_ROOT/"* ]]; then
    printf 'unsafe symbolic link in staged macOS package\n' >&2
    exit 1
  fi
done < <(find "$PACKAGE_DIR" -type l -print0)

readonly UNIVERSAL_BINARIES=(
  "Applications/Roammand.app/Contents/MacOS/roammand"
  "Library/PrivilegedHelperTools/roammand-host-agent"
  "Library/PrivilegedHelperTools/roammand-privileged-bridge"
  "Library/PrivilegedHelperTools/roammand-session-agent"
)
for path in "${UNIVERSAL_BINARIES[@]}"; do
  binary="$PACKAGE_DIR/$path"
  if file -b "$binary" | rg -q '^Mach-O'; then
    lipo "$binary" -verify_arch arm64 x86_64 >/dev/null || {
      printf 'macOS package binary is not Universal\n' >&2
      exit 1
    }
  fi
done
"$PACKAGE_DIR/Library/PrivilegedHelperTools/roammand-privileged-bridge" \
  check-macos-daemon >/dev/null
"$PACKAGE_DIR/Library/PrivilegedHelperTools/roammand-session-agent" \
  check-macos-agent >/dev/null
printf 'macOS package ok\n'
