# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Fixed critical Docker build failures
- Aligned code-server port configuration (8443)
- Fixed FreeLLMAPI health check endpoints
- Improved security defaults (mandatory passwords, restricted CORS)
- Standardized project structure

### Added
- LICENSE file (MIT)
- .dockerignore for optimized builds
- SECURITY.md with security guidelines
- CONTRIBUTING.md for contributors
- CHANGELOG.md for version tracking
- Complete .env.example with all required variables
- Kubernetes manifests in k8s/ directory

### Removed
- Obsolete config files (provider-variables.json, .env.template)
- Duplicate documentation (quick-start.md, update.md)
- Redundant scripts (generate-all-configs.sh, manage-providers.sh)

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
