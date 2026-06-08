# AGENTS.md

## Project Overview

This repository deploys Code Server inside Dokploy with integrated AI tools.

Primary goals:

1. Stable deployment
2. Persistent workspace
3. RustFS backups
4. OpenCode integration
5. OpenRouter support
6. Self-hosted Gitea for Git operations

## Rules

- Never delete user workspace data
- Never modify mounted volumes
- Always use Docker volumes
- Use non-root user
- Container must be restart-safe

## Coding Standards

- Docker Compose v3.9
- Alpine or Debian slim images
- No hardcoded secrets
- Environment variables only

## Backup Rules

Before any migration:

1. Snapshot workspace
2. Upload to RustFS
3. Verify checksum

## AI Providers

Supported:

- OpenRouter
- FreeLLMAPI
- Anthropic
- OpenAI

Do not hardcode API keys.

## Services

| Service | Purpose | Port |
|---------|---------|------|
| code-server | IDE | 8080 |
| gitea | Git hosting | 3001 |
| freellmapi | Free LLM proxy | 3000 |
| rustfs | S3 backup storage | 9000 |

## Network

All services communicate over `codeserver-network`.

Code Server connects to Gitea for Git operations and FreeLLMAPI for AI.
