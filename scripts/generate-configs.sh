#!/bin/bash
# scripts/generate-configs.sh - Unified configuration generator
# NOTE: This script generates config at runtime, not in the repo.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Resolve placeholders from .env.values if .env doesn't exist
if [ ! -f .env ] && [ -f "$ROOT_DIR/.env.values" ]; then
    echo "No .env found, resolving from .env.values..."
    source "$SCRIPT_DIR/resolve-env.sh"
fi

# Load environment variables
if [ -f .env ]; then
    source .env
fi

OUTPUT_FILE="${1:-/tmp/unified-config.json}"

# Generate unified-config.json with variable substitution
cat > "$OUTPUT_FILE" << EOF
{
  "providers": {
    "openrouter": {
      "baseURL": "${OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}",
      "apiKey": "${OPENROUTER_API_KEY}",
      "description": "OpenRouter AI platform with multiple model support"
    },
    "opencode-zen": {
      "baseURL": "${OPENCODE_ZEN_BASE_URL:-https://opencode.ai/zen/api/v1}",
      "apiKey": "${OPENCODE_ZEN_API_KEY}",
      "description": "OpenCode Zen for fast, efficient AI coding"
    },
    "freellmapi": {
      "baseURL": "${FRELLMAPI_BASE_URL:-http://freellmapi:3000/v1}",
      "apiKey": "${FRELLMAPI_API_KEY}",
      "description": "FreeLLMAPI for proxying multiple free models"
    },
    "anthropic": {
      "baseURL": "${ANTHROPIC_BASE_URL:-https://api.anthropic.com}",
      "apiKey": "${ANTHROPIC_API_KEY}",
      "description": "Anthropic Claude models"
    },
    "openai": {
      "baseURL": "${OPENAI_BASE_URL:-https://api.openai.com/v1}",
      "apiKey": "${OPENAI_API_KEY}",
      "description": "OpenAI GPT models"
    }
  },
  "defaultProvider": "${DEFAULT_PROVIDER:-freellmapi}",
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
