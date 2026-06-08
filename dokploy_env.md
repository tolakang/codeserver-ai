# Dokploy Environment Variable Hierarchy

## Purpose

This document explains how Dokploy environment variables work and the correct hierarchy for managing secrets, configuration values, API keys, and service settings.

---

# Environment Variable Hierarchy

Dokploy supports multiple levels of environment variables.

Priority (highest → lowest):

```text
Service Environment Variables
    ↓
Project Environment Variables
    ↓
Environment-Level Variables
```

A variable defined at a higher level overrides the same variable defined below it.

Example:

```text
Environment:
PORT=3000

Project:
PORT=4000

Service:
PORT=5000
```

Final value inside container:

```text
PORT=5000
```

---

# 1. Environment-Level Variables

Location:

```text
Dokploy
 └─ Environment
     └─ Environment Variables
```

Example:

```text
NODE_ENV=development
DATABASE_URL=postgresql://localhost:5432/mydb
API_KEY=your-api-key
```

Purpose:

Store variables shared across multiple projects.

Examples:

```env
OPENROUTER_API_KEY=
ANTHROPIC_API_KEY=
GITHUB_TOKEN=
POSTGRES_VERSION=
REDIS_VERSION=
```

Reference syntax:

```env
${{environment.API_KEY}}
${{environment.DATABASE_URL}}
```

Example:

```env
OPENROUTER_API_KEY=${{environment.OPENROUTER_API_KEY}}
```

Use Cases:

- Shared secrets
- Shared API keys
- Organization-wide configuration
- Infrastructure configuration

Avoid:

- Service-specific settings
- Application-specific ports
- Project-specific URLs

---

# 2. Project-Level Variables

Location:

```text
Project
 └─ Settings
     └─ Project Environment
```

Purpose:

Variables shared by all services inside one project.

Example Project:

```text
shopking
├── frontend
├── backend
├── worker
├── scheduler
└── nginx
```

Shared variables:

```env
APP_NAME=ShopKing
APP_URL=https://shop.example.com
PORT=3000
```

Reference syntax:

```env
${{project.APP_URL}}
${{project.PORT}}
```

Example:

```env
NEXT_PUBLIC_API_URL=${{project.APP_URL}}
```

Use Cases:

- Application URLs
- Shared database host
- Shared Redis host
- Shared domain names
- Common project settings

Avoid:

- Private service secrets
- Service-only configuration

---

# 3. Service Environment Variables

Location:

```text
Service
 └─ Environment Variables
```

Purpose:

Variables only used by one service.

Example:

Backend service:

```env
JWT_SECRET=super-secret
QUEUE_CONNECTION=redis
```

Frontend service:

```env
NEXT_PUBLIC_API_URL=https://api.example.com
```

Worker service:

```env
WORKER_CONCURRENCY=10
```

Use Cases:

- JWT secrets
- Service ports
- Runtime settings
- Feature flags
- Worker configuration

---

# Recommended Structure

Example ShopKing Project:

## Environment Level

```env
OPENROUTER_API_KEY=
ANTHROPIC_API_KEY=
POSTGRES_VERSION=17
REDIS_VERSION=8
```

---

## Project Level

```env
APP_NAME=ShopKing
APP_URL=https://shop.example.com
API_URL=https://api.shop.example.com
DB_HOST=postgres
REDIS_HOST=redis
```

---

## Backend Service

```env
JWT_SECRET=
APP_KEY=
QUEUE_CONNECTION=redis
```

---

## Frontend Service

```env
NEXT_PUBLIC_API_URL=${{project.API_URL}}
```

---

## Worker Service

```env
WORKER_CONCURRENCY=10
QUEUE_CONNECTION=redis
```

---

# Secret Management Best Practices

Store sensitive values in the highest reusable level.

Good:

```env
Environment Level:
OPENROUTER_API_KEY=
GITHUB_TOKEN=
```

Then reference:

```env
OPENROUTER_API_KEY=${{environment.OPENROUTER_API_KEY}}
```

Benefits:

- Single source of truth
- Easier rotation
- Less duplication
- More secure

---

# OpenCode Agent Rules

When generating Dokploy configurations:

### Rule 1

Check whether a variable should be:

```text
Environment Level
Project Level
Service Level
```

before creating it.

---

### Rule 2

Do not duplicate variables across levels.

Bad:

```env
Environment:
API_KEY=xxx

Project:
API_KEY=xxx

Service:
API_KEY=xxx
```

Good:

```env
Environment:
API_KEY=xxx

Service:
API_KEY=${{environment.API_KEY}}
```

---

### Rule 3

Secrets belong in:

```text
Environment Level
```

Examples:

```env
OPENROUTER_API_KEY
ANTHROPIC_API_KEY
GITHUB_TOKEN
DATABASE_PASSWORD
```

---

### Rule 4

Project-wide settings belong in:

```text
Project Environment
```

Examples:

```env
APP_URL
API_URL
DB_HOST
REDIS_HOST
```

---

### Rule 5

Service-specific settings belong in:

```text
Service Environment
```

Examples:

```env
PORT
JWT_SECRET
WORKER_CONCURRENCY
```

---

# Quick Decision Table

| Variable Type  | Location    |
| -------------- | ----------- |
| API Keys       | Environment |
| Shared Secrets | Environment |
| Domain Names   | Project     |
| App URLs       | Project     |
| Database Host  | Project     |
| Redis Host     | Project     |
| Service Port   | Service     |
| JWT Secret     | Service     |
| Worker Config  | Service     |
| Feature Flags  | Service     |

---

# Summary

```text
Environment Level
    ↓
Shared across ALL projects

Project Level
    ↓
Shared across ALL services inside ONE project

Service Level
    ↓
Used by ONE service only
```

Always place variables at the highest reusable level and reference them downward using:

```env
${{environment.VARIABLE_NAME}}
${{project.VARIABLE_NAME}}
```

This minimizes duplication, simplifies maintenance, and follows Dokploy best practices.
