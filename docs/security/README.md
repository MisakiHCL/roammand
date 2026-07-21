<!-- SPDX-License-Identifier: Apache-2.0 -->

# Security guide

**English** · [简体中文](README.zh-CN.md)

Roammand keeps long-term identity and authorization on user devices. The Host's
local grant registry—not a cloud account, signaling connection, QR code, or
STUN/TURN service—is the authority that permits remote control.

## Security goals

- A Controller can start a session only after the Host has stored a one-way
  grant for that exact public identity.
- Pairing, session offers, answers, and reconnects bind identities, nonces,
  expiry, permissions, SDP hashes, and DTLS fingerprints into signed canonical
  transcripts.
- Screen media and input travel over authenticated WebRTC protection between
  the peers. Signaling routes bounded negotiation messages and cannot mint a
  device signature or grant.
- Desktop private keys and grants stay in protected local storage. Privileged
  broker/helper processes receive narrow, temporary authority rather than the
  long-term Host secret.
- Permission loss, malformed input, replay, queue pressure, route migration,
  lease expiry, and session failure release held input and fail closed.

## Data and metadata visibility

Account-free does not mean anonymous or free of network metadata. Operators and
users should understand what each participant necessarily handles.

| Participant | Data it can observe | Data it is not designed to receive |
| --- | --- | --- |
| Controller and Host | Remote screen/input needed for the session; authenticated peer identity; ICE data exchanged with the peer | The other device's long-term private key |
| Signaling service | TCP source address while connected, registered/routed device IDs, rendezvous state, timing, sizes, bounded outer routing fields, and the nested envelope bytes it forwards | Long-term private keys, the Host's stored grant database, or decrypted WebRTC screen/input content |
| STUN service | Source address/port and request timing needed to report a public mapping | Screen media, input, device grants, or TURN relay traffic |
| Optional developer-operated TURN | Peer addresses, timing, traffic volume, and encrypted WebRTC packets it relays | Decrypted DTLS-SRTP/SCTP content or authorization authority |
| Exported diagnostics | Only the typed aggregate allowlist shown in the preview | Device identity, addresses, SDP/ICE, credentials, input, pixels, raw payloads, or stack traces |

The current signaling implementation treats nested envelopes as opaque: it
forwards them without decoding their format, logging their bodies, or persisting
them. That is data minimization, not end-to-end confidentiality from the
operator, because WSS terminates at the signaling service. A modified or
compromised process could inspect or retain forwarded public identity proofs and
WebRTC negotiation metadata. Signed identity, SDP, and fingerprint bindings
prevent signaling from authorizing a Controller or silently substituting a
different negotiation; they do not hide all negotiation bytes. Endpoint,
timing, size, and volume metadata also remain visible to the relevant service.

## Trust assumptions and limits

- The operating systems, the Host owner, and the approved Controller device are
  trusted. A compromised endpoint can see or generate everything that endpoint
  legitimately handles.
- Local IPC isolates other operating-system users and stale/substituted
  endpoints. It does not defend a user from arbitrary code already running with
  that same user's full privileges, or from an administrator/root compromise.
- The Host owner must verify the named Controller before QR approval and all
  four English words for desktop-code pairing. Approving the wrong Controller
  creates a real grant until it is revoked locally.
- The design does not promise anonymity, resistance to global traffic analysis,
  signaling availability, or connectivity through every NAT. The public profile
  has no TURN fallback and signaling routing state is single-instance memory.
- Flutter's current WebSocket API delivers a complete message before the
  Controller can apply its 263,168-byte application-frame check. The official
  service bounds forwarded messages, but an untrusted custom signaling endpoint
  can still cause a larger transient client allocation. Enforcing this limit
  before allocation requires a bounded native/streaming transport.
- Platform controls are not bypassed. macOS TCC/FileVault and Windows UAC,
  integrity, Winlogon, and SendSAS policy remain authoritative.
- Roammand does not provide automatic security updates. Operators and users
  must track the latest release or reviewed source revision themselves.

## Security documents

- [Privileged Helper threat model](privileged-helper-threat-model.md) — protected assets, trusted roles, local peer authentication, route migration, packaging, and fail-closed behavior.
- [Privacy-safe diagnostics](privacy-safe-diagnostics.md) — typed diagnostic allowlist, excluded data, retention limits, and user-controlled local export.
- [Account-free pairing V1](../architecture/account-free-pairing-v1.md) — invitation types, authenticated exchange, local approval, persistence, and replay handling.
- [Desktop identity and local IPC V1](../architecture/desktop-identity-ipc-v1.md) — key storage, same-user boundary, authenticated framing, and cleanup.
- [Desktop WebRTC V1](../architecture/desktop-webrtc-v1.md) — session authentication, media/input protection, ICE, permissions, and lifecycle.
- [Authenticated reconnect V1](../architecture/reconnect-v1.md) — bounded recovery, fresh authentication, and fail-closed input behavior.

The complete component flow is documented in the [architecture guide](../architecture/README.md).
To report a vulnerability without disclosing it publicly, follow
[SECURITY.md](../../SECURITY.md).
