<!-- SPDX-License-Identifier: Apache-2.0 -->

<p align="center">
  <img src="brand/roammand-app-icon.svg" width="112" alt="Roammand logo">
</p>

<h1 align="center">Roammand</h1>

<p align="center"><strong>Leave the desk. Keep work moving.</strong></p>
<p align="center">Private, account-free control for your own computers.</p>

**English** · [简体中文](README.zh-CN.md)

Roammand turns your phone, tablet, or another computer into a trusted control surface for the Windows and macOS machines that carry your work. Pair directly with your own devices, reconnect without an account, and stay in control wherever you are.

Continue desktop work from mobile, supervise long-running tasks, and keep your personal computing environment within reach.

## What you can do

- Pair a phone by QR code or another computer with a one-time code and four-word verification.
- Save trusted computers and reconnect without pairing again.
- Control Windows and macOS from iOS, Android, Windows, or macOS.
- Use touch gestures, text, modifiers, and special keys from mobile.
- Recover from temporary interruptions with bounded, authenticated reconnect.
- See who is connected, stop control locally, and revoke any Controller from the Host.
- Export privacy-safe diagnostics and run your own signaling and STUN services.

## How it works

1. Open **This computer** on the Host and create a phone QR invitation or desktop pairing code.
2. Scan or enter the invitation, compare the four verification words, and approve the named Controller beside the Host.
3. The computer appears in **My computers**. Choose **Connect** whenever you want to continue working remotely.

Authorization is one-way: a Controller can access only the Host that approved it. Reversing the direction requires a separate pairing and approval.

## Supported roles

| Platform | Host | Controller |
| --- | --- | --- |
| macOS | Yes | Yes |
| Windows | Yes | Yes |
| iOS / iPadOS | — | Yes |
| Android | — | Yes |

## Start from source

Install the pinned toolchains and workspace dependencies:

```bash
make bootstrap
make app-check
```

These workflows hide successful tool output and print one final `[PASS]` line. If a workflow fails, it prints a short error tail. Add `VERBOSE=1` to stream the complete output, for example `make app-check VERBOSE=1`.

With the built-in official signaling and STUN services, start only the desktop
app:

```bash
make app-run-macos
```

That command prepares native WebRTC, incrementally builds the Debug Host Agent,
and lets the desktop GUI start and stop it. To test a phone Controller, use a
second terminal for the mobile app:

```bash
cd apps/client_flutter
flutter devices
flutter run -d YOUR_IOS_DEVICE_ID --no-pub
# Or: flutter run -d YOUR_ANDROID_DEVICE_ID --no-pub
```

`-d` takes the exact device ID listed by `flutter devices`; `ios` and
`android` are platform names, not reliable physical-device selectors.

Physical-device source testing therefore drops from four terminals—signaling,
Host Agent, desktop app, and mobile app—to two terminals for the desktop and
mobile apps. Installed Release builds need no terminal. See [Building Roammand
from source](docs/BUILDING.md) for self-hosting, guarded plaintext `ws://`
debugging, platform prerequisites, Release builds, and Host packaging.

Desktop and mobile apps expose the same Network services settings for signaling
and STUN. The official profile can always be restored. This release attempts
direct ICE connections and has no TURN relay fallback, so restrictive networks
may still fail to connect.

## Security by design

- No cloud account is required.
- Long-term private keys and device grants remain on the devices.
- Pairing creates a permanent grant only after Host-local approval.
- Signaling relays bounded opaque messages and cannot authorize control.
- The Host keeps control visible and exposes local Stop and Emergency stop.
- Input is released and blocked while a session is recovering or changing graphical sessions.
- Diagnostics exclude device identities, network addresses, SDP/ICE, input, screen data, credentials, and raw payloads.

Read the [pairing model](docs/architecture/account-free-pairing-v1.md), [privileged session bridge](docs/architecture/privileged-session-bridge-v1.md), [threat model](docs/security/privileged-helper-threat-model.md), and [diagnostics policy](docs/security/privacy-safe-diagnostics.md) for the exact boundaries.

## Self-hosting

Roammand includes a pinned Docker Compose deployment for signaling and
STUN-only coturn. It runs non-root services with file-backed TLS secrets,
health checks, a single UDP STUN port, and bounded logs. See
[Docker Compose self-hosting](docs/self-hosting/docker-compose.md).

## Project guides

- [Build, run, package, and verify](docs/BUILDING.md)
- [Brand design guidelines](brand/README.md)
- [Architecture](docs/architecture/README.md)
- [Security](docs/security/README.md)
- [Operations](docs/operations/README.md)
- [Verification](docs/testing/README.md)

## License

Roammand uses path-specific open-source licenses. See [Licensing and third-party notices](LICENSES.md) for the exact terms.
