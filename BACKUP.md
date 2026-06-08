# Backup Strategy

## Overview

Daily automated backups using RustFS (S3-compatible storage).

## What Gets Backed Up

| Path | Container | Purpose |
|------|-----------|---------|
| /mnt/storage/code-server/workspace | code-server | Project files |
| /mnt/storage/code-server/config | code-server | IDE configuration |
| /mnt/storage/gitea/data | gitea | Git repositories + DB |

## What Does NOT Get Backed Up

- node_modules
- .cache
- npm/yarn cache
- /tmp files
- RustFS data (it IS the backup target)

## Backup Schedule

Daily at 2 AM via cron (run inside code-server container):

```bash
0 2 * * * docker exec code-server /scripts/backup.sh >> /var/log/backup.log 2>&1
```

## Retention Policy

- Daily: 7 days
- Weekly: 4 weeks
- Monthly: 6 months

## Manual Backup

```bash
docker exec code-server /scripts/backup.sh
```

## Restore

```bash
docker exec code-server /scripts/restore.sh <backup-filename>
```

## Setup

### 1. Configure RustFS

See [docs/rustfs.md](docs/rustfs.md) for RustFS setup.

### 2. Set Environment Variables

In `.env`:

```bash
RUSTFS_ENDPOINT=https://rustfs.yourdomain.com
RUSTFS_ACCESS_KEY=your-access-key
RUSTFS_SECRET_KEY=your-secret-key
RUSTFS_BUCKET=code-server-backups
```

### 3. Install Cron Job

```bash
crontab -e
# Add:
0 2 * * * docker exec code-server /scripts/backup.sh >> /var/log/backup.log 2>&1
```

## Backup Script

See `scripts/backup.sh` for implementation details.

The script:

1. Creates timestamped tarballs of workspace, config, and gitea data
2. Uploads to RustFS S3 bucket
3. Cleans up local tarballs
4. Removes backups older than retention period

## Verify Backups

Check backup list:

```bash
aws s3 ls s3://code-server-backups/ --endpoint-url https://rustfs.yourdomain.com
```

## Emergency Restore

```bash
# Stop services
docker compose down

# Restore from backup
docker exec code-server /scripts/restore.sh workspace-20250101-020000.tar.gz

# Restart services
docker compose up -d
```
