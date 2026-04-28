FROM golang:1.25-alpine AS builder

RUN apk add --no-cache git make

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN make build

FROM alpine:3.23

RUN apk add --no-cache ca-certificates tzdata curl

COPY --from=builder /src/build/picoclaw /usr/local/bin/picoclaw
COPY docker/entrypoint.sh /entrypoint.sh
COPY railway-start.sh /railway-start.sh
RUN chmod +x /entrypoint.sh /railway-start.sh

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget -q --spider http://localhost:${PORT:-18790}/health || exit 1

CMD ["/railway-start.sh"]
