<!-- SPDX-License-Identifier: Apache-2.0 -->

# Pairing verification

Pairing verification covers device identity, authenticated invitation exchange, Host-local approval, permanent one-way grants, and Controller persistence.

## Automated contract

| Area | Evidence | Gate |
| --- | --- | --- |
| Protocol | Schema compatibility, limits, canonical transcripts | `make test-schema` |
| Cryptography | SAS, HKDF, nonce, AAD, AEAD, tamper rejection across Dart/Rust/Go | `make test-conformance` |
| Rendezvous | QR/code lifecycle, binding, expiry, correlation, rate limits, race checks | `make test-m5` |
| Host coordinator | Identity proof, local decision, grant-before-success, cleanup | `make test-m5-lifecycle` |
| Controller | Invitation validation, Host proof, SAS, persistence, cancellation | `make test-m5-lifecycle` |
| Product UI | QR/code presentation, countdown, approval, saved Hosts, revocation | `make app-check` |

## Target-system evidence

- QR pairing uses only the live camera path and handles camera denial cleanly.
- Desktop codes expire within 120 seconds and never grant access by themselves.
- Both desktops show the same four English verification words.
- No grant exists before explicit approval on the Host.
- Controller identity survives restart in platform-protected storage without cross-device restore.
- A saved Host reconnects without pairing again.
- Host revocation blocks later sessions; Controller-side deletion remains local.
- WSS and TURN deployments preserve the authenticated pairing boundary.

Use synthetic names and endpoints in retained evidence. Pairing codes, private keys, transcripts, and device identities must not be recorded.
