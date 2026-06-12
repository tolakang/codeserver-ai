# Dokploy Deployment Guide

Each service has a standalone compose file. Deploy one Dokploy application per service.

## Applications

| Application | Compose File | Port |
|-------------|--------------|------|
| code-server | `deploy/docker-compose.code-server.yml` | 8443 |
| opencode-web | `deploy/docker-compose.opencode-web.yml` | 4001 |
| gitea | `deploy/docker-compose.gitea.yml` | 3001 |
| freellmapi | `deploy/docker-compose.freellmapi.yml` | 3000 |
| rustfs | `deploy/docker-compose.rustfs.yml` | 9000 |

## Deployment Steps

1. Create a new application in Dokploy.
2. Select **Docker Compose** as the deployment type.
3. Set the compose file path to one of the files above.
4. Add the required environment variables from `.env.example`.
5. Configure the reverse proxy:
   - Domain: your service domain
   - Port: service port
   - Upstream protocol: **HTTP**
   - Path: `/`
6. Deploy.

## Environment Variables

Set these variables in Dokploy's Environment Variables UI.

### Required for all services

```bash
TZ=UTC
```

### code-server

```bash
CS_PASSWORD=your-secure-password
CS_DEFAULT_WORKSPACE=/workspace
DEFAULT_PROVIDER=freellmapi
OPENCODE_MODEL=anthropic/claude-sonnet-4-6
FREELLMAPI_BASE_URL=http://freellmapi:3000/v1
FREELLMAPI_API_KEY=your-freellmapi-key
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_API_KEY=sk-your-openrouter-key
OPENCODE_ZEN_BASE_URL=https://opencode.ai/zen/api/v1
OPENCODE_ZEN_API_KEY=your-opencode-zen-key
ANTHROPIC_API_KEY=sk-ant-your-key
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_API_KEY=sk-your-openai-key
RUSTFS_ACCESS_KEY=your-access-key
RUSTFS_SECRET_KEY=your-secret-key
RUSTFS_ENDPOINT=http://rustfs:9000
RUSTFS_BUCKET=code-server-backups
ENCRYPTION_KEY=generate-with-openssl-rand-hex-32
POSTGRES_HOST=pgbouncer
POSTGRES_PORT=6432
POSTGRES_PASSWORD=your-postgres-password
CODESERVER_VERSION=4.123.0
```

### opencode-web

```bash
OPENCODE_SERVER_USERNAME=opencode
OPENCODE_SERVER_PASSWORD=your-opencode-password
OPENCODE_WEB_PORT=4001
OPENCODE_WEB_HOSTNAME=0.0.0.0
OPENCODE_MODEL=anthropic/claude-sonnet-4-6
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_API_KEY=sk-your-openrouter-key
OPENCODE_ZEN_BASE_URL=https://opencode.ai/zen/api/v1
OPENCODE_ZEN_API_KEY=your-opencode-zen-key
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_API_KEY=sk-your-openai-key
ANTHROPIC_API_KEY=sk-ant-your-key
FREELLMAPI_BASE_URL=http://freellmapi:3000/v1
FREELLMAPI_API_KEY=your-freellmapi-key
OPENCODE_VERSION=latest
```

### freellmapi

```bash
ENCRYPTION_KEY=generate-with-openssl-rand-hex-32
FREELLMAPI_VERSION=latest
```

### gitea

```bash
GITEA_DOMAIN=gitea.yourdomain.com
GITEA_ROOT_URL=https://gitea.yourdomain.com
GITEA_DB_USER=gitea
GITEA_DB_NAME=gitea
GITEA_ADMIN_USER=admin
GITEA_ADMIN_PASSWORD=your-gitea-password
GITEA_ADMIN_EMAIL=admin@yourdomain.com
POSTGRES_HOST=pgbouncer
POSTGRES_PORT=6432
POSTGRES_PASSWORD=your-postgres-password
GITEA_VERSION=1.23.0
```

### rustfs

```bash
RUSTFS_ROOT_USER=admin
RUSTFS_ROOT_PASSWORD=your-rustfs-password
```

## Local Docker Compose

Dokploy compose files use `${{project.VAR}}` placeholders. Plain Docker Compose does not expand them, so render a local compose file first:

```bash
./scripts/render-compose.sh deploy/docker-compose.opencode-web.yml docker-compose.opencode-web.local.yml
docker compose -f docker-compose.opencode-web.local.yml up -d
```

## Troubleshooting

### Bad Gateway

**Cause:** Reverse proxy is trying to reach the container over HTTPS while the container serves HTTP.

**Fix:** Set upstream protocol to **HTTP** in Dokploy and redeploy.

### OpenCode WEB `ServeError`

**Cause:** Missing `opencode.json` or missing provider configuration.

**Fix:** Ensure these env vars are set:

```bash
OPENCODE_SERVER_USERNAME=opencode
OPENCODE_SERVER_PASSWORD=your-opencode-password
OPENCODE_MODEL=anthropic/claude-sonnet-4-6
```

Then force rebuild the opencode-web app.

### Dockerfile parse error

**Cause:** Incorrect escaping in the Dockerfile.

**Fix:** Make sure every multi-line `RUN` instruction uses a single `\` at the end of each continued line.

## Architecture Notes

- code-server and RustFS Dockerfiles auto-detect the target architecture via Docker's built-in `TARGETARCH`.
- Do not set `TARGETARCH` manually unless you intentionally override the build platform.
- All services communicate over `codeserver-network`.
