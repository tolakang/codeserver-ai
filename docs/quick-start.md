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
