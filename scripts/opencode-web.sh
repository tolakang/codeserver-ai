#!/bin/bash
# scripts/opencode-web.sh - OpenCode WEB server management

set -e

echo "=== OpenCode WEB Server Starting ==="

# Ensure config directory exists
mkdir -p "$HOME/.config/opencode"

# Generate opencode.json from environment variables
# OpenCode supports {env:VAR} substitution for sensitive values
cat > "$HOME/.config/opencode/opencode.json" <<'OPencodeEOF'
{
  "$schema": "https://opencode.ai/config.json",
  "server": {
    "port": 4001,
    "hostname": "0.0.0.0"
  },
  "provider": {
    "openrouter": {
      "options": {
        "baseURL": "{env:OPENROUTER_BASE_URL}",
        "apiKey": "{env:OPENROUTER_API_KEY}"
      }
    },
    "opencode-zen": {
      "options": {
        "baseURL": "{env:OPENCODE_ZEN_BASE_URL}",
        "apiKey": "{env:OPENCODE_ZEN_API_KEY}"
      }
    },
    "openai": {
      "options": {
        "baseURL": "{env:OPENAI_BASE_URL}",
        "apiKey": "{env:OPENAI_API_KEY}"
      }
    },
    "anthropic": {
      "options": {
        "apiKey": "{env:ANTHROPIC_API_KEY}"
      }
    }
  },
  "model": "{env:OPENCODE_MODEL}"
}
OPencodeEOF

# Substitute runtime variables
sed -i "s/\"port\": 4001/\"port\": ${OPENCODE_WEB_PORT:-4001}/" "$HOME/.config/opencode/opencode.json"
sed -i "s/\"hostname\": \"0.0.0.0\"/\"hostname\": \"${OPENCODE_WEB_HOSTNAME:-0.0.0.0}\"/" "$HOME/.config/opencode/opencode.json"

echo "Generated OpenCode config at $HOME/.config/opencode/opencode.json"

# Start OpenCode WEB with configuration
exec opencode web \
  --port "${OPENCODE_WEB_PORT:-4001}" \
  --hostname "${OPENCODE_WEB_HOSTNAME:-0.0.0.0}"
