#!/bin/bash
# init.sh
# Container entrypoint initialization

set -e

LOG_FILE="/var/log/init.log"

echo "=== Code Server Init ===" | tee -a "$LOG_FILE"

# Run extension installer
/scripts/install-extensions.sh

# Provider configuration from environment variables
if [ ! -f /home/coder/.config/opencode/config.json ]; then
  echo "=== AI Provider Configuration ===" | tee -a "$LOG_FILE"
  
  # Determine provider from environment or use default
  PROVIDER="${DEFAULT_PROVIDER:-freellmapi}"
  
  mkdir -p /home/coder/.config/opencode
  
  # Generate provider config based on environment
  case $PROVIDER in
    openrouter)
      cat > /home/coder/.config/opencode/config.json <<EOF
{
  "provider": "openai",
  "baseURL": "${OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}",
  "apiKey": "${OPENROUTER_API_KEY}"
}
EOF
      ;;
    opencode-zen)
      cat > /home/coder/.config/opencode/config.json <<EOF
{
  "provider": "openai",
  "baseURL": "${OPENCODE_ZEN_BASE_URL:-https://opencode.ai/zen/api/v1}",
  "apiKey": "${OPENCODE_ZEN_API_KEY}"
}
EOF
      ;;
    freellmapi)
      cat > /home/coder/.config/opencode/config.json <<EOF
{
  "provider": "openai",
  "baseURL": "${FRELLMAPI_BASE_URL:-https://freellmapi:3000/v1}",
  "apiKey": "${FREELLMAPI_API_KEY}"
}
EOF
      ;;
    anthropic)
      cat > /home/coder/.config/opencode/config.json <<EOF
{
  "provider": "anthropic",
  "baseURL": "${ANTHROPIC_BASE_URL:-https://api.anthropic.com}",
  "apiKey": "${ANTHROPIC_API_KEY}"
}
EOF
      ;;
    openai)
      cat > /home/coder/.config/opencode/config.json <<EOF
{
  "provider": "openai",
  "baseURL": "${OPENAI_BASE_URL:-https://api.openai.com/v1}",
  "apiKey": "${OPENAI_API_KEY}"
}
EOF
      ;;
    *)
      echo "Warning: Unknown provider '$PROVIDER', using freellmapi as default" | tee -a "$LOG_FILE"
      cat > /home/coder/.config/opencode/config.json <<EOF
{
  "provider": "openai",
  "baseURL": "${FRELLMAPI_BASE_URL:-https://freellmapi:3000/v1}",
  "apiKey": "${FREELLMAPI_API_KEY}"
}
EOF
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

# Substitute ${CS_PASSWORD} in code-server config
if [ -f /home/coder/.config/code-server/config.yaml ]; then
  sed -i "s|\${CS_PASSWORD}|${CS_PASSWORD:?CS_PASSWORD must be set}|g" /home/coder/.config/code-server/config.yaml
fi

# Create memory directory
mkdir -p /workspace/.memory

# Ensure workspace and config dirs exist
mkdir -p /workspace /home/coder/.config/code-server

# Clear extension cache to avoid VSDA issues
rm -rf /home/coder/.local/share/code-server/extensions/* 2>/dev/null || true

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

echo "=== Init Complete ===" | tee -a "$LOG_FILE"

# Execute code-server
exec code-server --bind-addr 0.0.0.0:8443 /workspace "$@"
