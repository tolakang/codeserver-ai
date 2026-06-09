# codeserver-ai Development Plan

## Project Overview

Self-hosted Code Server IDE with AI integration, Gitea Git hosting, FreeLLMAPI proxy, and RustFS S3 backups — deployed on Dokploy.

## Current Architecture

```
                        ┌─────────────────────────────────────┐
                        │          codeserver-network          │
                        │                                      │
  ┌──────────┐    ┌─────┴──────┐    ┌──────────┐    ┌────────┐ │
  │ Code     │    │   Gitea    │    │FreeLLMAPI│    │ RustFS │ │
  │ Server   │◄──►│  (Source   │◄──►│ (Source  │◄──►│ (Binary│ │
  │ (.deb)   │    │   Build)   │    │  Build)  │    │   DL)  │ │
  │ :8080    │    │ :3001/2222 │    │ :3000    │    │ :9000  │ │
  └──────────┘    └─────┬──────┘    └──────────┘    └────────┘ │
                        │                                      │
                        │ Database                             │
                        ▼                                      │
                   ┌─────────┐                                 │
                   │ SQLite3 │                                 │
                   │ (file)  │                                 │
                   └─────────┘                                 │
                        │                                      │
                        ▼                                      │
                   ┌─────────┐                                 │
                   │ Volume  │                                 │
                   │ gitea-  │                                 │
                   │ data    │                                 │
                   └─────────┘                                 │
┌──────────────────┴──────────────────────────────────────────┘
│
▼
Dokploy (Docker-based deployment)
```

### Services

| Service | Build Method | Port | Data Storage |
|---------|-------------|------|-------------|
| code-server | .deb from GitHub | 8080 | Named volumes |
| gitea | Source (Go) | 3001, 2222 | Named volume + future PostgreSQL |
| freellmapi | Source (Node.js) | 3000 | Bind mount |
| rustfs | Binary download | 9000 | Bind mount |

### Key Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Combined orchestrator |
| `deploy/docker-compose.*.yml` | Per-service compose files for Dokploy |
| `Dockerfile.*` | Build definitions |
| `scripts/backup.sh` | RustFS backup |
| `scripts/restore.sh` | RustFS restore |
| `.env.example` | Environment template |

---

## Phase 1: Gitea Database Migration (Current Sprint)

### Objective
Replace SQLite3 with PostgreSQL + PgBouncer for production-grade database.

### Changes

#### 1. docker-compose.gitea.yml
- Add `postgres:16-alpine` service
- Add `pgbouncer` connection pooler
- Update gitea env vars to point to pgbouncer
- Add `postgres-data` volume
- Add `depends_on` with health checks

#### 2. New Files
- `deploy/backup-gitea.sh` — pg_dump script
- `deploy/backup-cron.yml` — Dokploy cron job
- `config/pgbouncer/pgbouncer.ini` — custom config

#### 3. Updated `.env.example`
- `POSTGRES_PASSWORD`
- `PGBOUNCER_PASSWORD`
- `GITEA_DOMAIN`

### Architecture (After)

```
┌──────────┐    ┌──────────┐    ┌──────────┐
│  Gitea   │───▶│PgBouncer │───▶│PostgreSQL│
│          │    │  :6432   │    │  :5432   │
└──────────┘    └──────────┘    └──────────┘
                                    │
                               ┌────┴────┐
                               │ Volume  │
                               │postgres-│
                               │ data    │
                               └─────────┘
```

### Migration Steps

| Step | Action | Duration |
|------|--------|----------|
| 1.1 | Add postgres service | 15 min |
| 1.2 | Add pgbouncer service | 15 min |
| 1.3 | Update gitea env vars | 10 min |
| 1.4 | Add volumes + depends_on | 5 min |
| 1.5 | Commit & push | 5 min |
| 1.6 | Deploy in Dokploy | 30 min |
| 1.7 | Run install page | 5 min |

### Rollback
- Revert compose to SQLite3 config
- Keep volumes intact
- Redeploy

---

## Phase 2: Backup Automation

### Objective
Automated daily PostgreSQL dumps with pg_dump + RustFS upload.

### Components

| Component | Schedule | Retention |
|-----------|----------|-----------|
| pg_dump to RustFS | Daily 2 AM UTC | 7 daily, 4 weekly, 6 monthly |
| Volume snapshot (Dokploy) | Weekly | 4 weeks |

### Backup Flow

```
pg_dump ──▶ gzip ──▶ aws s3 cp ──▶ RustFS (:9000)
                                      │
                                  ┌───┴───┐
                                  │ Volume │
                                  │rustfs- │
                                  │ data   │
                                  └───────┘
```

