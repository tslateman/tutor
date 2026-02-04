# Docker Cheat Sheet

## Images

### Listing & Inspecting

```bash
docker images                    # List images
docker images -a                 # Include intermediate
docker image ls                  # Same as above

docker inspect image_name        # Detailed info
docker history image_name        # Layer history
```

### Building

```bash
docker build .                   # Build from Dockerfile in current dir
docker build -t myapp:1.0 .      # With tag
docker build -t myapp:latest -t myapp:1.0 .  # Multiple tags
docker build -f Dockerfile.dev . # Specify Dockerfile
docker build --no-cache .        # Ignore cache
docker build --target stage .    # Build specific stage (multi-stage)
docker build --build-arg VAR=value .  # Pass build argument

# BuildKit (faster, better caching)
DOCKER_BUILDKIT=1 docker build .
```

### Pulling & Pushing

```bash
docker pull nginx                # Pull from Docker Hub
docker pull nginx:1.24           # Specific tag
docker pull myregistry.com/image # From private registry

docker push myrepo/myimage:1.0   # Push to registry
docker tag myapp:1.0 myrepo/myapp:1.0  # Tag for pushing

docker login                     # Login to Docker Hub
docker login myregistry.com      # Login to private registry
docker logout
```

### Removing

```bash
docker rmi image_name            # Remove image
docker rmi image_id              # By ID
docker rmi -f image_name         # Force remove
docker image prune               # Remove dangling images
docker image prune -a            # Remove all unused images
```

## Containers

### Running

```bash
docker run nginx                 # Run container
docker run -d nginx              # Detached (background)
docker run -it ubuntu bash       # Interactive with TTY
docker run --name mycontainer nginx  # Named container
docker run -p 8080:80 nginx      # Port mapping host:container
docker run -P nginx              # Map all exposed ports
docker run -v /host:/container nginx  # Volume mount
docker run -v myvolume:/data nginx    # Named volume
docker run -e VAR=value nginx    # Environment variable
docker run --env-file .env nginx # Env from file
docker run --rm nginx            # Remove when stopped
docker run --network mynet nginx # Attach to network
docker run --restart always nginx  # Restart policy
docker run -w /app node npm start  # Working directory
docker run -u 1000:1000 nginx    # Run as user:group
docker run --memory 512m nginx   # Memory limit
docker run --cpus 0.5 nginx      # CPU limit
docker run --entrypoint /bin/sh nginx  # Override entrypoint
```

### Managing

```bash
docker ps                        # List running containers
docker ps -a                     # Include stopped
docker ps -q                     # IDs only
docker ps -l                     # Last created

docker start container_name      # Start stopped container
docker stop container_name       # Stop container (graceful)
docker restart container_name    # Restart
docker kill container_name       # Force stop
docker pause container_name      # Pause
docker unpause container_name    # Unpause

docker rm container_name         # Remove stopped container
docker rm -f container_name      # Force remove running
docker container prune           # Remove all stopped
```

### Interacting

```bash
docker exec -it container bash   # Execute command in running container
docker exec container ls /app    # Non-interactive command
docker exec -u root container cmd  # As specific user

docker attach container          # Attach to running container
# Detach: Ctrl+P, Ctrl+Q

docker logs container            # View logs
docker logs -f container         # Follow logs
docker logs --tail 100 container # Last 100 lines
docker logs --since 1h container # Last hour
docker logs -t container         # With timestamps

docker top container             # Running processes
docker stats                     # Live resource usage
docker stats container           # Specific container
docker inspect container         # Detailed info
docker port container            # Port mappings
docker diff container            # Filesystem changes

docker cp container:/path ./local  # Copy from container
docker cp ./local container:/path  # Copy to container
```

### Creating Images from Containers

```bash
docker commit container newimage:tag
docker export container > backup.tar    # Export filesystem
docker import backup.tar newimage:tag   # Import as image
```

## Dockerfile

### Basic Structure

```dockerfile
# Base image
FROM node:18-alpine

# Metadata
LABEL maintainer="you@example.com"
LABEL version="1.0"

# Set working directory
WORKDIR /app

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Build arguments
ARG VERSION=latest

# Copy files
COPY package*.json ./
COPY . .

# Run commands during build
RUN npm install --production
RUN npm run build

# Expose port (documentation)
EXPOSE 3000

# Default command
CMD ["node", "server.js"]

# Or use ENTRYPOINT for fixed command
ENTRYPOINT ["node"]
CMD ["server.js"]
```

### Multi-stage Build

```dockerfile
# Build stage
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

### Best Practices

```dockerfile
# Use specific tags, not :latest
FROM node:18.17-alpine

