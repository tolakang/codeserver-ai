# Development Guide

## Local Development

```bash
docker compose up -d
```

This starts all 4 services: Code Server, Gitea, FreeLLMAPI, and RustFS.

## Workspace

All project files live in `/workspace` inside the container, mounted from:

```
/mnt/storage/code-server/workspace
```

This persists across container restarts, updates, and redeployments.

## Extensions

Installed automatically at startup via `scripts/install-extensions.sh`:

- OpenCode AI
- Amazon S3 Explorer

To add more extensions, edit `scripts/install-extensions.sh`.

## Services

| Service | URL | Purpose |
|---------|-----|---------|
| Code Server | http://localhost:8080 | Web IDE |
| Gitea | http://localhost:3001 | Git hosting |
| FreeLLMAPI | http://localhost:3000 | LLM proxy |
| RustFS | http://localhost:9000 | S3 storage |

## Backup

Daily RustFS backup at 2 AM. See [BACKUP.md](BACKUP.md).

## Upgrade

```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d
```

Never remove volumes. Data persists across upgrades.

## Troubleshooting

### Code Server won't start

```bash
docker compose logs code-server
```

### Gitea database issues

Gitea uses SQLite stored in `/mnt/storage/gitea/data`.

```bash
docker compose logs gitea
```

### FreeLLMAPI not connecting

Check OpenRouter API key in `.env`:

```bash
docker compose logs freellmapi
```

### Backup failed

Verify RustFS is running and accessible:

```bash
docker compose logs rustfs
curl http://localhost:9000/minio/health/live
```
