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

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| code-server | linuxserver/code-server:latest | 8080 | Web IDE |
| gitea | gitea/gitea:latest | 3001 | Git hosting |
| freellmapi | ghcr.io/tashfeenahmed/freellmapi:latest | 3000 | LLM proxy |
| rustfs | ghcr.io/rustfs/rustfs:latest | 9000 | S3 backup |

## Deployment

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
sudo mkdir -p /mnt/storage/rustfs/data
sudo chown -R 1000:1000 /mnt/storage
```

### 4. Deploy with Dokploy

**Option A: All services at once**

Upload `docker-compose.yml` to Dokploy as a compose stack.

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

Redeploy image only. Workspace remains persistent.

```bash
docker compose pull
docker compose up -d
```

## Backup

See [BACKUP.md](BACKUP.md) for RustFS backup strategy.

Daily automated backups at 2 AM:

```bash
0 2 * * * /mnt/storage/code-server/scripts/backup.sh
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
