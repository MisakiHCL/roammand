<!-- SPDX-License-Identifier: Apache-2.0 -->

# Self-host signaling and STUN with Docker Compose

**English** · [简体中文](docker-compose.zh-CN.md)

This deployment runs Roammand's account-free signaling service and a
STUN-only coturn service. Signaling routes bounded opaque protocol envelopes;
STUN helps peers discover their public network mapping. Neither service can
grant remote-control permission or access end-to-end encrypted WebRTC media.

This release does not provide a TURN relay. Direct connections can therefore
fail on symmetric NATs, enterprise networks, or other restrictive paths.

## Requirements

- Docker Engine with the Compose v2 plugin
- A public DNS name for signaling
- A trusted TLS certificate and unencrypted private key for that DNS name
- A public address forwarded directly to the Docker host
- Firewall access to TCP 8443 for WSS and UDP 3478 for STUN

STUN is UDP traffic, not HTTP. A path such as
`https://example.com/stun/` cannot replace UDP 3478, and an ordinary website
CDN cannot proxy it.

## Prepare configuration

From the repository root:

```bash
cd infra/compose
cp .env.example .env
mkdir -m 700 secrets
```

Copy the full signaling certificate chain to `secrets/tls-cert.pem` and its
private key to `secrets/tls-key.pem`. Grant the numeric signaling container
group read access without making the private key public:

```bash
sudo chown "$(id -un)":65532 secrets/tls-cert.pem secrets/tls-key.pem
chmod 640 secrets/tls-cert.pem secrets/tls-key.pem
```

If the files live elsewhere, edit `.env`. Do not commit `.env`, certificates,
private keys, public addresses, or operator-specific paths.

The example also caps signaling at 1,024 concurrent WebSocket connections, 64
from one source IP, and four active pairing rendezvous per Host. Tune
`SIGNALING_MAX_CONNECTIONS` (1–65,536),
`SIGNALING_MAX_CONNECTIONS_PER_IP` (1–65,536), and
`SIGNALING_MAX_RENDEZVOUS_PER_HOST` (1–64) in `.env` for the machine's memory,
expected NAT fan-out, and traffic; invalid or unbounded values are rejected at
startup.

Independently of those operator settings, outbound payload copies have fixed
hard budgets: 64 MiB across the process, 4 MiB across connections from one
source IP, and 526,336 bytes per connection (two maximum-sized frames). The
64-entry per-connection queue limit remains in force. Queued and currently
writing bytes count against all applicable budgets, and failed delivery or
connection shutdown releases every reservation.

## Validate and start

```bash
docker compose --env-file .env -f compose.yaml config
docker compose --env-file .env -f compose.yaml up -d --build
docker compose --env-file .env -f compose.yaml ps
```

Both containers run as non-root users with read-only root filesystems, dropped
Linux capabilities, `no-new-privileges`, bounded Docker logs, and health
checks. Coturn enables `stun-only` and publishes only UDP 3478; it has no user
database, relay allocation range, TLS listener, or TURN credential.

The resulting endpoints are:

- Signaling: `wss://signal.example.com:8443/v1/connect`
- STUN: `stun:stun.example.com:3478`

The two names may resolve to the same host. The STUN name does not need an HTTPS
certificate because this profile uses standard STUN over UDP rather than
STUNS/TLS.

In each Roammand app, open **Network services**, select **Custom service**, and
enter both endpoints. A developer who runs the Host Agent independently can use
the same values without the GUI:

```bash
ROAMMAND_SIGNALING_ENDPOINT='wss://signal.example.com:8443/v1/connect' \
ROAMMAND_STUN_URLS='stun:stun.example.com:3478' \
cargo run -p roammand-host-agent --features native-webrtc -- serve
```

If TLS terminates at Nginx or another reverse proxy, forward WebSocket Upgrade,
preserve the `roammand-signaling.v1.protobuf` subprotocol, disable response
buffering, and set `X-Real-IP` to the proxy-observed client address. Configure
`SIGNALING_TRUSTED_PROXY_CIDRS` with only the proxy network; never trust client
forwarding headers from the whole Internet.

## Verify from another network

Check signaling without printing private material:

```bash
curl --fail https://signal.example.com:8443/healthz
docker compose --env-file .env -f compose.yaml logs signaling
```

Use `turnutils_stunclient` from a machine outside the Docker host's network:

```bash
turnutils_stunclient -p 3478 stun.example.com
```

A local container health check is not proof that the cloud firewall allows
public UDP 3478. Complete one installed Host-to-Controller test across two
independent networks before publishing the endpoints.

## Operations

Rotate TLS material by replacing both certificate files and recreating the
signaling container:

```bash
docker compose --env-file .env -f compose.yaml up -d --force-recreate signaling
```

Stop the deployment with
`docker compose --env-file .env -f compose.yaml down`. Signaling presence,
pairing rendezvous, and rate-limit windows are intentionally in memory and are
cleared on restart; on-device identities and grants are not.
