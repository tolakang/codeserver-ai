# Gitea Setup

## Overview

Gitea provides self-hosted Git hosting for Code Server projects.

[Gitea Website](https://gitea.com)

## Deployment

Deploy Gitea as a Dokploy application using `docker-compose.gitea.yml`.

## Ports

| Port | Container | Purpose |
|------|-----------|---------|
| 3001 | 3000 | Web UI |
| 2222 | 22 | SSH Git access |

## First-Time Setup

### 1. Access Web UI

Open `http://your-server:3001` in browser.

### 2. Initial Configuration

The Gitea setup wizard will appear. Configure:

- **Database**: SQLite (default, stored in `/data/gitea/gitea.db`)
- **Repository Root Path**: `/data/git/repositories`
- **LFS Path**: `/data/git/lfs`
- **Server Domain**: `your-server-domain`
- **SSH Port**: `2222`
- **HTTP Port**: `3000`
- **Application URL**: `http://your-server:3001/`

### 3. Create Admin User

During setup or after:

```bash
docker exec -it gitea gitea admin user create \
  --username admin \
  --password changeme \
  --email admin@yourdomain.com \
  --admin
```

## Code Server Integration

### Clone from Gitea

Inside Code Server terminal:

```bash
# HTTP clone
git clone http://gitea:3000/username/repo.git

# SSH clone (use port 2222)
git clone ssh://git@gitea:2222/username/repo.git
```

### Set Default Remote

Configure git to use Gitea by default:

```bash
git config --global user.name "your-username"
git config --global user.email "your-email@yourdomain.com"
```

### Push to Gitea

```bash
git remote add origin http://gitea:3000/username/repo.git
git push -u origin main
```

## Persistence

Gitea data is stored in:

```
/mnt/storage/gitea/data
```

This includes:

- Git repositories
- SQLite database
- User avatars
- LFS objects

## Environment Variables

Set in `.env`:

```bash
GITEA_DOMAIN=gitea.yourdomain.com
GITEA_ADMIN_USER=admin
GITEA_ADMIN_PASSWORD=changeme
GITEA_ADMIN_EMAIL=admin@yourdomain.com
```

## Backup

Gitea data is included in daily backups. See [BACKUP.md](../BACKUP.md).

## Health Check

```bash
curl http://localhost:3001/api/v1/version
```

## Troubleshooting

### Cannot access Gitea UI

1. Check container is running: `docker compose ps gitea`
2. Check logs: `docker compose logs gitea`
3. Verify port 3001 is not blocked

### SSH not working

Ensure port 2222 is mapped and accessible:

```bash
ssh -p 2222 git@your-server
```

### Database locked

If SQLite database is locked:

```bash
docker compose restart gitea
```

### Permission issues

Fix ownership:

```bash
sudo chown -R 1000:1000 /mnt/storage/gitea/data
```
