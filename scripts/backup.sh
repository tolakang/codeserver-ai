#!/bin/bash
# Consolidated backup script for Code Server AI
# Backs up workspace, config, and Gitea database to RustFS S3

set -euo pipefail

LOG_FILE="/tmp/backup.log"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="/tmp/backups"
RUSTFS_ENDPOINT="${RUSTFS_ENDPOINT:-http://rustfs:9000}"
RUSTFS_BUCKET="${RUSTFS_BUCKET:-code-server-backups}"
POSTGRES_HOST="${POSTGRES_HOST:-pgbouncer}"
POSTGRES_PORT="${POSTGRES_PORT:-6432}"
POSTGRES_USER="${POSTGRES_USER:-${GITEA_DB_USER:-gitea}}"
POSTGRES_DB="${POSTGRES_DB:-${GITEA_DB_NAME:-gitea}}"
DAILY_RETENTION=7

export AWS_ACCESS_KEY_ID="${RUSTFS_ACCESS_KEY:-}"
export AWS_SECRET_ACCESS_KEY="${RUSTFS_SECRET_KEY:-}"
export AWS_DEFAULT_REGION="us-east-1"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== Backup Started: ${TIMESTAMP} ==="

mkdir -p "${BACKUP_DIR}"

if [ -z "${AWS_ACCESS_KEY_ID}" ] || [ -z "${AWS_SECRET_ACCESS_KEY}" ]; then
  log "Error: RUSTFS_ACCESS_KEY and RUSTFS_SECRET_KEY must be set"
  exit 1
fi

if [ -z "${POSTGRES_PASSWORD:-}" ]; then
  log "Error: POSTGRES_PASSWORD must be set"
  exit 1
fi

log "Backing up workspace..."
tar czf "${BACKUP_DIR}/workspace-${TIMESTAMP}.tar.gz" \
  --exclude='node_modules' \
  --exclude='.cache' \
  --exclude='.npm' \
  --exclude='__pycache__' \
  -C /workspace . 2>/dev/null || true

log "Backing up config..."
tar czf "${BACKUP_DIR}/config-${TIMESTAMP}.tar.gz" \
  -C /home/coder .config 2>/dev/null || true

log "Backing up Gitea database..."
PGPASSWORD="${POSTGRES_PASSWORD}" pg_dump \
  -h "${POSTGRES_HOST}" -p "${POSTGRES_PORT}" -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" \
  --no-owner --no-privileges \
  --clean --if-exists \
  | gzip > "${BACKUP_DIR}/gitea-${TIMESTAMP}.sql.gz"

for archive in workspace config gitea; do
  FILE="${BACKUP_DIR}/${archive}-${TIMESTAMP}.tar.gz"
  if [[ "$archive" == "gitea" ]]; then
    FILE="${BACKUP_DIR}/${archive}-${TIMESTAMP}.sql.gz"
  fi
  if [ ! -s "${FILE}" ]; then
    log "Warning: ${archive} backup is empty, skipping upload"
    rm -f "${FILE}"
  fi
done

log "Uploading to RustFS..."
UPLOAD_ERRORS=0

for archive in workspace config gitea; do
  FILE="${BACKUP_DIR}/${archive}-${TIMESTAMP}.tar.gz"
  if [[ "$archive" == "gitea" ]]; then
    FILE="${BACKUP_DIR}/${archive}-${TIMESTAMP}.sql.gz"
  fi
  if [ -f "${FILE}" ]; then
    if ! aws s3 cp "${FILE}" \
      "s3://${RUSTFS_BUCKET}/${archive}-${TIMESTAMP}.$( [[ "$archive" == "gitea" ]] && printf 'sql.gz' || printf 'tar.gz' )" \
      --endpoint-url "${RUSTFS_ENDPOINT}" 2>/dev/null; then
      log "Error: ${archive} upload failed"
      UPLOAD_ERRORS=$((UPLOAD_ERRORS + 1))
    fi
  fi
done

log "Cleaning up old local backups..."
find "${BACKUP_DIR}" -name "*.tar.gz" -mtime +"${DAILY_RETENTION}" -delete 2>/dev/null || true
find "${BACKUP_DIR}" -name "*.sql.gz" -mtime +"${DAILY_RETENTION}" -delete 2>/dev/null || true

log "Cleaning up old remote backups..."
CUTOFF_DATE="$(date -d "-${DAILY_RETENTION} days" +%Y-%m-%d 2>/dev/null || date -v-"${DAILY_RETENTION}"d +%Y-%m-%d 2>/dev/null || true)"
if [ -n "${CUTOFF_DATE}" ]; then
  aws s3 ls "s3://${RUSTFS_BUCKET}/" \
    --endpoint-url "${RUSTFS_ENDPOINT}" 2>/dev/null | \
    awk -v cutoff="${CUTOFF_DATE}" '$1 < cutoff {print $4}' | \
    grep -v '^$' | \
    xargs -r -I {} aws s3 rm "s3://${RUSTFS_BUCKET}/{}" \
      --endpoint-url "${RUSTFS_ENDPOINT}" 2>/dev/null || true
fi

rm -f "${BACKUP_DIR}"/*.tar.gz
rm -f "${BACKUP_DIR}"/*.sql.gz

if [ "${UPLOAD_ERRORS}" -gt 0 ]; then
  log "=== Backup Completed with Errors: ${TIMESTAMP} ==="
  exit 1
fi

log "=== Backup Complete: ${TIMESTAMP} ==="
