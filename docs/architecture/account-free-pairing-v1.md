<!-- SPDX-License-Identifier: Apache-2.0 -->

# Account-free pairing V1

This document defines Roammand's pairing and trust contract. It complements [Protocol V1](protocol-v1.md), [Signaling V1](signaling-v1.md), [desktop identity and local IPC V1](desktop-identity-ipc-v1.md), and [desktop WebRTC V1](desktop-webrtc-v1.md).

## Security boundary

Pairing is for a user authorizing control of their own devices without an account. The devices are the authority:

- The Controller long-term Ed25519 private key remains in that Controller's protected local storage.
- The Host long-term Ed25519 private key and permanent authorization registry remain in the Host Agent.
- Signaling stores only short-lived in-memory routing state and forwards opaque bounded envelopes.
- A QR payload, desktop pairing code, signaling server, or TURN service cannot create a grant by itself.
- A grant is directional: Controller → Host. Reverse control needs a separate pairing with roles exchanged.
- A grant persists until the Host revokes it locally. Removing the corresponding Controller-side Host record is not revocation.

The desktop Flutter process accesses Host identity and pairing actions through authenticated current-user IPC. The Agent exposes role-restricted pairing signatures, never a generic signing primitive or private seed.

## Invitations and lifetime

Only one pairing rendezvous may be active for a Host at a time. Its effective expiry is the earlier locally or server supplied deadline and is never more than 120 seconds after issuance.

QR pairing encodes a strict canonical URI:

```text
roammand://pair/v1/<base64url-no-padding HostPairingInvitation protobuf>
```

The invitation identifies the protocol version, QR role, random rendezvous ID, Host public identity, Host ephemeral X25519 public key, SHA-256 public-key fingerprint, signaling endpoint, and issue/expiry times. The parser bounds input before decoding, rejects unknown or non-canonical bytes, and validates the Host device ID and fingerprint. Production accepts WSS and loopback development WS. Source Debug builds may additionally accept a literal private IPv4 or IPv6 unique-local `ws://` endpoint only when every participating process explicitly enables `ROAMMAND_ALLOW_INSECURE_LAN_SIGNALING=true`; Profile and Release ignore that opt-in.

Desktop pairing uses a random eight-character Base32 code displayed as `ABCD-EFGH`. The service looks it up without retaining the plaintext code as durable state. After the Controller joins, the Host routes the same authenticated invitation through the opaque rendezvous.

The production mobile UI accepts QR data only from a live camera session. The first valid invitation stops capture before networking begins; duplicate detections are ignored. Invalid or expired codes leave the scanner available for a new scan.

## Authenticated exchange

Both paths use the same cryptographic exchange:

1. Host creates a fresh X25519 ephemeral key and invitation.
2. Controller joins, creates its fresh X25519 ephemeral key, and constructs the canonical `PairingSas` transcript from both public identities, rendezvous ID, and both ephemeral public keys.
3. Controller sends its identity, ephemeral public key, transcript SHA-256, and Ed25519 signature over the canonical transcript.
4. Host reconstructs the transcript, verifies all invitation bindings and the Controller signature, derives the X25519 shared secret, and returns an authenticated Host proof.
5. Both sides derive independent Host→Controller and Controller→Host AES-256-GCM keys with HKDF-SHA256. Direction, sequence, rendezvous, and device IDs are bound into canonical AAD.
6. Controller sends encrypted readiness. Host displays the sanitized Controller identity for a local decision.
7. For desktop-code pairing, both desktops derive the same four fixed English BIP-39 words from the first 44 transcript-hash bits. Users must compare all four words before approval. QR pairing relies on possession of the live authenticated invitation and still requires Host-local approval.
8. On approval, the Host persists the permanent one-way view-and-control grant before sending an encrypted accepted decision. Rejection, expiry, cancellation, disconnect, invalid state, or persistence failure never reports acceptance.
9. Controller validates the final grant and persists a bounded Host binding containing only the Host public identity, signaling endpoint, pairing time, later successful-session time, and an optional Controller-local alias. The alias is never sent to the Host and cannot alter identity or authorization.

Protocol vectors under `conformance/protocol_vectors/` fix transcript bytes, hashes, SAS indexes and words, HKDF keys, nonce, AAD, plaintext, and ciphertext/tag across Dart, Rust, and Go. SAS words are protocol values and are intentionally not localized.

## State and replay rules

The Host pairing coordinator progresses through `idle`, `creating`, `inviting`, `verifying_controller`, `waiting_local_decision`, and a terminal result before returning to idle. IPC snapshots carry a monotonically increasing revision so a restarted UI can recover an active invitation without creating another.

Encrypted messages use a fixed direction and strictly increasing non-zero sequence. Duplicate, reordered, skipped, wrong-direction, wrong-sender, oversized, unknown-version, unknown-enum, signature-substituted, AAD-substituted, and ciphertext-modified input fails closed. Terminal paths cancel timers, close signaling, and clear ephemeral keys and derived secrets.

## Persistent local records

Host grants use the existing protected authorization registry and are keyed by authenticated Controller identity. An identical repeated grant is idempotent; a conflicting identity is rejected.

Controller trusted-Host records use a bounded Protobuf snapshot inside a magic/version/length/SHA-256 envelope. Writes use same-directory temporary replacement, retain the last readable snapshot on failure, reject duplicate or non-desktop identities, and cap the list at 256 entries. Records are never uploaded.

Mobile identity is created once after the user confirms the suggested device name. Its Ed25519 seed is stored with this-device-only, non-synchronizing iOS Keychain policy or Android encrypted storage with backup disabled. Corrupt or substituted records fail explicitly and are not silently replaced.

## Product boundary

Pairing establishes identity, permanent local trust, and a reusable Host record. Remote-session behavior is defined by the desktop and mobile Controller contracts. Pairing does not add cloud synchronization, file transfer, clipboard, audio, or automatic updates.
