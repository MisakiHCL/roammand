<!-- SPDX-License-Identifier: Apache-2.0 -->

# Desktop session verification

Desktop verification covers authenticated WebRTC, bounded signaling, capture, input, ICE/TURN, and deterministic cleanup on Windows and macOS.

## Automated contract

| Area | Evidence | Gate |
| --- | --- | --- |
| Session authentication | Signed offer/answer bindings, nonce and replay rejection, grant enforcement | `make test` |
| Media and channels | H.264 preference, VP8 fallback, exact reliable/fast channels | `make test-native-webrtc` |
| Input safety | Ordering, bounds, permission checks, release on failure | `make test` |
| Lifecycle | Connect, close, reconnect, revoke, and ten-cycle cleanup | `make test` |
| Product UI | Flutter analysis, widget behavior, localized states | `make app-check` |
| Platform build | macOS Release and Windows CI build | `make app-build-macos` and CI |
| Endpoint policy | Debug-only private LAN WS opt-in; public WS and Release policy remain closed | `make test` |

## Target-system evidence

| Scenario | Evidence to record |
| --- | --- |
| macOS Host and Controller | Screen Recording, Accessibility, video, pointer, keyboard, Stop, cleanup |
| Windows Host and Controller | Capture, input, permissions, Stop, cleanup |
| macOS ↔ Windows | Authenticated cross-platform video and input |
| Same-LAN direct ICE | Direct route with stable video and input |
| Debug LAN signaling | Explicit private-address WS opt-in works across physical devices and is recorded as development-only evidence |
| Different-network direct ICE | Successful traversal or clean fail-closed behavior |
| Forced TURN relay | Relay route, short-lived credentials, encrypted media and data |
| Codec negotiation | H.264 selected when available, VP8 fallback otherwise |

Record operating-system versions, network path, route type, device roles, and date. Debug LAN WS is useful for functional development but is not a substitute for the WSS release-acceptance run. Never place real credentials, identities, SDP, ICE, input, or screen content in evidence files.
