# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- code-server now starts when `CS_PASSWORD` is missing by generating a temporary password.
- code-server config is created at startup when the mounted/configured file is absent.
- OpenCode provider config permissions are restricted.
- OpenCode WEB no longer enables mDNS by default, avoiding startup failures in Docker.
- OpenCode WEB health checks now use the root endpoint instead of an assumed `/health` path.
- OpenCode WEB Dockerfile now creates `/etc/sudoers.d` before writing sudoers rules.
- OpenCode WEB generates a complete `opencode.json` at runtime for provider and model configuration.
- code-server Dockerfile now creates `/etc/sudoers.d` before writing sudoers rules.
- Root compose no longer blocks code-server startup on dependent service health checks.

### Changed
- Compose services now use `pull_policy: build` to force local image builds.
- Update script supports `--check-only`.
- Local Docker Compose deployments now render Dokploy placeholders with `scripts/render-compose.sh`.
- Documentation now calls out the code-server `HTTP` upstream requirement for Bad Gateway prevention.
- OpenCode WEB is documented as a standalone Dokploy application with runtime provider configuration.

### Added
- OpenCode CLI to the code-server image so `opencode` can run directly in the code-server terminal.
- `scripts/render-compose.sh` for local Docker Compose deployments.
- OpenCode WEB port and hostname environment overrides.
- `OPENCODE_MODEL` environment variable for selecting the default OpenCode model.
- `development_plan.md` for tracking the OpenCode refactor.

### Removed
- Root `docker-compose.yml` orchestrator; each service now has its own standalone Dokploy compose file.
- mDNS flags from the OpenCode WEB startup command.

## [1.0.0] - 2024-01-01

### Added
- Initial release
- Code Server with AI integration
- Gitea self-hosted Git server
- FreeLLMAPI for free model access
- RustFS S3-compatible backups
- OpenCode WEB server
- Multi-architecture support (amd64/arm64)
- Docker Compose orchestration
- Dokploy deployment support
