#!/bin/bash
# scripts/opencode-web.sh - OpenCode WEB server management

set -e

echo "=== OpenCode WEB Server Starting ==="

echo "Starting OpenCode WEB..."

# Start OpenCode WEB with configuration
exec opencode web \
  --port 4001 \
  --hostname 0.0.0.0 \
  --mdns \
  --mdns-domain opencode.local