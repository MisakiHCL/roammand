#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REQUIRED_PUBLIC_FILES=(
  "README.md"
  "README.zh-CN.md"
  "CONTRIBUTING.md"
  "SECURITY.md"
  "LICENSES.md"
  "docs/BUILDING.md"
  "docs/architecture/desktop-identity-ipc-v1.md"
  "docs/architecture/account-free-pairing-v1.md"
  "docs/architecture/reconnect-v1.md"
  "docs/architecture/privileged-session-bridge-v1.md"
  "docs/security/privacy-safe-diagnostics.md"
  "docs/security/privileged-helper-threat-model.md"
  "docs/operations/final-product-acceptance.md"
  "docs/self-hosting/docker-compose.md"
  "docs/self-hosting/docker-compose.zh-CN.md"
  "docs/testing/pairing.md"
  "docs/testing/reliability-and-privacy.md"
  "docs/testing/platform-acceptance.md"
  "licenses/MPL-2.0.txt"
  "licenses/AGPL-3.0-only.txt"
  "licenses/Apache-2.0.txt"
)
readonly FORBIDDEN_PATTERNS=(
  "/Users/uhu/"
  "Documents/Codex"
  "../internal/"
  ".superpowers/brainstorm"
)

cd "$ROOT_DIR"

for required_file in "${REQUIRED_PUBLIC_FILES[@]}"; do
  if [[ ! -f "$required_file" ]]; then
    printf 'missing public file: %s\n' "$required_file" >&2
    exit 1
  fi
done

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  if rg -n --hidden --fixed-strings \
    --glob '!.git' \
    --glob '!.git/**' \
    --glob '!scripts/check_public_boundary.sh' \
    "$pattern" .; then
    printf 'forbidden internal reference: %s\n' "$pattern" >&2
    exit 1
  fi
done

printf 'public boundary ok\n'
