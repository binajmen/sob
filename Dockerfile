# Multi-stage Dockerfile for Gleam full-stack application
# Stage 1: Build environment
FROM ghcr.io/gleam-lang/gleam:v1.5.0-erlang-alpine AS builder

# Install Node.js for client build (Lustre dev tools)
RUN apk add --no-cache nodejs npm

# Set working directory
WORKDIR /build

# Copy package files first for better Docker layer caching
COPY shared/gleam.toml shared/gleam.toml
COPY client/gleam.toml client/gleam.toml
COPY server/gleam.toml server/gleam.toml

# Copy shared package (dependency for both client and server)
COPY shared/ shared/

# Copy client source
COPY client/src client/src
COPY client/assets client/assets

# Build client first (outputs to server/priv/static)
WORKDIR /build/client
RUN gleam deps download
RUN gleam run -m lustre/dev build --minify --outdir=../server/priv/static

# Copy server source
WORKDIR /build
COPY server/src server/src
COPY server/priv server/priv

# Build server
WORKDIR /build/server
RUN gleam deps download
RUN gleam build

# Stage 2: Runtime
FROM ghcr.io/gleam-lang/gleam:v1.5.0-erlang-alpine AS runtime

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S gleam && \
    adduser -S gleam -u 1001 -G gleam

# Set working directory
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder --chown=gleam:gleam /build/server/build /app/build
COPY --from=builder --chown=gleam:gleam /build/server/priv /app/priv
COPY --from=builder --chown=gleam:gleam /build/shared /app/shared

# Copy server gleam.toml for runtime dependencies
COPY --from=builder --chown=gleam:gleam /build/server/gleam.toml /app/gleam.toml

# Switch to non-root user
USER gleam

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8000/api/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Start the application
CMD ["gleam", "run"]