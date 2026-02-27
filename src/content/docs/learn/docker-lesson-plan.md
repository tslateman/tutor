---
title: "Docker Lesson Plan"
description:
  Eight lessons from images and layers to Compose and security in Docker.
---

A progressive curriculum to master Docker through hands-on practice.

<!-- prettier-ignore -->
:::note[Prerequisites]
Comfortable with [Unix CLI](../how/unix.md) and
[Shell Scripting](../how/shell.md).
:::

## Lesson 1: Images and Layers

**Goal:** Understand how Docker images work and how layers affect builds.

### Concepts

A Docker image is a read-only template built from layers. Each instruction in a
Dockerfile creates a layer. Layers are cached — unchanged layers skip
rebuilding.

Key terms:

- **Image** — a snapshot of a filesystem plus metadata (entrypoint, env vars)
- **Layer** — a diff on top of the previous layer, produced by one Dockerfile
  instruction
- **Tag** — a human-readable label pointing to a specific image (e.g.,
  `nginx:1.25-alpine`)
- **Digest** — an immutable SHA256 hash identifying an exact image

```text
┌─────────────────────────┐
│   CMD ["nginx", "-g"]   │  ← metadata layer
├─────────────────────────┤
│   COPY index.html       │  ← your code
├─────────────────────────┤
│   RUN apt-get install   │  ← dependencies
├─────────────────────────┤
│   FROM ubuntu:22.04     │  ← base image
└─────────────────────────┘
```

### Exercises

1. **Pull and list images**

   ```bash
   docker pull nginx:alpine
   docker pull python:3.12-slim
   docker images                    # List local images
   ```

2. **Inspect layers**

   ```bash
   docker history nginx:alpine      # Show layer stack
   docker inspect nginx:alpine      # Full metadata as JSON
   docker inspect --format '{{.Config.Cmd}}' nginx:alpine
   ```

3. **Compare image sizes**

   ```bash
   docker pull node:22              # Full image
   docker pull node:22-alpine       # Alpine variant
   docker images node               # Compare sizes
   ```

4. **Clean up**

   ```bash
   docker rmi node:22               # Remove specific image
   docker image prune               # Remove dangling images
   ```

### Checkpoint

Run `docker history` on two images. Explain why Alpine images are smaller (musl
libc, no extras) and why layer count matters for cache hits.

---

## Lesson 2: Running Containers

**Goal:** Run, manage, and inspect containers through their full lifecycle.

### Concepts

A container is a running instance of an image. It adds a writable layer on top
of the image's read-only layers. When the container stops, the writable layer
persists until the container is removed.

Container lifecycle: `create → start → running → stop → removed`

### Exercises

1. **Run your first container**

   ```bash
   docker run hello-world           # Pull + run + exit
   docker run -d --name web nginx   # Detached, named
   docker ps                        # Running containers
   docker ps -a                     # Include stopped
   ```

2. **Interact with a running container**

   ```bash
   docker exec -it web bash         # Shell into container
   ls /usr/share/nginx/html         # Browse the filesystem
   exit

   docker logs web                  # View stdout/stderr
   docker logs -f web               # Follow (like tail -f)
   docker top web                   # Processes inside
   docker stats web                 # Live CPU/memory
   ```

3. **Port mapping and environment variables**

   ```bash
   docker run -d --name web2 \
     -p 8080:80 \
     -e NGINX_HOST=localhost \
     nginx
   curl http://localhost:8080       # Hit the container
   docker port web2                 # Show port mappings
   ```

4. **Stop, restart, remove**

   ```bash
   docker stop web                  # Graceful (SIGTERM)
   docker start web                 # Restart stopped container
   docker kill web2                 # Force (SIGKILL)
   docker rm web web2               # Remove containers
   docker run --rm nginx echo "hi"  # Auto-remove on exit
   ```

### Checkpoint

Run an nginx container with port 8080 mapped to port 80. Curl it. Shell in with
`exec`. Stop and remove it. `docker ps -a` shows nothing.

---

## Lesson 3: Writing Dockerfiles

**Goal:** Write efficient Dockerfiles with proper layer ordering and security.

### Concepts

A Dockerfile is a recipe for building an image. Each instruction creates a
layer. Order matters for caching: put things that change rarely at the top,
things that change often at the bottom.

Key instructions:

