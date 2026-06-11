# Quick Start Guide

## Basic Setup

This guide covers the essential setup for Code Server AI on Dokploy.

## Prerequisites

- Dokploy instance with Docker support
- Administrator access to Dokploy

## Step 1: Clone Repository

```bash
git clone https://github.com/youruser/codeserver-ai.git
cd codeserver-ai
```

## Step 2: Configure Environment

```bash
cp .env.example .env
# Edit .env with your values
```

## Step 3: Create Storage Directories

```bash
sudo mkdir -p /mnt/storage/code-server
sudo mkdir -p /mnt/storage/gitea/data
sudo mkdir -p /mnt/storage/freellmapi/data
sudo mkdir -p /mnt/storage/rustfs/data
sudo chown -R 1000:1000 /mnt/storage
```

## Step 4: Deploy via Docker Compose

```bash
docker compose up -d
```

## Step 5: Access Code Server

Open your browser and navigate to:
- Code Server: `https://your-server:8443`
- Gitea: `https://your-server:3001`
- FreeLLMAPI: `https://your-server:3000`
- RustFS: `https://your-server:9000`

## First Time Setup

1. **Code Server**: Use password from `.env` (default: `changeme`)
2. **Gitea**: Create admin account during first run
3. **FreeLLMAPI**: Configure API keys in dashboard
4. **RustFS**: Create backup bucket

## Troubleshooting

### Service Not Starting

```bash
docker compose logs
```

### Code Server Connection Issues

1. Check firewall settings
2. Verify certificate is valid
3. Ensure password is correct

### Backup Not Working

1. Verify RustFS is running
2. Check `.env` for correct credentials
3. Ensure bucket exists in RustFS

## Next Steps

- Configure AI providers in FreeLLMAPI dashboard
- Set up Git integration in Code Server
- Configure automatic backups
- Add custom extensions

## AI Provider Configuration

Code Server AI uses a flexible provider system that allows you to configure different AI providers via environment variables.

### Setup Environment Variables

Create a `.env` file in your repository root with your API keys:

```bash
# Copy from template
cp config/.env.template .env

# Edit .env with your values
nano .env
```

### Provider Configuration Options

Each provider can be configured with the following environment variables:

#### OpenRouter
```bash
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
OPENROUTER_API_KEY=your-openrouter-api-key
```

#### OpenCode Zen
```bash
OPENCODE_ZEN_BASE_URL=https://opencode.ai/zen/api/v1
OPENCODE_ZEN_API_KEY=your-opencode-zen-api-key
```

#### FreeLLMAPI
```bash
FRELLMAPI_BASE_URL=https://freellmapi:3000/v1
FRELLMAPI_API_KEY=your-freellmapi-api-key
```

#### Anthropic
```bash
ANTHROPIC_BASE_URL=https://api.anthropic.com
ANTHROPIC_API_KEY=your-anthropic-api-key
```

#### OpenAI
```bash
OPENAI_BASE_URL=https://api.openai.com/v1
OPENAI_API_KEY=your-openai-api-key
```

### Generate Configuration

After setting up your environment variables, generate the configuration:

```bash
# Generate unified configuration
./scripts/generate-configs.sh
```

### Provider Management

Use the provider management script to:

```bash
# List all available providers
./scripts/manage-providers.sh list

# Configure a provider (uses environment variables)
./scripts/manage-providers.sh configure

# Test provider connection
./scripts/manage-providers.sh test
```

### Default Provider

The default provider is `freellmapi`. You can change this by setting the `DEFAULT_PROVIDER` environment variable:

```bash
DEFAULT_PROVIDER=openrouter
```

### Provider Selection

During container startup, the system will automatically use the provider configuration from your environment variables. No manual selection is required - the system will use the default provider or the one specified in your environment.

### Configuration Examples

**Example .env file:**
```bash
# Primary provider
DEFAULT_PROVIDER=openrouter
OPENROUTER_API_KEY=your-openrouter-key

# Backup provider
ANTHROPIC_API_KEY=your-anthropic-key

# FreeLLMAPI (already configured)
FREELLMAPI_API_KEY=your-freellmapi-key

# Encryption key
ENCRYPTION_KEY=generate-with-openssl-rand-hex-32

# RustFS credentials
RUSTFS_ACCESS_KEY=your-access-key
RUSTFS_SECRET_KEY=your-secret-key
```

### Switching Providers

To switch providers, simply update your `.env` file and regenerate the configuration:

```bash
# Update environment variables
./scripts/manage-providers.sh configure

# Regenerate configuration
./scripts/generate-configs.sh
```

The OpenCode extension will automatically use the new provider configuration.
