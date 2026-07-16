<!-- SPDX-License-Identifier: Apache-2.0 -->

# Mobile Controller verification

Mobile verification covers protected identity, camera pairing, authenticated video, gestures, keyboard input, responsive layout, and foreground lifecycle.

## Automated contract

| Area | Evidence | Gate |
| --- | --- | --- |
| Gesture and viewport mapping | Tap, double-tap, drag, right-click, scroll, zoom, rotation | `make test-m6-lifecycle` |
| Keyboard and lifecycle | Text, modifiers, special keys, background release, cleanup | `make test-m6-lifecycle` |
| Identity and camera policy | Protected storage, backup policy, camera-only entry | `make test-m6-config` |
| Product UI | Localization, narrow layouts, safe areas, keyboard insets | `make app-check` |
| Platform build | iOS Simulator and Android Debug | `make app-build-ios-simulator` and `make app-build-android` |

## Physical device coverage

| Controller | Windows Host | macOS Host |
| --- | --- | --- |
| iPhone | Pairing · video/input · keyboard/lifecycle | Pairing · video/input · keyboard/lifecycle |
| iPad | Pairing · video/input · keyboard/lifecycle | Pairing · video/input · keyboard/lifecycle |
| Android phone | Pairing · video/input · keyboard/lifecycle | Pairing · video/input · keyboard/lifecycle |
| Android tablet | Pairing · video/input · keyboard/lifecycle | Pairing · video/input · keyboard/lifecycle |

For each cell, verify portrait and landscape, safe areas, keyboard resize, local zoom, background release, explicit reconnect, Host-local Stop, and grant revocation. Exercise same-LAN direct ICE, different-network direct ICE, and forced TURN relay separately.
