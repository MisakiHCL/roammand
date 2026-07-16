#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

compose_file="infra/compose/compose.yaml"
env_file="infra/compose/.env.example"
dockerfile="services/signaling/Dockerfile"
entrypoint="infra/compose/coturn-entrypoint.sh"

fail() {
  echo "M7 self-hosting check failed: $1" >&2
  exit 1
}

for required in "$compose_file" "$env_file" "$dockerfile" "$entrypoint"; do
  [[ -f "$required" ]] || fail "$required is missing"
done
[[ -x "$entrypoint" ]] || fail "$entrypoint is not executable"
sh -n "$entrypoint" || fail "$entrypoint has invalid shell syntax"
if rg -n "'no-cli'|'no-loopback-peers'|'no-tlsv1(_1)?'" "$entrypoint"; then
  fail "$entrypoint uses obsolete coturn options"
fi

if rg -n '(^|[[:space:]])image:[[:space:]]*[^#[:space:]]*:latest([[:space:]]|$)|^FROM[[:space:]]+[^[:space:]]*:latest' "$compose_file" "$dockerfile"; then
  fail "mutable latest image tag is forbidden"
fi

rg -q '^FROM golang:1\.26\.5-alpine3\.24 AS build$' "$dockerfile" || fail "Go builder is not pinned"
rg -q '^FROM alpine:3\.24\.1$' "$dockerfile" || fail "signaling runtime is not pinned"
rg -q '^USER 65532:65532$' "$dockerfile" || fail "signaling image is not non-root"
rg -q 'image: coturn/coturn:4\.14\.0-r0' "$compose_file" || fail "coturn immutable revision is not pinned"
rg -q 'user: "65534:65532"' "$compose_file" || fail "coturn does not use the read-only secret group"

[[ "$(rg -c 'restart: unless-stopped' "$compose_file")" -eq 2 ]] || fail "both services need restart policy"
[[ "$(rg -c 'read_only: true' "$compose_file")" -ge 2 ]] || fail "both services need read-only roots"
[[ "$(rg -c '^[[:space:]]+- ALL$' "$compose_file")" -eq 2 ]] || fail "both services must drop all capabilities"
[[ "$(rg -c 'no-new-privileges:true' "$compose_file")" -eq 2 ]] || fail "both services need no-new-privileges"
[[ "$(rg -c 'max-size: "10m"' "$compose_file")" -eq 2 ]] || fail "both services need bounded logs"
[[ "$(rg -c '^    healthcheck:' "$compose_file")" -eq 2 ]] || fail "both services need health checks"

for required in \
  '"3478:3478/tcp"' \
  '"3478:3478/udp"' \
  '"5349:5349/tcp"' \
  '"5349:5349/udp"' \
  '"49160-49200:49160-49200/udp"' \
  'TLS_CERT_FILE' \
  'TLS_KEY_FILE' \
  'TURN_USERNAME_FILE' \
  'TURN_PASSWORD_FILE'; do
  rg -q "$required" "$compose_file" "$env_file" || fail "missing contract: $required"
done

if rg -n 'TURN_(USERNAME|PASSWORD):|SIGNALING_TLS_(CERT|KEY):|password[[:space:]]*[:=][[:space:]]*[^$/{]' "$compose_file" "$env_file"; then
  fail "inline credentials or key material are forbidden"
fi

rg -q 'name: Validate self-hosted Compose' .github/workflows/ci.yml || fail "CI self-hosting job is missing"
rg -q 'make test-m7-config' .github/workflows/ci.yml || fail "CI does not run the self-hosting gate"
rg -q 'openssl rand -hex' .github/workflows/ci.yml || fail "CI does not create ephemeral fixture secrets"

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  docker compose --env-file "$env_file" -f "$compose_file" config >/dev/null
  docker compose --env-file "$env_file" -f "$compose_file" build signaling
  echo "M7 self-hosting checks passed (Compose config and signaling build validated)"
else
  echo "M7 self-hosting checks passed"
  echo "SKIP: Docker Compose is unavailable; runtime config/build validation was not run"
fi
