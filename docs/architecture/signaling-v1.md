<!-- SPDX-License-Identifier: Apache-2.0 -->

# Signaling V1

Roammand Signaling V1 is a single-instance, in-memory routing service for device presence, short-lived pairing rendezvous, and opaque session negotiation messages. It is transport infrastructure, not an authorization service. Long-term private keys and binding records remain on user devices, and the service cannot create a Controller grant or approve remote control.

Here, “opaque” means the current server forwards nested envelope bytes without
decoding their protocol format, logging their bodies, or persisting them. It is
not an end-to-end confidentiality claim: WSS terminates at the service, so its
operator or a modified process can access and parse those bytes. Peer signatures
and transcript bindings prevent the service from minting authorization or
silently substituting a valid negotiation; they do not conceal public identity
proofs or every WebRTC negotiation field from the signaling operator.

## Connection contract

Clients connect to `GET /v1/connect` with WebSocket subprotocol `roammand-signaling.v1.protobuf`. During the brand migration, servers and current clients also accept the pre-brand `personal-remote-signaling.v1.protobuf` value so mixed-version upgrades keep working. Network deployments use WSS; plain `ws://` is intended only for loopback development. Compression is disabled. Every application message is a binary Protobuf `SignalingClientFrame` or `SignalingServerFrame` from `roammand.v1`.

The maximum encoded outer frame is 263,168 bytes. An opaque pairing or session envelope is limited to 262,144 bytes. Text frames, malformed Protobuf, unsupported protocol versions, absent payloads, invalid fixed-size identifiers, oversized request IDs, invalid enum values, and messages above the limit are rejected.

Accepted application messages and incoming WebSocket ping/pong frames also
consume fixed one-second inbound windows. The limits are 256 frames / 32 MiB
per connection, 4,096 frames / 128 MiB per source IP, and 32,768 frames /
512 MiB across the process. Exceeding any frame or byte limit closes the
WebSocket with status 1013 (`Try Again Later`), rather than allocating an
unbounded queue or returning a protocol-level error. The traffic limiter keeps
at most 65,536 source-IP windows and fails closed with the same status for a new
source when that map is full. These limits are fixed safety invariants.

An incomplete binary message cannot bypass those completed-frame windows and
pin unbounded memory. After its WebSocket header arrives, the reader reserves
263,169 bytes (one maximum outer frame plus the oversize probe) against fixed
per-connection, source-IP, and process-wide in-flight budgets of 263,169 bytes,
8 MiB, and 64 MiB. The body must complete within 10 seconds. Completion,
timeout, rejection, and connection close release every reservation; budget
exhaustion fails the connection closed.

Registration must be the first valid client frame and must complete within five seconds. A connection registers one 32-byte device ID. The first live connection for that ID wins; a duplicate receives `DEVICE_BUSY`. Registration proves only where to route transient signaling data. It does not authenticate ownership or grant control.

Registered clients must renew presence before its 45-second expiry. The current
Host and pairing links use a 15-second heartbeat interval; the Controller
session link uses 20 seconds. Every link permits only one outstanding heartbeat
and requires the acknowledgement to correlate to its request. If that ACK is
still missing at the next interval, the link fails into its close or
authenticated recovery path. A disconnect, timeout, service shutdown, or state
sweep removes the route and any rendezvous involving that device, so a
half-open socket cannot remain the apparent live route indefinitely.

Client setup and teardown are bounded as well. In particular, the Host's Rust
transport applies five-second deadlines to connect, application write, pong,
and close I/O; the Dart pairing and Controller-session links bound connect,
registration/request, and transport shutdown work.

## Pairing rendezvous

A Host creates either a QR rendezvous identified by a 16-byte random ID or a desktop-code rendezvous with an eight-character uppercase Base32 code. Every rendezvous expires exactly 120 seconds after creation. The service stores only a domain-separated SHA-256 lookup value for a desktop code, never its plaintext. Join attempts accept the code without case sensitivity.

One Controller may join a rendezvous. The Host cannot join its own rendezvous, a second Controller is rejected, and only the Host and joined Controller may relay pairing data. The service adds the authenticated connection's device ID as the sender and forwards `opaque_envelope` bytes unchanged. It does not decode the nested pairing protocol.

