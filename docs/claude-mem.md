# Claude Memory

## Overview

Claude-Mem provides persistent memory for AI conversations across sessions.

## Storage Location

Memory is stored in:

```
/workspace/.memory
```

This is inside the persistent workspace volume, so memory survives:

- Container restarts
- Container updates
- Server reboots
- Redeployments

## Volume Persistence

```
Host:    /mnt/storage/code-server/workspace/.memory
Container: /workspace/.memory
```

## Setup

Claude-Mem is automatically configured to use the workspace directory.

No additional setup required.

## How It Works

1. AI conversations are stored in `/workspace/.memory`
2. Each project gets its own memory context
3. Memory persists across sessions
4. Code Server restart does not affect memory

## Manual Memory Management

### View memory files

```bash
ls -la /workspace/.memory/
```

### Clear memory

```bash
rm -rf /workspace/.memory/*
```

### Backup memory

Memory is included in workspace backups:

```bash
# Part of regular backup
tar czf workspace.tar.gz /workspace
```

## Troubleshooting

### Memory not persisting

1. Verify workspace volume is mounted: `mount | grep workspace`
2. Check `/workspace/.memory` exists: `ls -la /workspace/.memory`

### Memory too large

Clear old memory files:

```bash
find /workspace/.memory -mtime +30 -delete
```
