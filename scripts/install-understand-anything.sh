#!/usr/bin/env bash
# scripts/install-understand-anything.sh

set -euo pipefail

REPO_URL="${UA_REPO_URL:-https://github.com/Egonex-AI/Understand-Anything.git}"
REPO_DIR="${UA_DIR:-${HOME:-/home/coder}/.understand-anything/repo}"
PLATFORM="${UNDERSTAND_ANYTHING_PLATFORM:-opencode}"
VERSION="${UNDERSTAND_ANYTHING_VERSION:-main}"
PNPM_VERSION="${UNDERSTAND_ANYTHING_PNPM_VERSION:-10.6.2}"
REBUILD="${UNDERSTAND_ANYTHING_REBUILD:-0}"
LOG_FILE="/tmp/understand-anything-install.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    log "Error: required command '$cmd' is not installed"
    exit 1
  fi
}

ensure_pnpm() {
  if command -v pnpm >/dev/null 2>&1; then
    return
  fi

  if command -v corepack >/dev/null 2>&1; then
    corepack enable >/dev/null 2>&1 || true
    corepack prepare "pnpm@${PNPM_VERSION}" --activate >/dev/null 2>&1 || true
  fi

  if ! command -v pnpm >/dev/null 2>&1; then
    log "pnpm not found; installing pnpm@${PNPM_VERSION}"
    npm install -g "pnpm@${PNPM_VERSION}"
  fi

  require_command pnpm
}

clone_or_update_repo() {
  if [ -d "$REPO_DIR/.git" ]; then
    log "Updating Understand Anything checkout at $REPO_DIR"
    git -C "$REPO_DIR" fetch --tags --force
    git -C "$REPO_DIR" fetch --force origin "$VERSION" 2>/dev/null || true
    git -C "$REPO_DIR" checkout "$VERSION" 2>/dev/null || git -C "$REPO_DIR" pull --ff-only
  else
    log "Cloning Understand Anything into $REPO_DIR"
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "$REPO_URL" "$REPO_DIR"
    if [ "$VERSION" != "main" ]; then
      git -C "$REPO_DIR" fetch --tags --force
      git -C "$REPO_DIR" fetch --force origin "$VERSION" 2>/dev/null || true
      git -C "$REPO_DIR" checkout "$VERSION"
    fi
  fi
}

skills_root() {
  printf '%s\n' "$REPO_DIR/understand-anything-plugin/skills"
}

list_skills() {
  local root
  root="$(skills_root)"
  if [ ! -d "$root" ]; then
    log "Skills directory not found: $root"
    exit 1
  fi

  find "$root" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort
}

link_skills() {
  local target="${HOME:-/home/coder}/.agents/skills"
  local root
  root="$(skills_root)"

  mkdir -p "$target"
  while IFS= read -r skill; do
    ln -sfn "$root/$skill" "$target/$skill"
    log "Linked $target/$skill -> $root/$skill"
  done < <(list_skills)
}

link_plugin_root() {
  local target="${HOME:-/home/coder}/.understand-anything-plugin"
  ln -sfn "$REPO_DIR/understand-anything-plugin" "$target"
  log "Linked $target -> $REPO_DIR/understand-anything-plugin"
}

build_core() {
  if [ "$REBUILD" != "1" ] && [ -f "$REPO_DIR/understand-anything-plugin/packages/core/dist/index.js" ]; then
    log "Understand Anything core already built"
    return
  fi

  log "Installing Understand Anything dependencies"
  (cd "$REPO_DIR" && pnpm install --frozen-lockfile || pnpm install)

  log "Building @understand-anything/core"
  (cd "$REPO_DIR" && pnpm --filter @understand-anything/core build)
}

main() {
  require_command git
  require_command node
  ensure_pnpm

  clone_or_update_repo
  link_skills
  link_plugin_root
  build_core

  log "Understand Anything installed for $PLATFORM"
  log "OpenCode skills: ${HOME:-/home/coder}/.agents/skills"
  log "Plugin root: ${HOME:-/home/coder}/.understand-anything-plugin"
  log "Restart opencode before using /understand commands"
}

main "$@"
