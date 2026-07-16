#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

set -eu
umask 077

fail() {
  printf '%s\n' "coturn configuration is invalid: $1" >&2
  exit 1
}

read_secret() {
  secret_path="$1"
  secret_name="$2"
  [ -r "$secret_path" ] || fail "$secret_name secret is unavailable"
  secret_value="$(sed -e 's/\r$//' "$secret_path")"
  [ -n "$secret_value" ] || fail "$secret_name secret is empty"
  [ "${#secret_value}" -le 128 ] || fail "$secret_name secret is too long"
  case "$secret_value" in
    *[!A-Za-z0-9_.-]*) fail "$secret_name secret contains unsupported characters" ;;
  esac
  printf '%s' "$secret_value"
}

realm="${TURN_REALM:-}"
external_ip="${TURN_EXTERNAL_IP:-}"
[ -n "$realm" ] || fail "TURN_REALM is missing"
[ -n "$external_ip" ] || fail "TURN_EXTERNAL_IP is missing"
[ "${#realm}" -le 253 ] || fail "TURN_REALM is too long"
case "$realm" in
  *[!A-Za-z0-9.-]*) fail "TURN_REALM contains unsupported characters" ;;
esac
case "$external_ip" in
  *[!A-Fa-f0-9:.]*) fail "TURN_EXTERNAL_IP is not an IP address" ;;
esac

username="$(read_secret /run/secrets/turn_username username)"
password="$(read_secret /run/secrets/turn_password password)"
config=/run/roammand/turnserver.conf

{
  printf '%s\n' \
    'listening-port=3478' \
    'tls-listening-port=5349' \
    'min-port=49160' \
    'max-port=49200' \
    'fingerprint' \
    'lt-cred-mech' \
    'stale-nonce=600' \
    'user-quota=12' \
    'total-quota=120' \
    'no-multicast-peers' \
    'no-stdout-log' \
    'log-file=/dev/null' \
    'simple-log' \
    'pidfile=/run/roammand/turnserver.pid' \
    'cert=/run/secrets/tls_cert' \
    'pkey=/run/secrets/tls_key'
  printf 'realm=%s\n' "$realm"
  printf 'server-name=%s\n' "$realm"
  printf 'external-ip=%s\n' "$external_ip"
  printf 'user=%s:%s\n' "$username" "$password"
} > "$config"

exec turnserver -c "$config"
