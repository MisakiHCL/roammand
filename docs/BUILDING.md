<!-- SPDX-License-Identifier: Apache-2.0 -->

# Building Roammand from source

**English** · [简体中文](BUILDING.zh-CN.md)

This guide covers the supported path for running, verifying, building, and packaging Roammand.

## Product workflow

Run `make help` at the repository root to see the common commands.

| Goal | Command |
| --- | --- |
| Check tools and resolve dependencies | `make bootstrap` |
| Analyze and test the Flutter app | `make app-check` |
| Build the Debug Host and run the macOS app | `make app-run-macos` |
| Run an available iOS target | `make app-run-ios` |
| Build the macOS Release app | `make app-build-macos` |
| Build the iOS Simulator app | `make app-build-ios-simulator` |
| Build the Android Debug APK | `make app-build-android` |
| Build and verify the macOS Host package | `make package-macos` |
| Run the complete product gate | `make test-product` |

`make bootstrap`, `make app-check`, and `make test-product` hide successful tool output and print one final `[PASS]` line. Failures include the last 40 log lines, the retained full-log path, and a command for enabling complete output. Add `VERBOSE=1` when you need to stream every command, for example `make test-product VERBOSE=1`.

Normal app use selects signaling and STUN from **Network services** and can
restore the built-in official profile. Build definitions remain useful as
development and CI defaults; pass them through `FLUTTER_ARGS`:

```bash
make app-run-macos \
  FLUTTER_ARGS='--dart-define=ROAMMAND_SIGNALING_ENDPOINT=wss://signal.example.com:8443/v1/connect --dart-define=ROAMMAND_STUN_URLS=stun:stun.example.com:3478'
```

## Required tools

The repository pins the versions used for generated files and automated checks.

| Tool | Version |
| --- | --- |
| Flutter | 3.44.0 |
| Go | 1.26.5 |
| Rust | 1.97.0 |
| Buf | 1.69.0 |

Also install Git, Make, Protocol Buffers, and ripgrep. Native desktop WebRTC requires `curl`, `unzip`, and the platform C/C++ toolchain.

On macOS, install Xcode command-line tools and CocoaPods. On Windows, install Visual Studio 2022 with **Desktop development with C++**, a supported Windows SDK, CMake, Ninja, and Git for Windows. Confirm the intended targets with:

```bash
flutter doctor -v
make doctor
```

## Resolve the workspace

From the repository root:

```bash
make bootstrap
```

This checks the pinned toolchain and resolves Flutter, Dart, Rust, and Go dependencies. It does not install system packages or developer credentials.

## Run Roammand locally

### Recommended: use the official services

On macOS, run only:

```bash
make app-run-macos
```

This target downloads or reuses verified native WebRTC, incrementally builds
the Debug Host Agent, and passes it to the GUI through
`ROAMMAND_HOST_AGENT_EXECUTABLE`. Official signaling and STUN are built in, so
there is no local service terminal.

When a phone is the Controller, use a second terminal for:

```bash
cd apps/client_flutter
flutter run -d ios --no-pub # or flutter run -d android --no-pub
```

Physical-device source testing therefore drops from four terminals to two.
Installed desktop and mobile Release builds launch from their graphical
interfaces and need no terminal. Re-run `make bootstrap` after dependency files
change; normal run targets intentionally use the locked, cached packages.

### Advanced: start local signaling

For a same-computer loopback run:

```bash
cd services/signaling
go run ./cmd/signaling
```

The default session endpoint is `ws://127.0.0.1:8080/v1/connect`.

For source Debug builds only, a physical Controller on the same trusted LAN can use plaintext WebSocket without installing a development certificate. Start signaling on all interfaces:

```bash
cd services/signaling
SIGNALING_LISTEN_ADDR=0.0.0.0:8080 go run ./cmd/signaling
```

Use the Host computer's private address, such as `ws://192.168.3.168:8080/v1/connect`. This opt-in accepts only literal RFC 1918 IPv4 or IPv6 unique-local addresses. Hostnames and public addresses remain rejected. Start every participating Debug component with the opt-in:

```bash
ROAMMAND_ALLOW_INSECURE_LAN_SIGNALING=true \
ROAMMAND_SIGNALING_ENDPOINT='ws://192.168.3.168:8080/v1/connect' \
cargo run -p roammand-host-agent --features native-webrtc -- serve
```

```bash
make app-run-macos \
  FLUTTER_ARGS='--dart-define=ROAMMAND_SIGNALING_ENDPOINT=ws://192.168.3.168:8080/v1/connect --dart-define=ROAMMAND_ALLOW_INSECURE_LAN_SIGNALING=true'
```

```bash
make app-run-ios \
  FLUTTER_ARGS='--dart-define=ROAMMAND_ALLOW_INSECURE_LAN_SIGNALING=true'
```

