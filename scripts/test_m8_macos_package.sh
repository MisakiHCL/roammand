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
test "$(rg -c 'ENABLE_HARDENED_RUNTIME = YES;' apps/client_flutter/macos/Runner.xcodeproj/project.pbxproj)" -eq 1
rg -q 'build_macos_universal_agents\.sh' scripts/package_m8_macos.sh
rg -q -- '--target "\$target"' scripts/build_macos_universal_agents.sh
rg -q 'webrtc-mac-arm64-release\.zip' scripts/build_macos_universal_agents.sh
rg -q 'webrtc-mac-x64-release\.zip' scripts/build_macos_universal_agents.sh
rg -q 'lipo -create' scripts/build_macos_universal_agents.sh
rg -q -- 'flutter build macos --release --no-pub' scripts/package_m8_macos.sh
rg -q -- '--options runtime' scripts/sign_macos_release.sh
rg -q -- '--timestamp' scripts/sign_macos_release.sh
rg -q 'Developer ID Application' scripts/sign_macos_release.sh
rg -q 'Developer ID Installer' scripts/build_macos_pkg.sh
rg -q 'pkgbuild --analyze' scripts/build_macos_pkg.sh
rg -q 'BundleIsRelocatable' scripts/build_macos_pkg.sh
rg -q -- '--component-plist' scripts/build_macos_pkg.sh
rg -q 'notarytool submit' scripts/notarize_macos_pkg.sh
rg -q -- '--timeout 2h' scripts/notarize_macos_pkg.sh
rg -q 'stapler staple' scripts/notarize_macos_pkg.sh
rg -q 'spctl --assess --type install' scripts/notarize_macos_pkg.sh
rg -q -- '--keychain-profile' scripts/notarize_macos_pkg.sh
rg -q '/dev/console' packaging/macos/scripts/postinstall
rg -Fq 'launchctl bootstrap "gui/$console_uid" "$AGENT_PLIST"' \
  packaging/macos/scripts/postinstall
rg -Fq 'launchctl kickstart -k "gui/$console_uid/dev.roammand.SessionAgent"' \
  packaging/macos/scripts/postinstall
if rg -qi 'sign out and in|注销并重新登录' \
  packaging/macos/scripts/postinstall scripts/install_m8_macos.sh docs/BUILDING.zh-CN.md; then
  printf 'macOS installation must not require a new login session\n' >&2
  exit 1
fi
if rg -q 'SUDO_UID' packaging/macos/scripts; then
  printf 'installer package scripts must not depend on a sudo shell\n' >&2
  exit 1
fi
plutil -lint packaging/macos/entitlements/*.entitlements >/dev/null
rg -q 'bridge-install-secret\.bin' scripts/install_m8_macos.sh scripts/uninstall_m8_macos.sh
rg -q 'bridge-owner-id' scripts/install_m8_macos.sh scripts/uninstall_m8_macos.sh
rg -q '/var/run/roammand' scripts/install_m8_macos.sh scripts/uninstall_m8_macos.sh
rg -q '/Applications/Roammand\.app' scripts/install_m8_macos.sh scripts/uninstall_m8_macos.sh
rg -q 'Application Support/Roammand' scripts/package_m8_macos.sh scripts/install_m8_macos.sh
rg -q 'uninstall-macos\.sh' scripts/package_m8_macos.sh scripts/install_m8_macos.sh
if rg -q '(private[_ -]?key|seed|signaling|turn[_ -]?password|/Users/|--shell|interactive service)' \
  packaging/macos scripts/package_m8_macos.sh scripts/install_m8_macos.sh scripts/uninstall_m8_macos.sh; then
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
