# Code Server AI

Production-grade self-hosted Code Server with OpenCode AI integration, Gitea, FreeLLMAPI, and RustFS backups.

## Architecture

```
Internet
    |
    v
Dokploy
    |
    +-- code-server (port 8443)
    |       +-- OpenCode VS Code extension
    |       +-- OpenCode CLI in terminal
    |       +-- Mobile-responsive touch UI
    |       +-- Workspace persisted in Docker named volume `codeserver-ai-workspace`
    |
    +-- opencode-web (port 4001)
    |       +-- OpenCode Web UI
    |
    +-- gitea (port 3001)
    |       +-- Git repositories
    |       +-- PostgreSQL via PgBouncer
    |
    +-- freellmapi (port 3000)
    |       +-- Free model proxy
    |
    +-- rustfs (port 9000)
            +-- S3-compatible backups
```

## Services

| Service | Source | Build Method | Port |
|---------|--------|--------------|------|
| code-server | [coder/code-server](https://github.com/coder/code-server) | Official .deb releases | 8443 |
| opencode-web | [anomalyco/opencode](https://github.com/anomalyco/opencode) | `opencode-ai` npm package | 4001 |
| gitea | [go-gitea/gitea](https://github.com/go-gitea/gitea) | Source build | 3001 |
| freellmapi | [tashfeenahmed/freellmapi](https://github.com/tashfeenahmed/freellmapi) | Source build | 3000 |
| rustfs | [rustfs/rustfs](https://github.com/rustfs/rustfs) | Binary release | 9000 |

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/youruser/codeserver-ai.git
cd codeserver-ai
```

### 2. Deploy with Dokploy

Each service has its own standalone compose file in `deploy/`.

1. **Create one Dokploy application per service**
   - `code-server` → `deploy/docker-compose.code-server.yml`
   - `opencode-web` → `deploy/docker-compose.opencode-web.yml`
   - `gitea` → `deploy/docker-compose.gitea.yml`
   - `freellmapi` → `deploy/docker-compose.freellmapi.yml`
   - `rustfs` → `deploy/docker-compose.rustfs.yml`

2. **Set environment variables** in Dokploy using values from `.env.example`.

3. **Configure reverse proxy**
   - code-server upstream protocol: **HTTP**
   - opencode-web upstream protocol: **HTTP**
   - TLS termination should be handled by Dokploy / Let's Encrypt

4. **Deploy**

See [deploy/README.md](deploy/README.md) for the detailed Dokploy checklist.

### 3. OpenCode WEB

OpenCode WEB runs as a separate Dokploy application on port `4001`.

Access it at:

```text
https://opencodeweb.yourdomain.com
```

Required environment variables:

```bash
OPENCODE_SERVER_USERNAME=opencode
OPENCODE_SERVER_PASSWORD=your-opencode-password
OPENCODE_WEB_PORT=4001
OPENCODE_WEB_HOSTNAME=0.0.0.0
OPENCODE_MODEL=anthropic/claude-sonnet-4-6
```

OpenCode WEB generates `opencode.json` at runtime from environment variables. Provider configuration is stored in:

```text
/home/opencode/.config/opencode/opencode.json
```

### 4. Code Server OpenCode Integration

The code-server container installs the OpenCode VS Code extension and the `opencode` CLI. It generates provider configuration at startup.

Use OpenCode in the code-server terminal:

```bash
opencode
```

Provider config is shared by the extension and CLI at:

```text
/home/coder/.config/opencode/config.json
```

The default provider is controlled by:

```bash
DEFAULT_PROVIDER=freellmapi
```

Supported providers:

- `freellmapi`
- `openrouter`
- `opencode-zen`
- `anthropic`
- `openai`

### 5. Mobile Responsive Code Server

Code Server uses a mobile-responsive layout on small screens:

- Sidebar becomes an overlay instead of pushing content
- Activity bar and titlebar are hidden below `768px`
- Tabs and scrollbars use larger touch targets
- Inputs prevent iOS auto-zoom

Terminal copy/paste is enabled for OpenCode and shell usage:

```text
Select text: click and drag in the terminal
Copy: auto-copy on selection
Paste: Ctrl+Shift+V or right-click
iPad Ctrl+C: sends interrupt to terminal
```

## File Structure

```
/
├── Dockerfile.codeserver          ← builds code-server from .deb
├── Dockerfile.gitea               ← clones and builds gitea
├── Dockerfile.freellmapi          ← clones and builds freellmapi
├── Dockerfile.rustfs              ← downloads rustfs binary
├── Dockerfile.opencode-web        ← builds OpenCode WEB server
├── deploy/
│   ├── docker-compose.code-server.yml
│   ├── docker-compose.gitea.yml
│   ├── docker-compose.freellmapi.yml
│   ├── docker-compose.rustfs.yml
│   ├── docker-compose.opencode-web.yml
│   └── README.md                  ← deployment guide
├── scripts/
│   ├── backup.sh
│   ├── restore.sh
│   ├── init.sh
│   ├── install-extensions.sh
│   ├── configure-provider.sh
│   ├── generate-configs.sh
│   ├── resolve-env.sh
│   ├── render-compose.sh
│   └── update.sh
├── config/
│   ├── code-server/               ← code-server config
│   │   ├── custom/mobile.css      ← mobile touch layout
│   │   └── keybindings.json       ← iPad Ctrl+C interrupt
│   ├── opencode/                  ← OpenCode extension config
│   ├── opencode-web/              ← OpenCode WEB config
│   └── gitea/                     ← gitea config
├── docs/
│   └── backup.md
├── .env.example
├── README.md
└── LICENSE
```

## Environment Variable Workflow

This project uses `${{project.*}}` placeholders in Dokploy compose files. For local Docker Compose, render them with `scripts/render-compose.sh` so Docker Compose can resolve them as `${VAR}` from `.env`.

### Example

**In `deploy/docker-compose.opencode-web.yml`:**

```yaml
environment:
  - OPENCODE_MODEL=${{project.OPENCODE_MODEL}}
```

**In Dokploy Environment Variables:**

```bash
OPENCODE_MODEL=anthropic/claude-sonnet-4-6
```

**In container:**

```json
{
  "model": "anthropic/claude-sonnet-4-6"
}
```

### Local Docker Compose

Dokploy placeholders are not expanded by plain Docker Compose. Render a local compose file before running Docker Compose directly:

```bash
./scripts/render-compose.sh deploy/docker-compose.opencode-web.yml docker-compose.opencode-web.local.yml
docker compose -f docker-compose.opencode-web.local.yml up -d
```

## Update Procedures

### Update All Services

```bash
./scripts/update.sh all
```

### Update Specific Service

```bash
./scripts/update.sh code-server
./scripts/update.sh opencode-web
./scripts/update.sh gitea
./scripts/update.sh freellmapi
./scripts/update.sh rustfs
```

## Backup

Workspace files live under `/workspace` in the `codeserver-ai-workspace` Docker named volume. The backup scripts archive this path so code-server updates do not depend on container image contents.

See [docs/backup.md](docs/backup.md) for RustFS backup strategy.

Daily automated backups at 2 AM:

```bash
0 2 * * * docker exec code-server /scripts/backup.sh >> /tmp/backup.log 2>&1
```

## Documentation

- [Deployment Guide](deploy/README.md)
- [Backup Strategy](docs/backup.md)
- [Development Plan](development_plan.md)

## License

MIT
