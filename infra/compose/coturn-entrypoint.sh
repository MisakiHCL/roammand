#!/bin/sh
# SPDX-License-Identifier: Apache-2.0

set -eu
umask 077

config=/run/roammand/turnserver.conf

{
  printf '%s\n' \
    'listening-port=3478' \
    'stun-only' \
    'fingerprint' \
    'no-tcp' \
    'no-tls' \
    'no-dtls' \
    'no-software-attribute' \
    'no-stdout-log' \
    'log-file=/dev/null' \
    'simple-log' \
    'pidfile=/run/roammand/turnserver.pid'
} > "$config"

exec turnserver -c "$config"
