#!/bin/bash
# scripts/generate-configs.sh - OpenCode configuration generator
# NOTE: This script generates config at runtime, not in the repo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_FILE="${1:-/tmp/unified-config.json}"

load_env_file() {
  local file="${1:-${ROOT_DIR}/.env}"
  local line key value

  [[ -f "$file" ]] || return 0

  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]] || continue

    key="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"

    if [[ "$value" == \"*\" && "$value" == *\" ]]; then
      value="${value:1:${#value}-2}"
    elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
      value="${value:1:${#value}-2}"
    fi

    declare -gx "$key=$value"
  done < "$file"
}

json_escape() {
  local value="${1:-}"
  printf '%s' "$value" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e $'s/\t/\\t/g' -e $'s/\r/\\r/g'
}

load_env_file "${ROOT_DIR}/.env"

mkdir -p "$(dirname "$OUTPUT_FILE")"

cat > "$OUTPUT_FILE" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "server": {
    "port": 4001,
    "hostname": "0.0.0.0"
  },
  "provider": {
    "openrouter": {
      "options": {
        "baseURL": "$(json_escape "${OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}")",
        "apiKey": "$(json_escape "${OPENROUTER_API_KEY:-}")"
      }
    },
    "opencode-zen": {
      "options": {
        "baseURL": "$(json_escape "${OPENCODE_ZEN_BASE_URL:-https://opencode.ai/zen/api/v1}")",
        "apiKey": "$(json_escape "${OPENCODE_ZEN_API_KEY:-}")"
      }
    },
    "openai": {
      "options": {
        "baseURL": "$(json_escape "${FREELLMAPI_BASE_URL:-http://freellmapi:3000/v1}")",
        "apiKey": "$(json_escape "${FREELLMAPI_API_KEY:-}")"
      }
    },
    "anthropic": {
      "options": {
        "apiKey": "$(json_escape "${ANTHROPIC_API_KEY:-}")"
      }
    }
  },
  "model": "$(json_escape "${OPENCODE_MODEL:-}")"
}
EOF

echo "Generated OpenCode config at $OUTPUT_FILE"
