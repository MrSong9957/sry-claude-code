---
name: docker-claude-code
description: Use when creating isolated, persistent Docker environments for Claude Code CLI development with multi-user support (root and non-root), API proxy configuration, and clean workspace initialization
---

# Docker Claude Code

## Overview

Create isolated, reproducible Docker development environments for Claude Code CLI with persistent storage, multi-user support (root and non-root), and seamless API proxy integration.

## When to Use

```
Need isolated Claude Code environment?
│
├─→ Local environment conflicts? → Use this skill
├─→ Need clean workspace per project? → Use this skill
├─→ Team collaboration standardization? → Use this skill
└─→ Testing with specific Claude versions? → Use this skill
```

**Use when:**
- Setting up isolated Claude Code CLI environments
- Need persistent workspace and configuration across container restarts
- Working with API proxy (CC Switch or similar)
- Team requires standardized development environments
- Testing projects without polluting host system

**Don't use for:**
- Production deployments (different security requirements)
- Simple CLI usage on host (use direct install instead)
- Non-Claude Code workloads

## Core Pattern

### Before (Host Installation)
```bash
# Problems: Version conflicts, pollution, hard to reset
npm install -g @anthropic-ai/claude-code
# Global dependencies, hard to isolate per project
```

### After (Docker Environment)
```bash
# Clean, isolated, reproducible
docker-compose up -d
docker-compose exec app claude  # Non-root user
docker-compose exec -u root app bash  # Root user
```

## Quick Reference

| Command | Purpose |
|---------|---------|
| `docker-compose up -d` | Start container in background |
| `docker-compose exec app claude` | Enter as non-root user |
| `docker-compose exec -u root app bash` | Enter as root user |
| `docker-compose logs -f` | Follow container logs |
| `docker-compose down` | Stop and remove container |
| `docker-compose exec app workspace` | Show workspace path |

## Implementation

### Directory Structure

```
project/
├── .env                    # Environment variables
├── docker-compose.yml      # Container orchestration
├── Dockerfile             # Image build instructions
├── workspace/             # Development workspace (git ignored)
└── dev-home/              # Persistent Claude config (git ignored)
    ├── claude/            # Claude home directory
    └── config/            # Claude config directory
```

### Configuration Files

**See [Dockerfile](#dockerfile), [docker-compose.yml](#docker-compose-yml), [.env.example](#env-example) below**

### Environment Variables

Required in `.env`:

```bash
# API Configuration
ANTHROPIC_API_KEY=dummy  # Uses host's key via proxy
ANTHROPIC_BASE_URL=http://host.docker.internal:15721

# Paths (optional, with defaults)
WORKSPACE_PATH=./workspace
DEV_HOME_PATH=./dev-home/claude
CLAUDE_CONFIG_PATH=./dev-home/config
```

### Multi-User Access

```bash
# Non-root user (claude) - recommended for development
docker-compose exec app claude

# Root user - for system-level operations
docker-compose exec -u root app bash
docker-compose exec -u root app claude  # Run claude as root
```

## Supporting Files

### Dockerfile

```dockerfile
# syntax=docker/dockerfile:1
FROM node:20-slim

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Create non-root user
RUN groupadd -r claude && useradd -r -g claude -G sudo -m -s /bin/bash claude

# Set up sudo for non-root user
RUN echo "claude ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

# Create workspace directory
RUN mkdir -p /workspace && chown -R claude:claude /workspace

# Set working directory
WORKDIR /workspace

# Switch to non-root user
USER claude

# Default command
CMD ["bash"]
```

### docker-compose.yml

```yaml
services:
  app:
    build: .
    container_name: docker-claude-code-app
    ports:
      - "8080:8000"  # Optional: for any web services
    environment:
      - ENV=development
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL:-http://host.docker.internal:15721}
    volumes:
      # Project files (read-only to prevent hot-reload issues)
      - .:/app:ro
      # Development workspace (read-write)
      - ${WORKSPACE_PATH:-./workspace}:/workspace
      # Claude home directory (persistent config)
      - ${DEV_HOME_PATH:-./dev-home/claude}:/home/claude
      # Claude config directory
      - ${CLAUDE_CONFIG_PATH:-./dev-home/config}:/home/claude/.config/claude
    working_dir: /workspace
    stdin_open: true  # docker run -i
    tty: true         # docker run -t
    restart: unless-stopped
```

### .env.example

```bash
# Claude Code CLI Configuration
# dummy 表示沿用宿主机的 API KEY
ANTHROPIC_API_KEY=dummy

# 端口要与 CC Switch 本地代理端口一致
ANTHROPIC_BASE_URL=http://host.docker.internal:15721

# Optional: Custom paths (defaults shown)
# WORKSPACE_PATH=./workspace
# DEV_HOME_PATH=./dev-home/claude
# CLAUDE_CONFIG_PATH=./dev-home/config
```

### .gitignore

```gitignore
# Environment variables
.env

# Docker volumes
workspace/
dev-home/
```

## Common Mistakes

### Mistake 1: Not Using `host.docker.internal`

```yaml
# WRONG: Won't work from container
ANTHROPIC_BASE_URL=http://localhost:15721

# CORRECT: Special DNS name for host access
ANTHROPIC_BASE_URL=http://host.docker.internal:15721
```

### Mistake 2: Mounting Project Files Read-Write

```yaml
# WRONG: Causes hot-reload scanning issues
volumes:
  - .:/app

# CORRECT: Read-only mount for config
volumes:
  - .:/app:ro
```

### Mistake 3: Forgetting `stdin_open` and `tty`

```yaml
# WRONG: Won't allow interactive CLI
# Missing stdin_open and tty

# CORRECT: Required for interactive sessions
stdin_open: true
tty: true
```

### Mistake 4: Not Persisting Claude Config

```yaml
# WRONG: Loses config on container restart
# No volume mounts for /home/claude

# CORRECT: Persist Claude home and config
volumes:
  - ./dev-home/claude:/home/claude
  - ./dev-home/config:/home/claude/.config/claude
```

### Mistake 5: Using Only Root User

```bash
# RISKY: Running everything as root
docker-compose exec -u root app bash

# BETTER: Use non-root user for development
docker-compose exec app claude

# ROOT: Only for system operations
docker-compose exec -u root app bash  # Install system packages
```

## Real-World Impact

**Benefits:**
- Isolation: Project dependencies don't conflict
- Reproducibility: Team uses identical environments
- Clean slate: Reset workspace by deleting volume
- Version control: Dockerfile tracks CLI version
- Multi-user: Safe development (non-root) + admin access (root)

**Use Cases:**
- Node.js projects with conflicting dependencies
- Python environments requiring specific Claude versions
- Team onboarding: `docker-compose up` and ready
- Testing: Isolate breaking changes from main environment
