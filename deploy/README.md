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
    FREELLMAPI_VERSION=latest
   ```
   > Provider API keys are configured through the FreeLLMAPI dashboard after deployment, not as environment variables.
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
   > Provider API keys are configured through the FreeLLMAPI dashboard after deployment, not as environment variables.
8. Click **Deploy**

---

## Environment Variables

Set these variables in Dokploy's Environment Variables UI. The `${{project.*}}` placeholders in docker-compose files will resolve to these values at deploy time.

### Complete Variable Reference

All variables from `.env.example` must be set in Dokploy. Here's the complete list:

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `TZ` | Timezone | `UTC` | Yes |
| `CS_PASSWORD` | Code Server authentication password | `your-secure-password` | Yes |
| `CS_DEFAULT_WORKSPACE` | Default workspace path | `/workspace` | Yes |
| `DEFAULT_PROVIDER` | AI provider | `freellmapi` | Yes |
| `OPENROUTER_BASE_URL` | OpenRouter API base URL | `https://openrouter.ai/api/v1` | Yes |
| `OPENROUTER_API_KEY` | OpenRouter API key | `sk-your-openrouter-key` | Yes |
| `OPENCODE_ZEN_BASE_URL` | OpenCode Zen API base URL | `https://opencode.ai/zen/api/v1` | Yes |
| `OPENCODE_ZEN_API_KEY` | OpenCode Zen API key | `your-opencode-zen-key` | Yes |
| `FREELLMAPI_BASE_URL` | FreeLLMAPI API base URL | `http://freellmapi:3000/v1` | Yes |
| `FREELLMAPI_API_KEY` | FreeLLMAPI API key | `your-freellmapi-key` | Yes |
| `ANTHROPIC_BASE_URL` | Anthropic API base URL | `https://api.anthropic.com` | Yes |
| `ANTHROPIC_API_KEY` | Anthropic API key | `sk-ant-your-key` | Yes |
| `OPENAI_BASE_URL` | OpenAI API base URL | `https://api.openai.com/v1` | Yes |
| `OPENAI_API_KEY` | OpenAI API key | `sk-your-openai-key` | Yes |
| `RUSTFS_ACCESS_KEY` | RustFS S3 access key | `your-access-key` | Yes |
| `RUSTFS_SECRET_KEY` | RustFS S3 secret key | `your-secret-key` | Yes |
| `RUSTFS_ENDPOINT` | RustFS endpoint | `http://rustfs:9000` | Yes |
| `RUSTFS_BUCKET` | RustFS bucket name | `code-server-backups` | Yes |
| `RUSTFS_ROOT_USER` | RustFS root username | `admin` | Yes |
| `RUSTFS_ROOT_PASSWORD` | RustFS root password | `your-rustfs-password` | Yes |
| `ENCRYPTION_KEY` | FreeLLMAPI encryption key | `openssl rand -hex 32` | Yes |
| `GITEA_DOMAIN` | Gitea hostname | `gitea.yourdomain.com` | Yes |
| `GITEA_ROOT_URL` | Gitea public root URL including protocol | `https://gitea.yourdomain.com` | Yes |
| `GITEA_DB_USER` | Gitea database user | `gitea` | Yes |
| `GITEA_DB_NAME` | Gitea database name | `gitea` | Yes |
| `GITEA_ADMIN_USER` | Gitea admin username | `admin` | Yes |
| `GITEA_ADMIN_PASSWORD` | Gitea admin password | `your-gitea-password` | Yes |
| `GITEA_ADMIN_EMAIL` | Gitea admin email | `admin@yourdomain.com` | Yes |
| `POSTGRES_PASSWORD` | PostgreSQL password for Gitea | `your-postgres-password` | Yes |
| `OPENCODE_SERVER_USERNAME` | OpenCode WEB username | `opencode` | Yes |
| `OPENCODE_SERVER_PASSWORD` | OpenCode WEB password | `your-opencode-password` | Yes |
| `CODESERVER_VERSION` | Code Server version | `4.123.0` | Yes |
| `GITEA_VERSION` | Gitea version | `1.23.0` | Yes |
| `FREELLMAPI_VERSION` | FreeLLMAPI version | `latest` | Yes |
| `OPENCODE_VERSION` | OpenCode WEB version | `latest` | Yes |

---

## Network Configuration

All services communicate over `codeserver-network`. This network must exist before deployment.

The compose files declare it as `external: true`, so create it before deploying services:

```bash
docker network create codeserver-network
```

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
