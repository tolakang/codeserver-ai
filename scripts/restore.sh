#!/bin/bash
# restore.sh
# Restore from RustFS S3 backup

set -euo pipefail

LOG_FILE="/tmp/restore.log"
RUSTFS_ENDPOINT="${RUSTFS_ENDPOINT:-http://rustfs:9000}"
RUSTFS_BUCKET="${RUSTFS_BUCKET:-code-server-backups}"

export AWS_ACCESS_KEY_ID="${RUSTFS_ACCESS_KEY:-}"
export AWS_SECRET_ACCESS_KEY="${RUSTFS_SECRET_KEY:-}"
export AWS_DEFAULT_REGION="us-east-1"

RESTORE_DIR="/tmp/restore"
POSTGRES_HOST="${POSTGRES_HOST:-pgbouncer}"
POSTGRES_PORT="${POSTGRES_PORT:-6432}"
POSTGRES_USER="${POSTGRES_USER:-${GITEA_DB_USER:-gitea}}"
POSTGRES_DB="${POSTGRES_DB:-${GITEA_DB_NAME:-gitea}}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Restore Started ==="

if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
  log "Error: RUSTFS_ACCESS_KEY and RUSTFS_SECRET_KEY must be set"
  exit 1
fi

mkdir -p "${RESTORE_DIR}"

log "Listing available backups..."
aws s3 ls "s3://${RUSTFS_BUCKET}/" \
  --endpoint-url "${RUSTFS_ENDPOINT}" | tee -a "$LOG_FILE"

if [ -z "${1:-}" ]; then
  log "Usage: ./restore.sh <backup-filename>"
  log "Example: ./restore.sh workspace-20250101-020000.tar.gz"
  exit 1
fi

BACKUP_FILE="$1"
if [[ "${BACKUP_FILE}" =~ ^(workspace|config)-[0-9]{8}-[0-9]{6}\.tar\.gz$ ]]; then
  RESTORE_TYPE="filesystem"
elif [[ "${BACKUP_FILE}" =~ ^gitea-[0-9]{8}-[0-9]{6}\.sql\.gz$ ]]; then
  RESTORE_TYPE="gitea-db"
else
  log "Error: Invalid backup filename format"
  log "Expected: <workspace|config>-YYYYMMDD-HHMMSS.tar.gz or gitea-YYYYMMDD-HHMMSS.sql.gz"
  exit 1
fi

log "Creating pre-restore snapshot..."
SNAPSHOT_DIR="/tmp/pre-restore-snapshot"
mkdir -p "${SNAPSHOT_DIR}"
if [ "${RESTORE_TYPE}" = "filesystem" ]; then
  tar czf "${SNAPSHOT_DIR}/workspace-pre-restore-$(date +%Y%m%d-%H%M%S).tar.gz" \
    --exclude='node_modules' \
    --exclude='.cache' \
    -C /workspace . 2>/dev/null || true
  tar czf "${SNAPSHOT_DIR}/config-pre-restore-$(date +%Y%m%d-%H%M%S).tar.gz" \
    -C /home/coder .config 2>/dev/null || true
else
  PGPASSWORD="${POSTGRES_PASSWORD:-}" pg_dump \
    -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
    --no-owner --no-privileges \
    --clean --if-exists \
    | gzip > "${SNAPSHOT_DIR}/gitea-pre-restore-$(date +%Y%m%d-%H%M%S).sql.gz" || true
fi

log "Snapshot saved to ${SNAPSHOT_DIR}/"

log "Downloading ${BACKUP_FILE}..."
if ! aws s3 cp "s3://${RUSTFS_BUCKET}/${BACKUP_FILE}" \
  "${RESTORE_DIR}/${BACKUP_FILE}" \
  --endpoint-url "${RUSTFS_ENDPOINT}" 2>/dev/null; then
  log "Error: Download failed"
  exit 1
fi

if [ ! -s "${RESTORE_DIR}/${BACKUP_FILE}" ]; then
  log "Error: Downloaded file is empty"
  exit 1
fi

if [ "${RESTORE_TYPE}" = "filesystem" ]; then
  if ! tar tzf "${RESTORE_DIR}/${BACKUP_FILE}" > /dev/null 2>&1; then
    log "Error: Downloaded file is not a valid tar.gz archive"
    exit 1
  fi

  log "Extracting filesystem backup..."
  tar xzf "${RESTORE_DIR}/${BACKUP_FILE}" -C / --no-same-owner
else
  if ! gzip -t "${RESTORE_DIR}/${BACKUP_FILE}" >/dev/null 2>&1; then
    log "Error: Downloaded file is not a valid gzip archive"
    exit 1
  fi

  if [ -z "${POSTGRES_PASSWORD:-}" ]; then
    log "Error: POSTGRES_PASSWORD must be set to restore Gitea database backups"
    exit 1
  fi

  log "Restoring Gitea database..."
  gzip -dc "${RESTORE_DIR}/${BACKUP_FILE}" | PGPASSWORD="${POSTGRES_PASSWORD}" psql \
    -v ON_ERROR_STOP=1 \
    -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"
fi

rm -f "${RESTORE_DIR}/${BACKUP_FILE}"

log "Restore complete!"
log "Pre-restore snapshot: ${SNAPSHOT_DIR}/"
if [ "${RESTORE_TYPE}" = "filesystem" ]; then
  log "Restart code-server to apply filesystem changes."
else
  log "Restart gitea to apply database changes."
fi
log "=== Restore Complete ==="
