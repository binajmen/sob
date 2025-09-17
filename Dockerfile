ARG GLEAM_VERSION=v1.12.0

# Build stage - compile the application
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine AS builder

# Add project code
COPY ./shared /build/shared
COPY ./client /build/client
COPY ./server /build/server

# Install git, just, and wget for resolving dependencies and build tools
RUN apk add --no-cache git

# Install dependencies for all projects
RUN cd /build/shared && gleam deps download
RUN cd /build/client && gleam deps download
RUN cd /build/server && gleam deps download

# Compile the client code and output to server's static directory
RUN cd /build/client \
  && gleam add --dev lustre_dev_tools \
  && gleam run -m lustre/dev build app --minify \
  && cp -r /build/client/priv/static/* /build/server/priv/static/

# Compile the server code
RUN cd /build/server \
  && gleam export erlang-shipment

# Runtime stage - slim image with only what's needed to run
FROM ghcr.io/gleam-lang/gleam:${GLEAM_VERSION}-erlang-alpine

# Install runtime dependencies for migrations and build tools
RUN apk add --no-cache wget && \
    wget -O /usr/local/bin/dbmate https://github.com/amacneil/dbmate/releases/latest/download/dbmate-linux-amd64 && \
    chmod +x /usr/local/bin/dbmate

# Copy the compiled server code from the builder stage
COPY --from=builder /build/server/build/erlang-shipment /app

# Copy the startup script, justfiles, and database migrations
COPY start.sh /app/start.sh
COPY server/db /app/db

# Set up the entrypoint
WORKDIR /app
RUN chmod +x ./start.sh

# Set environment variables
ENV HOST=0.0.0.0
ENV PORT=8000

# Expose the port the server will run on
EXPOSE 8000

# Run the server
CMD ["./start.sh", "run"]
