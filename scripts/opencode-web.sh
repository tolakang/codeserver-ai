#!/bin/bash
# scripts/opencode-web.sh - OpenCode WEB server management

set -e

echo "=== OpenCode WEB Server Starting ==="

echo "Starting OpenCode WEB..."

# Start OpenCode WEB with configuration
exec opencode web \
  --port "${OPENCODE_WEB_PORT:-4001}" \
  --hostname "${OPENCODE_WEB_HOSTNAME:-0.0.0.0}"