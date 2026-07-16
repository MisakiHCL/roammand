<!-- SPDX-License-Identifier: Apache-2.0 -->

# Reliability and privacy verification

Reliability verification proves that interruption never weakens authentication, leaves input held, or expands diagnostic data.

## Automated contract

| Area | Required evidence | Gate |
| --- | --- | --- |
| Authenticated reconnect | 1/2/4/8/15-second schedule, fresh nonce/signature, bounded retries | `make test-m7-reconnect` |
| Input safety | Immediate release and block during recovery; cleanup through repeated cycles | `make test-m7-reconnect` |
| Diagnostics | Typed allowlist, 128-event ring, 256 KiB bound, local preview/export | `make test-m7-privacy` |
| Safe logs | No identities, addresses, SDP/ICE, payloads, input, or screen data | `make test-m7-privacy` |
| Untrusted input | Fuzz/property checks and deterministic malformed-frame rejection | `make test-m7-fuzz` |
| Self-hosting | Pinned services, secrets, health checks, ports, and bounded logs | `make test-m7-config` |

## Target-system evidence

- Recover across real network interruption while input remains frozen.
- Recover through direct ICE and forced TURN with fresh authentication.
- Preview and save diagnostics without automatic upload or clipboard use.
- Run signaling and coturn with real DNS, certificates, NAT, and health checks.
- Observe resources for 30 minutes without monotonic growth.
- Run the long-duration harness with retained, bounded metrics.

Evidence must use synthetic identifiers and redact network topology, credentials, session transcripts, and user content.
