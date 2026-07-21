# SPDX-License-Identifier: AGPL-3.0-only

FROM golang:1.26.5-alpine3.24@sha256:0178a641fbb4858c5f1b48e34bdaabe0350a330a1b1149aabd498d0699ff5fb2 AS build

WORKDIR /src
COPY gen/go/go.mod gen/go/go.sum ./gen/go/
COPY services/signaling/go.mod services/signaling/go.sum ./services/signaling/
WORKDIR /src/services/signaling
RUN go mod download
RUN go mod verify

COPY gen/go /src/gen/go
COPY services/signaling /src/services/signaling
RUN CGO_ENABLED=0 GOOS=linux go build \
    -mod=readonly \
    -buildvcs=false \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/roammand-signaling \
    ./cmd/signaling

FROM alpine:3.24.1@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

WORKDIR /app
COPY --from=build /out/roammand-signaling /usr/local/bin/roammand-signaling

USER 65532:65532
EXPOSE 8443
ENTRYPOINT ["/usr/local/bin/roammand-signaling"]
