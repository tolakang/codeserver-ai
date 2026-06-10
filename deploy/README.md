# Dokploy Deployment Guide

This guide explains how to deploy each service individually in Dokploy.

## Important: Select Correct Deployment Type

Dokploy has two deployment types. **You must select the correct one:**

| Deployment Type | Use For | What to Provide |
|----------------|---------|-----------------|
| **Docker Compose** | Individual service deployment | Compose file path (e.g., `deploy/docker-compose.freellmapi.yml`) |
| **Dockerfile** | Custom image builds | Dockerfile path (e.g., `Dockerfile.freellmapi`) |

**Do NOT select "Dockerfile" type and point it at a compose file. This causes the parse error.**

---

## Option 1: Docker Compose Type (Recommended)

This is the recommended approach for each service.

### Steps for Each Service

1. **Create Application** in Dokploy
2. **Select "Docker Compose"** as the deployment type
3. **Set the compose file path** to one of:
   - `deploy/docker-compose.code-server.yml`
   - `deploy/docker-compose.gitea.yml`
   - `deploy/docker-compose.freellmapi.yml`
   - `deploy/docker-compose.rustfs.yml`
4. **Configure environment variables** in the Dokploy UI
5. **Deploy**

> **Note for code-server:** Uses Docker named volumes for persistence (automatic, no host setup required). Works with Dokploy Volume Backups to RustFS/S3.

### Example: Deploying FreeLLMAPI

1. Create new application in Dokploy
2. Name: `freellmapi`
3. Deployment type: **Docker Compose**
4. Compose file: `deploy/docker-compose.freellmapi.yml`
5. Go to **Environment Variables** and add:
   ```
   ENCRYPTION_KEY=your-encryption-key
   OPENROUTER_API_KEY=your-openrouter-key
   FREELLM_VERSION=latest
   ```
6. Click **Deploy**

> **Note:** FreeLLMAPI uses named volumes (`freellmapi-data`, `freellmapi-config`) for persistence. These work with Dokploy Volume Backups to RustFS/S3.

### Example: Deploying Gitea

1. Create new application in Dokploy
2. Name: `gitea`
3. Deployment type: **Docker Compose**
4. Compose file: `deploy/docker-compose.gitea.yml`
5. Go to **Environment Variables** and add:
   ```
   GITEA_DOMAIN=gitea.yourdomain.com
   ```
6. Click **Deploy**

---

## Option 2: Dockerfile Type

Use this if you want to build custom images without compose.

### Steps for Each Service

1. **Create Application** in Dokploy
2. **Select "Dockerfile"** as the deployment type
3. **Set the Dockerfile path** to one of:
   - `Dockerfile.codeserver`
   - `Dockerfile.gitea`
   - `Dockerfile.freellmapi`
   - `Dockerfile.rustfs`
4. **Set build context** to `.` (repository root)
5. **Configure build args** if needed:
    - code-server: `CODESERVER_VERSION=4.123.0`  # TARGETARCH auto-detected by buildx
6. **Configure run settings** (ports, volumes, environment) in the Dokploy UI
7. **Deploy**

### Example: Deploying FreeLLMAPI via Dockerfile

1. Create new application in Dokploy
2. Name: `freellmapi`
3. Deployment type: **Dockerfile**
4. Dockerfile: `Dockerfile.freellmapi`
5. Build context: `.`
6. After build, go to **Configuration** and set:
   - Port: `3000`
   - Volume: `/mnt/storage/freellmapi/data:/app/server/data`
7. Go to **Environment Variables** and add:
   ```
   ENCRYPTION_KEY=your-encryption-key
   PORT=3000
   PUID=1000
   PGID=1000
   ```
8. Click **Deploy**

---

## Environment Variables by Dokploy Level

Set variables at the correct Dokploy level to avoid duplication:

### Environment Level (shared secrets)

```
OPENROUTER_API_KEY=your-openrouter-api-key
ANTHROPIC_API_KEY=your-anthropic-api-key
OPENAI_API_KEY=your-openai-api-key
GITHUB_TOKEN=your-github-token
ENCRYPTION_KEY=generate-with-openssl-rand-hex-32
RUSTFS_ACCESS_KEY=your-access-key
RUSTFS_SECRET_KEY=your-secret-key
```

### Project Level (shared config)

```
CS_PASSWORD=changeme
CODESERVER_VERSION=4.123.0
# TARGETARCH=amd64  # Auto-detected by Docker/buildx; do not override
GITEA_DOMAIN=gitea.yourdomain.com
RUSTFS_ENDPOINT=http://rustfs:9000
RUSTFS_BUCKET=code-server-backups
TZ=UTC
```

### Service Level (service-specific)

**Code Server:**
```
CS_DEFAULT_WORKSPACE=/workspace
```

**Gitea:**
```
GITEA_ADMIN_USER=admin
GITEA_ADMIN_PASSWORD=changeme
GITEA_ADMIN_EMAIL=admin@yourdomain.com
```

**FreeLLMAPI:**
```
FREELLM_VERSION=latest
GOOGLE_API_KEY=your-google-api-key
NIM_API_KEY=your-nvidia-nim-api-key
OPENCODE_ZEN_API_KEY=your-opencode-zen-api-key
```

**RustFS:**
```
RUSTFS_ROOT_USER=admin
RUSTFS_ROOT_PASSWORD=changeme
```

---

## Network Configuration

All services communicate over `codeserver-network`. This network must exist before deployment.

The compose files declare it as `external: true`, meaning it should be created first:

```bash
docker network create codeserver-network
```

Or let the first service deployment create it automatically.

---

## Troubleshooting

### Error: `dockerfile parse error on line 6: unknown instruction: services:`

**Cause:** You selected "Dockerfile" type in Dokploy but pointed it at a compose file.

**Fix:** Change the deployment type to "Docker Compose" or use the correct Dockerfile path.

### Error: `No such container: select-a-container`

**Cause:** The build failed, so the container was never created.

**Fix:** Check the build logs in Dokploy. Usually caused by the error above.

### Error: `network codeserver-network not found`

**Cause:** The Docker network doesn't exist yet.

**Fix:** Deploy one service first (it will create the network), or run:
```bash
docker network create codeserver-network
```

### Build fails with `COPY vendor/...: no such file or directory`

**Cause:** Source code not cloned during build.

**Fix:** This should not happen with the current Dockerfiles (they clone source at build time). If you see this error, ensure you're using the latest Dockerfiles from the repository.

---

## Architecture-Specific Notes

### code-server Multi-Arch Support

The code-server Dockerfile now automatically detects the target architecture via Docker's built-in `TARGETARCH` build argument (set by buildx during multi-platform builds).

**Do not set `TARGETARCH` manually:**
- ❌ Don't add `TARGETARCH` to build args in Dokploy
- ❌ Don't set `TARGETARCH` in Project/Environment variables
- ✅ Let Docker/buildx auto-detect it

**How it works:**
| Build Scenario | TARGETARCH Value |
|----------------|------------------|
| buildx multi-platform (amd64) | `amd64` |
| buildx multi-platform (arm64) | `arm64` |
| Single-platform on arm64 host | `arm64` |
| Single-platform on amd64 host | `amd64` |

**If you see architecture mismatch error:**
```
Arch mismatch: TARGETARCH=amd64, system=arm64
```
This means `TARGETARCH` was overridden. Remove any manual `TARGETARCH` setting from:
1. Dokploy build args
2. Project environment variables
3. `.env` file
