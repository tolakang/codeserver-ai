# VS Code Extension Integration Guide

This document provides comprehensive guidance for setting up and using VS Code extensions in the Code Server deployment.

## Overview

The repository now includes enhanced VS Code extension integration with the following extensions:

- **OpenCode AI**: AI-powered coding assistant
- **GitHub Pull Requests**: GitHub PR management
- **GitLens**: Git visualization and analytics
- **Amazon S3 Explorer**: AWS S3 file management

## Installation

### Automatic Installation

Extensions are automatically installed at container startup via `scripts/install-extensions.sh`.

### Manual Installation

To install extensions manually:

```bash
docker exec code-server code-server --install-extension amazonwebservices.aws-toolkit-vscode@4.7.0
code-server --install-extension eamodio.gitlens
code-server --install-extension github.vscode-pull-request-github
code-server --install-extension opencode.opencode
```

## Configuration

### OpenCode Configuration

OpenCode is configured via `config/opencode/config.json`:

```json
{
  "provider": "openai",
  "baseURL": "https://openrouter.ai/api/v1",
  "apiKey": "${OPENROUTER_API_KEY}"
}
```

### Supported AI Providers

You can configure OpenCode to work with different AI providers:

#### Direct OpenRouter

```json
{
  "provider": "openai",
  "baseURL": "https://openrouter.ai/api/v1",
  "apiKey": "your-openrouter-key"
}
```

#### Direct Anthropic

```json
{
  "provider": "anthropic",
  "baseURL": "https://api.anthropic.com",
  "apiKey": "your-anthropic-key"
}
```

#### Direct OpenAI

```json
{
  "provider": "openai",
  "baseURL": "https://api.openai.com/v1",
  "apiKey": "your-openai-key"
}
```

## Environment Variables

Set the following environment variables in `.env`:

```bash
OPENROUTER_API_KEY=your-openrouter-key
ANTHROPIC_API_KEY=your-anthropic-key
OPENAI_API_KEY=your-openai-key
FREELLMAPI_API_KEY=your-freellmapi-key
GITHUB_TOKEN=your-github-token
```

## Usage

### GitHub Integration

1. Install the **GitHub Pull Requests** extension
2. Sign in to GitHub using the extension
3. Clone repositories using GitHub CLI or Git

### AI Coding Assistance

1. Install the **OpenCode AI** extension
2. Configure the AI provider in `config/opencode/config.json`
3. Use the OpenCode sidebar to start AI-powered coding sessions

### Git Visualization

1. Install the **GitLens** extension
2. Use GitLens to visualize commit history and branch information

### AWS Integration

1. Install the **Amazon S3 Explorer** extension
2. Connect to your S3 buckets for file management

## Backup and Restore

### Backup Strategy

The backup system now uses a single persistent volume for all code-server data:

- **Workspace**: `/workspace` - Contains all project files
- **Config**: `/workspace/config` - Contains IDE configuration
- **Extensions**: `/workspace/extensions` - Contains installed extensions

### Backup Commands

```bash
# Manual backup
docker exec code-server /scripts/backup.sh

# Restore from backup
docker exec code-server /scripts/restore.sh <backup-filename>
```

### Backup Retention

- Daily backups: 7 days
- Weekly backups: 4 weeks
- Monthly backups: 6 months

## Troubleshooting

### OpenCode Not Appearing

Check extension installation logs:

```bash
docker compose logs code-server | grep extension
```

### AI Not Responding

1. Verify FreeLLMAPI is running: `curl http://localhost:3000/health`
2. Check API key in `.env`
3. Review OpenCode output panel in Code Server

### Wrong Provider

Ensure `config/opencode/config.json` points to correct baseURL.

### Backup Failed

Verify RustFS is running and accessible:

```bash
docker compose logs rustfs
curl http://localhost:9000/minio/health/live
```

## Security

### HTTPS Configuration

Code Server now uses HTTPS on port 8443. Ensure you have:

1. SSL certificates configured
2. Firewall rules allowing port 8443
3. Strong password for code-server

### API Key Security

- Never hardcode API keys in configuration files
- Use environment variables for sensitive data
- Store API keys in Dokploy secrets for production

## Performance Optimization

### Resource Allocation

For optimal performance, allocate the following resources:

| Component | CPU | RAM |
|-----------|-----|-----|
| code-server | 2 vCPU | 4 GB |
| OpenCode | 1 vCPU | 2 GB |

### Storage Optimization

- Use Docker volumes for persistent storage
- Regularly clean up backup archives
- Monitor disk usage and set up alerts

## Migration Guide

### From Multiple Volumes to Single Volume

If migrating from the previous multi-volume setup:

1. Stop all services
2. Remove old volumes
3. Update `deploy/docker-compose.code-server.yml`
4. Start services
5. Run backup to verify the new structure

### From FreeLLMAPI to Direct Provider

If switching from FreeLLMAPI to direct provider:

1. Update `config/opencode/config.json`
2. Set the appropriate API key in `.env`
3. Restart code-server
4. Test AI functionality

## Frequently Asked Questions

### Q: How do I add more extensions?

Edit `scripts/install-extensions.sh` and add new extension installation commands.

### Q: How do I update extensions?

Restart the code-server container to reinstall updated extensions.

### Q: How do I configure GitHub authentication?

Use GitHub CLI inside the code-server terminal:

```bash
gh auth login
```

### Q: How do I backup specific directories?

Modify `scripts/backup.sh` to include additional directories in the tar command.

## References

- [OpenCode Documentation](https://opencode.ai)
- [GitHub Pull Requests Extension](https://github.com/github/vscode-pull-request-github)
- [GitLens Documentation](https://gitlens.amod.io)
- [Amazon S3 Explorer Documentation](https://aws.amazon.com/cli/)
