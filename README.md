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
- Built from Source (cloned at Docker build time)

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
sudo mkdir -p /mnt/storage/code-server/{config,workspace,extensions}
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

See [deploy/README.md](deploy/README.md) for detailed Dokploy setup.

## File Structure

```
/
├── Dockerfile.codeserver          ← builds code-server from .deb
├── Dockerfile.gitea               ← clones and builds gitea
├── Dockerfile.freellmapi          ← clones and builds freellmapi
├── Dockerfile.rustfs              ← downloads rustfs binary
├── docker-compose.yml             ← combined orchestrator
├── deploy/
│   ├── docker-compose.code-server.yml
│   ├── docker-compose.gitea.yml
│   ├── docker-compose.freellmapi.yml
│   └── docker-compose.rustfs.yml
├── scripts/
│   ├── backup.sh
│   ├── restore.sh
│   ├── init.sh
│   ├── install-extensions.sh
│   └── update.sh
├── config/
├── docs/
├── .env.example
└── README.md
```

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
```

## Backup

See [BACKUP.md](BACKUP.md) for RustFS backup strategy.

Daily automated backups at 2 AM:

```bash
0 2 * * * docker exec code-server /scripts/backup.sh >> /var/log/backup.log 2>&1
```

## Documentation

- [Dokploy Deployment Guide](deploy/README.md)
- [Development Guide](DEVELOPMENT.md)
- [Backup Strategy](BACKUP.md)
- [RustFS Setup](docs/rustfs.md)
- [OpenCode Guide](docs/opencode.md)
- [FreeLLMAPI Integration](docs/freellmapi.md)
- [Claude Memory](docs/claude-mem.md)
- [Gitea Setup](docs/gitea.md)

## License

MIT
