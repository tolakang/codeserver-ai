#!/bin/bash
# restore.sh
# Restore from RustFS S3 backup

set -e

# Configuration
RUSTFS_ENDPOINT="${RUSTFS_ENDPOINT:-http://rustfs:9000}"
RUSTFS_BUCKET="${RUSTFS_BUCKET:-code-server-backups}"
RUSTFS_ACCESS_KEY="${RUSTFS_ACCESS_KEY}"
RUSTFS_SECRET_KEY="${RUSTFS_SECRET_KEY}"

RESTORE_DIR="/tmp/restore"

echo "=== Restore Started ==="

mkdir -p "${RESTORE_DIR}"

# Download from RustFS
if [ -n "${RUSTFS_ACCESS_KEY}" ]; then
  echo "Listing available backups..."
  aws s3 ls "s3://${RUSTFS_BUCKET}/" \
    --endpoint-url "${RUSTFS_ENDPOINT}" \
    --region us-east-1

  echo ""
  echo "To restore, provide a backup filename:"
  echo "  ./restore.sh workspace-20250101-020000.tar.gz"
  echo ""

  if [ -z "$1" ]; then
    echo "Usage: ./restore.sh <backup-filename>"
    echo "Example: ./restore.sh workspace-20250101-020000.tar.gz"
    exit 1
  fi

  BACKUP_FILE="$1"

  echo "Downloading ${BACKUP_FILE}..."
  aws s3 cp "s3://${RUSTFS_BUCKET}/${BACKUP_FILE}" \
    "${RESTORE_DIR}/${BACKUP_FILE}" \
    --endpoint-url "${RUSTFS_ENDPOINT}" \
    --region us-east-1

  echo "Extracting..."
  tar xzf "${RESTORE_DIR}/${BACKUP_FILE}" -C /

  echo "Restore complete!"
  echo "Restart code-server to apply changes."
else
  echo "Error: RUSTFS_ACCESS_KEY not set"
  exit 1
fi

echo "=== Restore Complete ==="
