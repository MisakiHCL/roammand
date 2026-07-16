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
- Export privacy-safe diagnostics and run your own signaling and TURN services.

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

Start the signaling service:

```bash
cd services/signaling
go run ./cmd/signaling
```

Start the Host Agent with native WebRTC from the repository root:

```bash
ROAMMAND_SIGNALING_ENDPOINT='ws://127.0.0.1:8080/v1/connect' \
cargo run -p roammand-host-agent --features native-webrtc -- serve
```

Run the macOS app with the same endpoint:

```bash
make app-run-macos \
  FLUTTER_ARGS='--dart-define=ROAMMAND_SIGNALING_ENDPOINT=ws://127.0.0.1:8080/v1/connect'
```

Release builds and normal network use require WSS with a certificate trusted by every device. Source Debug builds can explicitly opt into plaintext `ws://` on a private LAN address for physical-device development; see [Building Roammand from source](docs/BUILDING.md) for the guarded commands, platform prerequisites, TURN configuration, release builds, and Host packaging.

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

Roammand includes a pinned Docker Compose deployment for signaling and coturn. It runs non-root services with file-backed secrets, health checks, explicit relay ports, and bounded logs. See [Docker Compose self-hosting](docs/self-hosting/docker-compose.md).

## Project guides

- [Build, run, package, and verify](docs/BUILDING.md)
- [Brand design guidelines](brand/README.md)
- [Architecture](docs/architecture/README.md)
- [Security](docs/security/README.md)
- [Operations](docs/operations/README.md)
- [Verification](docs/testing/README.md)

## License

Roammand uses path-specific open-source licenses. See [Licensing and third-party notices](LICENSES.md) for the exact terms.
