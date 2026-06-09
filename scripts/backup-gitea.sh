#!/bin/bash
# backup-gitea.sh
# Daily PostgreSQL dump via PgBouncer, upload to RustFS

set -euo pipefail

# Configuration
TIMESTAMP=$(date +%F-%H%M)
BACKUP_DIR="/tmp/gitea-backups"
BACKUP_FILE="gitea-db-${TIMESTAMP}.sql.gz"
LOCAL_RETENTION_DAYS=7
RUSTFS_ENDPOINT="${RUSTFS_ENDPOINT:-http://rustfs:9000}"
RUSTFS_BUCKET="${RUSTFS_BUCKET:-gitea-backups}"

# AWS CLI env vars for RustFS (S3-compatible)
export AWS_ACCESS_KEY_ID="${RUSTFS_ACCESS_KEY}"
export AWS_SECRET_ACCESS_KEY="${RUSTFS_SECRET_KEY}"
export AWS_DEFAULT_REGION="us-east-1"

echo "=== Gitea DB Backup Started: ${TIMESTAMP} ==="

mkdir -p "${BACKUP_DIR}"

# Validate credentials
if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
  echo "Error: RUSTFS_ACCESS_KEY and RUSTFS_SECRET_KEY must be set"
  exit 1
fi

if [ -z "${POSTGRES_PASSWORD}" ]; then
  echo "Error: POSTGRES_PASSWORD must be set"
  exit 1
fi

# Run pg_dump via PgBouncer
echo "Running pg_dump..."
PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump \
  -h pgbouncer -p 6432 -U gitea -d gitea \
  --no-owner --no-privileges \
  --clean --if-exists \
  2>/dev/null | gzip > "${BACKUP_DIR}/${BACKUP_FILE}"

# Verify backup
if [ ! -s "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
  echo "Error: Backup file is empty"
  rm -f "${BACKUP_DIR}/${BACKUP_FILE}"
  exit 1
fi

echo "Backup size: $(du -h "${BACKUP_DIR}/${BACKUP_FILE}" | cut -f1)"

# Upload to RustFS
echo "Uploading to RustFS..."
if aws s3 cp "${BACKUP_DIR}/${BACKUP_FILE}" \
  "s3://${RUSTFS_BUCKET}/${BACKUP_FILE}" \
  --endpoint-url "${RUSTFS_ENDPOINT}" 2>/dev/null; then
  echo "Upload successful"
else
  echo "Warning: Upload failed, backup kept locally at ${BACKUP_DIR}/${BACKUP_FILE}"
  exit 1
fi

# Cleanup old local backups
find "${BACKUP_DIR}" -name "gitea-db-*.sql.gz" -mtime +${LOCAL_RETENTION_DAYS} -delete 2>/dev/null || true

# Cleanup old remote backups (older than 30 days)
echo "Cleaning up remote backups older than 30 days..."
CUTOFF_DATE=$(date -d "-30 days" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d 2>/dev/null || echo "")
if [ -n "${CUTOFF_DATE}" ]; then
  aws s3 ls "s3://${RUSTFS_BUCKET}/" \
    --endpoint-url "${RUSTFS_ENDPOINT}" 2>/dev/null | \
    awk -v cutoff="${CUTOFF_DATE}" '$1 < cutoff {print $4}' | \
    grep -v '^$' | \
    xargs -I {} aws s3 rm "s3://${RUSTFS_BUCKET}/{}" \
      --endpoint-url "${RUSTFS_ENDPOINT}" 2>/dev/null || true
fi

echo "=== Gitea DB Backup Complete: ${TIMESTAMP} ==="
