#!/bin/bash
# install-extensions.sh
# Auto-install Code Server extensions at startup

set -e

echo "Installing Code Server extensions..."

# Amazon S3 Explorer (pinned to v4.7.0+ for url.parse deprecation fix)
code-server --install-extension amazonwebservices.aws-toolkit-vscode@4.7.0 2>/dev/null || \
  echo "Warning: AWS Toolkit not found, skipping"

# Git integration
code-server --install-extension eamodio.gitlens 2>/dev/null || \
  echo "Warning: GitLens not found, skipping"

echo "Extensions installed successfully"