Only the Host may complete a rendezvous as succeeded or rejected. Expiry and member disconnection produce corresponding closure notifications. Successful signaling completion is not proof of a permanent grant: the Host still makes the local authorization decision specified by Protocol V1, including four-word SAS confirmation for desktop pairing.

Pairing creation and join attempts use separate fixed-window limits from the
general inbound traffic limits:

- create and join share 30 attempts per source IP per 60 seconds;
- joins allow 5 attempts per rendezvous ID or normalized pairing code per 60 seconds.

The limiter retains at most 65,536 source-IP windows and 262,144 lookup-key
windows. A request needing a new entry when an applicable map is full fails
closed with `PAIRING_RATE_LIMITED`, just like an exhausted attempt budget.

The source IP is the TCP peer address unless that direct peer belongs to a configured `SIGNALING_TRUSTED_PROXY_CIDRS` network, in which case the proxy-overwritten `X-Real-IP` value is used. Forwarded headers from every other peer are ignored. A limited response includes a bounded retry delay. Operators should place only a carefully configured transport proxy in front of the service and must not treat proxy authentication as device authorization.

## Session routing

A registered sender provides a 32-byte recipient device ID and an opaque envelope. If the recipient is online, the service forwards the bytes unchanged and supplies the sender device ID from the registered connection. If the recipient is absent, it returns `DEVICE_OFFLINE`. WebRTC offers, answers, ICE candidates, and signed session authentication remain peer-protocol data inside the opaque envelope; as explained above, the signaling operator can access the forwarded bytes even though the current server does not parse them.

The service does not persist session messages, inspect signatures, terminate WebRTC, relay screen media, or synthesize authorization. Delivery is best-effort through a bounded per-connection queue. The buffered queue retains at most 64 entries. Before copying an encoded frame into that queue, transport atomically reserves its payload size against a 526,336-byte per-connection budget (two maximum-sized frames), a 4 MiB source-IP budget, and a 64 MiB process-wide budget. Reservations include the frame currently being written and are released after write success, write failure, queue drain, or connection close.

If the entry limit or any byte budget is full, the new relayed message is dropped and its sender receives `DEVICE_OFFLINE`; the recipient route is not removed by another sender. A recipient whose current socket write exceeds the bounded write deadline is disconnected. The byte budgets are fixed safety invariants rather than deployment knobs, so raising connection-count limits cannot silently remove the process-wide outbound memory bound.

## Public errors

Signaling V1 uses `UnifiedError` with stable codes and no stack traces or internal exception text:

| Code | Meaning |
| --- | --- |
| `PAIRING_CODE_EXPIRED` | Rendezvous is absent or expired |
| `PAIRING_RATE_LIMITED` | A pairing create/join budget or limiter-map capacity was exhausted; retry delay is supplied |
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
source IP, 4,096 active rendezvous globally, and four active rendezvous per Host
by default. Operators can set bounded values with `SIGNALING_MAX_CONNECTIONS`
(1–65,536), `SIGNALING_MAX_CONNECTIONS_PER_IP` (1–65,536),
`SIGNALING_MAX_RENDEZVOUS` (1–65,536), and
`SIGNALING_MAX_RENDEZVOUS_PER_HOST` (1–64). A connection above the global limit
receives HTTP 503, and one above the per-IP limit receives HTTP 429, before
WebSocket upgrade. A Host above its per-Host rendezvous limit receives
`PAIRING_REJECTED`; exhaustion of the process-wide rendezvous capacity returns
`SERVER_UNAVAILABLE`.

Graceful shutdown uses a ten-second deadline by default and accepts an explicit
`SIGNALING_SHUTDOWN_TIMEOUT` greater than zero and no longer than one minute.
New upgrades are rejected once shutdown begins; active routes are closed before
the process exits or the deadline forces transport closure.

All presence, rate-limit, rendezvous, and connection state is local memory and is cleared on restart. Signaling does not provide multi-instance coordination, durable queues, TURN, WebRTC media, device key storage, pairing presentation, screen capture, or input control.
