#!/bin/bash
# install-extensions.sh
# Auto-install Code Server extensions at startup

set -e

echo "Installing Code Server extensions..."

# OpenCode AI
code-server --install-extension opencode.opencode 2>/dev/null || \
  echo "Warning: opencode.opencode not found on marketplace, skipping"

# Amazon S3 Explorer
code-server --install-extension amazonwebservices.aws-toolkit-vscode 2>/dev/null || \
  echo "Warning: AWS Toolkit not found, skipping"

# Git integration
code-server --install-extension eamodio.gitlens 2>/dev/null || \
  echo "Warning: GitLens not found, skipping"

echo "Extensions installed successfully"
