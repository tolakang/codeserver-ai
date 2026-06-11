#!/bin/bash
# init.sh
# Container entrypoint initialization

set -e

LOG_FILE="/var/log/init.log"

echo "=== Code Server Init ===" | tee -a "$LOG_FILE"

# Run extension installer
/scripts/install-extensions.sh

# Provider selection for OpenCode
if [ ! -f /home/coder/.config/opencode/config.json ]; then
  echo "=== AI Provider Selection ===" | tee -a "$LOG_FILE"
  echo "Select your preferred AI provider:" | tee -a "$LOG_FILE"
  echo "1. OpenRouter (default)" | tee -a "$LOG_FILE"
  echo "2. OpenCode Zen" | tee -a "$LOG_FILE"
  echo "3. FreeLLMAPI (default)" | tee -a "$LOG_FILE"
  echo "4. Anthropic" | tee -a "$LOG_FILE"
  echo "5. OpenAI" | tee -a "$LOG_FILE"
  echo "" | tee -a "$LOG_FILE"
  
  read -p "Enter choice (1-5): " provider_choice
  
  case $provider_choice in
    1) PROVIDER="openrouter" ;;
    2) PROVIDER="opencode-zen" ;;
    3) PROVIDER="freellmapi" ;;
    4) PROVIDER="anthropic" ;;
    5) PROVIDER="openai" ;;
    *) PROVIDER="freellmapi" ;;
  esac
  
  mkdir -p /home/coder/.config/opencode
  
  # Generate provider config
  case $PROVIDER in
    openrouter)
      cat > /home/coder/.config/opencode/config.json <<'EOF'
{
  "provider": "openai",
  "baseURL": "https://openrouter.ai/api/v1",
  "apiKey": "${OPENROUTER_API_KEY}"
}
EOF
      ;;
    opencode-zen)
      cat > /home/coder/.config/opencode/config.json <<'EOF'
{
  "provider": "openai",
  "baseURL": "https://opencode.ai/zen/api/v1",
  "apiKey": "${OPENCODE_ZEN_API_KEY}"
}
EOF
      ;;
    freellmapi)
      cat > /home/coder/.config/opencode/config.json <<'EOF'
{
  "provider": "openai",
  "baseURL": "https://freellmapi:3000/v1",
  "apiKey": "${FREELLMAPI_API_KEY}"
}
EOF
      ;;
    anthropic)
      cat > /home/coder/.config/opencode/config.json <<'EOF'
{
  "provider": "anthropic",
  "baseURL": "https://api.anthropic.com",
  "apiKey": "${ANTHROPIC_API_KEY}"
}
EOF
      ;;
    openai)
      cat > /home/coder/.config/opencode/config.json <<'EOF'
{
  "provider": "openai",
  "baseURL": "https://api.openai.com/v1",
  "apiKey": "${OPENAI_API_KEY}"
}
EOF
      ;;
  esac
  
  echo "OpenCode configured with $PROVIDER provider" | tee -a "$LOG_FILE"
  echo "Provider config saved to: /home/coder/.config/opencode/config.json"
else
  echo "OpenCode extension config already exists, skipping provider selection" | tee -a "$LOG_FILE"
fi

# Copy OpenCode WEB config if not already in place
if [ ! -f /config/opencode-web/opencode.json ]; then
  mkdir -p /config/opencode-web
  echo "Warning: OpenCode WEB config not found, skipping" | tee -a "$LOG_FILE"
fi

# Substitute ${CS_PASSWORD} in code-server config
if [ -f /home/coder/.config/code-server/config.yaml ]; then
  sed -i "s|\${CS_PASSWORD}|${CS_PASSWORD:-changeme}|g" /home/coder/.config/code-server/config.yaml
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
exec code-server --bind-addr 0.0.0.0:8080 /workspace "$@"
