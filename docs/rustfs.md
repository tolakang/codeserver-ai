# RustFS Setup

## Overview

RustFS provides S3-compatible backup storage for Code Server data.

[RustFS GitHub](https://github.com/rustfs/rustfs)

## Deployment

Deploy RustFS as a Dokploy application using `docker-compose.rustfs.yml`.

## Configuration

### Environment Variables

Set in `.env`:

```bash
RUSTFS_ROOT_USER=admin
RUSTFS_ROOT_PASSWORD=changeme
```

### Data Storage

RustFS stores data in:

```
/mnt/storage/rustfs/data
```

This directory persists across container restarts.

## S3 Access

### Endpoint

```
http://rustfs:9000        (internal network)
http://your-server:9000   (external access)
```

### Create Backup Bucket

After deploying RustFS, create a bucket:

```bash
# Using MinIO client
mc alias set rustfs http://localhost:9000 ${RUSTFS_ROOT_USER} ${RUSTFS_ROOT_PASSWORD}
mc mb rustfs/code-server-backups
```

### Access Keys

Create access keys for backup scripts:

```bash
mc admin user add rustfs backup-user changeme
mc admin policy attach rustfs readwrite --user backup-user
```

## Integration with Code Server

Code Server backup scripts use AWS CLI compatible commands:

```bash
aws s3 cp backup.tar.gz \
  s3://code-server-backups/ \
  --endpoint-url http://rustfs:9000
```

## VS Code Extension

Install "Amazon S3 Explorer" in Code Server to browse backups:

1. Open Code Server
2. Extensions panel
3. Search "Amazon S3 Explorer"
4. Configure:
   - Endpoint: `http://rustfs:9000`
   - Access Key: your key
   - Secret Key: your secret
   - Region: `us-east-1`

## Health Check

```bash
curl http://localhost:9000/minio/health/live
```

## Troubleshooting

### Connection refused

Ensure RustFS is on the same Docker network:

```bash
docker network inspect codeserver-network
```

### Bucket not found

Create the bucket before running backup scripts.

### Permission denied

Verify access keys match `.env` configuration.
