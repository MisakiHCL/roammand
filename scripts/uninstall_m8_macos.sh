#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && { DRY_RUN=true; shift; }
(($# == 0)) || { printf 'unknown macOS uninstall option\n' >&2; exit 2; }

if $DRY_RUN; then
  printf 'would stop services and remove installed program files; preserve local identity and grants; no changes made\n'
  exit 0
fi
[[ "$EUID" -eq 0 ]] || { printf 'administrator privileges are required; run with sudo or use --dry-run\n' >&2; exit 1; }

readonly SERVICE_DATA_DIR="/Library/Application Support/Roammand"
readonly PACKAGE_RECEIPT_ID="dev.roammand.pkg"
readonly OWNER_ID_FILE="$SERVICE_DATA_DIR/bridge-owner-id"
readonly INSTALLED_APP_PATTERN='^/Applications/Roammand[.]app/Contents/MacOS/roammand([[:space:]]|$)'
readonly INSTALLED_HOST_AGENT_PATTERN='^/Library/PrivilegedHelperTools/roammand-host-agent([[:space:]]|$)'
readonly INSTALLED_BRIDGE_PATTERN='^/Library/PrivilegedHelperTools/roammand-privileged-bridge([[:space:]]|$)'
readonly INSTALLED_SESSION_AGENT_PATTERN='^/Library/PrivilegedHelperTools/roammand-session-agent([[:space:]]|$)'
OWNER_ID=""
if [[ -f "$OWNER_ID_FILE" ]]; then
  OWNER_ID="$(tr -d '[:space:]' <"$OWNER_ID_FILE")"
  [[ "$OWNER_ID" =~ ^[0-9]+$ && "$OWNER_ID" != "0" ]] || OWNER_ID=""
fi

if [[ -n "$OWNER_ID" ]]; then
  launchctl bootout "gui/$OWNER_ID/dev.roammand.SessionAgent" 2>/dev/null || true
  launchctl bootout "gui/$OWNER_ID/dev.roammand.HostAgent" 2>/dev/null || true
fi
launchctl bootout system/dev.roammand.PrivilegedBridge 2>/dev/null || true
/usr/bin/pkill -TERM -f "$INSTALLED_HOST_AGENT_PATTERN" 2>/dev/null || true
/usr/bin/pkill -TERM -f "$INSTALLED_BRIDGE_PATTERN" 2>/dev/null || true
/usr/bin/pkill -TERM -f "$INSTALLED_SESSION_AGENT_PATTERN" 2>/dev/null || true
/usr/bin/pkill -TERM -f "$INSTALLED_APP_PATTERN" 2>/dev/null || true
pkgutil --forget "$PACKAGE_RECEIPT_ID" >/dev/null 2>&1 || true
rm -f "/Library/LaunchDaemons/dev.roammand.PrivilegedBridge.plist" \
  "/Library/LaunchAgents/dev.roammand.HostAgent.plist" \
  "/Library/LaunchAgents/dev.roammand.SessionAgent.plist" \
  "/Library/PrivilegedHelperTools/roammand-host-agent" \
  "/Library/PrivilegedHelperTools/roammand-privileged-bridge" \
  "/Library/PrivilegedHelperTools/roammand-session-agent" \
  "$SERVICE_DATA_DIR/install-manifest.sha256" \
  "$SERVICE_DATA_DIR/bridge-install-secret.bin" \
  "$SERVICE_DATA_DIR/bridge-owner-id" \
  "/var/run/roammand/bridge.sock" \
  "/var/log/roammand-privileged-bridge.log"
rm -rf "/var/run/roammand" "$SERVICE_DATA_DIR" "/Applications/Roammand.app"
printf 'macOS program files removed; local identity and grants were preserved\n'
