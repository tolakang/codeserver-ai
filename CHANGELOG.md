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
- RustFS builds now auto-detect `amd64` or `arm64` when `TARGETARCH` is not provided.
- Gitea admin user creation is handled by a one-shot init service.
- Restore now supports Gitea database backups.
- Backup now creates the RustFS bucket when it does not exist.
- Root compose no longer blocks code-server startup on dependent service health checks.

### Changed
- Compose services now use `pull_policy: build` to force local image builds.
- Update script supports `--check-only`.
- Local Docker Compose deployments now render Dokploy placeholders with `scripts/render-compose.sh`.
- Documentation now calls out the code-server `HTTP` upstream requirement for Bad Gateway prevention.

### Added
- `scripts/render-compose.sh` for local Docker Compose deployments.
- OpenCode WEB port and hostname environment overrides.

### Removed
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
