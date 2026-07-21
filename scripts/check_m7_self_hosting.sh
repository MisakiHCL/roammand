#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

compose_file="infra/compose/compose.yaml"
env_file="infra/compose/.env.example"
dockerfile="services/signaling/Dockerfile"
dockerignore=".dockerignore"
dockerfile_ignore="services/signaling/Dockerfile.dockerignore"
entrypoint="infra/compose/coturn-entrypoint.sh"
builder_image="golang:1.26.5-alpine3.24@sha256:0178a641fbb4858c5f1b48e34bdaabe0350a330a1b1149aabd498d0699ff5fb2"
runtime_image="alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b"
coturn_image="coturn/coturn:4.14.0-r0@sha256:0c0e8fc0c263b85a134e9e4242b5e46e1f4c077c5029633511191c05b5c2c814"

fail() {
  echo "M7 self-hosting check failed: $1" >&2
  exit 1
}

for required in \
  "$compose_file" \
  "$env_file" \
  "$dockerfile" \
  "$dockerignore" \
  "$dockerfile_ignore" \
  "$entrypoint"; do
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

expected_dockerignore_rules() {
  printf '%s\n' \
    '**' \
    '!gen/' \
    '!gen/go/' \
    '!gen/go/**' \
    '!services/' \
    '!services/signaling/' \
    '!services/signaling/**' \
    '**/.env' \
    '**/.env.*' \
    '**/secrets/' \
    '**/secrets/**' \
    '**/*.pem' \
    '**/*.key' \
    '**/*.p8' \
    '**/*.p12' \
    '**/*.pfx' \
    '**/*.mobileprovision' \
    '**/id_rsa*' \
    '**/id_ed25519*' \
    '**/.git/' \
    '**/.git/**' \
    '**/bin/' \
    '**/bin/**' \
    '**/coverage.out' \
    '**/*.log'
}

for ignore_file in "$dockerignore" "$dockerfile_ignore"; do
  if ! diff -u \
    <(expected_dockerignore_rules) \
    <(awk 'NF > 0 && $1 !~ /^#/ { print }' "$ignore_file"); then
    fail "$ignore_file does not match the approved build context rules"
  fi
done

rg -Fqx "FROM $builder_image AS build" "$dockerfile" || fail "Go builder is not digest-pinned"
rg -Fqx "FROM $runtime_image" "$dockerfile" || fail "signaling runtime is not digest-pinned"
while IFS= read -r image; do
  [[ "$image" == *@sha256:* ]] || fail "Dockerfile base image is not digest-pinned: $image"
done < <(awk '/^FROM[[:space:]]/ { print $2 }' "$dockerfile")
rg -q '^USER 65532:65532$' "$dockerfile" || fail "signaling image is not non-root"
rg -Fq "image: $coturn_image" "$compose_file" || fail "coturn image is not digest-pinned"
rg -q 'user: "65534:65534"' "$compose_file" || fail "coturn is not running as nobody"

[[ "$(rg -c 'restart: unless-stopped' "$compose_file")" -eq 2 ]] || fail "both services need restart policy"
[[ "$(rg -c 'read_only: true' "$compose_file")" -ge 2 ]] || fail "both services need read-only roots"
[[ "$(rg -c '^[[:space:]]+- ALL$' "$compose_file")" -eq 2 ]] || fail "both services must drop all capabilities"
[[ "$(rg -c 'no-new-privileges:true' "$compose_file")" -eq 2 ]] || fail "both services need no-new-privileges"
[[ "$(rg -c 'max-size: "10m"' "$compose_file")" -eq 2 ]] || fail "both services need bounded logs"
[[ "$(rg -c '^    healthcheck:' "$compose_file")" -eq 2 ]] || fail "both services need health checks"

for required in \
  '"3478:3478/udp"' \
  'TLS_CERT_FILE' \
  'TLS_KEY_FILE'; do
  rg -q "$required" "$compose_file" "$env_file" || fail "missing contract: $required"
done

for required in stun-only no-tcp no-tls no-dtls no-software-attribute; do
  rg -q "'$required'" "$entrypoint" || fail "coturn is missing $required"
done

if rg -n '5349|49160|49200|turn_username|turn_password|lt-cred-mech|user=' \
  "$compose_file" "$env_file" "$entrypoint"; then
  fail "STUN-only deployment exposes TURN credentials or relay ports"
fi

if rg -n 'SIGNALING_TLS_(CERT|KEY):|password[[:space:]]*[:=][[:space:]]*[^$/{]' "$compose_file" "$env_file"; then
  fail "inline credentials or key material are forbidden"
fi

rg -q 'name: Validate self-hosted Compose' .github/workflows/ci.yml || fail "CI self-hosting job is missing"
rg -q 'make test-m7-config' .github/workflows/ci.yml || fail "CI does not run the self-hosting gate"
rg -q 'openssl req -x509' .github/workflows/ci.yml || fail "CI does not create ephemeral TLS fixtures"

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  docker compose --env-file "$env_file" -f "$compose_file" config >/dev/null
  docker compose --env-file "$env_file" -f "$compose_file" build signaling
  echo "M7 self-hosting checks passed (Compose config and signaling build validated)"
else
  echo "M7 self-hosting checks passed"
  echo "SKIP: Docker Compose is unavailable; runtime config/build validation was not run"
fi