---

## Phase 3: Code Server Optimization

### Objective
Improve build speed and resource efficiency.

| Task | Current | Target | Priority |
|------|---------|--------|----------|
| Multi-stage build optimization | ~5 min | ~2 min | Medium |
| Named volume migration (gitea) | Done | Done | Complete |
| Named volume migration (freellmapi) | Bind mount | Named volume | Low |
| Named volume migration (rustfs) | Bind mount | Named volume | Low |

---

## Phase 4: Gitea Build Optimization

### Objective
Reduce Gitea source build time from ~230s to ~170s.

### Completed Optimizations

| Optimization | Status | Savings |
|-------------|--------|---------|
| Share git clone between stages | ✅ Done | ~4.5s |
| Pre-download Go modules with cache | ✅ Done | ~55s |
| Copy docker/root from local source | ✅ Done | ~2s |

---

## Phase 5: Documentation & Monitoring

### Tasks

| Task | Priority |
|------|----------|
| Update README with new architecture diagram | Medium |
| Add PostgreSQL migration guide to docs/gitea.md | Medium |
| Add PgBouncer tuning docs | Low |
| Add backup restore procedure for PostgreSQL | Medium |
| Add health check monitoring recommendations | Low |

---

## Service-Level Configs

### Gitea

| Config | Value | Notes |
|--------|-------|-------|
| DB Type | postgres | via pgbouncer |
| DB Host | pgbouncer | pooler, not direct |
| DB Port | 6432 | pgbouncer default |
| DB Name | gitea | |
| DB User | gitea | |
| DB SSL | disable | internal network |

### PgBouncer

| Setting | Value | Reason |
|---------|-------|--------|
| Pool Mode | transaction | best for web apps |
| Default Pool Size | 20 | per Gitea docs |
| Min Pool Size | 5 | avoid connection storms |
| Max Client Conn | 100 | safe limit |
| Reserve Pool Size | 5 | burst handling |
| Reserve Pool Timeout | 5s | |

### PostgreSQL

| Setting | Value | Reason |
|---------|-------|--------|
| Image | postgres:16-alpine | current stable, small |
| max_connections | 200 | pgbouncer handles pooling |
| shared_buffers | 256MB | good for <2GB memory |
| effective_cache_size | 1GB | assumes 2GB+ total |

---

## Port Mapping

| Service | Internal Port | External Port | Notes |
|---------|--------------|---------------|-------|
| code-server | 8080 | 8080 | Web IDE |
| gitea | 3000 | 3001 | Web UI |
| gitea | 22 | 2222 | SSH |
| pgbouncer | 6432 | — | Internal only |
| postgres | 5432 | — | Internal only |
| freellmapi | 3000 | 3000 | LLM proxy |
| rustfs | 9000 | 9000 | S3 storage |

---

## Environment Variables

```bash
# Database
POSTGRES_PASSWORD=<auto-generated>
PGBOUNCER_PASSWORD=<auto-generated>

# Gitea
GITEA_DOMAIN=https://git.example.com

# Existing (unchanged)
CS_PASSWORD=<value>
OPENROUTER_API_KEY=<value>
RUSTFS_ACCESS_KEY=<value>
RUSTFS_SECRET_KEY=<value>
RUSTFS_ENDPOINT=http://rustfs:9000
```

---

## Testing

| Test | Method |
|------|--------|
| Gitea starts | `curl -f http://localhost:3001/api/v1/version` |
| PostgreSQL connected | Check Gitea logs for "Connected to database" |
| PgBouncer working | `psql -h localhost -p 6432 -U gitea -d gitea -c "SELECT 1"` |
| Backup works | Run `backup-gitea.sh` manually, verify in RustFS |
| Health checks pass | `docker inspect --format='{{json .State.Health}}'` |
| SSH access | `ssh -p 2222 git@localhost` |

---

## Deployment Checklist

- [ ] Generate secure passwords
- [ ] Update `.env` with all variables
- [ ] Update `docker-compose.gitea.yml`
- [ ] Create `deploy/backup-gitea.sh`
- [ ] Create `deploy/backup-cron.yml`
- [ ] Commit and push to GitHub
- [ ] Deploy in Dokploy
- [ ] Run install page (fresh deploy)
- [ ] Verify all health checks pass
- [ ] Test backup manually
- [ ] Test SSH access

---

## Notes

- All services communicate over `codeserver-network` (external: true)
- No hardcoded secrets — always use env vars
- Named volumes preferred over bind mounts
- Container must be restart-safe
- Never delete user workspace data
