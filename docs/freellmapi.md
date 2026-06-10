# FreeLLMAPI Integration

## Overview

FreeLLMAPI provides free access to LLM models via multiple providers, proxied through an OpenAI-compatible API.

[FreeLLMAPI GitHub](https://github.com/tashfeenahmed/freellmapi)

## Architecture

```
Code Server
      |
      v
   OpenCode
      |
      v
FreeLLMAPI (port 3000)
      |
      +---> Google Gemini
      +---> NVIDIA NIM
      +---> GitHub Models
      +---> OpenCode Zen
      +---> OpenRouter
      +---> Groq
      +---> Cerebras
      +---> Mistral
      +---> ...and more
```

## Deployment

Deploy as a Dokploy application using `docker-compose.freellmapi.yml`.

### Named Volumes

FreeLLMAPI uses Docker named volumes for persistence:
- `freellmapi-data` — API keys, settings, provider configs
- `freellmapi-config` — Application configuration

These work with Dokploy Volume Backups to RustFS/S3.

## Supported Providers

| Provider | Free Models | Env Var |
|----------|-------------|---------|
| Google | Gemini 2.5 Flash, 3.x previews | `GOOGLE_API_KEY` |
| NVIDIA NIM | Llama 4 Scout/Maverick | `NIM_API_KEY` |
| GitHub Models | GPT-4.1, GPT-4o | `GITHUB_TOKEN` |
| OpenCode Zen | DeepSeek V4 Flash, Nemotron | `OPENCODE_ZEN_API_KEY` |
| OpenRouter | 21+ free models | `OPENROUTER_API_KEY` |
| Groq | Llama 3.3, Llama 4, GPT-OSS | Via dashboard |
| Cerebras | Qwen3 235B | Via dashboard |
| Mistral | Large 3, Codestral | Via dashboard |
| Cloudflare | Kimi K2, GLM-4.7 | Via dashboard |
| Cohere | Command R+ | Via dashboard |
| HuggingFace | DeepSeek V4, Kimi K2.6 | Via dashboard |

## Deployment

Deploy as a Dokploy application using `docker-compose.freellmapi.yml`.

## Configuration

### Environment Variables

Set in `.env`:

```bash
# Encryption key (required for key storage)
ENCRYPTION_KEY=$(openssl rand -hex 32)

# Provider API keys
OPENROUTER_API_KEY=your-openrouter-api-key
GOOGLE_API_KEY=your-google-api-key
NIM_API_KEY=your-nvidia-nim-api-key
GITHUB_TOKEN=your-github-token
OPENCODE_ZEN_API_KEY=your-opencode-zen-api-key
```

### Generate Encryption Key

```bash
openssl rand -hex 32
```

This is required for FreeLLMAPI to encrypt stored API keys.

### Get API Keys

| Provider | Where to Get |
|----------|--------------|
| Google | https://aistudio.google.com/apikey |
| NVIDIA NIM | https://build.nvidia.com |
| GitHub Models | https://github.com/settings/tokens |
| OpenCode Zen | https://opencode.ai/zen |
| OpenRouter | https://openrouter.ai/keys |

### Internal URL

From Code Server, connect to FreeLLMAPI at:

```
http://freellmapi:3000/v1
```

### External URL

```
http://your-server:3000/v1
```

### Health Check

```bash
curl http://localhost:3000/health
```

## Dashboard Setup

1. Open `http://your-server:3000` in browser
2. Create admin account on first run
3. Go to **Keys** page
4. Add provider API keys
5. Reorder **Fallback Chain** to set priority
6. Copy your unified `freellmapi-...` API key

## OpenCode Configuration

Edit `config/opencode/config.json`:

```json
{
  "provider": "openai",
  "baseURL": "http://freellmapi:3000/v1",
  "apiKey": "freellmapi-your-unified-key"
}
```

## Available Models

Check available models at:

```
http://localhost:3000/v1/models
```

## Health Check

```bash
curl http://localhost:3000/health
```

## Provider Notes

### Google Gemini

- Free tier: Generous daily limits
- Best for: General coding, conversation
- Get key: https://aistudio.google.com/apikey

### NVIDIA NIM

- Free tier: Trial access
- Best for: Vision tasks (Llama 4 Scout/Maverick)
- Note: Disabled by default, enable in dashboard
- Get key: https://build.nvidia.com

### GitHub Models

- Free tier: Experimentation/prototyping
- Best for: GPT-4.1, GPT-4o access
- Get key: https://github.com/settings/tokens

### OpenCode Zen

- Free tier: DeepSeek V4 Flash, Nemotron
- Best for: Fast inference, coding tasks
- Get key: https://opencode.ai/zen

## Troubleshooting

### No models available

1. Verify at least one API key is configured
2. Check FreeLLMAPI logs: `docker compose logs freellmapi`
3. Open dashboard and check key status on Keys page

### Connection refused

Ensure FreeLLMAPI is on the same Docker network:

```bash
docker network inspect codeserver-network
```

### Rate limiting

Free tier has rate limits. FreeLLMAPI automatically falls back to next provider.

### NVIDIA NIM not working

NVIDIA NIM is disabled by default. Enable it in the dashboard Fallback Chain.

### Key not encrypting

Ensure `ENCRYPTION_KEY` is set and 64 hex characters long.
