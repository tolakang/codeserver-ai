#!/bin/bash
# scripts/generate-configs.sh - Unified configuration generator
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
  "providers": {
    "openrouter": {
      "baseURL": "$(json_escape "${OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}")",
      "apiKey": "$(json_escape "${OPENROUTER_API_KEY:-}")",
      "description": "OpenRouter AI platform with multiple model support"
    },
    "opencode-zen": {
      "baseURL": "$(json_escape "${OPENCODE_ZEN_BASE_URL:-https://opencode.ai/zen/api/v1}")",
      "apiKey": "$(json_escape "${OPENCODE_ZEN_API_KEY:-}")",
      "description": "OpenCode Zen for fast, efficient AI coding"
    },
    "freellmapi": {
      "baseURL": "$(json_escape "${FREELLMAPI_BASE_URL:-http://freellmapi:3000/v1}")",
      "apiKey": "$(json_escape "${FREELLMAPI_API_KEY:-}")",
      "description": "FreeLLMAPI for proxying multiple free models"
    },
    "anthropic": {
      "baseURL": "$(json_escape "${ANTHROPIC_BASE_URL:-https://api.anthropic.com}")",
      "apiKey": "$(json_escape "${ANTHROPIC_API_KEY:-}")",
      "description": "Anthropic Claude models"
    },
    "openai": {
      "baseURL": "$(json_escape "${OPENAI_BASE_URL:-https://api.openai.com/v1}")",
      "apiKey": "$(json_escape "${OPENAI_API_KEY:-}")",
      "description": "OpenAI GPT models"
    }
  },
  "defaultProvider": "$(json_escape "${DEFAULT_PROVIDER:-freellmapi}")",
  "server": {
    "port": 4001,
    "hostname": "0.0.0.0",
    "mdns": true,
    "mdns-domain": "opencode.local",
    "cors": []
  }
}
EOF

echo "Generated unified-config.json at $OUTPUT_FILE"
