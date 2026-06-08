# FreeLLMAPI Integration

## Overview

FreeLLMAPI provides free access to LLM models via OpenRouter, proxied through an OpenAI-compatible API.

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
      v
OpenRouter Free Models
```

## Deployment

Deploy as a Dokploy application using `docker-compose.freellmapi.yml`.

## Configuration

### Environment Variables

Set in `.env`:

```bash
OPENROUTER_API_KEY=your-openrouter-api-key
```

Get a free API key at [openrouter.ai](https://openrouter.ai).

### Internal URL

From Code Server, connect to FreeLLMAPI at:

```
http://freellmapi:3000/v1
```

### External URL

```
http://your-server:3000/v1
```

## OpenCode Configuration

Edit `config/opencode/config.json`:

```json
{
  "provider": "openai",
  "baseURL": "http://freellmapi:3000/v1",
  "apiKey": "dummy"
}
```

## Available Models

FreeLLMAPI routes to OpenRouter's free tier models. Check available models at:

```
http://localhost:3000/v1/models
```

## Health Check

```bash
curl http://localhost:3000/health
```

## Troubleshooting

### No models available

1. Verify OpenRouter API key is valid
2. Check FreeLLMAPI logs: `docker compose logs freellmapi`
3. Ensure network connectivity to OpenRouter

### Connection refused

Ensure FreeLLMAPI is on the same Docker network as Code Server:

```bash
docker network inspect codeserver-network
```

### Rate limiting

Free tier has rate limits. Consider upgrading OpenRouter plan for production use.
