# OpenCode WEB Integration Guide

## Overview

This document describes the integration of OpenCode WEB into the code-server-ai project. OpenCode WEB provides a standalone web interface for AI-powered coding assistance, separate from the code-server extension.

## Architecture

```
Internet
    |
    v
 Dokploy
    |
    +-- code-server (port 8080)
    |   +-- OpenCode extension (IDE integration)
    |   +-- Claude Memory persistence
    |   +-- Workspace files
    |
    +-- freellmapi (port 3000)
    |   +-- AI proxy to OpenRouter free models
    |
    +-- opencode-web (port 4001)
    |   +-- Web interface for AI coding
    |   +-- Session management
    |   +-- Server status monitoring
    |
    +-- gitea (port 3001)
    |   +-- Git repositories
    |
    +-- rustfs (port 9000)
            +-- S3 backups
```

## Features

- **Standalone Web Interface**: Access OpenCode in your browser without code-server
- **Session Management**: View and manage AI coding sessions
- **Server Status**: Monitor connected servers and their status
- **mDNS Discovery**: Automatically discover the web server on local network
- **Password Protection**: Secure access with configurable authentication
- **Integration with FreeLLMAPI**: Uses existing AI proxy for OpenRouter free models

## Configuration

### Environment Variables

Add the following to your `.env` file:

```bash
# OpenCode WEB Configuration
ENABLE_OPENCODE_WEB=true
OPENCODE_SERVER_PASSWORD=your-secure-password
OPENCODE_SERVER_USERNAME=opencode
OPENCODE_VERSION=latest
FREELLMAPI_API_KEY=your-freellmapi-api-key
```

### Service Configuration

In Dokploy, configure the OpenCode WEB service with:

```yaml
PUID=1000
PGID=1000
TZ=UTC
OPENCODE_SERVER_PASSWORD=${{project.OPENCODE_SERVER_PASSWORD}}
OPENCODE_SERVER_USERNAME=${{project.OPENCODE_SERVER_USERNAME}}
FREELLMAPI_API_KEY=${{environment.FREELLMAPI_API_KEY}}
```

## Deployment

### Quick Start

1. **Enable OpenCode WEB** in your `.env` file:
   ```bash
   ENABLE_OPENCODE_WEB=true
   OPENCODE_SERVER_PASSWORD=your-secure-password
   ```

2. **Update and deploy**:
   ```bash
   ./scripts/update.sh opencode-web
   docker compose -f docker-compose.opencode-web.yml up -d
   ```

3. **Access the web interface**:
   - Local: `http://localhost:4001`
   - Network: `http://<server-ip>:4001`
   - mDNS: `http://opencode.local` (if enabled)

### Full Deployment

Deploy all services including OpenCode WEB:

```bash
# Update all services
docker compose up -d

# Or update specific services
./scripts/update.sh all
```

## Usage

### Web Interface

Once deployed, access OpenCode WEB at:
- **Local access**: `http://localhost:4001`
- **Network access**: `http://<server-ip>:4001`
- **mDNS access**: `http://opencode.local` (if enabled)

The web interface provides:
- **Session Management**: View and manage active AI coding sessions
- **Server Status**: Monitor connected servers and their status
- **New Sessions**: Start new AI coding sessions

### Terminal Attachment

You can attach a terminal TUI to the web server:

```bash
# Start the web server
opencode web --port 4001 --hostname 0.0.0.0

# In another terminal, attach the TUI
opencode attach http://localhost:4001
```

This allows you to use both the web interface and terminal simultaneously, sharing the same sessions and state.

## Configuration Options

### Port and Hostname

Configure the web server port and hostname:

```bash
# Custom port and hostname
OPENCODE_SERVER_PASSWORD=secret opencode web --port 4096 --hostname 0.0.0.0
```

### mDNS Discovery

Enable mDNS to make the server discoverable on the local network:

```bash
opencode web --mdns
# or with custom domain
opencode web --mdns --mdns-domain myproject.local
```

### CORS Configuration

Allow additional domains for CORS (useful for custom frontends):

```bash
opencode web --cors https://example.com
```

## Integration with Existing Setup

### AI Provider Configuration

OpenCode WEB uses the same AI provider configuration as the code-server extension:

