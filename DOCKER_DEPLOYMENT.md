# Docker Deployment Guide

This guide explains how to deploy the SOB Gleam application using Docker.

## Quick Start

1. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

2. **Run with Docker Compose:**
   ```bash
   just up
   ```

3. **Access the application:**
   - Application: http://localhost:3000
   - Direct server access: http://localhost:8000

## Architecture

- **Multi-stage Dockerfile:** Builds client (Lustre) and server (Erlang/OTP) in optimized layers
- **Client Build:** Compiles to static assets placed in `server/priv/static`
- **Server:** Serves both API endpoints and static files
- **Database:** PostgreSQL with automatic migrations
- **Proxy:** Caddy handles HTTPS and routing

## Environment Configuration

### Development (.env)
```bash
PGHOST=localhost
PGDATABASE=sob_dev
PGUSER=postgres
PGPASSWORD=password
PGPORT=5432
HOST=localhost
PORT=8000
```

### Production (.env.production)
```bash
PGHOST=your-production-db-host
PGDATABASE=sob_production
PGUSER=your_db_user
PGPASSWORD=secure_password
PGPORT=5432
HOST=0.0.0.0
PORT=8000
```

## Available Commands

### Local Development
- `just run` - Run locally without Docker
- `just client build-dev` - Build client for development
- `just server run` - Run server locally

### Docker Development
- `just up` - Start all services with Docker Compose
- `just down` - Stop all services
- `just logs` - View application logs
- `just restart` - Restart the application service

### Docker Production
- `just docker-build` - Build production Docker image
- `just docker-run` - Run single container with .env file
- `just prod-build` - Build production-tagged image
- `just prod-run` - Run production container

### Cleanup
- `just clean` - Remove containers, images, and volumes

## Deployment Steps

### 1. Local Development
```bash
# Start development environment
just up

# Check logs
just logs

# Make changes and restart
just restart
```

### 2. Production Deployment
```bash
# Build production image
just prod-build

# Run in production mode
just prod-run
```

### 3. Server Deployment (following Gleam Linux guide)

1. **Build and push to registry:**
   ```bash
   docker build -t your-registry/sob-app:latest .
   docker push your-registry/sob-app:latest
   ```

2. **Deploy with Podman (recommended):**
   ```bash
   podman run -d \
     --name sob-app \
     -p 8000:8000 \
     --env-file .env.production \
     --restart=unless-stopped \
     your-registry/sob-app:latest
   ```

3. **Set up reverse proxy (Caddy):**
   ```
   your-domain.com {
       reverse_proxy localhost:8000
   }
   ```

## Health Checks

The application includes health checks:
- **Docker:** `wget http://localhost:8000/api/health`
- **Compose:** Automatic health monitoring with retries

## Troubleshooting

### Common Issues

1. **Port conflicts:**
   - Change ports in docker-compose.yml
   - Check if ports 3000, 5432, or 8000 are in use

2. **Database connection:**
   - Ensure database service is healthy
   - Check environment variables
   - Verify database credentials

3. **Build failures:**
   - Clear Docker cache: `docker system prune -f`
   - Check .dockerignore isn't excluding needed files
   - Ensure all dependencies are available

### Logs and Debugging
```bash
# View all logs
just logs

# View specific service logs
docker compose logs -f app
docker compose logs -f database

# Debug inside container
docker compose exec app sh
```

## File Structure

```
├── Dockerfile              # Multi-stage build configuration
├── .dockerignore           # Files excluded from Docker context
├── docker-compose.yml      # Development orchestration
├── Caddyfile              # Reverse proxy configuration
├── .env.example           # Development environment template
├── .env.production.example # Production environment template
└── justfile               # Build and deployment commands
```

## Security Notes

- Server binds to `0.0.0.0` in production for container networking
- Uses non-root user in container for security
- Environment variables should be properly secured in production
- Health checks ensure application availability
- Proper signal handling with dumb-init