For Android, run `flutter run -d android --dart-define=ROAMMAND_ALLOW_INSECURE_LAN_SIGNALING=true` from `apps/client_flutter`. On iOS, approve the Local Network prompt. The Rust environment switch is honored only in builds with debug assertions, and the Flutter switch only when `kDebugMode` is true. Profile, Release, and packaged Hosts ignore the opt-in and continue to reject non-loopback `ws://`. Host bindings created with a plaintext private-LAN endpoint are development-only; pair again through WSS before testing a Profile or Release app.

For normal cross-device use and all release acceptance, use WSS and a certificate trusted by every device:

```bash
cd services/signaling
SIGNALING_LISTEN_ADDR=0.0.0.0:8443 \
SIGNALING_TLS_CERT_FILE='certs/fullchain.pem' \
SIGNALING_TLS_KEY_FILE='certs/private-key.pem' \
go run ./cmd/signaling
```

Use `wss://<server-name>:8443/v1/connect` as the endpoint. A reverse proxy must preserve binary WebSocket frames and the `roammand-signaling.v1.protobuf` subprotocol.

### Advanced: start the Host Agent independently

On the computer being controlled:

```bash
ROAMMAND_SIGNALING_ENDPOINT='wss://signal.example.com:8443/v1/connect' \
cargo run -p roammand-host-agent --features native-webrtc -- serve
```

Windows PowerShell:

```powershell
$env:ROAMMAND_SIGNALING_ENDPOINT = 'wss://signal.example.com:8443/v1/connect'
cargo run -p roammand-host-agent --features native-webrtc -- serve
```

The Host Agent owns the desktop device identity, authorization registry, WebRTC peer, capture, and input path. On macOS, grant Screen Recording and Accessibility when prompted. This independent mode is for low-level development; the standard `make app-run-macos` workflow lets the GUI manage the Agent.

### Advanced: start the app independently

macOS:

```bash
make app-run-macos \
  FLUTTER_ARGS='--dart-define=ROAMMAND_SIGNALING_ENDPOINT=wss://signal.example.com:8443/v1/connect'
```

Windows:

```powershell
cd apps\client_flutter
flutter run -d windows --dart-define=ROAMMAND_SIGNALING_ENDPOINT=wss://signal.example.com:8443/v1/connect
```

The Flutter app and Host Agent must run as the same operating-system user. The app connects to the Agent through authenticated current-user IPC. The GUI starts and stops an Agent it owns; when it connects to a developer-started Agent, it never takes ownership or stops that process on exit.

### Pair a Controller

- Phone or tablet: open **This computer** on the Host, show the phone QR code, run `flutter run -d android` or `flutter run -d ios`, and scan with the camera.
- Another computer: create a desktop pairing code, enter it under **My computers**, compare all four English verification words, and approve beside the Host.

After approval, the saved computer card can start future sessions without pairing again. Deleting the card on a Controller is local-only; revoking on the Host blocks future sessions.

## STUN configuration

The release profile uses direct ICE with STUN and no TURN fallback. Configure
the same public STUN service on the Host and Controller. An independently run
Host Agent reads both endpoints from its environment:

```bash
ROAMMAND_SIGNALING_ENDPOINT='wss://signal.example.com:8443/v1/connect' \
ROAMMAND_STUN_URLS='stun:stun.example.com:3478' \
cargo run -p roammand-host-agent --features native-webrtc -- serve
```

The installed GUI passes its selected **Network services** profile to the Agent
it owns. Flutter development builds can override the default STUN service with
`--dart-define=ROAMMAND_STUN_URLS=stun:stun.example.com:3478`.

Follow [Docker Compose self-hosting](self-hosting/docker-compose.md) to deploy
matching WSS signaling and UDP STUN services. Without TURN, some symmetric NAT,
enterprise, and cellular paths are expected to fail rather than relay traffic.

### Optional low-level TURN test

The peer layer retains TURN environment inputs for isolated developer tests,
but TURN is not exposed by the release profile or the default Compose stack.
For a relay-only test, configure the same short-lived values on both peers:

```bash
ROAMMAND_ICE_TRANSPORT_POLICY=relay \
ROAMMAND_TURN_URLS='turns:turn.example.com:5349' \
ROAMMAND_TURN_USERNAME='<short-lived-username>' \
ROAMMAND_TURN_PASSWORD='<short-lived-password>' \
ROAMMAND_SIGNALING_ENDPOINT='wss://signal.example.com:8443/v1/connect' \
cargo run -p roammand-host-agent --features native-webrtc -- serve
```

