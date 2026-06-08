#!/bin/bash
# restore.sh
# Restore from RustFS S3 backup

set -e

# Configuration
RUSTFS_ENDPOINT="${RUSTFS_ENDPOINT:-http://rustfs:9000}"
RUSTFS_BUCKET="${RUSTFS_BUCKET:-code-server-backups}"

# Map to AWS CLI environment variables
export AWS_ACCESS_KEY_ID="${RUSTFS_ACCESS_KEY}"
export AWS_SECRET_ACCESS_KEY="${RUSTFS_SECRET_KEY}"
export AWS_DEFAULT_REGION="us-east-1"

RESTORE_DIR="/tmp/restore"

echo "=== Restore Started ==="

# Validate credentials
if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
  echo "Error: RUSTFS_ACCESS_KEY and RUSTFS_SECRET_KEY must be set"
  exit 1
fi

mkdir -p "${RESTORE_DIR}"

# List available backups
echo "Listing available backups..."
aws s3 ls "s3://${RUSTFS_BUCKET}/" \
  --endpoint-url "${RUSTFS_ENDPOINT}"

echo ""

if [ -z "$1" ]; then
  echo "Usage: ./restore.sh <backup-filename>"
  echo "Example: ./restore.sh workspace-20250101-020000.tar.gz"
  exit 1
fi

# Validate filename format
BACKUP_FILE="$1"
if [[ ! "${BACKUP_FILE}" =~ ^[a-zA-Z0-9._-]+\.tar\.gz$ ]]; then
  echo "Error: Invalid backup filename format"
  echo "Expected: <name>-YYYYMMDD-HHMMSS.tar.gz"
  exit 1
fi

# Create pre-restore snapshot
echo "Creating pre-restore snapshot..."
SNAPSHOT_DIR="/tmp/pre-restore-snapshot"
mkdir -p "${SNAPSHOT_DIR}"
tar czf "${SNAPSHOT_DIR}/workspace-pre-restore-$(date +%Y%m%d-%H%M%S).tar.gz" \
  --exclude='node_modules' \
  --exclude='.cache' \
  -C /mnt/storage/code-server workspace 2>/dev/null || true
echo "Snapshot saved to ${SNAPSHOT_DIR}/"

# Download from RustFS
echo "Downloading ${BACKUP_FILE}..."
if ! aws s3 cp "s3://${RUSTFS_BUCKET}/${BACKUP_FILE}" \
  "${RESTORE_DIR}/${BACKUP_FILE}" \
  --endpoint-url "${RUSTFS_ENDPOINT}"; then
  echo "Error: Download failed"
  exit 1
fi

# Validate archive
if [ ! -s "${RESTORE_DIR}/${BACKUP_FILE}" ]; then
  echo "Error: Downloaded file is empty"
  exit 1
fi

if ! tar tzf "${RESTORE_DIR}/${BACKUP_FILE}" > /dev/null 2>&1; then
  echo "Error: Downloaded file is not a valid tar.gz archive"
  exit 1
fi

# Extract
echo "Extracting..."
tar xzf "${RESTORE_DIR}/${BACKUP_FILE}" -C / --no-same-owner

# Cleanup
rm -f "${RESTORE_DIR}/${BACKUP_FILE}"

echo "Restore complete!"
echo "Pre-restore snapshot: ${SNAPSHOT_DIR}/"
echo "Restart code-server to apply changes."

echo "=== Restore Complete ==="
