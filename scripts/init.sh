#!/bin/bash
# init.sh
# Container entrypoint initialization

set -e

echo "=== Code Server Init ==="

# Run extension installer
/scripts/install-extensions.sh

# Copy OpenCode config if not already in place
if [ ! -f /home/coder/.config/opencode/config.json ]; then
  mkdir -p /home/coder/.config/opencode
  if cp /config/opencode/config.json /home/coder/.config/opencode/config.json 2>/dev/null; then
    echo "OpenCode extension config installed"
  else
    echo "Warning: OpenCode extension config not found, skipping"
  fi
fi

# Copy OpenCode WEB config if not already in place
if [ ! -f /config/opencode-web/opencode.json ]; then
  mkdir -p /config/opencode-web
  echo "Warning: OpenCode WEB config not found, skipping"
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
  echo "Git config created"
fi

echo "=== Init Complete ==="

# Execute code-server
exec code-server --bind-addr 0.0.0.0:8080 /workspace "$@"
