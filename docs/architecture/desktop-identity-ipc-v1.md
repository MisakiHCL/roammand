<!-- SPDX-License-Identifier: Apache-2.0 -->

# Desktop identity and local IPC V1

Desktop identity and local IPC V1 define the boundary between the Rust Host Agent and the Flutter desktop application. The Host Agent owns long-term Host identity keys and permanent Controller authorizations. The Flutter application is an authenticated current-user client; it does not read private keys or authorization files directly.

This contract is implemented on macOS and Windows. Production Host startup is intentionally unsupported on other platforms.

## Security boundary

The product has no account service. Long-term identity and Controller grants remain on the Host device. The signaling service can route opaque messages but cannot access the local IPC endpoint, hold the Host private key, create a grant by itself, or independently authorize remote control.

Local IPC assumes that the current operating-system user account is trusted. It defends against other local users, accidental cross-instance connections, stale or substituted endpoints, unauthenticated local clients, oversized frames, and malformed protocol state. It does not attempt to defend a user from arbitrary code already running with that same user's full privileges.

The Flutter macOS Runner is not App Sandbox-contained because it must connect to the separately running current-user Agent endpoint. Endpoint ownership, file modes, peer credentials, and the authenticated handshake remain the local access boundary.

## Host identity

On first start, the Agent generates a 32-byte Ed25519 seed from the operating system's secure random source. The seed never appears in Protobuf, logs, the Flutter UI, or the signaling service.

Storage is platform-specific:

| Platform | Protected identity storage | Local transport |
| --- | --- | --- |
| macOS | Keychain generic-password item | Unix domain socket |
| Windows | Current-user DPAPI ciphertext in a restricted file | Local-only Named Pipe |

The V1 device ID is deterministic:

```text
SHA-256(
  UTF-8("personal-remote-device-id-v1") ||
  0x00 ||
  U16-BE(ED25519 = 1) ||
  ed25519_public_key
)
```

The Dart, Rust, and Go conformance libraries use shared Golden Vectors for this derivation. A restart loads the existing seed and therefore preserves the public key and device ID. Changing only the display name does not rotate identity.

The Agent signs only validated canonical Session Answer or Session Reconnect transcripts whose Host device ID matches its own identity. Ordinary Protobuf serialization is never used as an authentication transcript.

## One-way Controller grants

A grant authorizes one Controller to access one Host with an explicit, non-empty permission set. Input control requires screen-view permission. Grant IDs are random 16-byte values, duplicate Controller grants are rejected, self-grants are rejected, and grant count is bounded by the protocol limit.

Controller-to-Host authorization is directional. It does not grant Host-to-Controller control; reverse control requires a separate pairing and grant on the other Host. A grant has no automatic expiry and remains valid until this Host revokes it.

The Agent persists grants before changing its in-memory registry. The private snapshot contains the Host device ID, public Controller identity, permissions, timestamps, and a versioned SHA-256 envelope. It contains no long-term private key. Persistence uses a current-user-only directory and atomic replacement. Corrupt, oversized, unsupported, or wrong-Host snapshots fail closed instead of being silently discarded.

Revocation is persisted before it is reported successful. Active sessions belonging to the revoked Controller are terminated and local clients receive bounded `SessionTerminatedEvent` notifications. Restarting the Agent preserves both the identity and remaining grants.

## Endpoint discovery and OS access control

The Agent creates a private runtime directory and publishes two current-user-only files while it is running:

- a versioned endpoint discovery record containing transport, endpoint, and random Agent instance ID;
- a random 32-byte IPC authentication token.

On macOS, the socket, token, and discovery file are mode `0600`; their directory is mode `0700`. The Agent verifies the connecting peer UID before sending protocol data. It replaces only an owned, inactive stale socket and refuses an unexpected file or a live endpoint.

