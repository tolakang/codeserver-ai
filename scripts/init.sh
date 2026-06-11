#!/bin/bash
# init.sh
# Container entrypoint initialization

set -euo pipefail

LOG_FILE="/tmp/init.log"

json_escape() {
  local value="${1:-}"
  printf '%s' "$value" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e $'s/\t/\\t/g' -e $'s/\r/\\r/g'
}

yaml_escape() {
  local value="${1:-}"
  printf "%s" "$value" | sed "s/'/''/g"
}

write_opencode_config() {
  local provider="$1"
  local opencode_provider="$2"
  local base_url="$3"
  local api_key="$4"

  cat > /home/coder/.config/opencode/config.json <<EOF
{
  "provider": "$(json_escape "$opencode_provider")",
  "baseURL": "$(json_escape "$base_url")",
  "apiKey": "$(json_escape "$api_key")"
}
EOF
}

log() {
  echo "$1" | tee -a "$LOG_FILE"
}

echo "=== Code Server Init ===" | tee -a "$LOG_FILE"

mkdir -p /workspace /workspace/.memory /home/coder/.config/code-server /home/coder/.config/opencode /var/log/codeserver-ai

# Run extension installer
/scripts/install-extensions.sh

# Provider configuration from environment variables
if [ ! -f /home/coder/.config/opencode/config.json ]; then
  echo "=== AI Provider Configuration ===" | tee -a "$LOG_FILE"

  PROVIDER="${DEFAULT_PROVIDER:-freellmapi}"

  case "$PROVIDER" in
    openrouter)
      write_opencode_config "$PROVIDER" "openai" "${OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}" "${OPENROUTER_API_KEY:-}"
      ;;
    opencode-zen)
      write_opencode_config "$PROVIDER" "openai" "${OPENCODE_ZEN_BASE_URL:-https://opencode.ai/zen/api/v1}" "${OPENCODE_ZEN_API_KEY:-}"
      ;;
    freellmapi)
      write_opencode_config "$PROVIDER" "openai" "${FREELLMAPI_BASE_URL:-http://freellmapi:3000/v1}" "${FREELLMAPI_API_KEY:-}"
      ;;
    anthropic)
      write_opencode_config "$PROVIDER" "anthropic" "${ANTHROPIC_BASE_URL:-https://api.anthropic.com}" "${ANTHROPIC_API_KEY:-}"
      ;;
    openai)
      write_opencode_config "$PROVIDER" "openai" "${OPENAI_BASE_URL:-https://api.openai.com/v1}" "${OPENAI_API_KEY:-}"
      ;;
    *)
      echo "Warning: Unknown provider '$PROVIDER', using freellmapi as default" | tee -a "$LOG_FILE"
      write_opencode_config "$PROVIDER" "openai" "${FREELLMAPI_BASE_URL:-http://freellmapi:3000/v1}" "${FREELLMAPI_API_KEY:-}"
      ;;
  esac

  echo "OpenCode configured with $PROVIDER provider" | tee -a "$LOG_FILE"
  echo "Provider config saved to: /home/coder/.config/opencode/config.json"
else
  echo "OpenCode extension config already exists, skipping provider configuration" | tee -a "$LOG_FILE"
fi

# Copy OpenCode WEB config if not already in place
if [ ! -f /config/opencode-web/opencode.json ]; then
  mkdir -p /config/opencode-web
  echo "Warning: OpenCode WEB config not found, skipping" | tee -a "$LOG_FILE"
fi

# Substitute CS_PASSWORD in code-server config
if [ -f /home/coder/.config/code-server/config.yaml ]; then
  cat > /home/coder/.config/code-server/config.yaml <<EOF
bind-addr: 0.0.0.0:8443
auth: password
password: '$(yaml_escape "${CS_PASSWORD:?CS_PASSWORD must be set}")'
disable-telemetry: true
EOF
fi

# Create default git config if not exists
if [ ! -f /home/coder/.gitconfig ]; then
  cat > /home/coder/.gitconfig <<'EOF'
[user]
    name = coder
    email = coder@localhost
[core]
    editor = code-server
[alias]
    st = status
    co = checkout
    br = branch
    ci = commit
    lg = log --oneline --graph --decorate -20
EOF
  echo "Git config created" | tee -a "$LOG_FILE"
fi

# Clear extension cache to avoid VSDA issues
rm -rf /home/coder/.local/share/code-server/extensions/* 2>/dev/null || true

echo "=== Init Complete ===" | tee -a "$LOG_FILE"

# Execute code-server
exec code-server --bind-addr 0.0.0.0:8443 "${DEFAULT_WORKSPACE:-/workspace}" "$@"
