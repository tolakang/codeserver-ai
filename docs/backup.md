# Backup Strategy

## Overview

This document covers the backup procedures for Code Server AI, including workspace data, configuration, and Gitea database.

## Backup Method

All backups are stored in RustFS S3-compatible storage.

## Manual Backup

### Run Backup Script

```bash
docker exec code-server /scripts/backup.sh
```

### Check Backup Status

```bash
docker compose logs code-server | grep backup
```

## Automated Backup

### Cron Job Setup

Add to your system's crontab:

```bash
0 2 * * * docker exec code-server /scripts/backup.sh >> /var/log/backup.log 2>&1
```

### Verify Backup Logs

```bash
tail -f /var/log/backup.log
```

## Restore Procedures

### Restore from RustFS

```bash
docker exec code-server /scripts/restore.sh
```

### Restore Specific Files

```bash
# Download specific backup from RustFS
aws s3 cp s3://code-server-backups/workspace-2024-01-01-120000.tar.gz /tmp/

# Extract specific backup
tar xzf /tmp/workspace-2024-01-01-120000.tar.gz -C /workspace
```

## Backup Retention

- **Local backups**: 7 days
- **Remote backups**: 30 days

Old backups are automatically cleaned up by the backup script.

## Backup Contents

### Workspace Backup

Includes:
- User workspace files
- Claude memory data
- Git repositories
- Extension installations

### Configuration Backup

Includes:
- Code Server configuration
- Gitea configuration
- AI provider settings

### Gitea Database Backup

Includes:
- User accounts
- Git repositories metadata
- Issues and pull requests
- Wiki data

## Troubleshooting

### Backup Fails

```bash
docker compose logs code-server
```

### Restore Fails

```bash
docker compose logs code-server
```

### Missing Backups

1. Verify RustFS is running
2. Check `.env` credentials
3. Ensure bucket exists
4. Verify backup script permissions

## Backup Health Check

### Verify RustFS Connection

```bash
curl http://localhost:9000/minio/health/live
```

### List Available Backups

```bash
aws s3 ls s3://code-server-backups/
```

## Backup Best Practices

1. **Test restores regularly**: Verify backup integrity
2. **Monitor disk space**: Ensure sufficient storage
3. **Verify credentials**: Check `.env` file permissions
4. **Schedule during low usage**: Run backups during off-peak hours
5. **Document restore procedures**: Keep restore instructions accessible

## Emergency Procedures

### Complete System Failure

1. Restore latest backup using `/scripts/restore.sh`
2. Re-deploy all services
3. Verify all data is restored
4. Test critical functionality

### Partial Data Loss

1. Identify affected backup
2. Restore specific component
3. Test affected functionality
4. Verify data integrity

## Backup Monitoring

### Check Backup Success

```bash
grep "Backup Complete" /var/log/backup.log
tail -n 10 /var/log/backup.log
```

### Monitor Storage Usage

```bash
aws s3 ls s3://code-server-backups/ --human-readable
```

## Backup Security

- All credentials encrypted in environment variables
- Backup files stored in encrypted S3 bucket
- Access restricted to container network
- Regular rotation of encryption keys
