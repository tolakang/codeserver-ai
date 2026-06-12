# Contributing to Code Server AI

Thank you for your interest in contributing! This document provides guidelines and information for contributors.

## Getting Started

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

## Development Setup

### Prerequisites

- Docker and Docker Compose
- Git
- Bash

### Local Development

1. Clone your fork:
   ```bash
   git clone https://github.com/your-username/codeserver-ai.git
   cd codeserver-ai
   ```

2. Copy the environment file:
   ```bash
   cp .env.example .env
   ```

3. Edit `.env` with your configuration.

4. Render Dokploy compose placeholders for local Docker Compose:
   ```bash
   ./scripts/render-compose.sh docker-compose.yml docker-compose.local.yml
   ```

5. Start the services:
   ```bash
   docker compose -f docker-compose.local.yml up -d
   ```

## Code Style

### Shell Scripts

- Use `#!/bin/bash` as the shebang.
- Use `set -euo pipefail` for scripts that run in containers.
- Quote variables: `"$VARIABLE"` not `$VARIABLE`.
- Keep container entrypoints idempotent.
- Validate scripts with `bash -n scripts/*.sh`.

### Docker

- Use multi-stage builds when possible.
- Minimize image size by combining `RUN` commands.
- Use specific base image versions where practical.
- Add `HEALTHCHECK` instructions for long-running services.
- Do not bake secrets into images.

### Documentation

- Update `README.md` for user-facing changes.
- Update `deploy/README.md` for Dokploy deployment changes.
- Update `docs/backup.md` for backup or restore changes.
- Keep environment variable references consistent across compose files and docs.

## Pull Request Guidelines

- Provide a clear description of changes.
- Reference any related issues.
- Ensure shell syntax checks pass.
- Update documentation as needed.
- Keep commits focused and atomic.

## Reporting Issues

- Use the GitHub issue tracker.
- Provide detailed reproduction steps.
- Include environment information.
- Attach relevant logs.
- Include Dokploy deployment type and reverse proxy upstream protocol when reporting Bad Gateway issues.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
