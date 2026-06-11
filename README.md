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

See [docs/backup.md](docs/backup.md) for backup strategy.

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
├── k8s/
│   └── backup-cron.yml            ← Kubernetes backup cronjob
├── scripts/
│   ├── backup.sh                  ← backup to RustFS
│   ├── restore.sh                 ← restore from RustFS
│   ├── init.sh                    ← container initialization
│   ├── install-extensions.sh      ← AI extensions installer
│   ├── install-opencode-web.sh    ← OpenCode WEB installer
│   ├── opencode-web.sh            ← OpenCode WEB server
│   ├── update.sh                  ← update all services
│   ├── configure-provider.sh      ← AI provider management
│   └── generate-configs.sh        ← configuration generation
├── config/
│   ├── unified-config.json        ← unified provider configuration
│   ├── code-server/               ← code-server config
│   └── gitea/                     ← gitea config
├── docs/
│   └── backup.md                  ← backup procedures
├── .env.example                   ← environment template
├── .dockerignore                  ← Docker build exclusions
├── LICENSE                        ← MIT license
└── README.md
```

> **Architecture Note:** code-server builds for **both amd64 and arm64** automatically via Docker/buildx. No manual `TARGETARCH` configuration needed.

## Update Procedures

### Overview

All services are rebuilt from source during updates to ensure latest security patches and features.

### Update All Services

#### Basic Update

```bash
./scripts/update.sh
```

#### Update Specific Service

```bash
./scripts/update.sh code-server
./scripts/update.sh gitea
./scripts/update.sh freellmapi
./scripts/update.sh rustfs
./scripts/update.sh opencode-web
```

### Update Process

#### 1. Check Latest Versions

The update script automatically fetches the latest versions from GitHub:

- **code-server**: Latest stable release
- **gitea**: Latest stable release
- **freellmapi**: Latest version (default: `latest`)
- **rustfs**: Latest stable release
- **opencode-web**: Latest version (default: `latest`)

#### 2. Architecture Detection

The script automatically detects system architecture:

```bash
# x86_64 systems
TARGETARCH=amd64

# ARM systems (Raspberry Pi, etc.)
TARGETARCH=arm64
```

#### 3. Service Updates

Each service is updated in sequence:

##### Code Server Update

```bash
echo "--- Updating code-server ---"
CODESERVER_VERSION=$CODESERVER_VERSION TARGETARCH=$TARGETARCH \
  docker compose -f deploy/docker-compose.code-server.yml build --no-cache
docker compose -f deploy/docker-compose.code-server.yml up -d
```

##### Gitea Update

```bash
echo "--- Updating gitea ---"
docker compose -f deploy/docker-compose.gitea.yml build --no-cache
docker compose -f deploy/docker-compose.gitea.yml up -d
```

##### FreeLLMAPI Update

```bash
echo "--- Updating freellmapi ---"
FREELLM_VERSION=${FREELLM_VERSION:-latest} \
  docker compose -f deploy/docker-compose.freellmapi.yml build --no-cache
docker compose -f deploy/docker-compose.freellmapi.yml up -d
```

##### RustFS Update

```bash
echo "--- Updating rustfs ---"
docker compose -f deploy/docker-compose.rustfs.yml build --no-cache
docker compose -f deploy/docker-compose.rustfs.yml up -d
```

##### OpenCode WEB Update

```bash
echo "--- Updating opencode-web ---"
  OPENCODE_VERSION=${OPENCODE_VERSION:-latest} \
    docker compose -f deploy/docker-compose.opencode-web.yml build --no-cache
docker compose -f deploy/docker-compose.opencode-web.yml up -d
```

### Update Best Practices

#### Before Updating

1. **Backup data**: Run backup script before updating
2. **Check system resources**: Ensure sufficient disk space
3. **Test in staging**: Update test environment first
4. **Notify users**: Inform users of potential downtime

#### During Update

1. **Monitor logs**: Watch for errors during update
2. **Check service health**: Verify services start correctly
3. **Test functionality**: Test critical features after update
4. **Rollback plan**: Have rollback procedure ready

#### After Update

1. **Verify services**: Check all services are running
2. **Test integrations**: Verify AI integrations work
3. **Check backups**: Ensure backup system still works
4. **Monitor performance**: Watch for performance issues

### Update Troubleshooting

#### Update Fails

```bash
# Check update logs
docker compose logs code-server