```bash
cd apps/client_flutter
flutter run -d ios \
  --dart-define=ROAMMAND_ICE_TRANSPORT_POLICY=relay \
  --dart-define=ROAMMAND_TURN_URLS=turns:turn.example.com:5349 \
  --dart-define=ROAMMAND_TURN_USERNAME='<short-lived-username>' \
  --dart-define=ROAMMAND_TURN_PASSWORD='<short-lived-password>'
```

TURN URL, username, and password are an all-or-nothing group. Do not commit or
log credentials. This advanced path requires a separately operated TURN
service and is not a fallback provided by Roammand's official first-release
profile.

## Build platform apps

```bash
make app-build-macos
make app-build-ios-simulator
make app-build-android
```

Windows Release:

```powershell
cd apps\client_flutter
flutter build windows --release
```

Build output remains under `apps/client_flutter/build/` and is ignored by Git.

## Package the installed Host

Package scripts require a clean worktree for their default Release build. They stage only allowlisted apps, agents, bridge/helpers, service definitions, licenses, and a sorted SHA-256 manifest. Device identities, grants, endpoints, credentials, private keys, and local developer paths are excluded.

### macOS

```bash
make package-macos
sudo ./scripts/install_m8_macos.sh --package dist/m8-macos --dry-run
sudo ./scripts/install_m8_macos.sh --package dist/m8-macos
```

The installer places `Roammand.app` in `/Applications`, installed Host and
privileged binaries in `/Library/PrivilegedHelperTools`, and protected-session
launchd definitions in `/Library/LaunchDaemons` and `/Library/LaunchAgents`.
Opening the GUI starts its installed Host Agent. Closing the window keeps both
running in the tray; explicit **Exit** stops the Agent started by that GUI.
Sign out and in once so the protected-session Agent loads.

For independent development, start `roammand-host-agent serve` before the GUI;
the GUI connects to that existing process and does not own or stop it. Set
`ROAMMAND_HOST_AGENT_AUTOSTART=false` to disable installed-Agent fallback, or
set `ROAMMAND_HOST_AGENT_EXECUTABLE` to test a specific Agent binary.

Preview and remove installed components with:

```bash
sudo ./scripts/uninstall_m8_macos.sh --dry-run
sudo ./scripts/uninstall_m8_macos.sh
```

### Windows

Use an elevated PowerShell:

```powershell
pwsh -NoProfile -File scripts/package_m8_windows.ps1
pwsh -NoProfile -File scripts/check_m8_windows_package.ps1 -Package dist\m8-windows
pwsh -NoProfile -File scripts/install_m8_windows.ps1 -Package dist\m8-windows -WhatIf
pwsh -NoProfile -File scripts/install_m8_windows.ps1 -Package dist\m8-windows
```

Preview and remove installed components with:

```powershell
pwsh -NoProfile -File scripts/uninstall_m8_windows.ps1 -WhatIf
pwsh -NoProfile -File scripts/uninstall_m8_windows.ps1
```

Both uninstallers preserve each user's device identity and Controller grants. Use the [final product acceptance checklist](operations/final-product-acceptance.md) to validate protected graphical sessions on real operating systems.

## Configure local Apple signing

The public Xcode projects do not contain an Apple developer identity. Configure the ignored local override from the repository root:

```bash
./scripts/configure_apple_signing.sh \
  --team-id YOUR_TEAM_ID \
  --bundle-id com.example.roammand
./scripts/configure_apple_signing.sh --check
```

The command validates its inputs, writes `apps/client_flutter/apple/Signing.local.xcconfig` atomically, and sets mode `0600`. Certificates, private keys, provisioning profiles, App Store Connect `*.p8` keys, and local export options must remain outside Git.

Inspect the effective Release settings when needed:

```bash
cd apps/client_flutter
xcodebuild -project ios/Runner.xcodeproj -scheme Runner \
  -configuration Release -sdk iphoneos -showBuildSettings \
  | grep -E 'DEVELOPMENT_TEAM|PRODUCT_BUNDLE_IDENTIFIER'
xcodebuild -project macos/Runner.xcodeproj -scheme Runner \
  -configuration Release -showBuildSettings \
  | grep -E 'DEVELOPMENT_TEAM|PRODUCT_BUNDLE_IDENTIFIER'
```

iOS distribution uses App Store/TestFlight archives. The complete macOS Host uses Developer ID signing, Hardened Runtime, a signed installer, notarization, and stapling for direct distribution. Its privileged non-sandboxed architecture is not a Mac App Store target; a store-distributed macOS app requires a separate sandboxed Controller-only design.

## Verify changes

```bash
make format-check
make test
make test-product
```

Generate and verify versioned protocol outputs with:

```bash
make generate
make generate-check
make test-conformance
```

Protocol, pairing, session, bridge, security, self-hosting, and operations contracts are collected in the [architecture](architecture/README.md), [security](security/README.md), [self-hosting](self-hosting/docker-compose.md), and [operations](operations/README.md) guides.
