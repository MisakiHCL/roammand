<!-- SPDX-License-Identifier: Apache-2.0 -->

# Self-host signaling and STUN with Docker Compose

**English** · [简体中文](docker-compose.zh-CN.md)

This deployment runs Roammand's account-free signaling service and a
STUN-only coturn service. Signaling routes bounded protocol envelopes without
decoding their nested format; STUN helps peers discover their public network
mapping. Neither service can grant remote-control permission or access
end-to-end encrypted WebRTC media. “Opaque” describes the current signaling
implementation, not confidentiality from its operator.

This profile does not provide a TURN relay. Direct connections can therefore
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

## Deployment and privacy boundary

The reference topology runs one signaling instance and terminates TLS inside
that container. Presence, pairing rendezvous, rate-limit windows, and routes are
process memory: do not place independent replicas behind a load balancer. A
multi-instance deployment requires shared routing/state that this repository
does not provide.

The services hold no device grant or long-term key, but they are not anonymous
infrastructure. WSS terminates at signaling, so its process and operator can
access the bounded nested envelope bytes it forwards, including public identity
proofs and WebRTC negotiation metadata, as well as TCP source addresses,
registered routing identifiers, timing, and sizes. The current implementation
does not decode, persist, or normally log the nested bodies. STUN observes the
address/port whose public mapping it returns. Operators must restrict access to
the runtime, proxy logs, telemetry, and infrastructure-level flow logs.

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

The Dockerfile-specific ignore file (with a matching root fallback) uses an
allowlist: only `gen/go` and `services/signaling` enter the signaling build
context. Compose secrets, environment files, repository metadata, and common
local build products are therefore not sent to the Docker daemon or a
configured remote builder. Keep both rules aligned when changing the
Dockerfile; never add credentials to an allowed source tree.

The example also caps signaling at 1,024 concurrent WebSocket connections, 64
from one source IP, 4,096 active pairing rendezvous globally, and four active
rendezvous per Host. Tune `SIGNALING_MAX_CONNECTIONS` (1–65,536),
`SIGNALING_MAX_CONNECTIONS_PER_IP` (1–65,536),
`SIGNALING_MAX_RENDEZVOUS` (1–65,536), and
`SIGNALING_MAX_RENDEZVOUS_PER_HOST` (1–64) in `.env` for the machine's memory,
expected NAT fan-out, and traffic; invalid or unbounded values are rejected at
startup. `SIGNALING_SHUTDOWN_TIMEOUT` defaults to 10 seconds, is capped at one
minute, and remains shorter than the Compose stop grace period.

Independently of those operator settings, outbound payload copies have fixed
hard budgets: 64 MiB across the process, 4 MiB across connections from one
source IP, and 526,336 bytes per connection (two maximum-sized frames). The
64-entry per-connection queue limit remains in force. Queued and currently
writing bytes count against all applicable budgets, and failed delivery or
connection shutdown releases every reservation.

Inbound traffic uses fixed one-second windows with both frame-count and byte
limits: 256 frames / 32 MiB per connection, 4,096 frames / 128 MiB per source
IP, and 32,768 frames / 512 MiB process-wide. Application messages and incoming
WebSocket ping/pong frames count toward these limits. Crossing a limit, or
arriving from a new source after the 65,536-entry traffic-IP map is full, closes
that WebSocket with status 1013 (`Try Again Later`). These are fixed safety
limits, not environment-variable tuning knobs.

Pairing create and join requests share a separate budget of 30 attempts per
source IP per 60 seconds. Joins also allow only five attempts per rendezvous ID
or normalized code per 60 seconds. The pairing limiter retains at most 65,536
source-IP windows and 262,144 lookup windows; a new key when either applicable
map is full fails closed with `PAIRING_RATE_LIMITED` and a bounded retry delay.

Partially delivered binary messages have a separate fixed in-flight memory
budget. Once a WebSocket message header arrives, the service reserves 263,169
bytes per active read against an 8 MiB source-IP budget and a 64 MiB process
budget, then requires the body to finish within 10 seconds. Every success,
timeout, rejection, and close releases the reservation. These limits prevent
slow fragmented messages from bypassing the completed-frame rate windows and
are not operator tuning knobs.

## Validate and start

```bash
docker compose --env-file .env -f compose.yaml config
docker compose --env-file .env -f compose.yaml up -d --build
docker compose --env-file .env -f compose.yaml ps
```

Both containers run as non-root users with read-only root filesystems, dropped
Linux capabilities, `no-new-privileges`, bounded Docker logs, and health checks;
signaling additionally has a process-count limit. The coturn image is pinned by
version and digest. Coturn enables `stun-only` and publishes only UDP 3478; it
has no user database, relay allocation range, TLS listener, or TURN credential.

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

The supplied Compose file terminates TLS in the signaling process. If a custom
deployment terminates TLS at Nginx or another reverse proxy, remove both
signaling TLS variables and their secret mounts/definitions together, bind the
plaintext origin only to a private container/host network, and never publish
that origin port. Forward WebSocket Upgrade, preserve the
`roammand-signaling.v1.protobuf` subprotocol, disable
response buffering, and overwrite `X-Real-IP` with the proxy-observed client
address. Configure `SIGNALING_TRUSTED_PROXY_CIDRS` with only the direct proxy
network; the service rejects a CIDR covering an entire IPv4 or IPv6 address
family. Never trust client forwarding headers from the whole Internet.

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

`/healthz` proves only that the HTTP process is serving. Current Host and
pairing links heartbeat every 15 seconds; the Controller session link uses 20
seconds. Each allows one outstanding heartbeat, requires a strictly correlated
acknowledgement, and enters its bounded close or authenticated recovery path if
that ACK is still missing at the next interval. Client connect, request/write,
and shutdown work is also bounded. Monitor real client success and bounded
reconnect/error counts without adding identifiers or payloads to logs.

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

There is no server-side trust database to back up. Protect and back up only the
operator-owned Compose configuration and TLS material, using a secret store
rather than the repository. For upgrades, deploy a reviewed source revision,
rebuild the signaling image, verify both health checks, and complete a real
cross-network session. Expect connected clients and active pairing rendezvous to
be disrupted when the signaling process is recreated.
