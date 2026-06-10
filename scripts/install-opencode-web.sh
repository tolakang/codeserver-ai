#!/bin/bash
# scripts/install-opencode-web.sh - Install OpenCode WEB interface

set -e

echo "Installing OpenCode WEB interface..."

# Install OpenCode CLI globally
if command -v npm >/dev/null 2>&1; then
  npm install -g opencode-ai
else
  echo "Error: npm not found. Please install Node.js and npm first."
  exit 1
fi

# Verify installation
if command -v opencode >/dev/null 2>&1; then
  OPCODE_VERSION=$(opencode --version)
  echo "OpenCode installed successfully (version: $OPCODE_VERSION)"
else
  echo "Error: opencode command not found after installation"
  exit 1
fi

echo "OpenCode WEB installation complete"