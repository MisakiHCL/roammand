#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

cd "$ROOT_DIR"

plutil -lint packaging/macos/*.plist >/dev/null
rg -q '<string>dev\.roammand\.PrivilegedBridge</string>' \
  packaging/macos/dev.roammand.PrivilegedBridge.plist
rg -q '<string>Aqua</string>' packaging/macos/dev.roammand.SessionAgent.plist
rg -q '<string>LoginWindow</string>' packaging/macos/dev.roammand.SessionAgent.plist
test ! -e packaging/macos/dev.roammand.HostAgent.plist
test "$(rg -c 'MACOSX_DEPLOYMENT_TARGET = 14\.4;' apps/client_flutter/macos/Runner.xcodeproj/project.pbxproj)" -eq 3
rg -q -- '--features native-webrtc' scripts/package_m8_macos.sh
rg -q -- 'flutter build macos --release --no-pub' scripts/package_m8_macos.sh
rg -q 'bridge-install-secret\.bin' scripts/install_m8_macos.sh scripts/uninstall_m8_macos.sh
rg -q 'bridge-owner-id' scripts/install_m8_macos.sh scripts/uninstall_m8_macos.sh
rg -q '/var/run/roammand' scripts/install_m8_macos.sh scripts/uninstall_m8_macos.sh
rg -q '/Applications/Roammand\.app' scripts/install_m8_macos.sh scripts/uninstall_m8_macos.sh
rg -q 'Application Support/Roammand' scripts/package_m8_macos.sh scripts/install_m8_macos.sh
if rg -n '(private[_ -]?key|seed|signaling|turn[_ -]?password|/Users/|--shell|interactive service)' \
  packaging/macos scripts/package_m8_macos.sh scripts/install_m8_macos.sh; then
  printf 'macOS package contains forbidden privilege or local data\n' >&2
  exit 1
fi

mkdir -p "$TEMP_DIR/Roammand.app/Contents/MacOS"
printf 'app\n' >"$TEMP_DIR/Roammand.app/Contents/MacOS/roammand"
printf 'host\n' >"$TEMP_DIR/roammand-host-agent"
printf '#!/bin/sh\nexit 0\n' >"$TEMP_DIR/roammand-privileged-bridge"
printf '#!/bin/sh\nexit 0\n' >"$TEMP_DIR/roammand-session-agent"
chmod 0755 "$TEMP_DIR"/roammand-*

./scripts/package_m8_macos.sh \
  --output "$TEMP_DIR/package" \
  --app-bundle "$TEMP_DIR/Roammand.app" \
  --host-agent "$TEMP_DIR/roammand-host-agent" \
  --bridge "$TEMP_DIR/roammand-privileged-bridge" \
  --session-agent "$TEMP_DIR/roammand-session-agent"
./scripts/check_m8_macos_package.sh "$TEMP_DIR/package"
ln -s /etc/passwd "$TEMP_DIR/package/unsafe-link"
if ./scripts/check_m8_macos_package.sh "$TEMP_DIR/package" >/dev/null 2>&1; then
  printf 'macOS package checker accepted an escaping symbolic link\n' >&2
  exit 1
fi
rm "$TEMP_DIR/package/unsafe-link"
./scripts/install_m8_macos.sh --dry-run \
  --package "$TEMP_DIR/package" | rg -q 'no changes made'
./scripts/uninstall_m8_macos.sh --dry-run | rg -q 'preserve local identity and grants'

printf 'M8 macOS package contract ok\n'
