# Development Plan: codeserver-ai Refactoring

## Overview

This document tracks the OpenCode WEB and AI provider refactoring for `codeserver-ai`.

## Refactoring Goals

1. Make OpenCode WEB deployable as a standalone Dokploy container.
2. Prepare OpenCode provider configuration for multiple AI providers.
3. Generate runtime `opencode.json` for OpenCode WEB.
4. Keep code-server OpenCode extension working with direct provider connections.
5. Use standalone compose files per service for Dokploy.
6. Update documentation and deployment guides.
7. Audit code, test syntax, and push to GitHub.

## Current State

### Completed

- Researched OpenCode CLI config format:
  - `opencode.json` supports `$schema`, `server`, `provider`, and `model`.
  - OpenCode supports `{env:VAR}` substitution.
  - `opencode web` uses `OPENCODE_SERVER_USERNAME` and `OPENCODE_SERVER_PASSWORD` for auth.
- Fixed `Dockerfile.opencode-web` sudoers directory creation.
- Rewrote `scripts/opencode-web.sh` to generate runtime `opencode.json`.
- Rewrote `config/opencode-web/opencode.json` with full server/provider/model config.
- Updated `config/opencode/config.json` for code-server extension provider config.
- Updated `scripts/init.sh` to generate richer OpenCode config with model support.
- Updated `scripts/configure-provider.sh` to generate OpenCode-compatible config.
- Updated `scripts/generate-configs.sh` to generate OpenCode-compatible config.
- Updated `deploy/docker-compose.opencode-web.yml` with provider/model env vars.
- Updated `deploy/docker-compose.code-server.yml` with `OPENCODE_MODEL`.
- Updated `deploy/docker-compose.code-server.yml` with fixed workspace volume name `codeserver-ai-workspace`.
- Updated `.env.example` with `OPENCODE_MODEL`.
- Removed root `docker-compose.yml` orchestrator in favor of standalone service compose files.
- Removed unused `scripts/install-opencode-web.sh`.
- Rewrote `README.md`, `deploy/README.md`, `CHANGELOG.md`, and `SECURITY.md`.
- Created this development plan.

### Remaining

- Full container build/run test is blocked locally because Docker daemon cannot start in this environment (`/var/run/docker.sock` unavailable and `/var/run` read-only).
- Push to GitHub after final review.

## File Changes Summary

| File | Action | Status |
|------|--------|--------|
| `Dockerfile.opencode-web` | Fixed sudoers path | ✅ |
| `Dockerfile.codeserver` | Fixed sudoers directory creation | ✅ |
| `scripts/opencode-web.sh` | Rewritten runtime config generation | ✅ |
| `scripts/init.sh` | Rewritten OpenCode config generation | ✅ |
| `scripts/configure-provider.sh` | Updated provider config format | ✅ |
| `scripts/generate-configs.sh` | Updated OpenCode config output | ✅ |
| `config/opencode-web/opencode.json` | Full provider/model config | ✅ |
| `config/opencode/config.json` | Provider/model config | ✅ |
| `deploy/docker-compose.opencode-web.yml` | Standalone OpenCode WEB app config | ✅ |
| `deploy/docker-compose.code-server.yml` | Added model env var and fixed workspace volume name | ✅ |
| `docker-compose.yml` | Removed root orchestrator | ✅ |
| `scripts/install-opencode-web.sh` | Removed unused script | ✅ |
| `.env.example` | Added `OPENCODE_MODEL` and updated references | ✅ |
| `README.md` | Rewritten | ✅ |
| `deploy/README.md` | Rewritten | ✅ |
| `CHANGELOG.md` | Updated | ✅ |
| `SECURITY.md` | Updated | ✅ |
| `development_plan.md` | Created | ✅ |

## Validation

### Completed

```bash
bash -n scripts/*.sh
python3 -m json.tool config/opencode/config.json
python3 -m json.tool config/opencode-web/opencode.json
for f in deploy/*.yml; do
  out="/tmp/$(basename "$f")"
  bash scripts/render-compose.sh "$f" "$out"
  docker compose --env-file .env -f "$out" config
done
```

### Blocked

```bash
service docker start
docker info
```

Docker daemon cannot start in this environment due read-only filesystem restrictions. Container build/run testing should be run on the Dokploy host or a machine with a writable Docker runtime.

## Dokploy Deployment Notes

### opencode-web

- Compose file: `deploy/docker-compose.opencode-web.yml`
- Domain: `opencodeweb.nokor24.com`
- Port: `4001`
- Path: `/`
- Upstream protocol: **HTTP**
- TLS: Let's Encrypt at Dokploy reverse proxy
- Required env vars:
  - `OPENCODE_SERVER_USERNAME`
  - `OPENCODE_SERVER_PASSWORD`
  - `OPENCODE_WEB_PORT`
  - `OPENCODE_WEB_HOSTNAME`
  - `OPENCODE_MODEL`
  - Provider API keys/base URLs

### code-server

- Compose file: `deploy/docker-compose.code-server.yml`
- Domain: your code-server domain
- Port: `8443`
- Path: `/`
- Upstream protocol: **HTTP**
- Required env vars:
  - `CS_PASSWORD`
  - `CS_DEFAULT_WORKSPACE`
  - `DEFAULT_PROVIDER`
  - `OPENCODE_MODEL`
  - provider API keys/base URLs

## Next Steps

1. Push changes to GitHub.
2. Force rebuild `opencode-web` in Dokploy.
3. If Bad Gateway persists, verify reverse proxy upstream protocol is `HTTP`.
4. Check logs:
   ```bash
   docker logs -f opencode-web
   ```
5. Confirm OpenCode WEB login page loads.
6. Confirm code-server OpenCode extension can call the selected provider.
