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
- Built from Source (git submodules + .deb releases)

## Architecture

```
Internet
    |
    v
Dokploy
    |
    +-- Code Server (port 8080)
    |       +-- OpenCode
    |       +-- Claude-Mem
    |       +-- Workspace
    |
    +-- Gitea (port 3001)
    |       +-- Git Repos
    |       +-- SQLite DB
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
| code-server | [coder/code-server](https://github.com/coder/code-server) | .deb from GitHub releases | 8080 |
| gitea | [go-gitea/gitea](https://github.com/go-gitea/gitea) | Git submodule, multi-stage build | 3001 |
| freellmapi | [tashfeenahmed/freellmapi](https://github.com/tashfeenahmed/freellmapi) | Git submodule, multi-stage build | 3000 |
| rustfs | [rustfs/rustfs](https://github.com/rustfs/rustfs) | Git submodule, binary download | 9000 |

## Deployment

### 1. Clone Repository with Submodules

```bash
git clone --recurse-submodules https://github.com/youruser/codeserver-ai.git
cd codeserver-ai
```

If already cloned without submodules:
```bash
git submodule update --init --recursive
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your values
```

### 3. Create Storage Directories

```bash
sudo mkdir -p /mnt/storage/code-server/{config,workspace,extensions}
sudo mkdir -p /mnt/storage/gitea/data
sudo mkdir -p /mnt/storage/freellmapi/data
sudo mkdir -p /mnt/storage/rustfs/data
sudo chown -R 1000:1000 /mnt/storage
```

### 4. Build and Deploy

```bash
# Build all images
docker compose build

# Deploy all services
docker compose up -d
```

**Option B: Individual services**

Deploy each compose file as a separate Dokploy application:

1. `docker-compose.code-server.yml`
2. `docker-compose.gitea.yml`
3. `docker-compose.freellmapi.yml`
4. `docker-compose.rustfs.yml`

### 5. First-Time Setup

1. Access Code Server at `http://your-server:8080`
2. Access Gitea at `http://your-server:3001` and complete setup wizard
3. Create admin user in Gitea
4. OpenCode and FreeLLMAPI connect automatically

## Update

Update all services from source:

```bash
./scripts/update.sh
```

Update specific service:

```bash
./scripts/update.sh code-server
./scripts/update.sh gitea
./scripts/update.sh freellmapi
./scripts/update.sh rustfs
```

Manual update:

```bash
# Pull latest source
git submodule update --remote

# Get latest code-server version
CODESERVER_VERSION=$(curl -fsSL https://api.github.com/repos/coder/code-server/releases/latest \
  | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//')

# Rebuild and redeploy
CODESERVER_VERSION=$CODESERVER_VERSION docker compose build
docker compose up -d
```

## Backup

See [BACKUP.md](BACKUP.md) for RustFS backup strategy.

Daily automated backups at 2 AM:

```bash
0 2 * * * docker exec code-server /scripts/backup.sh >> /var/log/backup.log 2>&1
```

## Documentation

- [Development Guide](DEVELOPMENT.md)
- [Backup Strategy](BACKUP.md)
- [RustFS Setup](docs/rustfs.md)
- [OpenCode Guide](docs/opencode.md)
- [FreeLLMAPI Integration](docs/freellmapi.md)
- [Claude Memory](docs/claude-mem.md)
- [Gitea Setup](docs/gitea.md)

## License

MIT
