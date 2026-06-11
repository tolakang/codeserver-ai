#!/bin/bash
# install-extensions.sh
# Auto-install Code Server extensions at startup

set -euo pipefail

LOG_FILE="/tmp/install-extensions.log"

log() {
  echo "$1" | tee -a "$LOG_FILE"
}

log "Installing Code Server extensions..."

if code-server --install-extension amazonwebservices.aws-toolkit-vscode@4.7.0 2>/dev/null; then
  log "Successfully installed AWS Toolkit"
else
  log "Warning: AWS Toolkit not found, skipping"
fi

if code-server --install-extension eamodio.gitlens 2>/dev/null; then
  log "Successfully installed GitLens"
else
  log "Warning: GitLens not found, skipping"
fi

if code-server --install-extension github.vscode-pull-request-github 2>/dev/null; then
  log "Successfully installed GitHub Pull Requests"
else
  log "Warning: GitHub Pull Requests not found, skipping"
fi

if code-server --install-extension opencode.opencode 2>/dev/null; then
  log "Successfully installed OpenCode extension"
else
  log "Warning: OpenCode extension not found, skipping"
fi

log "Extensions installation complete"
