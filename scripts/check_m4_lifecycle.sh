#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$ROOT_DIR"

cargo test -p roammand-host-webrtc --test lifecycle
cargo test -p roammand-host-webrtc --test session
cargo test -p roammand-host-agent --test remote_session

(
  cd apps/client_flutter
  flutter test \
    test/peer_session_test.dart \
    test/host_maintenance_test.dart \
    test/remote_desktop_controller_test.dart \
    test/remote_desktop_lifecycle_test.dart
)

system="$(uname -s)"
case "$system" in
  Darwin|MINGW*|MSYS*|CYGWIN*)
    native_root="$(./scripts/fetch_libwebrtc.sh)"
    LK_CUSTOM_WEBRTC="$native_root" \
      cargo test -p roammand-host-webrtc --features native-webrtc
    LK_CUSTOM_WEBRTC="$native_root" \
      cargo test -p roammand-host-agent --features native-webrtc \
        --test remote_session --test process_lifecycle
    ;;
  *)
    printf 'SKIP native lifecycle: unsupported build host %s\n' "$system"
    ;;
esac

printf 'M4 lifecycle checks passed\n'
