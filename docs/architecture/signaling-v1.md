<!-- SPDX-License-Identifier: Apache-2.0 -->

# Signaling V1

Roammand Signaling V1 is a single-instance, in-memory routing service for device presence, short-lived pairing rendezvous, and opaque session negotiation messages. It is transport infrastructure, not an authorization service. Long-term private keys and binding records remain on user devices, and the service cannot create a Controller grant or approve remote control.

## Connection contract

Clients connect to `GET /v1/connect` with WebSocket subprotocol `roammand-signaling.v1.protobuf`. During the brand migration, servers and current clients also accept the pre-brand `personal-remote-signaling.v1.protobuf` value so mixed-version upgrades keep working. Network deployments use WSS; plain `ws://` is intended only for loopback development. Compression is disabled. Every application message is a binary Protobuf `SignalingClientFrame` or `SignalingServerFrame` from `roammand.v1`.

The maximum encoded outer frame is 263,168 bytes. An opaque pairing or session envelope is limited to 262,144 bytes. Text frames, malformed Protobuf, unsupported protocol versions, absent payloads, invalid fixed-size identifiers, oversized request IDs, invalid enum values, and messages above the limit are rejected.

Registration must be the first valid client frame and must complete within five seconds. A connection registers one 32-byte device ID. The first live connection for that ID wins; a duplicate receives `DEVICE_BUSY`. Registration proves only where to route transient signaling data. It does not authenticate ownership or grant control.

Registered devices send a heartbeat every 15 seconds. Presence expires after 45 seconds without renewal. A disconnect, timeout, service shutdown, or state sweep removes the route and any rendezvous involving that device.

## Pairing rendezvous

A Host creates either a QR rendezvous identified by a 16-byte random ID or a desktop-code rendezvous with an eight-character uppercase Base32 code. Every rendezvous expires exactly 120 seconds after creation. The service stores only a domain-separated SHA-256 lookup value for a desktop code, never its plaintext. Join attempts accept the code without case sensitivity.

One Controller may join a rendezvous. The Host cannot join its own rendezvous, a second Controller is rejected, and only the Host and joined Controller may relay pairing data. The service adds the authenticated connection's device ID as the sender and forwards `opaque_envelope` bytes unchanged. It does not decode the nested pairing protocol.

Only the Host may complete a rendezvous as succeeded or rejected. Expiry and member disconnection produce corresponding closure notifications. Successful signaling completion is not proof of a permanent grant: the Host still makes the local authorization decision specified by Protocol V1, including four-word SAS confirmation for desktop pairing.

Join attempts use fixed-window limits:

- 30 attempts per source IP per 60 seconds;
- 5 attempts per rendezvous ID or normalized pairing code per 60 seconds.

The source IP is the TCP peer address unless that direct peer belongs to a configured `SIGNALING_TRUSTED_PROXY_CIDRS` network, in which case the proxy-overwritten `X-Real-IP` value is used. Forwarded headers from every other peer are ignored. A limited response includes a bounded retry delay. Operators should place only a carefully configured transport proxy in front of the service and must not treat proxy authentication as device authorization.

## Session routing

A registered sender provides a 32-byte recipient device ID and an opaque envelope. If the recipient is online, the service forwards the bytes unchanged and supplies the sender device ID from the registered connection. If the recipient is absent, it returns `DEVICE_OFFLINE`. WebRTC offers, answers, ICE candidates, and signed session authentication remain end-to-end protocol data inside the opaque envelope.

The service does not persist session messages, inspect signatures, terminate WebRTC, relay screen media, or synthesize authorization. Delivery is best-effort through a bounded per-connection queue. The buffered queue retains at most 64 entries. Before copying an encoded frame into that queue, transport atomically reserves its payload size against a 526,336-byte per-connection budget (two maximum-sized frames), a 4 MiB source-IP budget, and a 64 MiB process-wide budget. Reservations include the frame currently being written and are released after write success, write failure, queue drain, or connection close.

If the entry limit or any byte budget is full, the new relayed message is dropped and its sender receives `DEVICE_OFFLINE`; the recipient route is not removed by another sender. A recipient whose current socket write exceeds the bounded write deadline is disconnected. The byte budgets are fixed safety invariants rather than deployment knobs, so raising connection-count limits cannot silently remove the process-wide outbound memory bound.

## Public errors

Signaling V1 uses `UnifiedError` with stable codes and no stack traces or internal exception text:

| Code | Meaning |
| --- | --- |
| `PAIRING_CODE_EXPIRED` | Rendezvous is absent or expired |
| `PAIRING_RATE_LIMITED` | A join limit was exceeded; retry delay is supplied |
| `PAIRING_REJECTED` | Pairing state or membership rejected the action |
| `DEVICE_OFFLINE` | A routing target is not present |
| `DEVICE_BUSY` | The device ID already has a live route |
| `INVALID_REQUEST` | Frame or payload validation failed |
| `PROTOCOL_UNSUPPORTED` | The protocol major version is unsupported |
| `MESSAGE_TOO_LARGE` | The encoded application frame exceeds its limit |
| `SERVER_UNAVAILABLE` | The service cannot safely complete the operation |

Unknown internal failures map to `SERVER_UNAVAILABLE`. Logs and simulator output do not contain device IDs, rendezvous IDs, pairing codes, public keys, or opaque payloads.

## Runtime and cleanup

`GET /healthz` returns `ok` when the process is serving. Runtime configuration
is described in [Building from source](../BUILDING.md). A TLS certificate and
key must be configured together. When a reverse proxy overwrites `X-Real-IP`,
`SIGNALING_TRUSTED_PROXY_CIDRS` must contain only that direct proxy network;
forwarding headers from untrusted peers are ignored. `SIGINT` and `SIGTERM`
stop new HTTP work, close active WebSocket connections, remove presence and
rendezvous state, and finish within the configured shutdown deadline.

The process accepts at most 1,024 concurrent WebSocket connections, 64 from one
source IP, and four active rendezvous per Host by default. Operators can set
bounded values with `SIGNALING_MAX_CONNECTIONS` (1–65,536),
`SIGNALING_MAX_CONNECTIONS_PER_IP` (1–65,536), and
`SIGNALING_MAX_RENDEZVOUS_PER_HOST` (1–64). A connection above the global limit
receives HTTP 503, and one above the per-IP limit receives HTTP 429, before
WebSocket upgrade. A Host above its rendezvous limit receives
`PAIRING_REJECTED`.

All presence, rate-limit, rendezvous, and connection state is local memory and is cleared on restart. Signaling does not provide multi-instance coordination, durable queues, TURN, WebRTC media, device key storage, pairing presentation, screen capture, or input control.
