#!/bin/bash
# update.sh
# Pull latest source and rebuild all services
# Usage: ./scripts/update.sh [service]
#   Without args: updates all services
#   With service name: updates only that service (code-server, gitea, freellmapi, rustfs)

set -e

echo "=== codeserver-ai Update ==="

# Update git submodules
echo "Updating git submodules..."
git submodule update --remote

# Get latest code-server version from GitHub releases
echo "Checking latest code-server version..."
CODESERVER_VERSION=$(curl -fsSL https://api.github.com/repos/coder/code-server/releases/latest \
  | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//')
echo "Latest code-server: $CODESERVER_VERSION"

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  TARGETARCH="amd64" ;;
  aarch64) TARGETARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac
echo "Architecture: $TARGETARCH"

# Update specific service or all
SERVICE="${1:-all}"

update_codeserver() {
  echo "--- Updating code-server ---"
  CODESERVER_VERSION=$CODESERVER_VERSION TARGETARCH=$TARGETARCH \
    docker compose build code-server
  docker compose up -d code-server
}

update_gitea() {
  echo "--- Updating gitea ---"
  docker compose build gitea
  docker compose up -d gitea
}

update_freellmapi() {
  echo "--- Updating freellmapi ---"
  docker compose build freellmapi
  docker compose up -d freellmapi
}

update_rustfs() {
  echo "--- Updating rustfs ---"
  docker compose build rustfs
  docker compose up -d rustfs
}

case "$SERVICE" in
  code-server) update_codeserver ;;
  gitea)       update_gitea ;;
  freellmapi)  update_freellmapi ;;
  rustfs)      update_rustfs ;;
  all)
    update_codeserver
    update_gitea
    update_freellmapi
    update_rustfs
    ;;
  *)
    echo "Unknown service: $SERVICE"
    echo "Usage: $0 [code-server|gitea|freellmapi|rustfs|all]"
    exit 1
    ;;
esac

echo ""
echo "=== Update Complete ==="
echo "Services updated: $SERVICE"
echo ""
docker compose ps
