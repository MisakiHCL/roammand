#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

readonly ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly ANDROID_MANIFEST="$ROOT_DIR/apps/client_flutter/android/app/src/main/AndroidManifest.xml"
readonly IOS_PLIST="$ROOT_DIR/apps/client_flutter/ios/Runner/Info.plist"
readonly MOBILE_PAGE="$ROOT_DIR/apps/client_flutter/lib/mobile/remote/mobile_remote_desktop_page.dart"

rg -q 'android.permission.INTERNET' "$ANDROID_MANIFEST"
rg -q 'android.permission.CAMERA' "$ANDROID_MANIFEST"
rg -q 'android:allowBackup="false"' "$ANDROID_MANIFEST"
rg -q 'android:windowSoftInputMode="adjustResize"' "$ANDROID_MANIFEST"
if rg -q 'android.permission.FOREGROUND_SERVICE' "$ANDROID_MANIFEST"; then
  printf 'mobile Controller must not declare a background foreground service\n' >&2
  exit 1
fi

rg -q '<key>NSCameraUsageDescription</key>' "$IOS_PLIST"
rg -q 'UIInterfaceOrientationLandscapeLeft' "$IOS_PLIST"
rg -q 'UIInterfaceOrientationPortrait' "$IOS_PLIST"
if rg -q '<key>UIBackgroundModes</key>' "$IOS_PLIST"; then
  printf 'mobile Controller must not declare iOS background modes\n' >&2
  exit 1
fi

for lifecycle_case in inactive hidden paused detached resumed; do
  rg -q "case AppLifecycleState\.$lifecycle_case" "$MOBILE_PAGE"
done
rg -q '_releaseInput\(\);' "$MOBILE_PAGE"
rg -q '_closeSession\(pop: false\)' "$MOBILE_PAGE"

(
  cd "$ROOT_DIR/apps/client_flutter"
  flutter test \
    test/mobile_viewport_test.dart \
    test/mobile_gesture_machine_test.dart \
    test/mobile_gesture_surface_test.dart \
    test/mobile_keyboard_controller_test.dart \
    test/mobile_remote_desktop_page_test.dart \
    test/mobile_home_page_test.dart \
    test/mobile_remote_launcher_test.dart
)

printf 'M6 lifecycle checks passed\n'