| Instruction   | Purpose                          |
| ------------- | -------------------------------- |
| `FROM`        | Base image                       |
| `WORKDIR`     | Set working directory            |
| `COPY`        | Copy files from host             |
| `RUN`         | Execute command during build     |
| `ENV`         | Set environment variable         |
| `EXPOSE`      | Document exposed port            |
| `CMD`         | Default command (overridable)    |
| `ENTRYPOINT`  | Fixed command                    |
| `USER`        | Set user for subsequent commands |
| `ARG`         | Build-time variable              |
| `HEALTHCHECK` | Container health check           |

### Exercises

1. **Create a simple app and Dockerfile**

   ```bash
   mkdir docker-lesson && cd docker-lesson
   echo '<h1>Hello Docker</h1>' > index.html
   ```

   ```dockerfile
   # Dockerfile
   FROM nginx:alpine
   COPY index.html /usr/share/nginx/html/index.html
   EXPOSE 80
   ```

   ```bash
   docker build -t my-site .
   docker run -d -p 8080:80 --name site my-site
   curl http://localhost:8080
   docker rm -f site
   ```

2. **Optimize layer caching**

   ```dockerfile
   FROM node:22-alpine
   WORKDIR /app

   # Dependencies first (changes rarely)
   COPY package*.json ./
   RUN npm ci --only=production

   # Code last (changes often)
   COPY . .

   EXPOSE 3000
   CMD ["node", "server.js"]
   ```

   Change a source file and rebuild. The `npm ci` layer caches.

3. **Add a .dockerignore**

   ```text
   # .dockerignore
   .git
   node_modules
   *.md
   .env
   Dockerfile
   ```

   ```bash
   docker build -t my-app .
   # Build context is smaller — faster builds
   ```

4. **Run as non-root**

   ```dockerfile
   FROM node:22-alpine
   WORKDIR /app
   COPY --chown=node:node . .
   RUN npm ci --only=production
   USER node
   CMD ["node", "server.js"]
   ```

### Checkpoint

Build an image. Change only a source file and rebuild — the dependency layer
must cache (look for `CACHED` in build output). Verify the container runs as a
non-root user with `docker exec <container> whoami`.

---

## Lesson 4: Multi-Stage Builds

**Goal:** Separate build and runtime environments to reduce image size.

### Concepts

Multi-stage builds use multiple `FROM` instructions. Each `FROM` starts a new
stage. You copy artifacts from earlier stages into the final image, leaving
build tools behind.

```text
┌──────────────────────┐    ┌──────────────────────┐
│     Build Stage      │    │    Runtime Stage      │
│ ──────────────────── │    │ ──────────────────── │
│ Full SDK/compiler    │    │ Minimal base image   │
│ Source code          │ ──→│ Compiled binary only  │
│ Dev dependencies     │    │ No build tools       │
│ ~800MB+              │    │ ~50MB                │
└──────────────────────┘    └──────────────────────┘
```

### Exercises

1. **Build a Go binary with multi-stage**

   ```bash
   mkdir multi-stage && cd multi-stage
   ```

   ```go
   // main.go
   package main

   import (
       "fmt"
       "net/http"
   )

   func main() {
       http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
           fmt.Fprintln(w, "Hello from multi-stage build")
       })
       http.ListenAndServe(":8080", nil)
   }
   ```

   ```bash
   go mod init multi-stage
   ```

   ```dockerfile
   # Build stage
   FROM golang:1.23 AS builder
   WORKDIR /app
   COPY go.mod main.go ./
   RUN CGO_ENABLED=0 go build -o server .

   # Runtime stage
   FROM alpine:3.20
   COPY --from=builder /app/server /server
   EXPOSE 8080
   CMD ["/server"]
   ```

   ```bash
   docker build -t multi-stage .
   docker images multi-stage        # Check the size
   ```

2. **Compare with single-stage**

   ```dockerfile
   # Dockerfile.single
   FROM golang:1.23
   WORKDIR /app
   COPY go.mod main.go ./
   RUN go build -o server .
   EXPOSE 8080
   CMD ["./server"]
   ```

   ```bash
   docker build -t single-stage -f Dockerfile.single .
   docker images | grep stage       # Compare sizes
   ```

3. **Multi-stage for Node.js**

   ```dockerfile
   FROM node:22 AS builder
   WORKDIR /app
   COPY package*.json ./
   RUN npm ci
   COPY . .
   RUN npm run build

   FROM node:22-alpine
   WORKDIR /app
   COPY --from=builder /app/dist ./dist
   COPY --from=builder /app/node_modules ./node_modules
   USER node
   EXPOSE 3000
   CMD ["node", "dist/server.js"]
   ```

