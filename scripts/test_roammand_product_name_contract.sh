#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if git ls-files | rg -i '(personal[-_]?remote|personalremote)'; then
  printf 'legacy engineering name remains in a tracked path\n' >&2
  exit 1
fi

readonly CONFIG_PATHS=(
  .github
  Makefile
  Cargo.toml
  apps/client_flutter/android
  apps/client_flutter/apple
  apps/client_flutter/ios
  apps/client_flutter/macos
  apps/client_flutter/pubspec.yaml
  apps/client_flutter/windows
  crates/host-agent/Cargo.toml
  crates/host-platform/Cargo.toml
  crates/host-webrtc/Cargo.toml
  crates/ipc/Cargo.toml
  crates/privileged-bridge/Cargo.toml
  gen/dart/pubspec.yaml
  gen/go/go.mod
  gen/rust/Cargo.toml
  infra
  packaging
  services/signaling/go.mod
)

if rg -n -i '(personal[-_]remote|personalremote|\bPRD_)' "${CONFIG_PATHS[@]}"; then
  printf 'legacy engineering name remains in public package or platform configuration\n' >&2
  exit 1
fi

readonly PRODUCT_DOCS=(
  README.md README.zh-CN.md CONTRIBUTING.md brand docs \
  apps/client_flutter/README.md packaging/macos/README.md packaging/windows/README.md
)
legacy_doc_matches="$(rg -n -i '(Personal Remote Desktop|personal[-_]remote|personalremote|\bPRD_)' \
  "${PRODUCT_DOCS[@]}" || true)"
legacy_doc_matches="$(printf '%s\n' "$legacy_doc_matches" | \
  rg -v 'desktop-identity-ipc-v1\.md:.*personal-remote-device-id-v1|signaling-v1\.md:.*personal-remote-signaling\.v1\.protobuf' || true)"
if [[ -n "$legacy_doc_matches" ]]; then
  printf '%s\n' "$legacy_doc_matches"
  printf 'unexpected legacy engineering name remains in public product documentation\n' >&2
  exit 1
fi

rg -q --fixed-strings 'const PRODUCT_NAME: &str = "Roammand"' \
  crates/privileged-bridge/src/indicator.rs
rg -q --fixed-strings 'product_name: "Roammand"' \
  crates/privileged-bridge/src/indicator_copy.rs
rg -q --fixed-strings 'Roammand Host Agent' crates/host-agent/src/main.rs
rg -q --fixed-strings 'Roammand Host' crates/host-agent/src/runtime.rs
rg -q --fixed-strings 'Applications/Roammand.app' scripts/package_m8_macos.sh
rg -q --fixed-strings '/Applications/Roammand.app' scripts/install_m8_macos.sh
rg -q --fixed-strings 'Program Files\Roammand' scripts/package_m8_windows.ps1
rg -q --fixed-strings 'ProgramData\Roammand' scripts/package_m8_windows.ps1
rg -q --fixed-strings '<displayName>Roammand Privileged Bridge</displayName>' \
  packaging/windows/RoammandPrivilegedBridge.xml

printf 'Roammand product-name contract ok\n'
