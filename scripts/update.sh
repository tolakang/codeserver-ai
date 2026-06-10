#!/bin/bash
# update.sh
# Rebuild all services from source
# Usage: ./scripts/update.sh [service]
#   Without args: updates all services
#   With service name: updates only that service (code-server, gitea, freellmapi, rustfs)

set -e

echo "=== codeserver-ai Update ==="

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
    docker compose -f deploy/docker-compose.code-server.yml build --no-cache
  docker compose -f deploy/docker-compose.code-server.yml up -d
}

update_gitea() {
  echo "--- Updating gitea ---"
  docker compose -f deploy/docker-compose.gitea.yml build --no-cache
  docker compose -f deploy/docker-compose.gitea.yml up -d
}

update_freellmapi() {
  echo "--- Updating freellmapi ---"
  FREELLM_VERSION=${FREELLM_VERSION:-latest} \
    docker compose -f deploy/docker-compose.freellmapi.yml build --no-cache
  docker compose -f deploy/docker-compose.freellmapi.yml up -d
}

update_rustfs() {
  echo "--- Updating rustfs ---"
  docker compose -f deploy/docker-compose.rustfs.yml build --no-cache
  docker compose -f deploy/docker-compose.rustfs.yml up -d
}

update_opencode_web() {
  echo "--- Updating opencode-web ---"
  OPENCODE_VERSION=${OPENCODE_VERSION:-latest} \
    docker compose -f docker-compose.opencode-web.yml build --no-cache
  docker compose -f docker-compose.opencode-web.yml up -d
}

update_all() {
  echo "--- Updating all services ---"
  CODESERVER_VERSION=$CODESERVER_VERSION TARGETARCH=$TARGETARCH \
    docker compose -f deploy/docker-compose.code-server.yml build --no-cache
  docker compose -f deploy/docker-compose.code-server.yml up -d

  docker compose -f deploy/docker-compose.gitea.yml build --no-cache
  docker compose -f deploy/docker-compose.gitea.yml up -d

  FREELLM_VERSION=${FREELLM_VERSION:-latest} \
    docker compose -f deploy/docker-compose.freellmapi.yml build --no-cache
  docker compose -f deploy/docker-compose.freellmapi.yml up -d

  docker compose -f deploy/docker-compose.rustfs.yml build --no-cache
  docker compose -f deploy/docker-compose.rustfs.yml up -d

  OPENCODE_VERSION=${OPENCODE_VERSION:-latest} \
    docker compose -f docker-compose.opencode-web.yml build --no-cache
  docker compose -f docker-compose.opencode-web.yml up -d
}

case "$SERVICE" in
  code-server) update_codeserver ;;
  gitea)       update_gitea ;;
  freellmapi)  update_freellmapi ;;
  rustfs)      update_rustfs ;;
  opencode-web) update_opencode_web ;;
  all)         update_all ;;
  *)
    echo "Unknown service: $SERVICE"
    echo "Usage: $0 [code-server|gitea|freellmapi|rustfs|opencode-web|all]"
    exit 1
    ;;
esac

echo ""
  echo "=== Update Complete ==="
  echo "Services updated: $SERVICE"
  echo ""
  docker compose -f deploy/docker-compose.code-server.yml ps 2>/dev/null || true
  docker compose -f deploy/docker-compose.gitea.yml ps 2>/dev/null || true
  docker compose -f deploy/docker-compose.freellmapi.yml ps 2>/dev/null || true
  docker compose -f deploy/docker-compose.rustfs.yml ps 2>/dev/null || true
  docker compose -f docker-compose.opencode-web.yml ps 2>/dev/null || true
