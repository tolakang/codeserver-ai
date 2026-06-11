#!/bin/bash
# scripts/install-opencode-web.sh - Install OpenCode WEB interface

set -euo pipefail

OPENCODE_VERSION="${OPENCODE_VERSION:-latest}"

echo "Installing OpenCode WEB interface..."

if command -v npm >/dev/null 2>&1; then
  npm install -g "opencode-ai@${OPENCODE_VERSION}"
else
  echo "Error: npm not found. Please install Node.js and npm first."
  exit 1
fi

if command -v opencode >/dev/null 2>&1; then
  OPENCODE_VERSION_INSTALLED="$(opencode --version)"
  echo "OpenCode installed successfully (version: $OPENCODE_VERSION_INSTALLED)"
else
  echo "Error: opencode command not found after installation"
  exit 1
fi

echo "OpenCode WEB installation complete"
