#!/bin/bash
# backup.sh
# Daily backup to RustFS S3

set -e

# Configuration
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="/tmp/backups"
RUSTFS_ENDPOINT="${RUSTFS_ENDPOINT:-http://rustfs:9000}"
RUSTFS_BUCKET="${RUSTFS_BUCKET:-code-server-backups}"

# Map to AWS CLI environment variables
export AWS_ACCESS_KEY_ID="${RUSTFS_ACCESS_KEY}"
export AWS_SECRET_ACCESS_KEY="${RUSTFS_SECRET_KEY}"
export AWS_DEFAULT_REGION="us-east-1"

# Retention (days)
DAILY_RETENTION=7

echo "=== Backup Started: ${TIMESTAMP} ==="

mkdir -p "${BACKUP_DIR}"

# Validate credentials
if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
  echo "Error: RUSTFS_ACCESS_KEY and RUSTFS_SECRET_KEY must be set"
  exit 1
fi

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

# Validate archives are non-empty
for archive in workspace config gitea; do
  FILE="${BACKUP_DIR}/${archive}-${TIMESTAMP}.tar.gz"
  if [ ! -s "${FILE}" ]; then
    echo "Warning: ${archive} backup is empty, skipping upload"
    rm -f "${FILE}"
  fi
done

# Upload to RustFS
echo "Uploading to RustFS..."
UPLOAD_ERRORS=0

for archive in workspace config gitea; do
  FILE="${BACKUP_DIR}/${archive}-${TIMESTAMP}.tar.gz"
  if [ -f "${FILE}" ]; then
    if ! aws s3 cp "${FILE}" \
      "s3://${RUSTFS_BUCKET}/${archive}-${TIMESTAMP}.tar.gz" \
      --endpoint-url "${RUSTFS_ENDPOINT}" 2>/dev/null; then
      echo "Error: ${archive} upload failed"
      UPLOAD_ERRORS=$((UPLOAD_ERRORS + 1))
    fi
  fi
done

# Cleanup local backups
echo "Cleaning up old local backups..."
find "${BACKUP_DIR}" -name "*.tar.gz" -mtime +${DAILY_RETENTION} -delete 2>/dev/null || true

# Cleanup old remote backups
echo "Cleaning up old remote backups..."
CUTOFF_DATE=$(date -d "-${DAILY_RETENTION} days" +%Y-%m-%d 2>/dev/null || date -v-${DAILY_RETENTION}d +%Y-%m-%d 2>/dev/null || echo "")
if [ -n "${CUTOFF_DATE}" ]; then
  aws s3 ls "s3://${RUSTFS_BUCKET}/" \
    --endpoint-url "${RUSTFS_ENDPOINT}" 2>/dev/null | \
    awk -v cutoff="${CUTOFF_DATE}" '$1 < cutoff {print $4}' | \
    grep -v '^$' | \
    xargs -I {} aws s3 rm "s3://${RUSTFS_BUCKET}/{}" \
      --endpoint-url "${RUSTFS_ENDPOINT}" 2>/dev/null || true
fi

# Cleanup temp files
rm -f "${BACKUP_DIR}"/*.tar.gz

if [ ${UPLOAD_ERRORS} -gt 0 ]; then
  echo "=== Backup Completed with Errors: ${TIMESTAMP} ==="
  exit 1
fi

echo "=== Backup Complete: ${TIMESTAMP} ==="
