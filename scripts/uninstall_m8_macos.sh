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

launchctl bootout system/dev.roammand.PrivilegedBridge 2>/dev/null || true
rm -f "/Library/LaunchDaemons/dev.roammand.PrivilegedBridge.plist" \
  "/Library/LaunchAgents/dev.roammand.HostAgent.plist" \
  "/Library/LaunchAgents/dev.roammand.SessionAgent.plist" \
  "/Library/PrivilegedHelperTools/roammand-host-agent" \
  "/Library/PrivilegedHelperTools/roammand-privileged-bridge" \
  "/Library/PrivilegedHelperTools/roammand-session-agent" \
  "/Library/Application Support/Roammand/install-manifest.sha256" \
  "/Library/Application Support/Roammand/bridge-install-secret.bin" \
  "/Library/Application Support/Roammand/bridge-owner-id" \
  "/var/run/roammand/bridge.sock"
rm -rf "/var/run/roammand"
rm -rf "/Library/Application Support/Roammand" \
  "/Library/Application Support/Roammand" \
  "/Applications/Roammand.app" \
  "/Applications/Roammand.app"
printf 'macOS program files removed; local identity and grants were preserved\n'