4. **Build a specific stage**

   ```bash
   docker build --target builder -t my-app-builder .
   # Useful for CI: run tests in the build stage
   ```

### Checkpoint

Build both single-stage and multi-stage images for the Go app. The multi-stage
image should be 10x+ smaller. Explain why: the final image contains only the
binary, not the Go toolchain.

---

## Lesson 5: Volumes and Persistence

**Goal:** Persist data across container restarts using volumes and bind mounts.

### Concepts

Containers are ephemeral — data in the writable layer disappears when the
container is removed. Volumes solve this.

| Type         | What It Does                                 | Use Case                  |
| ------------ | -------------------------------------------- | ------------------------- |
| Named volume | Docker-managed directory on the host         | Database storage, caches  |
| Bind mount   | Maps a specific host path into the container | Development (live reload) |
| tmpfs        | In-memory filesystem, never written to disk  | Secrets, scratch space    |

### Exercises

1. **Named volumes**

   ```bash
   docker volume create mydata
   docker volume ls
   docker volume inspect mydata

   # Write data
   docker run --rm -v mydata:/data alpine sh -c 'echo "persisted" > /data/test.txt'

   # Read from a new container
   docker run --rm -v mydata:/data alpine cat /data/test.txt
   # Output: persisted
   ```

2. **Bind mounts for development**

   ```bash
   mkdir -p ~/docker-dev && echo '<h1>Live reload</h1>' > ~/docker-dev/index.html

   docker run -d --name dev \
     -v ~/docker-dev:/usr/share/nginx/html:ro \
     -p 8080:80 nginx

   curl http://localhost:8080
   # Edit ~/docker-dev/index.html — changes appear immediately
   echo '<h1>Updated</h1>' > ~/docker-dev/index.html
   curl http://localhost:8080

   docker rm -f dev
   ```

3. **Database with persistent volume**

   ```bash
   docker run -d --name pg \
     -e POSTGRES_PASSWORD=secret \
     -v pgdata:/var/lib/postgresql/data \
     postgres:16-alpine

   # Create data
   docker exec -it pg psql -U postgres -c "CREATE TABLE test (id int);"
   docker exec -it pg psql -U postgres -c "INSERT INTO test VALUES (1);"

   # Destroy and recreate container
   docker rm -f pg
   docker run -d --name pg2 \
     -e POSTGRES_PASSWORD=secret \
     -v pgdata:/var/lib/postgresql/data \
     postgres:16-alpine

   # Data survives
   docker exec -it pg2 psql -U postgres -c "SELECT * FROM test;"

   docker rm -f pg2
   ```

4. **Cleanup**

   ```bash
   docker volume rm mydata pgdata
   docker volume prune              # Remove all unused volumes
   ```

### Checkpoint

Create a named volume. Write a file from one container, read it from another.
Remove both containers and verify the data survives until the volume itself is
removed.

---

## Lesson 6: Networking

**Goal:** Connect containers to each other and to the host.

### Concepts

Docker creates isolated networks. Containers on the same network can reach each
other by name. Containers on different networks cannot communicate without
explicit configuration.

| Driver   | Purpose                                 |
| -------- | --------------------------------------- |
| `bridge` | Default; isolated network on one host   |
| `host`   | Share the host's network (no isolation) |
| `none`   | No networking                           |

### Exercises

1. **Default bridge network**

   ```bash
   # Containers on the default bridge can't resolve each other by name
   docker run -d --name web nginx
   docker run --rm alpine ping -c 2 web
   # Fails: "bad address 'web'"
   docker rm -f web
   ```

2. **Custom bridge network**

   ```bash
   docker network create mynet
   docker network ls

   docker run -d --name web --network mynet nginx
   docker run --rm --network mynet alpine ping -c 2 web
   # Succeeds: DNS resolution works on custom networks

   docker rm -f web
   ```

3. **Multi-container communication**

   ```bash
   docker network create app-net

   # Start a backend API
   docker run -d --name api --network app-net \
     -e PORT=3000 nginx

   # Start a frontend that calls the API
   docker run --rm --network app-net alpine \
     wget -qO- http://api:80
   # Output: nginx default page — proves name resolution works

   docker rm -f api
   docker network rm app-net
   ```

