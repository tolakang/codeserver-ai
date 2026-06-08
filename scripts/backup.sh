#!/bin/bash
# backup.sh
# Daily backup to RustFS S3

set -e

# Configuration
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/tmp/backups"
RUSTFS_ENDPOINT="${RUSTFS_ENDPOINT:-http://rustfs:9000}"
RUSTFS_BUCKET="${RUSTFS_BUCKET:-code-server-backups}"
RUSTFS_ACCESS_KEY="${RUSTFS_ACCESS_KEY}"
RUSTFS_SECRET_KEY="${RUSTFS_SECRET_KEY}"

# Directories to backup
WORKSPACE_DIR="/mnt/storage/code-server/workspace"
CONFIG_DIR="/mnt/storage/code-server/config"
GITEA_DIR="/mnt/storage/gitea/data"

# Retention (days)
DAILY_RETENTION=7

echo "=== Backup Started: ${TIMESTAMP} ==="

mkdir -p "${BACKUP_DIR}"

# Backup workspace
echo "Backing up workspace..."
tar czf "${BACKUP_DIR}/workspace-${TIMESTAMP}.tar.gz" \
  --exclude='node_modules' \
  --exclude='.cache' \
  --exclude='.npm' \
  --exclude='__pycache__' \
  -C /mnt/storage/code-server workspace 2>/dev/null || true

# Backup config
echo "Backing up config..."
tar czf "${BACKUP_DIR}/config-${TIMESTAMP}.tar.gz" \
  -C /mnt/storage/code-server config 2>/dev/null || true

# Backup gitea
echo "Backing up gitea..."
tar czf "${BACKUP_DIR}/gitea-${TIMESTAMP}.tar.gz" \
  --exclude='*.log' \
  -C /mnt/storage gitea 2>/dev/null || true

# Upload to RustFS
echo "Uploading to RustFS..."

if [ -n "${RUSTFS_ACCESS_KEY}" ]; then
  aws s3 cp "${BACKUP_DIR}/workspace-${TIMESTAMP}.tar.gz" \
    "s3://${RUSTFS_BUCKET}/workspace-${TIMESTAMP}.tar.gz" \
    --endpoint-url "${RUSTFS_ENDPOINT}" \
    --region us-east-1 2>/dev/null || echo "Warning: workspace upload failed"

  aws s3 cp "${BACKUP_DIR}/config-${TIMESTAMP}.tar.gz" \
    "s3://${RUSTFS_BUCKET}/config-${TIMESTAMP}.tar.gz" \
    --endpoint-url "${RUSTFS_ENDPOINT}" \
    --region us-east-1 2>/dev/null || echo "Warning: config upload failed"

  aws s3 cp "${BACKUP_DIR}/gitea-${TIMESTAMP}.tar.gz" \
    "s3://${RUSTFS_BUCKET}/gitea-${TIMESTAMP}.tar.gz" \
    --endpoint-url "${RUSTFS_ENDPOINT}" \
    --region us-east-1 2>/dev/null || echo "Warning: gitea upload failed"
else
  echo "Warning: RUSTFS_ACCESS_KEY not set, skipping upload"
fi

# Cleanup old local backups
echo "Cleaning up old backups..."
find "${BACKUP_DIR}" -name "*.tar.gz" -mtime +${DAILY_RETENTION} -delete 2>/dev/null || true

# Cleanup old remote backups
if [ -n "${RUSTFS_ACCESS_KEY}" ]; then
  echo "Cleaning up old remote backups..."
  CUTOFF_DATE=$(date -d "-${DAILY_RETENTION} days" +%Y%m%d 2>/dev/null || date -v-${DAILY_RETENTION}d +%Y%m%d 2>/dev/null || echo "")
  if [ -n "${CUTOFF_DATE}" ]; then
    aws s3 ls "s3://${RUSTFS_BUCKET}/" \
      --endpoint-url "${RUSTFS_ENDPOINT}" \
      --region us-east-1 2>/dev/null | \
      awk -v cutoff="${CUTOFF_DATE}" '$2 < cutoff {print $4}' | \
      xargs -I {} aws s3 rm "s3://${RUSTFS_BUCKET}/{}" \
        --endpoint-url "${RUSTFS_ENDPOINT}" \
        --region us-east-1 2>/dev/null || true
  fi
fi

echo "=== Backup Complete: ${TIMESTAMP} ==="
