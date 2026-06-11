# Update Procedures

## Overview

This document covers the update procedures for all services in Code Server AI.

## Update Strategy

All services are rebuilt from source during updates to ensure latest security patches and features.

## Update All Services

### Basic Update

```bash
./scripts/update.sh
```

### Update Specific Service

```bash
./scripts/update.sh code-server
./scripts/update.sh gitea
./scripts/update.sh freellmapi
./scripts/update.sh rustfs
./scripts/update.sh opencode-web
```

## Update Process

### 1. Check Latest Versions

The update script automatically fetches the latest versions from GitHub:

- **code-server**: Latest stable release
- **gitea**: Latest stable release
- **freellmapi**: Latest version (default: `latest`)
- **rustfs**: Latest stable release
- **opencode-web**: Latest version (default: `latest`)

### 2. Architecture Detection

The script automatically detects system architecture:

```bash
# x86_64 systems
TARGETARCH=amd64

# ARM systems (Raspberry Pi, etc.)
TARGETARCH=arm64
```

### 3. Service Updates

Each service is updated in sequence:

#### Code Server Update

```bash
echo "--- Updating code-server ---"
CODESERVER_VERSION=$CODESERVER_VERSION TARGETARCH=$TARGETARCH \
  docker compose -f deploy/docker-compose.code-server.yml build --no-cache
docker compose -f deploy/docker-compose.code-server.yml up -d
```

#### Gitea Update

```bash
echo "--- Updating gitea ---"
docker compose -f deploy/docker-compose.gitea.yml build --no-cache
docker compose -f deploy/docker-compose.gitea.yml up -d
```

#### FreeLLMAPI Update

```bash
echo "--- Updating freellmapi ---"
FREELLM_VERSION=${FREELLM_VERSION:-latest} \
  docker compose -f deploy/docker-compose.freellmapi.yml build --no-cache
docker compose -f deploy/docker-compose.freellmapi.yml up -d
```

#### RustFS Update

```bash
echo "--- Updating rustfs ---"
docker compose -f deploy/docker-compose.rustfs.yml build --no-cache
docker compose -f deploy/docker-compose.rustfs.yml up -d
```

#### OpenCode WEB Update

```bash
echo "--- Updating opencode-web ---"
  OPENCODE_VERSION=${OPENCODE_VERSION:-latest} \
    docker compose -f deploy/docker-compose.opencode-web.yml build --no-cache
docker compose -f deploy/docker-compose.opencode-web.yml up -d
```

## Update Best Practices

### Before Updating

1. **Backup data**: Run backup script before updating
2. **Check system resources**: Ensure sufficient disk space
3. **Test in staging**: Update test environment first
4. **Notify users**: Inform users of potential downtime

### During Update

1. **Monitor logs**: Watch for errors during update
2. **Check service health**: Verify services start correctly
3. **Test functionality**: Test critical features after update
4. **Rollback plan**: Have rollback procedure ready

### After Update

1. **Verify services**: Check all services are running
2. **Test integrations**: Verify AI integrations work
3. **Check backups**: Ensure backup system still works
4. **Monitor performance**: Watch for performance issues

## Update Troubleshooting

### Update Fails

```bash
# Check update logs
docker compose logs code-server

# Check specific service logs
docker compose logs gitea
```

### Service Not Starting After Update

```bash
# Check container status
docker compose ps

# Check container logs
docker compose logs [service-name]
```

### Rollback

If an update causes issues:

1. **Stop all services**:

```bash
docker compose down
```

2. **Restore from backup**:

```bash
./scripts/restore.sh
```

3. **Restart services**:

```bash
docker compose up -d
```

## Update Monitoring

### Check Update Status

```bash
# Check if update is running
docker compose ps

# Check update logs
tail -f /var/log/update.log
```

### Monitor Service Health

```bash
# Check code-server status
docker compose -f deploy/docker-compose.code-server.yml ps

# Check gitea status
docker compose -f deploy/docker-compose.gitea.yml ps

# Check freellmapi status
docker compose -f deploy/docker-compose.freellmapi.yml ps

# Check rustfs status
docker compose -f deploy/docker-compose.rustfs.yml ps

# Check opencode-web status
docker compose -f deploy/docker-compose.opencode-web.yml ps
```

## Update Frequency

### Recommended Schedule

- **Security patches**: Update immediately when available
- **Feature updates**: Update during maintenance windows
- **Major versions**: Plan for downtime and test thoroughly

### Automated Updates

Consider setting up a monitoring system to alert when new versions are available:

```bash
# Example: Check for updates weekly
crontab -e
0 0 * * 0 ./scripts/update.sh --check-only
```

## Update Scripts

### update.sh

Main update script with the following functions:

- `update_codeserver`: Updates code-server service
- `update_gitea`: Updates Gitea service
- `update_freellmapi`: Updates FreeLLMAPI service
- `update_rustfs`: Updates RustFS service
- `update_opencode_web`: Updates OpenCode WEB service
- `update_all`: Updates all services

### update.sh Usage

```bash
# Update all services
./scripts/update.sh

# Update specific service
./scripts/update.sh code-server
./scripts/update.sh gitea
./scripts/update.sh freellmapi
./scripts/update.sh rustfs
./scripts/update.sh opencode-web
```

## Post-Update Checklist

After each update, verify:

- [ ] All services are running
- [ ] Code Server is accessible
- [ ] Gitea Git server works
- [ ] AI integrations function
- [ ] Backups are working
- [ ] Extensions are installed
- [ ] User data is intact
- [ ] Performance is acceptable

## Update Support

If you encounter issues during updates:

1. **Check logs**: Review update logs for error messages
2. **Contact support**: Reach out to your Dokploy administrator
3. **Rollback**: Use backup to restore previous state
4. **Document issues**: Record any problems for future reference
