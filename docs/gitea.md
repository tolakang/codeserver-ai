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

## Database

Gitea uses **PostgreSQL** via **PgBouncer** connection pooler.

| Component | Container | Port |
|-----------|-----------|------|
| PostgreSQL 16 | gitea-postgres | 5432 |
| PgBouncer | gitea-pgbouncer | 6432 |
| Gitea | gitea | 3000 |

Connection flow: `Gitea ──▶ PgBouncer (6432) ──▶ PostgreSQL (5432)`

## First-Time Setup

### 1. Access Web UI

Open `http://your-server:3001` in browser.

### 2. Initial Configuration

The Gitea setup wizard will appear. Configure:

- **Database**: PostgreSQL (pre-configured via env vars)
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

Gitea data is stored in volumes:

| Volume | Container | Contents |
|--------|-----------|----------|
| `gitea-data` | gitea | Git repos, config, SSH keys, avatars |
| `postgres-data` | gitea-postgres | PostgreSQL database files |

## Environment Variables

Set in `.env`:

```bash
# ---- Gitea ----
GITEA_DOMAIN=https://gitea.yourdomain.com

# ---- PostgreSQL ----
POSTGRES_PASSWORD=your-postgres-password
```

Database config is auto-configured via env vars in `docker-compose.gitea.yml`.

## Backup

### Daily pg_dump

A separate backup script (`scripts/backup-gitea.sh`) runs daily via Dokploy cron job at 2 AM UTC:

```bash
pg_dump -h pgbouncer -p 6432 -U gitea -d gitea | gzip > gitea-db-$(date +%F).sql.gz
aws s3 cp ... s3://gitea-backups/
```

Retention: 30 days.

### Manual Backup

```bash
docker exec gitea-postgres pg_dump -U gitea -d gitea | gzip > gitea-backup.sql.gz
```

### Restore

```bash
gunzip < gitea-backup.sql.gz | docker exec -i gitea-postgres psql -U gitea -d gitea
```

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

### Database connection issues

Check PostgreSQL and PgBouncer health:

```bash
docker compose logs gitea-postgres
docker compose logs gitea-pgbouncer
docker compose restart gitea
```

### Permission issues

Fix ownership:

```bash
sudo chown -R 1000:1000 /mnt/storage/gitea/data
```
