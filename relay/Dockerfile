# syntax=docker/dockerfile:1

FROM golang:1.25-alpine AS build

ARG VERSION=dev

RUN apk add --no-cache ca-certificates

WORKDIR /src

# Copy the manifests first so dependency download is cached independently of
# source changes.
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# CGO is off so the result is a static binary that runs on any base image,
# including scratch.
ENV CGO_ENABLED=0
RUN go build -trimpath -ldflags "-s -w -X main.version=${VERSION}" -o /out/relayd ./cmd/relayd

FROM scratch

COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /out/relayd /relayd

# Runs unprivileged: the process needs no filesystem access at all, since file
# content is never written to disk.
USER 65534:65534

EXPOSE 8443
ENTRYPOINT ["/relayd"]
