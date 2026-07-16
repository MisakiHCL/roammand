<!-- SPDX-License-Identifier: Apache-2.0 -->

# Self-host signaling and TURN with Docker Compose

This deployment runs the account-free signaling relay and a coturn TURN relay. The signaling service routes opaque protocol envelopes and never grants remote-control permission. Device private keys and Controller-to-Host grants remain on the devices.

## Requirements

- Docker Engine with the Compose v2 plugin
- A public DNS name and a trusted TLS certificate whose private key is not password-encrypted
- A public IPv4 or IPv6 address forwarded directly to this machine
- Firewall access to TCP 8443, TCP/UDP 3478 and 5349, and UDP 49160–49200

The bounded relay range supports a small personal deployment. Increase it deliberately if concurrent TURN allocations exhaust the range; keep the published range and coturn configuration identical.

## Prepare configuration and secrets

From the repository root:

```bash
cd infra/compose
cp .env.example .env
mkdir -m 700 secrets
printf '%s\n' 'choose-a-username' > secrets/turn-username
openssl rand -hex 32 > secrets/turn-password
chmod 600 secrets/turn-username secrets/turn-password
```

Copy the full certificate chain to `secrets/tls-cert.pem` and its private key to `secrets/tls-key.pem`. Compose file-backed secrets preserve host ownership, so grant only the dedicated container group read access while keeping the files owned by the account that runs Compose:

```bash
sudo chown "$(id -un)":65532 secrets/tls-cert.pem secrets/tls-key.pem \
  secrets/turn-username secrets/turn-password
chmod 640 secrets/tls-cert.pem secrets/tls-key.pem \
  secrets/turn-username secrets/turn-password
```

Edit `.env` and replace the example realm and documentation-only IP address. Secret values are read from Docker secret files; do not put the TURN password or TLS private key in `.env` or `compose.yaml`.

The TURN username and password accept only ASCII letters, digits, `_`, `.`, and `-`, with a maximum of 128 characters. The generated hexadecimal password satisfies this policy.

## Validate and start

```bash
docker compose --env-file .env -f compose.yaml config
docker compose --env-file .env -f compose.yaml up -d --build
docker compose --env-file .env -f compose.yaml ps
```

Both containers run without Linux capabilities, with read-only root filesystems, `no-new-privileges`, bounded Docker logs, health checks, and non-root numeric users. coturn writes its generated credential file only to a private in-memory filesystem and does not emit connection logs.

The resulting endpoints are:

- Signaling: `wss://your-domain.example:8443/v1/connect`
- TURN over UDP: `turn:your-domain.example:3478?transport=udp`
- TURN over TLS/TCP: `turns:your-domain.example:5349?transport=tcp`

Configure every participating Controller and Host with the same signaling endpoint and TURN URLs, username, and password. The Host Agent reads `ROAMMAND_SIGNALING_ENDPOINT`, `ROAMMAND_TURN_URLS`, `ROAMMAND_TURN_USERNAME`, and `ROAMMAND_TURN_PASSWORD`. Flutter builds use the corresponding `--dart-define` values. Treat the TURN credential as a secret in build and deployment systems.

## Operations

Check state without printing secret material:

```bash
docker compose --env-file .env -f compose.yaml ps
docker compose --env-file .env -f compose.yaml logs signaling
```

Rotate TURN credentials by replacing both TURN secret files and recreating coturn. Rotate TLS material by replacing the certificate files and recreating both services:

```bash
docker compose --env-file .env -f compose.yaml up -d --force-recreate
```

Stop the deployment with `docker compose --env-file .env -f compose.yaml down`. The signaling and rendezvous state is intentionally ephemeral; restarting it does not revoke on-device bindings.
