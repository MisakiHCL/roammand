<!-- SPDX-License-Identifier: Apache-2.0 -->

# Protocol V1

Roammand Protocol V1 is defined by the compatibility-stable `roammand.v1` Protobuf package under `schema/proto`. Generated Dart, Rust, and Go libraries are committed under `gen/` and reproduced with `make generate`.

Buf applies the `STANDARD` lint policy and `FILE` breaking-change policy. Existing V1 files, messages, fields, field numbers, and enum values must remain wire compatible. A change that cannot satisfy the V1 compatibility policy requires a new versioned package.

## Trust and authorization

The product has no cloud account and is intended only for controlling devices owned by the same user. Long-term private keys and binding records remain on devices. No private-key field exists in the protocol.

A `ControllerGrant` is a one-way, persistent Controller-to-Host authorization. It does not imply Host-to-Controller control, and it has no automatic expiration. Reverse control requires a separate grant. A grant remains valid until the Host records a `GrantRevocation`.

The signaling service can relay rendezvous and session messages, but it cannot mint a Controller grant, hold a device's long-term private key, or independently authorize remote control. A pairing code identifies a rendezvous; it is not proof that the Host accepted a grant.

QR and desktop pairing rendezvous have a maximum lifetime of 120,000 milliseconds. Desktop pairing requires a Host-local decision and confirmation of a four-word SAS derived from the canonical pairing transcript. The protocol provides the deterministic SAS digest material; word-list presentation is outside Protocol V1.

## Schema overview

Protocol V1 includes:

- protocol version and capability negotiation;
- Ed25519 device public-key identities;
- QR and eight-character Base32 desktop pairing rendezvous;
- pairing confirmation material and Host-local decisions;
- one-way Controller grants and Host revocations;
- signaling envelopes with typed `oneof` payloads;
- signed Offer, Answer, and Reconnect session authentication data;
- WebRTC descriptions, ICE candidates, and end-of-candidates messages;
- reliable input and fast pointer channels;
- session state and typed unified errors.

Zero-valued security enums are unspecified and are not accepted as negotiated or authenticated values. Unknown ordinary Protobuf fields remain accepted for forward compatibility, while unknown enum numeric values and missing required `oneof` payloads are rejected at validation boundaries.

## Canonical Transcript V1

Authentication and SAS bytes do not use ordinary Protobuf serialization. Every implementation constructs this independent canonical format:

```text
magic        4 bytes   ASCII "PRDT"
version      u16 BE    1
purpose      u16 BE
field_count  u16 BE
fields:
  tag        u16 BE
  length     u32 BE
  value      raw bytes
```

Transcript limits and canonical rules are:

- at most 4,096 encoded bytes;
- at most 16 fields;
- at most 1,024 bytes in one field;
- tags are strictly increasing;
- duplicate, unknown, missing, or incorrectly sized fields are invalid;
- trailing or truncated bytes are invalid;
- times are unsigned 64-bit big-endian Unix milliseconds;
- permission bits and reconnect generation are unsigned 32-bit big-endian;
- strings are not included.

Purpose values and required tags are:

| Purpose | Value | Required tags |
| --- | ---: | --- |
| Pairing SAS | 1 | 1–7 |
| Session Offer | 2 | 1, 2, 8–14 |
| Session Answer | 3 | 1, 2, 8–16 |
| Session Reconnect | 4 | 1, 2, 8–17 |

The tag table is fixed:

| Tag | Meaning | Length |
| ---: | --- | ---: |
| 1 | Controller device ID | 32 bytes |
| 2 | Host device ID | 32 bytes |
| 3 | Rendezvous ID | 16 bytes |
| 4 | Controller Ed25519 public key | 32 bytes |
| 5 | Host Ed25519 public key | 32 bytes |
| 6 | Controller X25519 ephemeral public key | 32 bytes |
| 7 | Host X25519 ephemeral public key | 32 bytes |
| 8 | Session ID | 16 bytes |
| 9 | Nonce | 32 bytes |
| 10 | Issued-at Unix milliseconds | 8 bytes |
| 11 | Expires-at Unix milliseconds | 8 bytes |
| 12 | Requested permission bits | 4 bytes |
| 13 | Offer SHA-256 | 32 bytes |
| 14 | Controller DTLS fingerprint SHA-256 | 32 bytes |
| 15 | Answer SHA-256 | 32 bytes |
| 16 | Host DTLS fingerprint SHA-256 | 32 bytes |
| 17 | Reconnect generation | 4 bytes |

The SHA-256 Golden Vector digests in purpose order are:

```text
f89f31c4716edbcff1d8a4ad5fbe1161730b022cf28770146e481a06ef5981c6
43799575bb7f848965239b6c4f1205074b7e637a83d60481a4f4a0be1e1c0376
c21982f1d29e4e37653b377aad93fdb36c5a2f4a2c019e115c66c4408e296b40
c5e94ec5922fca06163e25ead7127ea532a16d8e95ee9a7f7183d439a62047cc
```

The complete structured inputs, expected bytes, and negative cases are in `conformance/protocol_vectors`.

## Input channels

`ReliableInputEnvelope` is the `input.reliable` channel. It carries pointer buttons, keyboard events, text, session close/emergency-stop controls, and release-all-input. Its sequence is intended to be strictly increasing at the session layer.

`PointerFastEnvelope` is the `pointer.fast` channel. It carries move/drag state and scroll deltas. These events may be dropped or observed out of order. Protocol V1 defines and validates the messages but does not implement input injection, coordinate conversion, or sending frequency.

## Wire-boundary validation

The Dart, Rust, and Go libraries use the same validation order: encoded size, protocol version, required `oneof`, fixed-length bytes, enum membership and repeated-value uniqueness, UTF-8 byte limits, then lifetime and state combinations.

| Item | Limit |
| --- | ---: |
| Signaling envelope | 262,144 bytes |
| Reliable input envelope | 16,384 bytes |
| Fast pointer envelope | 256 bytes |
| Device name | 128 UTF-8 bytes |
| Request ID | 64 UTF-8 bytes |
| Message key | 128 UTF-8 bytes |
| Signaling endpoint | 2,048 UTF-8 bytes |
| SDP | 131,072 UTF-8 bytes |
| ICE candidate | 4,096 UTF-8 bytes |
| SDP mid | 64 UTF-8 bytes |
| Text input | 4,096 UTF-8 bytes |
| Error detail string | 256 UTF-8 bytes |

Device IDs and Ed25519/X25519 public keys are 32 bytes. Rendezvous and session IDs are 16 bytes. Nonces and SHA-256 digests are 32 bytes. Ed25519 signatures are 64 bytes.

Session state combinations are exact:

- Idle has an empty session ID and no error.
- Signaling, Authenticating, Connecting, Connected, Reconnecting, and Closing have a 16-byte session ID and no error.
- Failed has a 16-byte session ID and a valid, non-unspecified `UnifiedError`.
- Unspecified and unknown states are invalid.

Stable validation categories are `message_too_large`, `invalid_protocol_version`, `missing_payload`, `invalid_length`, `invalid_enum`, `invalid_state`, `invalid_utf8_length`, `invalid_lifetime`, and `duplicate_value`.

## Commands

From the repository root:

```bash
make generate
make generate-check
make schema-breaking
make test-conformance
make test
```

`make generate-check` regenerates all committed types and fails on a Git diff. `make schema-breaking` compares against `main` by default; set `BUF_BREAKING_AGAINST` to compare against another Git commit.
