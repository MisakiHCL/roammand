<!-- SPDX-License-Identifier: Apache-2.0 -->

# Verification guide

**English** · [简体中文](README.zh-CN.md)

Roammand separates deterministic gates from evidence that requires real devices, networks, permissions, or protected operating-system desktops.

- [Desktop session](desktop-session.md) — authenticated WebRTC, capture, input, ICE/TURN, and lifecycle.
- [Pairing](pairing.md) — live QR with Host approval, one-time desktop codes with four-word verification, persistence, and revocation.
- [Mobile Controller](mobile-controller.md) — physical iOS and Android coverage across Windows and macOS Hosts.
- [Reliability and privacy](reliability-and-privacy.md) — reconnect, diagnostics, untrusted input, self-hosting, and resource observation.
- [Platform acceptance](platform-acceptance.md) — installed Host, protected desktops, packaging, and cross-platform release evidence.

Run the complete deterministic gate with `make test-product`. Use the [manual acceptance checklist](../operations/final-product-acceptance.md) for signed-off target-system evidence.
