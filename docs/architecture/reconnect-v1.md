<!-- SPDX-License-Identifier: Apache-2.0 -->

# Authenticated reconnect V1

This document defines how an authenticated Roammand session recovers from a temporary signaling or WebRTC interruption. Reconnect never creates trust: the existing one-way Controller-to-Host grant remains authoritative, and the Host can revoke it at any time.

## State and timing

An active Controller moves from `connected` to `reconnecting` after a recoverable signaling or peer failure. It schedules at most five attempts after 1, 2, 4, 8, and 15 seconds. Those delays total the complete 30-second recovery window; there is no hidden grace period or unbounded retry loop.

Entering `reconnecting` immediately blocks new remote input, releases held buttons and keys on a best-effort basis, and clears pending fast-pointer data. A spontaneous peer recovery cancels every remaining timer. If the fifth attempt fails, the session becomes `failed` and waits for an explicit user retry or close. Manual retry creates a new session resource group instead of reusing closed signaling, peer, identity-adapter, or renderer objects.

The Host retains the matching active session for at most 30 seconds. It releases remote input while retained, rejects new input envelopes, and continues to return busy for other Controllers. Revoking the grant terminates the retained session immediately.

Mobile application backgrounding is not a reconnect trigger. It releases input, closes the session, and requires the user to choose **Connect** after returning to the foreground.

## Fresh authentication on every attempt

Every reconnect offer contains a fresh 32-byte nonce, new issue and expiry times, the current ICE-restart SDP hash, the current DTLS fingerprint, and a new Ed25519 signature over the canonical protocol transcript. The Controller must not reuse authentication, SDP, candidates, or transcript bytes from an earlier attempt.

When the Host still has the peer, it authenticates the offer, restarts ICE on that peer, and returns a Host-signed reconnect response with a strictly increasing generation. The Controller verifies both device identities and public keys, session ID, nonce, offer and answer hashes, DTLS fingerprints, permissions, time window, and generation before accepting it.

If the Host process restarted and lost its peer, the same fresh offer may establish a new peer only after the full normal session authentication and grant checks. This path returns a normal signed answer; it is not an anonymous or reduced-authentication fallback.

Stale generations, expired messages, replayed nonces, mismatched identities, unexpected candidates, invalid signatures, and revoked or absent grants fail closed.

## Resource and protocol boundaries

- Only one reconnect offer may be in flight for a session.
- Pending candidates and signaling frames retain their protocol count and byte limits.
- ICE restart reuses the current peer only while the authenticated Host session is retained.
- Successful recovery re-enables input only after the authenticated peer reports connected.
- Failure and close cancel timers and dispose session-scoped subscriptions, channels, capture, and input state.
- The signaling service continues to route bounded opaque envelopes. It cannot validate device grants or authorize remote control.

Recovery, privacy, and resource checks are collected in [Reliability and privacy verification](../testing/reliability-and-privacy.md). Diagnostic boundaries are defined in [Privacy-safe diagnostics](../security/privacy-safe-diagnostics.md).
