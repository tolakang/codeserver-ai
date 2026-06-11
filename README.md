# Code Server on Dokploy

Production-grade self-hosted Code Server with AI integration, Gitea, and RustFS backups.

## Features

- Persistent Workspace
- OpenCode AI Integration
- OpenRouter Support
- FreeLLMAPI Free Models
- RustFS S3 Backup
- Claude Memory Persistence
- Self-hosted Gitea Git Server
- Auto-installed Extensions
- Built from Source (multi-arch: amd64/arm64 auto-detected)

## Architecture

```
Internet
    |
    v
Dokploy
    |
    +-- Code Server (port 8443 HTTPS)
    |       +-- OpenCode
    |       +-- Claude-Mem
    |       +-- Workspace
    |
    +-- Gitea (port 3001)
    |       +-- Git Repos
    |       +-- PostgreSQL via PgBouncer
    |
    +-- FreeLLMAPI (port 3000)
    |       +-- OpenRouter Free Models
    |
    +-- RustFS (port 9000)
            +-- S3 Backups
```

## Services

| Service | Source | Build Method | Port |
|---------|--------|--------------|------|
| code-server | [coder/code-server](https://github.com/coder/code-server) | .deb from GitHub releases | 8443 |
| gitea | [go-gitea/gitea](https://github.com/go-gitea/gitea) | Cloned at build time | 3001 |
| freellmapi | [tashfeenahmed/freellmapi](https://github.com/tashfeenahmed/freellmapi) | Cloned at build time | 3000 |
| rustfs | [rustfs/rustfs](https://github.com/rustfs/rustfs) | Binary from releases | 9000 |

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/youruser/codeserver-ai.git
cd codeserver-ai
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your values
```

### 3. Create Storage Directories

```bash
sudo mkdir -p /mnt/storage/code-server
sudo mkdir -p /mnt/storage/gitea/data
sudo mkdir -p /mnt/storage/freellmapi/data
sudo mkdir -p /mnt/storage/rustfs/data
sudo chown -R 1000:1000 /mnt/storage
```

### 4. Deploy

**Option A: All services at once (docker compose)**

```bash
docker compose up -d
```

**Option B: Individual services via Dokploy**

See [docs/quick-start.md](docs/quick-start.md) for detailed Dokploy setup.

## File Structure

```
/
├── Dockerfile.codeserver          ← builds code-server from .deb
├── Dockerfile.gitea               ← clones and builds gitea
├── Dockerfile.freellmapi          ← clones and builds freellmapi
├── Dockerfile.rustfs              ← downloads rustfs binary
├── Dockerfile.opencode-web        ← builds OpenCode WEB server
├── docker-compose.yml             ← combined orchestrator
├── deploy/
│   ├── docker-compose.code-server.yml
│   ├── docker-compose.gitea.yml
│   ├── docker-compose.freellmapi.yml
│   ├── docker-compose.rustfs.yml
│   └── docker-compose.opencode-web.yml
├── scripts/
│   ├── backup.sh                 ← backup to RustFS
│   ├── restore.sh                ← restore from RustFS
│   ├── init.sh                   ← container initialization
│   ├── install-extensions.sh     ← AI extensions installer
│   ├── install-opencode-web.sh    ← OpenCode WEB installer
│   ├── opencode-web.sh            ← OpenCode WEB server
│   ├── update.sh                  ← update all services
│   └── manage-providers.sh        ← AI provider management
├── config/
│   ├── unified-config.json        ← unified provider configuration
│   ├── opencode/                  ← OpenCode extension config
│   │   └── config.json
│   └── opencode-web/              ← OpenCode WEB config
│       └── opencode.json
├── docs/
│   ├── backup.sh                 ← backup to RustFS
│   ├── restore.sh                ← restore from RustFS
│   ├── init.sh                   ← container initialization
│   ├── install-extensions.sh     ← AI extensions installer
│   ├── install-opencode-web.sh    ← OpenCode WEB installer
│   ├── opencode-web.sh            ← OpenCode WEB server
│   └── update.sh                  ← update all services
├── config/
│   ├── unified-config.json        ← unified provider configuration
│   ├── opencode/                  ← OpenCode extension config
│   │   └── config.json
│   └── opencode-web/              ← OpenCode WEB config
│       └── opencode.json
├── docs/
│   ├── quick-start.md             ← basic setup guide
│   ├── backup.md                  ← backup procedures
│   └── update.md                  ← update procedures
└── deploy/
    ├── docker-compose.code-server.yml
    ├── docker-compose.gitea.yml
    ├── docker-compose.freellmapi.yml
    └── docker-compose.rustfs.yml
```

> **Architecture Note:** code-server builds for **both amd64 and arm64** automatically via Docker/buildx. No manual `TARGETARCH` configuration needed.

## Update

Update all services (rebuilds from latest source):

```bash
./scripts/update.sh
```

Update specific service:

```bash
./scripts/update.sh code-server
./scripts/update.sh gitea
./scripts/update.sh freellmapi
./scripts/update.sh rustfs
./scripts/update.sh opencode-web
```

## AI Provider Management

Manage AI providers for OpenCode extension:

```bash
# List all available providers
./scripts/manage-providers.sh list

# Configure a new provider
./scripts/manage-providers.sh configure

# Test provider connection
./scripts/manage-providers.sh test
```

### Available Providers

1. **OpenRouter** - Access to 100+ open-source models
2. **OpenCode Zen** - Fast, efficient coding assistant
3. **FreeLLMAPI** - Proxy for multiple free models (default)
4. **Anthropic** - Claude 3.5 Sonnet and Haiku
5. **OpenAI** - GPT-4o, GPT-4 Turbo

### Provider Configuration

Each provider requires an API key. Set these in your `.env` file:

```bash
# OpenRouter
OPENROUTER_API_KEY=your-openrouter-key

# OpenCode Zen
OPENCODE_ZEN_API_KEY=your-opencode-zen-key

# FreeLLMAPI
FREELLMAPI_API_KEY=your-freellmapi-key

# Anthropic
ANTHROPIC_API_KEY=your-anthropic-key

# OpenAI
OPENAI_API_KEY=your-openai-key
```

### Provider Selection

During first container startup, you'll be prompted to select your preferred AI provider:

1. **OpenRouter** - Access to 100+ open-source models
2. **OpenCode Zen** - Fast, efficient coding assistant
3. **FreeLLMAPI** - Proxy for multiple free models (default)
4. **Anthropic** - Claude 3.5 Sonnet and Haiku
5. **OpenAI** - GPT-4o, GPT-4 Turbo

If you don't have an API key for your selected provider, you can set it up later using the provider management script.

## Backup

See [docs/backup.md](docs/backup.md) for RustFS backup strategy.

Daily automated backups at 2 AM:

```bash
0 2 * * * docker exec code-server /scripts/backup.sh >> /var/log/backup.log 2>&1
```

## Documentation

- [Quick Start Guide](docs/quick-start.md)
- [Backup Strategy](docs/backup.md)
- [Update Procedures](docs/update.md)
- [Provider Management](docs/update.md#provider-management)

## License

MIT