On Windows, the Named Pipe rejects remote clients and uses a protected DACL granting access only to the current user and `SYSTEM`. Runtime files use the equivalent protected DACL. After connection, the Agent resolves the client process token and verifies that its SID matches the Agent user's SID.

Only one production Agent instance may own the endpoint. A clean shutdown stops acceptance, closes active clients, waits for connection tasks, removes temporary discovery/token/socket artifacts, and retains protected identity and grants.

## Framing and mutual authentication

Each stream record is:

```text
payload_length  u32 big-endian
payload         encoded roammand.v1 LocalIpcClientFrame or LocalIpcServerFrame
```

The payload must contain 1 to 65,536 bytes. Zero-length, oversized, truncated, invalid Protobuf, unsupported V1 version, missing payload, and invalid request-ID frames are rejected.

Authentication happens once before business requests:

1. The Agent sends `LocalIpcChallenge` with its 16-byte instance ID and a fresh 32-byte server nonce.
2. The client reads the private token, generates a 32-byte client nonce, and sends `LocalIpcAuthenticate` with `HMAC-SHA-256(token, "PRD-IPC-CLIENT-V1" || instance_id || server_nonce || client_nonce)`.
3. The Agent verifies the client proof and replies with `LocalIpcAuthenticated` containing the same construction under the `PRD-IPC-SERVER-V1` domain.
4. The client verifies the server proof, then zeroes its in-memory token copy.

The instance ID prevents a discovery record from being reused across Agent starts. Independent proof domains prevent reflection. HMAC comparison is constant-time in the Rust implementation.

## Authenticated operations

An authenticated V1 client can request:

| Request | Successful response | Purpose |
| --- | --- | --- |
| `GetHostStatusRequest` | `HostStatus` | Public Host identity, Agent instance/start time, grant count |
| `ListControllerGrantsRequest` | `ControllerGrantList` | Current grants and last successful connection times |
| `CreateControllerGrantRequest` | `ControllerGrantCreated` | Persist a validated one-way grant after a local pairing decision |
| `SignCanonicalTranscriptRequest` | `CanonicalTranscriptSignature` | Sign a Host-bound Answer or Reconnect transcript |
| `RevokeControllerGrantRequest` | `ControllerGrantRevoked` | Persist revocation and report terminated-session count |

The Flutter Host surface uses status, list, and revoke. Its pairing coordinator may create a grant only after the required Host-local approval and four-word SAS workflow.

Every request has a non-empty request ID of at most 64 UTF-8 bytes. Responses echo that ID; unsolicited events have their own event payload. Stable `UnifiedError` values cross the boundary instead of internal exception text or stack traces.

## Resource and lifecycle limits

| Resource | Limit |
| --- | ---: |
| Encoded local IPC payload | 65,536 bytes |
| Simultaneous local clients | 4 |
| Pending request IDs per connection | 32 |
| Outbound frames per connection | 32 |
| Authentication deadline | 3 seconds |
| Business request deadline | 5 seconds |

The Dart client also bounds pending requests to 32, correlates responses by ID, treats unknown/duplicate terminal responses as protocol failures, and resolves every pending operation on timeout, disconnect, or explicit close. Its controller cancels streams and refresh timers when the UI is disposed.

## Compatibility and conformance

The messages live in the `roammand.v1` package in `schema/proto/roammand/v1/local_ipc.proto`. Buf's V1 compatibility rules apply. Local IPC uses protocol major `1`, minor `0`; unsupported versions fail closed.

`conformance/protocol_vectors/local_ipc_v1.json` proves that Dart can decode Rust server frames and Rust can decode and execute the Dart status request. Platform tests verify Keychain/DPAPI behavior, restricted files, peer-user gates, endpoint cleanup, duplicate-instance rejection, and identity/grant persistence across process restarts.

## Scope boundaries

This IPC boundary does not perform signaling, network authentication, pairing presentation, WebRTC transport, capture, input injection, TURN, service installation, signing, notarization, or packaging. Each responsibility remains isolated in its dedicated component.
