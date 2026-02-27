# ── Stage 1: Build ──────────────────────────────────────────
FROM golang:1.24-alpine AS builder

RUN apk add --no-cache git

WORKDIR /app

# Copy dependency files first for better layer caching
COPY server/go.mod server/go.sum ./
RUN go mod download

# Copy the rest of the source code
COPY server/ .

# Build a statically linked binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/main ./cmd/api/main.go

# ── Stage 2: Runtime ────────────────────────────────────────
FROM alpine:3.19

RUN apk add --no-cache ca-certificates tzdata

LABEL maintainer="Inventify Team"

WORKDIR /app

# Copy the compiled binary from builder
COPY --from=builder /app/main .

# Expose the default API port
EXPOSE 8080

# Run as non-root user for security
RUN adduser -D -g '' appuser
USER appuser

# Environment variables should be injected at runtime via
# docker-compose.yml or `docker run -e`, NOT baked into the image.

CMD ["./main"]
