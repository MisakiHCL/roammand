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
  "Documents/Codex"
  "../internal/"
  ".superpowers/brainstorm"
)

is_sensitive_tracked_file() {
  local path="$1"
  local name="${path##*/}"
  case "$name" in
    .env|.env.local|Signing.local.xcconfig|*.local.xcconfig|\
      *.certSigningRequest|*.cer|*.key|*.pem|*.p8|*.p12|*.pfx|\
      *.mobileprovision|*.provisionprofile|*.xcarchive|*.ipa|*.pkg|*.dmg|\
      notarytool*.json|notarization*.json)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

cd "$ROOT_DIR"

for required_file in "${REQUIRED_PUBLIC_FILES[@]}"; do
  if [[ ! -f "$required_file" ]]; then
    printf 'missing public file: %s\n' "$required_file" >&2
    exit 1
  fi
done

for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
  if rg --quiet --hidden --fixed-strings \
    --glob '!.git' \
    --glob '!.git/**' \
    --glob '!scripts/check_public_boundary.sh' \
    "$pattern" .; then
    printf 'forbidden internal reference found\n' >&2
    exit 1
  fi
done

if rg --quiet --hidden \
  --glob '!.git' \
  --glob '!.git/**' \
  --glob '!scripts/check_public_boundary.sh' \
  '(/Users/[^/[:space:]]+/|/home/[^/[:space:]]+/|[A-Za-z]:\\Users\\[^\\[:space:]]+\\)' .; then
  printf 'personal filesystem path found in public files\n' >&2
  exit 1
fi

while IFS= read -r -d '' tracked_file; do
  if is_sensitive_tracked_file "$tracked_file"; then
    printf 'sensitive Apple release file is tracked\n' >&2
    exit 1
  fi
done < <(git ls-files -z)

if git grep --quiet -I -E -- \
  '-----BEGIN ([A-Z0-9]+ )?PRIVATE KEY-----'; then
  printf 'private key material found in tracked files\n' >&2
  exit 1
fi

readonly LOCAL_SIGNING_CONFIG="apps/client_flutter/apple/Signing.local.xcconfig"
if [[ -f "$LOCAL_SIGNING_CONFIG" ]]; then
  local_team_id="$(awk '
    $1 == "ROAMMAND_APPLE_TEAM_ID" && $2 == "=" && NF == 3 {
      count += 1
      value = $3
    }
    END { if (count == 1) print value }
  ' "$LOCAL_SIGNING_CONFIG")"
  if [[ -n "$local_team_id" ]] && git grep --quiet -I --fixed-strings \
    "$local_team_id"; then
    printf 'local Apple Team ID found in tracked files\n' >&2
    exit 1
  fi
fi

printf 'public boundary ok\n'
