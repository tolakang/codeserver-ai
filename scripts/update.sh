#!/bin/bash
# update.sh
# Rebuild all services from source
# Usage: ./scripts/update.sh [service] [--check-only]
#   service: code-server, gitea, freellmapi, rustfs, opencode-web, all

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

COMPOSE="docker compose"
CHECK_ONLY=0
SERVICE="all"
TMP_DIR="$(mktemp -d "${ROOT_DIR}/.compose-tmp.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

usage() {
  echo "Usage: $0 [code-server|gitea|freellmapi|rustfs|opencode-web|all] [--check-only]"
}

for arg in "$@"; do
  case "$arg" in
    --check-only|check)
      CHECK_ONLY=1
      ;;
    code-server|gitea|freellmapi|rustfs|opencode-web|all)
      SERVICE="$arg"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage
      exit 1
      ;;
  esac
done

latest_code_server_version() {
  curl -fsSL https://api.github.com/repos/coder/code-server/releases/latest \
    | grep '"tag_name"' \
    | cut -d'"' -f4 \
    | sed 's/v//'
}

CODESERVER_VERSION="${CODESERVER_VERSION:-$(latest_code_server_version)}"
FREELLMAPI_VERSION="${FREELLMAPI_VERSION:-latest}"
OPENCODE_VERSION="${OPENCODE_VERSION:-latest}"

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) TARGETARCH="amd64" ;;
  aarch64|arm64) TARGETARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

echo "=== codeserver-ai Update ==="
echo "Service: $SERVICE"
echo "Architecture: $TARGETARCH"
echo "Latest code-server: $CODESERVER_VERSION"

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo "Check-only mode enabled; no containers were rebuilt or restarted."
  exit 0
fi

if [ ! -f .env ]; then
  echo "Error: .env file not found. Copy .env.example to .env and configure it."
  exit 1
fi

render_compose() {
  local source_file="$1"
  local output_file="$2"
  ./scripts/render-compose.sh "$source_file" "$output_file" >/dev/null
}

render_compose deploy/docker-compose.code-server.yml "$TMP_DIR/code-server.yml"
render_compose deploy/docker-compose.gitea.yml "$TMP_DIR/gitea.yml"
render_compose deploy/docker-compose.freellmapi.yml "$TMP_DIR/freellmapi.yml"
render_compose deploy/docker-compose.rustfs.yml "$TMP_DIR/rustfs.yml"
render_compose deploy/docker-compose.opencode-web.yml "$TMP_DIR/opencode-web.yml"

update_codeserver() {
  echo "--- Updating code-server ---"
  CODESERVER_VERSION="$CODESERVER_VERSION" TARGETARCH="$TARGETARCH" \
    $COMPOSE -f "$TMP_DIR/code-server.yml" build --no-cache
  $COMPOSE -f "$TMP_DIR/code-server.yml" up -d
}

update_gitea() {
  echo "--- Updating gitea ---"
  $COMPOSE -f "$TMP_DIR/gitea.yml" build --no-cache
  $COMPOSE -f "$TMP_DIR/gitea.yml" up -d
}

update_freellmapi() {
  echo "--- Updating freellmapi ---"
  FREELLMAPI_VERSION="$FREELLMAPI_VERSION" \
    $COMPOSE -f "$TMP_DIR/freellmapi.yml" build --no-cache
  $COMPOSE -f "$TMP_DIR/freellmapi.yml" up -d
}

update_rustfs() {
  echo "--- Updating rustfs ---"
  $COMPOSE -f "$TMP_DIR/rustfs.yml" build --no-cache
  $COMPOSE -f "$TMP_DIR/rustfs.yml" up -d
}

update_opencode_web() {
  echo "--- Updating opencode-web ---"
  OPENCODE_VERSION="$OPENCODE_VERSION" \
    $COMPOSE -f "$TMP_DIR/opencode-web.yml" build --no-cache
  $COMPOSE -f "$TMP_DIR/opencode-web.yml" up -d
}

update_all() {
  echo "--- Updating all services ---"
  update_codeserver
  update_gitea
  update_freellmapi
  update_rustfs
  update_opencode_web
}

case "$SERVICE" in
  code-server) update_codeserver ;;
  gitea) update_gitea ;;
  freellmapi) update_freellmapi ;;
  rustfs) update_rustfs ;;
  opencode-web) update_opencode_web ;;
  all) update_all ;;
esac

echo ""
echo "=== Update Complete ==="
echo "Services updated: $SERVICE"
echo ""
$COMPOSE -f "$TMP_DIR/code-server.yml" ps 2>/dev/null || true
$COMPOSE -f "$TMP_DIR/gitea.yml" ps 2>/dev/null || true
$COMPOSE -f "$TMP_DIR/freellmapi.yml" ps 2>/dev/null || true
$COMPOSE -f "$TMP_DIR/rustfs.yml" ps 2>/dev/null || true
$COMPOSE -f "$TMP_DIR/opencode-web.yml" ps 2>/dev/null || true