4. **Inspect and debug networks**

   ```bash
   docker network create debug-net
   docker run -d --name debug-box --network debug-net alpine sleep 3600

   docker network inspect debug-net    # Show connected containers
   docker exec debug-box cat /etc/hosts
   docker exec debug-box nslookup debug-box

   docker rm -f debug-box
   docker network rm debug-net
   ```

### Checkpoint

Create a custom network. Run two containers on it. Prove they can reach each
other by name with `ping` or `wget`. Remove both and verify
`docker network inspect` shows no connected containers.

---

## Lesson 7: Docker Compose

**Goal:** Define and run multi-service applications with Compose.

### Concepts

Docker Compose describes a multi-container application in a single YAML file.
One command (`docker compose up`) creates networks, volumes, and containers for
the entire stack.

Compose handles:

- Service definitions (images, builds, ports, environment)
- Dependencies (`depends_on`)
- Shared networks (created automatically)
- Named volumes
- Development overrides

### Exercises

1. **Create a Compose file**

   ```bash
   mkdir compose-demo && cd compose-demo
   ```

   ```yaml
   # compose.yaml
   services:
     web:
       image: nginx:alpine
       ports:
         - "8080:80"
       volumes:
         - ./html:/usr/share/nginx/html:ro
       depends_on:
         - api

     api:
       image: python:3.12-alpine
       command: python -m http.server 5000
       expose:
         - "5000"
   ```

   ```bash
   mkdir html && echo '<h1>Compose works</h1>' > html/index.html
   docker compose up -d
   curl http://localhost:8080
   docker compose ps
   docker compose logs
   docker compose down
   ```

2. **Add a database**

   ```yaml
   # compose.yaml
   services:
     web:
       image: nginx:alpine
       ports:
         - "8080:80"

     db:
       image: postgres:16-alpine
       environment:
         POSTGRES_USER: app
         POSTGRES_PASSWORD: secret
         POSTGRES_DB: mydb
       volumes:
         - pgdata:/var/lib/postgresql/data

     redis:
       image: redis:7-alpine

   volumes:
     pgdata:
   ```

   ```bash
   docker compose up -d
   docker compose exec db psql -U app -d mydb -c "SELECT 1;"
   docker compose down
   docker compose down -v            # Also remove volumes
   ```

3. **Build from Dockerfile**

   ```yaml
   # compose.yaml
   services:
     app:
       build: .
       ports:
         - "3000:3000"
       volumes:
         - .:/app
         - /app/node_modules
       environment:
         - NODE_ENV=development
   ```

   ```bash
   docker compose up --build         # Build and start
   docker compose build              # Build only
   ```

4. **Useful Compose commands**

   ```bash
   docker compose up -d              # Start detached
   docker compose ps                 # List services
   docker compose logs -f web        # Follow one service
   docker compose exec web sh        # Shell into service
   docker compose restart api        # Restart one service
   docker compose stop               # Stop (keep containers)
   docker compose down               # Stop and remove
   docker compose config             # Validate YAML
   ```

### Checkpoint

Write a `compose.yaml` with nginx and postgres. Start both with
`docker compose up -d`. Connect to postgres with `docker compose exec`. Tear
down with `docker compose down -v`. No containers, no volumes remain.

---

## Lesson 8: Debugging and Security

**Goal:** Troubleshoot container failures and harden images for production.

### Concepts

Debugging containers requires different tools than debugging host processes. You
cannot SSH into a container — use `exec`, `logs`, and `inspect` instead.

Security starts at the Dockerfile. The attack surface of your container is the
sum of everything in the image.

### Exercises

1. **Debug a container that won't start**

   ```bash
   # Create a broken image
   echo 'FROM alpine' > Dockerfile.broken
   echo 'CMD ["nonexistent-command"]' >> Dockerfile.broken
   docker build -t broken -f Dockerfile.broken .

   docker run --name fail broken
   # Container exits immediately

   docker logs fail                  # See the error
   docker inspect fail --format '{{.State.ExitCode}}'

   # Enter the image to investigate
   docker run -it --entrypoint sh broken
   which nonexistent-command         # Not found
   exit

   docker rm fail
   ```

