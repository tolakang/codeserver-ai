# Backup Strategy

## Overview

Code Server AI backs up workspace files, code-server/OpenCode configuration, and the Gitea PostgreSQL database to RustFS S3-compatible storage.

The code-server workspace is mounted at `/workspace` from the fixed Docker named volume `codeserver-ai-workspace`. Backups archive this path so workspace contents survive code-server container rebuilds and Dokploy updates.

## Required Environment Variables

Set these on the `code-server` container:

```bash
RUSTFS_ACCESS_KEY=your-rustfs-access-key
RUSTFS_SECRET_KEY=your-rustfs-secret-key
RUSTFS_ENDPOINT=http://rustfs:9000
RUSTFS_BUCKET=code-server-backups
POSTGRES_HOST=pgbouncer
POSTGRES_PORT=6432
POSTGRES_USER=gitea
POSTGRES_DB=gitea
POSTGRES_PASSWORD=your-postgres-password
```

The backup script creates `RUSTFS_BUCKET` if it does not exist.

## Manual Backup

Run the backup from the code-server container:

```bash
docker exec code-server /scripts/backup.sh
```

Expected backup names:

```text
workspace-YYYYMMDD-HHMMSS.tar.gz
config-YYYYMMDD-HHMMSS.tar.gz
gitea-YYYYMMDD-HHMMSS.sql.gz
```

## Automated Backup

Add this to the host crontab:

```bash
0 2 * * * docker exec code-server /scripts/backup.sh >> /tmp/backup.log 2>&1
```

## Restore Procedures

List backups:

```bash
docker exec code-server sh -c 'aws s3 ls s3://code-server-backups/ --endpoint-url http://rustfs:9000'
```

Restore workspace or config:

```bash
docker exec code-server /scripts/restore.sh workspace-20240101-120000.tar.gz
docker exec code-server /scripts/restore.sh config-20240101-120000.tar.gz
```

Restore the Gitea database:

```bash
docker exec code-server /scripts/restore.sh gitea-20240101-120000.sql.gz
docker restart gitea
```

The restore script creates a pre-restore snapshot in `/tmp/pre-restore-snapshot/` before applying changes.

## Backup Retention

- Local temporary backups: 7 days
- Remote RustFS backups: 7 days

Old backups are cleaned automatically by `/scripts/backup.sh`.

## Backup Contents

### Workspace Backup

Includes:

- User workspace files
- Claude memory data
- Git repositories
- Installed extensions

### Configuration Backup

Includes:

- Code Server configuration
- OpenCode provider configuration
- User dotfiles under `/home/coder/.config`

### Gitea Database Backup

Includes:

- User accounts
- Repository metadata
- Issues and pull requests
- Wiki data

## Troubleshooting

### Backup Fails

```bash
docker exec code-server sh -c 'tail -n 100 /tmp/backup.log'
docker logs code-server
```

Common causes:

1. Missing `RUSTFS_ACCESS_KEY` or `RUSTFS_SECRET_KEY`
2. Missing `POSTGRES_PASSWORD`
3. RustFS is not reachable from `code-server`
4. The RustFS bucket cannot be listed or created

### Restore Fails

```bash
docker exec code-server sh -c 'tail -n 100 /tmp/restore.log'
docker logs code-server
docker logs gitea
```

Common causes:

1. Backup filename does not match the expected format
2. Missing `POSTGRES_PASSWORD` for Gitea database restore
3. Gitea database connection settings are wrong
4. The downloaded archive is empty or corrupt

## Backup Security

- Store credentials in Dokploy/Docker secrets or environment variables.
- Never commit `.env`, API keys, RustFS credentials, or generated passwords.
- Use TLS termination at the reverse proxy.
- Keep code-server upstream protocol as `HTTP` behind the proxy.
- Rotate service credentials regularly.