# Combine RUN commands to reduce layers
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git && \
    rm -rf /var/lib/apt/lists/*

# Copy dependency files first (cache optimization)
COPY package*.json ./
RUN npm ci --only=production
COPY . .

# Use non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Use .dockerignore to exclude files
# node_modules, .git, *.log, etc.
```

### Instructions Reference

| Instruction   | Purpose                            |
| ------------- | ---------------------------------- |
| `FROM`        | Base image                         |
| `WORKDIR`     | Set working directory              |
| `COPY`        | Copy files from host               |
| `ADD`         | Copy with auto-extract/URL support |
| `RUN`         | Execute command during build       |
| `ENV`         | Set environment variable           |
| `ARG`         | Build-time variable                |
| `EXPOSE`      | Document exposed port              |
| `CMD`         | Default command (overridable)      |
| `ENTRYPOINT`  | Fixed command                      |
| `VOLUME`      | Create mount point                 |
| `USER`        | Set user for subsequent commands   |
| `LABEL`       | Add metadata                       |
| `HEALTHCHECK` | Container health check             |
| `SHELL`       | Override default shell             |

## Volumes

```bash
# Create volume
docker volume create myvolume

# List volumes
docker volume ls

# Inspect volume
docker volume inspect myvolume

# Remove volume
docker volume rm myvolume
docker volume prune              # Remove unused volumes

# Use in container
docker run -v myvolume:/data nginx
docker run -v /host/path:/container/path nginx  # Bind mount
docker run -v /host/path:/container/path:ro nginx  # Read-only
```

## Networks

```bash
# List networks
docker network ls

# Create network
docker network create mynetwork
docker network create --driver bridge mynetwork
docker network create --subnet 172.20.0.0/16 mynetwork

# Inspect network
docker network inspect mynetwork

# Connect/disconnect container
docker network connect mynetwork container
docker network disconnect mynetwork container

# Remove network
docker network rm mynetwork
docker network prune             # Remove unused

# Run container on network
docker run --network mynetwork nginx
docker run --network mynetwork --network-alias db postgres

# Container communication
# Containers on same network can reach each other by name
docker run --network mynetwork --name web nginx
docker run --network mynetwork --name api node
# 'web' can reach 'api' via http://api:port
```

### Network Drivers

| Driver    | Use Case                                      |
| --------- | --------------------------------------------- |
| `bridge`  | Default, isolated network on single host      |
| `host`    | Share host's network (no isolation)           |
| `none`    | No networking                                 |
| `overlay` | Multi-host networking (Swarm)                 |
| `macvlan` | Assign MAC address, appear as physical device |

## Docker Compose

### docker-compose.yml

```yaml
version: "3.8"

services:
  web:
    build: .
    # Or use image:
    # image: nginx:latest
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgres://db:5432/mydb
    env_file:
      - .env
    volumes:
      - ./src:/app/src
      - node_modules:/app/node_modules
    depends_on:
      - db
      - redis
    networks:
      - frontend
      - backend
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  db:
    image: postgres:15
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: mydb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - backend

  redis:
    image: redis:7-alpine
    networks:
      - backend

volumes:
  node_modules:
  postgres_data:

networks:
  frontend:
  backend:
```

### Commands

```bash
# Start services
docker compose up                # Foreground
docker compose up -d             # Detached
docker compose up --build        # Rebuild images
docker compose up service_name   # Specific service

# Stop services
docker compose down              # Stop and remove
docker compose down -v           # Also remove volumes
docker compose down --rmi all    # Also remove images
docker compose stop              # Stop only (keep containers)

# Manage services
docker compose ps                # List containers
docker compose logs              # View logs
docker compose logs -f service   # Follow specific service
docker compose exec service bash # Execute in running service
docker compose run service cmd   # Run one-off command

# Build
docker compose build             # Build all
docker compose build service     # Build specific

# Scale
docker compose up -d --scale web=3

# Other
docker compose config            # Validate and view config
docker compose pull              # Pull images
docker compose restart           # Restart services
```

### Multiple Compose Files

```bash
# Override with additional file
docker compose -f docker-compose.yml -f docker-compose.prod.yml up

# Use .env file
# docker-compose.yml can use ${VAR} syntax
# Values loaded from .env automatically
```

## System & Cleanup

```bash
# System info
docker info
docker version

# Disk usage
docker system df
docker system df -v              # Verbose

# Clean up
docker system prune              # Remove unused data
docker system prune -a           # More aggressive
docker system prune -a --volumes # Include volumes

# Individual cleanup
docker container prune           # Stopped containers
docker image prune               # Dangling images
docker image prune -a            # All unused images
docker volume prune              # Unused volumes
docker network prune             # Unused networks
```

## Registry & Repository

```bash
# Search Docker Hub
docker search nginx

# Save/load images (for offline transfer)
docker save -o image.tar myimage:tag
docker load -i image.tar

# Run local registry
docker run -d -p 5000:5000 --name registry registry:2
docker tag myimage localhost:5000/myimage
docker push localhost:5000/myimage
```

## Debugging

```bash
# Container won't start
docker logs container
docker inspect container

# Enter failed container
docker commit failed_container debug_image
docker run -it debug_image sh

# Check resource usage
docker stats

# Inspect networking
docker network inspect bridge
docker exec container cat /etc/hosts

# Check mounts
docker inspect -f '{{ .Mounts }}' container

# Events
docker events                    # Real-time events
docker events --since 1h
```

## Quick Reference

| Task                 | Command                         |
| -------------------- | ------------------------------- |
| Build image          | `docker build -t name .`        |
| Run container        | `docker run -d -p 8080:80 name` |
| List containers      | `docker ps -a`                  |
| List images          | `docker images`                 |
| Stop container       | `docker stop name`              |
| Remove container     | `docker rm name`                |
| Remove image         | `docker rmi name`               |
| View logs            | `docker logs -f name`           |
| Shell into container | `docker exec -it name bash`     |
| Copy files           | `docker cp name:/path ./local`  |
| Compose up           | `docker compose up -d`          |
| Compose down         | `docker compose down`           |
| Clean up             | `docker system prune -a`        |
