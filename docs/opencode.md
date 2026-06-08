# OpenCode Extension

## Overview

OpenCode provides AI-powered coding assistance directly inside Code Server.

[OpenCode Website](https://opencode.ai)

## Installation

OpenCode is auto-installed at container startup via `scripts/install-extensions.sh`.

Manual install:

```bash
code-server --install-extension opencode.opencode
```

## Configuration

OpenCode is configured via `config/opencode/config.json`.

### Default Config

```json
{
  "provider": "openai",
  "baseURL": "http://freellmapi:3000/v1",
  "apiKey": "dummy"
}
```

This routes all AI requests through FreeLLMAPI, which forwards to OpenRouter free models.

## AI Provider Architecture

```
OpenCode (Code Server)
        |
        v
   FreeLLMAPI (port 3000)
        |
        v
   OpenRouter Free Models
        |
        v
   Claude / GPT / Llama
```

## Using Other Providers

### Direct OpenRouter

Edit `config/opencode/config.json`:

```json
{
  "provider": "openai",
  "baseURL": "https://openrouter.ai/api/v1",
  "apiKey": "your-openrouter-key"
}
```

### Direct Anthropic

```json
{
  "provider": "anthropic",
  "baseURL": "https://api.anthropic.com",
  "apiKey": "your-anthropic-key"
}
```

### Direct OpenAI

```json
{
  "provider": "openai",
  "baseURL": "https://api.openai.com/v1",
  "apiKey": "your-openai-key"
}
```

## Environment Variables

Set in `.env`:

```bash
OPENROUTER_API_KEY=your-key
ANTHROPIC_API_KEY=your-key
OPENAI_API_KEY=your-key
```

Never hardcode API keys in config files.

## Troubleshooting

### OpenCode not appearing

Check extension install logs:

```bash
docker compose logs code-server | grep extension
```

### AI not responding

1. Verify FreeLLMAPI is running: `curl http://localhost:3000/health`
2. Check API key in `.env`
3. Review OpenCode output panel in Code Server

### Wrong provider

Ensure `config/opencode/config.json` points to correct baseURL.
