#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/dist/m8-macos"
APP_BUNDLE=""
HOST_AGENT=""
BRIDGE=""
SESSION_AGENT=""

while (($#)); do
  case "$1" in
    --output) OUTPUT_DIR="$2"; shift 2 ;;
    --app-bundle) APP_BUNDLE="$2"; shift 2 ;;
    --host-agent) HOST_AGENT="$2"; shift 2 ;;
    --bridge) BRIDGE="$2"; shift 2 ;;
    --session-agent) SESSION_AGENT="$2"; shift 2 ;;
    *) printf 'unknown macOS package option: %s\n' "$1" >&2; exit 2 ;;
  esac
done

cd "$ROOT_DIR"

if [[ -z "$APP_BUNDLE$HOST_AGENT$BRIDGE$SESSION_AGENT" ]]; then
  if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
    printf 'refusing release build from a dirty worktree\n' >&2
    exit 1
  fi
  ./scripts/build_macos_universal_agents.sh
  # Dependency resolution is explicit in `make bootstrap`; packaging reuses
  # the locked cache and must not depend on pub.dev being reachable.
  (cd apps/client_flutter && flutter build macos --release --no-pub)
  APP_BUNDLE="$ROOT_DIR/apps/client_flutter/build/macos/Build/Products/Release/roammand.app"
  HOST_AGENT="$ROOT_DIR/target/macos-universal/release/roammand-host-agent"
  BRIDGE="$ROOT_DIR/target/macos-universal/release/roammand-privileged-bridge"
  SESSION_AGENT="$ROOT_DIR/target/macos-universal/release/roammand-session-agent"
elif [[ -z "$APP_BUNDLE" || -z "$HOST_AGENT" || -z "$BRIDGE" || -z "$SESSION_AGENT" ]]; then
  printf 'all four artifact overrides are required together\n' >&2
  exit 2
fi

for artifact in "$APP_BUNDLE" "$HOST_AGENT" "$BRIDGE" "$SESSION_AGENT"; do
  [[ -e "$artifact" ]] || { printf 'missing package artifact\n' >&2; exit 1; }
done

if [[ "$OUTPUT_DIR" == "/" || "$OUTPUT_DIR" == "$ROOT_DIR" ]]; then
  printf 'unsafe macOS package output directory\n' >&2
  exit 2
fi
rm -rf "$OUTPUT_DIR"
install -d -m 0755 \
  "$OUTPUT_DIR/Applications" \
  "$OUTPUT_DIR/Library/PrivilegedHelperTools" \
  "$OUTPUT_DIR/Library/LaunchDaemons" \
  "$OUTPUT_DIR/Library/LaunchAgents" \
  "$OUTPUT_DIR/Library/Application Support/Roammand/licenses"
cp -R "$APP_BUNDLE" "$OUTPUT_DIR/Applications/Roammand.app"
install -m 0755 "$HOST_AGENT" \
  "$OUTPUT_DIR/Library/PrivilegedHelperTools/roammand-host-agent"
install -m 0755 "$BRIDGE" \
  "$OUTPUT_DIR/Library/PrivilegedHelperTools/roammand-privileged-bridge"
install -m 0755 "$SESSION_AGENT" \
  "$OUTPUT_DIR/Library/PrivilegedHelperTools/roammand-session-agent"
install -m 0644 packaging/macos/dev.roammand.PrivilegedBridge.plist \
  "$OUTPUT_DIR/Library/LaunchDaemons/dev.roammand.PrivilegedBridge.plist"
install -m 0644 packaging/macos/dev.roammand.SessionAgent.plist \
  "$OUTPUT_DIR/Library/LaunchAgents/"
install -m 0644 licenses/MPL-2.0.txt licenses/Apache-2.0.txt \
  "$OUTPUT_DIR/Library/Application Support/Roammand/licenses/"
install -m 0755 scripts/uninstall_m8_macos.sh \
  "$OUTPUT_DIR/Library/Application Support/Roammand/uninstall-macos.sh"

./scripts/write_macos_package_manifest.sh "$OUTPUT_DIR" >/dev/null

printf 'staged macOS package directory\n'
