#!/bin/bash
# scripts/render-compose.sh - Convert Dokploy compose files for local Docker Compose

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
  echo "Usage: $0 <compose-file> [output-file]"
  echo
  echo "Examples:"
  echo "  $0 docker-compose.yml docker-compose.local.yml"
  echo "  $0 deploy/docker-compose.code-server.yml /tmp/code-server.yml"
  echo
  echo "The rendered file replaces Dokploy \${{project.VAR}} placeholders with Docker Compose \${VAR} variables."
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ -z "${1:-}" ]; then
  usage
  exit 1
fi

COMPOSE_FILE="$1"
if [[ "$COMPOSE_FILE" != /* ]]; then
  COMPOSE_FILE="${ROOT_DIR}/${COMPOSE_FILE}"
fi

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "Error: compose file not found: $COMPOSE_FILE" >&2
  exit 1
fi

OUTPUT_FILE="${2:-}"
if [ -n "$OUTPUT_FILE" ] && [[ "$OUTPUT_FILE" != /* ]]; then
  OUTPUT_FILE="${ROOT_DIR}/${OUTPUT_FILE}"
fi

rendered="$(sed -E 's/\$\{\{project\.([A-Za-z_][A-Za-z0-9_]*)\}\}/\${\1}/g' "$COMPOSE_FILE")"

if [ -n "$OUTPUT_FILE" ]; then
  mkdir -p "$(dirname "$OUTPUT_FILE")"
  printf '%s\n' "$rendered" > "$OUTPUT_FILE"
  echo "Rendered compose file: $OUTPUT_FILE"
else
  printf '%s\n' "$rendered"
fi