2. **Debug a running container**

   ```bash
   docker run -d --name debug-web nginx

   docker exec -it debug-web bash
   cat /etc/nginx/nginx.conf        # Check config
   curl localhost                    # Test from inside
   exit

   docker stats debug-web            # CPU and memory
   docker inspect debug-web --format '{{.NetworkSettings.IPAddress}}'
   docker diff debug-web             # Filesystem changes since start

   docker rm -f debug-web
   ```

3. **Copy files for analysis**

   ```bash
   docker run -d --name inspect-me nginx
   docker cp inspect-me:/etc/nginx/nginx.conf ./nginx.conf
   docker cp ./custom.conf inspect-me:/etc/nginx/conf.d/

   docker rm -f inspect-me
   ```

4. **Apply security best practices**

   ```dockerfile
   # Secure Dockerfile
   FROM node:22-alpine

   # Non-root user
   RUN addgroup -g 1001 -S app && \
       adduser -u 1001 -S app -G app
   WORKDIR /app

   # Dependencies (owned by root, not writable by app)
   COPY package*.json ./
   RUN npm ci --only=production && npm cache clean --force

   # Source (owned by app user)
   COPY --chown=app:app . .

   USER app

   HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
     CMD wget -qO- http://localhost:3000/health || exit 1

   EXPOSE 3000
   CMD ["node", "server.js"]
   ```

   Security checklist:

   | Practice                 | Why                                       |
   | ------------------------ | ----------------------------------------- |
   | Use Alpine or distroless | Fewer packages = smaller attack surface   |
   | Run as non-root          | Limits blast radius if compromised        |
   | Pin image versions       | Reproducible builds, no surprise changes  |
   | Add HEALTHCHECK          | Orchestrators detect unhealthy containers |
   | Scan images              | `docker scout cves` or Trivy catches CVEs |
   | No secrets in image      | Use runtime injection or BuildKit secrets |

5. **Scan an image**

   ```bash
   docker scout cves nginx:alpine   # Built-in scanner
   # Or with Trivy:
   # trivy image nginx:alpine
   ```

6. **Set resource limits**

   ```bash
   docker run -d --name limited \
     --memory 256m \
     --cpus 0.5 \
     nginx

   docker stats limited              # Verify limits
   docker rm -f limited
   ```

### Checkpoint

Build the secure Dockerfile. Verify: non-root user (`whoami`), health check
passes (`docker inspect --format '{{.State.Health.Status}}'`), image is under
200MB (`docker images`).

---

## Practice Projects

### Project 1: Containerize a Python App

Write a Flask or FastAPI app. Create a Dockerfile with:

- Multi-stage build (install deps in build stage, copy to runtime)
- Non-root user
- Health check endpoint
- `.dockerignore` that excludes `.git`, `__pycache__`, `.venv`

Target: image under 100MB.

### Project 2: Multi-Service Compose Stack

Create a `compose.yaml` with:

- Web server (nginx) reverse-proxying to an API
- API service (Python or Node.js) connecting to a database
- PostgreSQL with a named volume
- Redis for caching
- Custom network separating frontend from backend

Verify: `docker compose up -d` starts everything; the web server reaches the
API; data survives `docker compose down` and `docker compose up -d`.

### Project 3: Debug a Broken Container

Given this deliberately broken Dockerfile, find and fix all issues:

```dockerfile
FROM ubuntu:latest
RUN apt-get install -y curl python3
COPY . .
ENV DB_PASSWORD=hunter2
CMD python3 app.py
```

Issues to find: missing `apt-get update`, `latest` tag, no `.dockerignore`, no
`WORKDIR`, secret in ENV, running as root, shell form CMD.

---

## Command Reference

| Stage    | Must Know                                                           |
| -------- | ------------------------------------------------------------------- |
| Beginner | `docker run` `docker ps` `docker stop` `docker rm` `docker images`  |
| Daily    | `docker build` `docker exec` `docker logs` `docker compose up/down` |
| Power    | `docker inspect` `docker stats` `docker network` `docker volume`    |
| Advanced | `docker scout` `docker buildx` `docker save/load` multi-stage       |

## See Also

- [Docker](../how/docker.md) — Quick reference: images, containers, Compose,
  networking
- [CLI Pipelines](../how/cli-pipelines.md) — Pipe composition used alongside
  Docker commands
- [Operating Systems Lesson Plan](operating-systems-lesson-plan.md) — Processes,
  namespaces, and cgroups that Docker builds on
- [Security Lesson Plan](security-lesson-plan.md) — Threat modeling and
  hardening beyond container scope
