#!/bin/bash
# scripts/opencode-web.sh - OpenCode WEB server management

set -e

echo "=== OpenCode WEB Server Starting ==="

# Wait for dependencies
FRELLMAPI_URL="http://freellmapi:3000/health"
MAX_RETRIES=30
RETRY_COUNT=0

echo "Waiting for FreeLLMAPI at $FRELLMAPI_URL..."

until curl -f "$FRELLMAPI_URL" >/dev/null 2>&1; do
  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
    echo "Error: FreeLLMAPI did not become healthy after $MAX_RETRIES attempts"
    exit 1
  fi
  echo "Retry $RETRY_COUNT/$MAX_RETRIES..."
  sleep 2
done

echo "FreeLLMAPI is healthy, starting OpenCode WEB..."

# Start OpenCode WEB with configuration
exec opencode web \
  --port 4001 \
  --hostname 0.0.0.0 \
  --mdns \
  --mdns-domain opencode.local