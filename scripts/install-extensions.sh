#!/bin/bash
# install-extensions.sh
# Auto-install Code Server extensions at startup

set -e

LOG_FILE="/var/log/install-extensions.log"

echo "Installing Code Server extensions..." | tee -a "$LOG_FILE"

# Amazon S3 Explorer (pinned to v4.7.0+ for url.parse deprecation fix)
if code-server --install-extension amazonwebservices.aws-toolkit-vscode@4.7.0 2>/dev/null; then
  echo "Successfully installed AWS Toolkit" | tee -a "$LOG_FILE"
else
  echo "Warning: AWS Toolkit not found, skipping" | tee -a "$LOG_FILE"
fi

# Git integration
if code-server --install-extension eamodio.gitlens 2>/dev/null; then
  echo "Successfully installed GitLens" | tee -a "$LOG_FILE"
else
  echo "Warning: GitLens not found, skipping" | tee -a "$LOG_FILE"
fi

# GitHub Pull Requests
if code-server --install-extension github.vscode-pull-request-github 2>/dev/null; then
  echo "Successfully installed GitHub Pull Requests" | tee -a "$LOG_FILE"
else
  echo "Warning: GitHub Pull Requests not found, skipping" | tee -a "$LOG_FILE"
fi

# OpenCode AI Extension
if code-server --install-extension opencode.opencode 2>/dev/null; then
  echo "Successfully installed OpenCode extension" | tee -a "$LOG_FILE"
else
  echo "Warning: OpenCode extension not found, skipping" | tee -a "$LOG_FILE"
fi

echo "Extensions installation complete" | tee -a "$LOG_FILE"