# Check specific service logs
docker compose logs gitea
```

#### Service Not Starting After Update

```bash
# Check container status
docker compose ps

# Check container logs
docker compose logs [service-name]
```

#### Rollback

If an update causes issues:

1. **Stop all services**:

```bash
docker compose down
```

2. **Restore from backup**:

```bash
./scripts/restore.sh
```

3. **Restart services**:

```bash
docker compose up -d
```

### Update Monitoring

#### Check Update Status

```bash
# Check if update is running
docker compose ps

# Check update logs
tail -f /var/log/update.log
```

#### Monitor Service Health

```bash
# Check code-server status
docker compose -f deploy/docker-compose.code-server.yml ps

# Check gitea status
docker compose -f deploy/docker-compose.gitea.yml ps

# Check freellmapi status
docker compose -f deploy/docker-compose.freellmapi.yml ps

# Check rustfs status
docker compose -f deploy/docker-compose.rustfs.yml ps

# Check opencode-web status
docker compose -f deploy/docker-compose.opencode-web.yml ps
```

### Update Frequency

#### Recommended Schedule

- **Security patches**: Update immediately when available
- **Feature updates**: Update during maintenance windows
- **Major versions**: Plan for downtime and test thoroughly

### Automated Updates

Consider setting up a monitoring system to alert when new versions are available:

```bash
# Example: Check for updates weekly
crontab -e
0 0 * * 0 ./scripts/update.sh --check-only
```

## AI Provider Management

Manage AI providers for OpenCode extension:

```bash
# List all available providers
./scripts/configure-provider.sh list

# Configure a provider (uses environment variables)
./scripts/configure-provider.sh configure

# Test provider connection
./scripts/configure-provider.sh test
```

### Available Providers

1. **OpenRouter** - Access to 100+ open-source models
2. **OpenCode Zen** - Fast, efficient coding assistant
3. **FreeLLMAPI** - Proxy for multiple free models (default)
4. **Anthropic** - Claude 3.5 Sonnet and Haiku
5. **OpenAI** - GPT-4o, GPT-4 Turbo

### Provider Configuration

Each provider can be configured using environment variables in your `.env` file:

```bash
# OpenRouter Provider
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_API_KEY=your-openrouter-key

# OpenCode Zen Provider
OPENCODE_ZEN_BASE_URL=https://opencode.ai/zen/api/v1
OPENCODE_ZEN_API_KEY=your-opencode-zen-key

# FreeLLMAPI Provider
FRELLMAPI_BASE_URL=http://freellmapi:3000/v1
FRELLMAPI_API_KEY=your-freellmapi-key

# Anthropic Provider
ANTHROPIC_BASE_URL=https://api.anthropic.com
ANTHROPIC_API_KEY=your-anthropic-key

# OpenAI Provider
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_API_KEY=your-openai-key

# Default Provider
DEFAULT_PROVIDER=freellmapi
```

### Configuration Generation

After setting up your environment variables, generate the configuration:

```bash
# Generate unified configuration
./scripts/generate-configs.sh
```

This will create the unified configuration based on your environment variables.

### Provider Selection

During container startup, the system will automatically use the provider configuration from your environment variables. No manual selection is required - the system will use the default provider or the one specified in your environment.

### Configuration Examples

**Example 1: OpenRouter as primary provider:**
```bash
DEFAULT_PROVIDER=openrouter
OPENROUTER_API_KEY=your-openrouter-key
```

**Example 2: OpenCode Zen as primary provider:**
```bash
DEFAULT_PROVIDER=opencode-zen
OPENCODE_ZEN_API_KEY=your-opencode-zen-key
```

**Example 3: Multiple providers:**
```bash
# Primary provider
DEFAULT_PROVIDER=openrouter
OPENROUTER_API_KEY=your-openrouter-key

# Backup provider
ANTHROPIC_API_KEY=your-anthropic-key

# FreeLLMAPI (already configured)
FRELLMAPI_API_KEY=your-freellmapi-key
```

## Backup

See [docs/backup.md](docs/backup.md) for RustFS backup strategy.

Daily automated backups at 2 AM:

```bash
0 2 * * * docker exec code-server /scripts/backup.sh >> /var/log/backup.log 2>&1
```

## Documentation

- [Backup Strategy](docs/backup.md)

## License

MIT
