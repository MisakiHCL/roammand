<!-- SPDX-License-Identifier: Apache-2.0 -->

# Security guide

**English** · [简体中文](README.zh-CN.md)

Roammand keeps long-term identity and authorization on user devices. These documents describe the sensitive assets, privileged runtime boundaries, failure behavior, and the exact data allowed in a user-exported diagnostic report.

- [Privileged Helper threat model](privileged-helper-threat-model.md) — protected assets, trusted roles, local peer authentication, route migration, packaging, and fail-closed behavior.
- [Privacy-safe diagnostics](privacy-safe-diagnostics.md) — typed diagnostic allowlist, excluded data, retention limits, and user-controlled local export.

The end-to-end trust and authorization flow is documented in the [architecture guide](../architecture/README.md). To report a vulnerability, follow [SECURITY.md](../../SECURITY.md).