**config/opencode/config.json** (for code-server extension):
```json
{
  "provider": "openai",
  "baseURL": "http://freellmapi:3000/v1",
  "apiKey": "${FREELLMAPI_API_KEY}"
}
```

**config/opencode-web/opencode.json** (for web interface):
```json
{
  "server": {
    "port": 4001,
    "hostname": "0.0.0.0",
    "mdns": true,
    "mdns-domain": "opencode.local",
    "cors": []
  },
  "provider": "openai",
  "baseURL": "http://freellmapi:3000/v1",
  "apiKey": "${FREELLMAPI_API_KEY}"
}
```

### Fallback to OpenRouter

If you prefer to use OpenRouter directly instead of FreeLLMAPI, update the web interface configuration:

```json
{
  "server": {
    "port": 4001,
    "hostname": "0.0.0.0",
    "mdns": true
  },
  "provider": "openai",
  "baseURL": "https://openrouter.ai/api/v1",
  "apiKey": "${OPENROUTER_API_KEY}"
}
```

## Monitoring and Maintenance

### Health Checks

The OpenCode WEB service includes health checks:

```bash
# Check service status
docker compose -f docker-compose.opencode-web.yml ps

# View logs
docker compose -f docker-compose.opencode-web.yml logs -f

# Health endpoint
curl http://localhost:4001/health
```

### Updates

Update OpenCode WEB to the latest version:

```bash
./scripts/update.sh opencode-web
```

Update all services including OpenCode WEB:

```bash
./scripts/update.sh all
```

### Backup Considerations

OpenCode WEB sessions are stored in the container's memory and are not persisted across restarts. For persistent session storage, consider:

1. Using the terminal attachment feature for long-running sessions
2. Exporting sessions when needed
3. Using the code-server extension for persistent workspace integration

## Troubleshooting

### Common Issues

**Issue: OpenCode WEB fails to start**

Check the following:

1. Verify FreeLLMAPI is running:
   ```bash
   curl http://localhost:3000/health
   ```

2. Check OpenCode WEB logs:
   ```bash
   docker compose -f docker-compose.opencode-web.yml logs
   ```

3. Verify environment variables are set correctly

**Issue: Web interface not accessible**

1. Check firewall settings
2. Verify port 4001 is open
3. Check container network configuration

**Issue: AI not responding**

1. Verify FreeLLMAPI health: `curl http://localhost:3000/health`
2. Check API key configuration in `.env`
3. Review OpenCode WEB output panel

### Service Dependencies

OpenCode WEB depends on FreeLLMAPI. If FreeLLMAPI is not healthy, OpenCode WEB will not start. Monitor both services:

```bash
docker compose -f docker-compose.yml ps
```

## Migration Guide

### From Extension-Only to Web+Extension

If you're currently using only the OpenCode extension in code-server and want to add the web interface:

1. **Enable OpenCode WEB** in your `.env` file
2. **Update the docker-compose.yml** to include the opencode-web service
3. **Deploy the new service**
4. **Access the web interface** at `http://localhost:4001`

You can use both the extension and web interface simultaneously, providing flexibility for different use cases.

## Security Considerations

### Authentication

OpenCode WEB supports password authentication:

```bash
OPENCODE_SERVER_PASSWORD=your-secure-password opencode web
```

### Network Access

By default, OpenCode WEB binds to `127.0.0.1`. To make it accessible on your network:

```bash
opencode web --hostname 0.0.0.0
```

### Firewall

Ensure port 4001 is open in your firewall if accessing from outside the container network.

## Development and Testing

### Local Development

To develop OpenCode WEB locally:

1. Clone the repository
2. Set up your `.env` file with the required variables
3. Start the services:
   ```bash
   docker compose -f docker-compose.yml up -d
   ```

4. Access the web interface at `http://localhost:4001`

### Testing

Test the OpenCode WEB service:

```bash
# Check if the service is healthy
docker compose -f docker-compose.opencode-web.yml exec opencode-web curl -f http://localhost:4001/health

# Test web interface access
open http://localhost:4001
```

## Support

For issues and support, refer to:
- [OpenCode Documentation](https://opencode.ai/docs/web/)
- [GitHub Repository](https://github.com/anomalyco/opencode)
- [Discord Community](https://opencode.ai/discord)

## License

This integration is part of the codeserver-ai project, licensed under MIT.
