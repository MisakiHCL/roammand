<!-- SPDX-License-Identifier: Apache-2.0 -->

# Operations guide

**English** · [简体中文](README.zh-CN.md)

Operational checks complement automated tests with behavior that must be observed on real devices and protected operating-system desktops.

- [Release acceptance](final-product-acceptance.md) — real macOS, Windows, iOS, and Android checks for installation, pairing, control, recovery, permissions, local Stop, Emergency stop, and cleanup.
- [Official signaling and STUN profile](official-infrastructure-plan.md) — public endpoints, metadata and deployment boundaries, readiness checks, and the explicit absence of TURN relay.

Use the package and installation commands in [Building Roammand from source](../BUILDING.md) before running the checklist. Self-hosted signaling and STUN deployment is covered by [Docker Compose self-hosting](../self-hosting/docker-compose.md).
