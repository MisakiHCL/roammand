<!-- SPDX-License-Identifier: Apache-2.0 -->

# Official signaling and relay plan

**English** · [简体中文](official-infrastructure-plan.zh-CN.md)

Status: **deferred**. The client lifecycle is being completed first. This plan
does not authorize or record a production deployment, server address, SSH
configuration, certificate path, or secret.

## Intended public endpoints

- Signaling: `wss://signal.hcl.life/v1/connect`
- TURN over UDP: `turn:turn.hcl.life:3478?transport=udp`
- TURN over TCP: `turn:turn.hcl.life:3478?transport=tcp`
- TURN over TLS/TCP: `turns:turn.hcl.life:5349?transport=tcp`
- Short-lived TURN credentials: an HTTPS control-plane endpoint, preferably
  under `https://signal.hcl.life/v1/`.

Signaling is WebSocket traffic and may be routed by an HTTP reverse proxy.
TURN is not HTTP and must be exposed through direct DNS or a compatible layer-4
load balancer. A URL path such as `https://hcl.life/turn/` can issue temporary
credentials, but it cannot relay TURN traffic.

## Deployment boundary

The official client may contain public endpoint names. It must not contain a
long-lived TURN password, infrastructure credential, private key, server
address, or operator-specific path.

The first controlled preview may colocate signaling and coturn, but an official
public service should isolate TURN because it is directly reachable and carries
high-bandwidth relay traffic. If TURN shares the website origin address, its DNS
record also makes that origin discoverable even when the website uses a CDN.

## Required work before public use

1. Add trusted-proxy handling to signaling before placing its IP rate limiter
   behind Nginx, a CDN, or a load balancer.
2. Replace the fixed coturn user with time-limited HMAC credentials and keep the
   shared authentication secret on the server only.
3. Add allocation, bandwidth, port-range, and abuse limits sized for a public
   preview rather than the current personal Compose profile.
4. Configure WebSocket upgrade forwarding, no caching, connection timeouts,
   certificates, health checks, firewall rules, and secret rotation.
5. Test direct ICE and forced relay from independent networks before embedding
   the official defaults in a release build.
6. Add monitoring for active signaling connections, TURN allocations,
   bandwidth, authentication failures, container restarts, and certificate
   expiry without logging private session payloads.

The current signaling presence and rendezvous state is process-local. A single
instance is acceptable for a preview with reconnect behavior; horizontal
scaling requires shared routing/state or a message bus and is not achieved by
starting multiple replicas behind a load balancer.

## Client integration after deployment

Release builds will provide the public signaling endpoint and TURN credential
endpoint to both the GUI and its managed Host Agent. Development builds keep
the existing environment overrides and may continue to run signaling, coturn,
Host Agent, and Flutter independently.

Do not mark this plan complete until the endpoints pass installed macOS and
Windows Host tests plus physical iOS and Android Controller tests across
separate public networks.
