#!/bin/bash
# scripts/resolve-env.sh - Generate .env from .env.example

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
EXAMPLE_FILE="${ROOT_DIR}/.env.example"
OUTPUT_FILE="${ROOT_DIR}/.env"
IN_ENVIRONMENT_SECTION=0

if [ ! -f "$EXAMPLE_FILE" ]; then
    echo "Error: $EXAMPLE_FILE not found"
    echo "Please create .env.example from the template"
    exit 1
fi

echo "Generating .env from .env.example..."

: > "$OUTPUT_FILE"

while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" =~ ^#\ ENVIRONMENT\ SECTION ]]; then
        IN_ENVIRONMENT_SECTION=1
        continue
    fi

    if [[ "$line" == "# PROJECT SECTION"* || "$line" == "# SERVICE SECTION"* ]]; then
        IN_ENVIRONMENT_SECTION=0
        continue
    fi

    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

    if [[ "$IN_ENVIRONMENT_SECTION" -eq 1 && "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
        printf '%s=%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" >> "$OUTPUT_FILE"
    fi
done < "$EXAMPLE_FILE"

echo ""
echo "Environment variables written to $OUTPUT_FILE"
echo "Review the file and replace placeholder values before using Docker Compose."
