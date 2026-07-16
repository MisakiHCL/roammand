# SPDX-License-Identifier: AGPL-3.0-only

FROM golang:1.26.5-alpine3.24 AS build

WORKDIR /src
COPY gen/go/go.mod gen/go/go.sum ./gen/go/
COPY services/signaling/go.mod services/signaling/go.sum ./services/signaling/
WORKDIR /src/services/signaling
RUN go mod download

COPY gen/go /src/gen/go
COPY services/signaling /src/services/signaling
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/roammand-signaling \
    ./cmd/signaling

FROM alpine:3.24.1

WORKDIR /app
COPY --from=build /out/roammand-signaling /usr/local/bin/roammand-signaling

USER 65532:65532
EXPOSE 8443
ENTRYPOINT ["/usr/local/bin/roammand-signaling"]
