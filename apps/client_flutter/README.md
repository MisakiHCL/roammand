<!-- SPDX-License-Identifier: MPL-2.0 -->

# Roammand Flutter app

Roammand is the shared Windows, macOS, iOS, and Android product interface. It provides desktop Host status and Controller flows plus mobile onboarding, camera-only pairing, remote control, authenticated recovery, and privacy-safe Diagnostics preview/export. Desktop and mobile Controllers share the same authenticated WebRTC session protocol and the Night Aurora design system.

For the complete run path, choose [English](../../README.md) or [简体中文](../../README.zh-CN.md). Security contracts are documented in [Account-free pairing V1](../../docs/architecture/account-free-pairing-v1.md), [Desktop WebRTC V1](../../docs/architecture/desktop-webrtc-v1.md), [Mobile Controller V1](../../docs/architecture/mobile-controller-v1.md), [Authenticated reconnect V1](../../docs/architecture/reconnect-v1.md), [Privacy-safe diagnostics](../../docs/security/privacy-safe-diagnostics.md), and [Desktop identity and local IPC V1](../../docs/architecture/desktop-identity-ipc-v1.md).

## Product workflow

Run the supported workflow from the repository root:

```bash
make bootstrap
make app-check
make app-run-macos
make app-build-ios-simulator
make app-build-macos
make package-macos
make test-product
```

Use `make help` for all product targets. Signaling and STUN are configured at
runtime from **Network services**. Build definitions remain available as
development and automation defaults.

## App-only verification

```bash
flutter pub get
flutter gen-l10n
dart format lib test tool
flutter analyze
flutter test
```

User-visible copy belongs in `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`; generated localization files are committed.

## Desktop Host and Controller

The Rust Agent owns the desktop private key and Host grants. An installed GUI
starts and stops its own Agent; an independently started development Agent
remains separate and is never stopped by the GUI.

Start a Host Agent from the repository root:

```bash
ROAMMAND_SIGNALING_ENDPOINT='wss://signal.example.com:8443/v1/connect' \
cargo run -p roammand-host-agent --features native-webrtc -- serve
```

After `Host Agent ready`, start Flutter and select the matching custom service
from **Network services**:

```bash
cd apps/client_flutter
flutter run -d macos
```

Use `flutter run -d windows` on Windows. **This computer** creates a two-minute QR or code invitation, displays the pending Controller, and is the only place that can approve or revoke its one-way grant.

A desktop acting only as Controller runs its local Agent without `ROAMMAND_SIGNALING_ENDPOINT`:

```bash
cargo run -p roammand-host-agent -- serve
```

Start its Flutter app, select the same service profile, enter the Host code,
compare the fixed four-word SAS, and wait for Host approval. **My computers**
then shows a persistent Host card and can launch remote control.
`Ctrl+Alt+Shift+Esc` is a local-only close shortcut.

For physical-device development on a trusted LAN, source Debug builds may explicitly accept a private-address `ws://` endpoint. Pass `ROAMMAND_ALLOW_INSECURE_LAN_SIGNALING=true` to the Agent environment and as a Dart definition to every participating app. This opt-in is ignored by Profile and Release builds; the complete commands and address restrictions are in [Building Roammand from source](../../docs/BUILDING.md).

## Mobile pairing and control

Run a physical device:

```bash
flutter run -d android
flutter run -d ios
```

Use the command for the connected platform. The first launch confirms a best-effort system device name and creates an Ed25519 identity in protected local storage. Pairing accepts QR data only from the camera. After Host-local approval, choose **Connect** on the saved Host card to render video and use tap, double-tap, long-press drag, two-finger right-click, scroll, pinch zoom, text, modifiers, and special keys.

The signaling endpoint is read from the validated per-Host binding. The STUN
service and the default signaling address for future manual pairing flows are
edited in **Network services**. Re-pairing an authenticated Host updates its
saved signaling address after that Host changes service. This release has no
TURN fallback, so restrictive networks may not establish a direct connection.

Backgrounding releases remote input and closes the session. Resuming never reconnects automatically.

## Reconnect and Diagnostics

A foreground session that loses signaling or its peer releases and blocks input, then shows reconnect progress over the complete 30-second recovery window. Each attempt uses fresh signed authentication. Automatic recovery stops after the fifth attempt; the failure surface offers an explicit retry that creates fresh session resources.

Desktop and mobile remote pages expose **Diagnostics**. The dialog lists the allowlisted aggregate session/reconnect/WebRTC data and the identifiers, network details, payloads, input, and screen data that are excluded. Saving is user initiated and local; the app never uploads a report automatically. See [Authenticated reconnect V1](../../docs/architecture/reconnect-v1.md) and [Privacy-safe diagnostics](../../docs/security/privacy-safe-diagnostics.md).

## Dependencies and cleanup

Runtime Network services settings provide signaling and STUN endpoints. The
lower-level TURN environment remains available for isolated developer tests but
is not part of the release profile. Scanner controllers, timers, signaling
subscriptions, and pairing/session resources are released on pause,
cancellation, terminal state, or disposal.
