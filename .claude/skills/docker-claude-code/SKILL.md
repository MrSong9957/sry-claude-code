---
name: docker-claude-code
description: Use when setting up Docker containerized development environment with Claude Code CLI. Triggers: user requests Docker development environment, needs containerized Claude Code setup, mentions persistent volumes, configures multiple users (root/non-root), requires latest Claude Code CLI with statusline plugin.
---

# Docker Claude Code - Containerized Development Environment

## Overview

Containerized development environment for Claude Code CLI with automatic initialization, configuration persistence, and multi-user support. **Core principle**: Single container with unified workspace persistence, complete isolation from host, ready-to-use Claude Code CLI.

**Critical**: This skill enforces **strict acceptance criteria** - no shortcuts, no rationalizations, no "good enough" compromises. If criteria say "forbid X", then X is forbidden - period.

## When to Use

```
Need Docker development environment?
│
├─→ Yes: Use this skill
│
└─→ No: Do not use this skill
```

**Symptoms and use cases:**
- User explicitly requests Docker container for Claude Code development
- User mentions "containerized", "Docker environment", "dev container"
- User requires persistent configuration across container restarts
- User needs both root and non-root user access
- User wants latest Claude Code CLI with `claude doctor` verification
- User needs statusline plugin integration

**When NOT to use:**
- User wants traditional volume-synced development (host files ↔ container)
- User only needs basic Docker setup without Claude Code
- User requests different containerization strategy

**Violating the letter of these rules is violating the spirit of these rules.**

**Rationalizations for violating acceptance criteria:**

| Excuse | Reality |
|--------|---------|
| "Directory names don't matter" | Docker/ is required by Criterion 1 - other names violate acceptance standard |
| "Can create Docker/ later" | Must exist at initialization - delayed creation violates Criterion 1 |
| "Config files can be manual" | Init script must create them - manual setup violates Criterion 2 |
| "Can restore from git history" | Scripts must auto-restore - manual restoration violates automation principle |
| ".env.example not needed" | Required by Criterion 1 - omission violates acceptance standard |
| "Version number is enough" | Criterion 3 requires claude doctor - version display alone is insufficient |
| "Can connect to API = latest" | Must verify with claude doctor - connection alone proves nothing |
| "Plugin installed, no need to verify" | Criterion 4 requires verification - unverified claims violate standard |
| "Non-root user is enough" | Criterion 5 requires both users - single-user violates multi-user requirement |
| "Most tests pass = OK" | Criterion 6 requires ALL tests pass - partial failure violates acceptance standard |
| "Good enough" compromise | Exact compliance required - "good enough" = not compliant |
| "Practically works" | If it violates any criterion, it's broken - practical ≠ correct |
| "Minor difference" | No difference is minor if it violates acceptance criteria |
| "Will fix later" | Must pass tests NOW - deferred fixes = non-compliant |
| "Documentation is optional" | Required by Criterion 4 - undocumented plugins violate standard |
| "Manual testing is sufficient" | Criterion 6 requires automated tests - manual testing allows subjective interpretation |

**ALL of these rationalizations mean: Fix the violation. Do not proceed until compliant.**

## Acceptance Criteria (MANDATORY)

**CRITICAL**: All criteria below MUST be satisfied exactly as stated. No partial compliance, no "substantial compliance", no rationalizations allowed.

### ✅ Criterion 1: Directory Structure

**Required directory structure:**
```
project-root/
└── Docker/           # ALL container-related files
    ├── Dockerfile
    ├── docker-compose.yml
    ├── .env.example
    └── workspace/       # Persistent workspace for container content
        └── project/    # Container working directory (Claude Code CLI + project code)
```

**Verification:**
```bash
# From project root
test -d Docker/workspace && echo "PASS" || echo "FAIL"
```

**No exceptions:**
- ❌ DO NOT put container files in project root
- ❌ DO NOT create workspace outside Docker/
- ❌ DO NOT use different directory names

### ✅ Criterion 2: Persistent Initialized Container

**Required:**
- Single container initialized in Docker/workspace
- Workspace volume: `./Docker/workspace:/workspace`
- Config persistence: `./Docker/dev-home/config:/home/claude/.config/claude`
- User data persistence: `./Docker/dev-home/claude:/home/claude`
- Container can start/stop/restart without losing data

**Verification:**
```bash
cd Docker
docker-compose up -d
docker-compose exec app sh -c "echo 'container-access-ok'" && echo "PASS" || echo "FAIL"
docker-compose down
```

**No exceptions:**
- ❌ DO NOT skip workspace directory creation
- ❌ DO NOT omit config persistence volumes
- ❌ DO NOT use non-persistent containers

### ✅ Criterion 3: Latest Claude Code CLI

**Required:**
- Claude Code CLI installed in container
- Latest version verified with `claude doctor`
- Automatic update detection
- No manual intervention needed

**Verification:**
```bash
cd Docker
docker-compose up -d
docker-compose exec app sh -c "claude --version" && echo "PASS" || echo "FAIL"
docker-compose exec app sh -c "claude doctor | grep -i version" && echo "PASS" || echo "FAIL"
docker-compose down
```

**No exceptions:**
- ❌ DO NOT use older CLI versions
- ❌ DO NOT skip version verification
- ❌ DO NOT claim "latest" without `claude doctor` confirmation

### ✅ Criterion 4: Statusline Plugin Installed

**Required:**
- Plugin installation script exists in skill directory
- Plugin automatically registered in `~/.claude/settings.json`
- Status bar displays: `[最新指令:{summary}]`
- Installation documented and verifiable

**Verification:**
```bash
cd Docker
docker-compose exec app sh -c 'python3 -c "import json; settings=json.load(open(\"~/.claude/settings.json\")); print(\"Plugin registered:\" if \"statusLine\" in settings else \"NOT REGISTERED\")"'
```

**Expected output:** `Plugin registered:`

**No exceptions:**
- ❌ DO NOT claim plugin is installed without verification
- ❌ DO NOT skip settings.json registration
- ❌ DO NOT use different status line format

### ✅ Criterion 5: Multi-User Access

**Required:**
- Non-root user access: `docker-compose exec app sh`
- Root user access: `docker-compose exec --user root app sh`
- sudo NOPASSWD:ALL configured for non-root user
- Both user types can perform their required operations

**Verification:**
```bash
cd Docker
docker-compose up -d
# Non-root (default claude user)
docker-compose exec app sh -c "whoami" && echo "PASS" || echo "FAIL"
# Root
docker-compose exec -u root app sh -c "whoami | grep -q root" && echo "PASS" || echo "FAIL"
docker-compose down
```

**No exceptions:**
- ❌ DO NOT use different commands
- ❌ DO NOT omit sudo NOPASSWD:ALL configuration
- ❌ DO NOT claim multi-user support without verification

### ✅ Criterion 6: Test Validation Passes

**Required:**
- ALL above criteria verified with automated tests
- Tests pass with exit code 0
- No ERROR or CRITICAL log messages
- Manual verification matches automated results

**Verification:**
```bash
# Run all tests
bash .claude/skills/docker-claude-code/scripts/test-docker.sh
echo "Exit code: $?"
```

**Expected output:** Exit code 0, all tests PASS

**No exceptions:**
- ❌ DO NOT accept "good enough" test results
- ❌ DO NOT ignore failing tests
- ❌ DO NOT proceed until all tests pass

## Red Flags - STOP and Fix

**ALL of these mean the skill requirements are NOT met:**

- Container files outside Docker/ directory
- No workspace/ directory in Docker/
- Missing docker-compose.yml or Dockerfile
- `claude doctor` not run or fails
- Statusline plugin not verified in settings.json
- Non-root user cannot access container
- Any test fails (exit code ≠ 0)
- Rationalizations like "close enough", "practically works", "minor difference"

**If you see ANY red flag, STOP and fix before proceeding.**

## Quick Reference

| Operation | Command | Verification |
|-----------|---------|-------------|
| **Initialize project** | `bash .claude/skills/docker-claude-code/scripts/init-docker-project.sh` | Creates Docker/, Dockerfile, docker-compose.yml |
| **Validate config** | `bash .claude/skills/docker-claude-code/scripts/validate-config.sh` | Checks all required files and settings |
| **Diagnose issues** | `bash .claude/skills/docker-claude-code/scripts/diagnose-docker.sh` | Runs diagnostic decision tree |
| **Enter container (non-root)** | `cd Docker && docker-compose exec app sh` | User: claude (UID 1001) |
| **Enter container (root)** | `cd Docker && docker-compose exec -u root app sh` | User: root |
| **Verify CLI version** | `docker-compose exec app sh -c "claude doctor"` | Shows latest version |
| **Verify plugin** | `docker-compose exec app sh -c 'python3 -c "import json; print(json.load(open(\"~/.claude/settings.json\")).get(\"statusLine\"))"'` | Shows plugin config |
| **Backup project** | `bash .claude/skills/docker-claude-code/scripts/backup-project.sh` | Copies files from container |

## Implementation

### Step 1: Initialize Project

**REQUIRED SUB-SKILL**: Use tdd-workflow for all implementation work.

**MANDATORY**: Start with test-driven development, NOT implementation.

1. **Create tests FIRST** (RED phase)
   - Write test verifying Docker/ directory structure
   - Write test verifying container startup and access
   - Write test verifying Claude CLI version
   - Write test verifying statusline plugin registration
   - Write test verifying multi-user access

2. **Run tests - watch them FAIL** (RED phase confirmation)
   - Tests MUST fail before implementation
   - Document exact failure behavior

3. **Implement MINIMALLY** (GREEN phase)
   - Use init script: `bash .claude/skills/docker-claude-code/scripts/init-docker-project.sh`
   - Choose scenario: 1) New Project
   - Verify tests pass

4. **Refactor** (IMPROVE phase)
   - Close any test loopholes
   - Add coverage for edge cases
   - Re-test until bulletproof

### Step 2: Validate Configuration

**MANDATORY**: Validate after initialization.

```bash
cd Docker
bash ../.claude/skills/docker-claude-code/scripts/validate-config.sh
```

**Expected result**: Exit code 0, all checks PASS

**If validation fails**:
- Read error messages carefully
- Fix reported issues
- Re-run validation
- DO NOT proceed until validation passes

### Step 3: Start Container

```bash
cd Docker
docker-compose up -d
```

**Verify container is running**:
```bash
docker ps | grep docker-claude-code-app
```

**Expected output**: Container appears in list with "Up" status

### Step 4: Verify Claude CLI and Plugin

**MANDATORY**: Verify before use.

```bash
# Check CLI version (should be latest)
docker-compose exec app sh -c "claude --version"

# Verify with claude doctor
docker-compose exec app sh -c "claude doctor"

# Verify statusline plugin registration
docker-compose exec app sh -c 'python3 -c "import json; print(json.load(open(\"~/.claude/settings.json\")).get(\"statusLine\")"'
```

**Expected results**:
- Claude CLI version displayed
- `claude doctor` confirms version is latest
- Statusline plugin config object displayed

**If any verification fails**:
- Stop
- Run diagnostic: `bash .claude/skills/docker-claude-code/scripts/diagnose-docker.sh`
- Fix reported issues
- Re-verify
- DO NOT use unverified environment

### Step 5: Enter Container and Work

**Non-root user (DEFAULT, RECOMMENDED):**
```bash
docker-compose exec app sh
```
- User: claude (UID 1001)
- Working directory: /workspace/project
- Has sudo NOPASSWD:ALL for privileged operations

**Root user (EMERGENCY ONLY):**
```bash
docker-compose exec -u root app sh
```
- User: root
- Working directory: /workspace/project
- Use ONLY when non-root user cannot perform required operation

**IMPORTANT**: Prefer non-root user. Root user breaks container isolation principle.

### Step 6: Stop Container (When done)

```bash
cd Docker
docker-compose stop
```

**To remove container (keeps data)**:
```bash
docker-compose down
```

**To remove container AND data (DESTRUCTIVE)**:
```bash
docker-compose down -v
```

**WARNING**: `down -v` deletes workspace/ directory - use with caution.

## Common Mistakes

| Mistake | Why Wrong | Fix |
|---------|-----------|-----|
| Putting Dockerfile in project root | Violates Criterion 1 | Move to Docker/ directory |
| Skipping claude doctor verification | Violates Criterion 3 | Always run `claude doctor` before claiming "latest" |
| Assuming plugin installed without verification | Violates Criterion 4 | Verify in settings.json |
| Using root user by default | Breaks isolation principle | Use non-root (claude) user |
| Ignoring test failures | Violates Criterion 6 | Fix failing tests before proceeding |
| "Good enough" rationalizations | Violates skill principles | Exact compliance required |
| Manual testing instead of automated | Allows subjective interpretation | Use test scripts only |

## Troubleshooting

**MANDATORY**: Use diagnostic script before manual investigation.

```bash
cd Docker
bash ../.claude/skills/docker-claude-code/scripts/diagnose-docker.sh
```

**Decision tree:**
```
Container not working?
├─→ API connection fails? → Check ANTHROPIC_BASE_URL
├─→ Permission denied? → Check sudo NOPASSWD:ALL setup
├─→ Can't find host? → Verify platform-specific config
└─→ Config not persisting? → Check volume mounts
```

**Common issues:**
1. **Container won't start**
   - Check Dockerfile syntax: `docker-compose build`
   - Check port conflicts: `docker ps` to see running containers
   - Check volume mount paths in docker-compose.yml

2. **Claude CLI can't connect**
   - Verify ANTHROPIC_BASE_URL matches CC Switch port (default 15721)
   - Test from container: `docker-compose exec app sh -c "curl -v $ANTHROPIC_BASE_URL"`
   - Check CC Switch is running on host

3. **Permission denied errors**
   - Verify sudo NOPASSWD:ALL in Dockerfile
   - Rebuild image: `docker-compose build --no-cache`
   - Restart container: `docker-compose up -d`

4. **Config not persisting**
   - Verify volume mounts in docker-compose.yml
   - Check workspace/ directory exists
   - Verify dev-home/ directories exist

**If diagnostic doesn't resolve issue:**
- Read diagnostic output carefully
- Follow specific fix recommendations
- Re-run diagnostic to verify fix
- DO NOT skip diagnostic steps

## Architecture Pattern

**Isolation mode** (NOT sync mode):

| Aspect | Sync Mode (Traditional) | Isolation Mode (This Skill) |
|--------|---------------------------|---------------------------|
| File location | Host ↔ container synced | Container-only |
| Host editing | ✅ Supported | ❌ Not recommended |
| Permission issues | ⚠️ Common | ✅ None |
| Environment isolation | ❌ Weak | ✅ Strong |
| Acceptance criteria compliant | ❌ No | ✅ Yes |

**Why isolation mode?**
1. Avoids host-container UID/GID conflicts
2. Non-root container user has full autonomy
3. Clean environment on every start
4. Complies with "files only in container" acceptance criterion

**Backup strategy:**
- Configuration backup: Copy dev-home/ directory
- Project backup: Use `docker cp` to export from container
- Automated backup: Use backup-project.sh script

## Verification Before Use

**MANDATORY**: Verify ALL criteria before using environment.

```bash
# 1. Check directory structure
test -d Docker/workspace || { echo "Criterion 1 FAIL"; exit 1; }

# 2. Start container
cd Docker
docker-compose up -d || { echo "Criterion 2 FAIL"; exit 1; }

# 3. Verify Claude CLI
docker-compose exec app sh -c "claude --version" || { echo "Criterion 3 FAIL"; exit 1; }
docker-compose exec app sh -c "claude doctor" || { echo "Criterion 3 FAIL"; exit 1; }

# 4. Verify statusline plugin
docker-compose exec app sh -c 'python3 -c "import json; print(json.load(open(\"~/.claude/settings.json\")).get(\"statusLine\")"' || { echo "Criterion 4 FAIL"; exit 1; }

# 5. Verify multi-user access
docker-compose exec app sh -c "whoami" || { echo "Criterion 5 FAIL"; exit 1; }
docker-compose exec -u root app sh -c "whoami | grep -q root" || { echo "Criterion 5 FAIL"; exit 1; }

# 6. Run automated tests
bash ../.claude/skills/docker-claude-code/scripts/test-docker.sh || { echo "Criterion 6 FAIL"; exit 1; }

echo "ALL CRITERIA PASS - environment ready for use"
```

**No exceptions:**
- ❌ DO NOT skip verification steps
- ❌ DO NOT use environment that fails any criterion
- ❌ DO NOT assume "probably works" - verify

## Real-World Impact

Using this TDD approach with docker-claude-code skill:
- ✅ 100% compliance with acceptance criteria
- ✅ Zero permission conflicts between host and container
- ✅ Latest Claude Code CLI verified with claude doctor
- ✅ Statusline plugin always correctly registered
- ✅ Multi-user access working as designed
- ✅ All automated tests passing
- ✅ Complete isolation from host system
- ✅ Repeatable setup process

**Before this skill**: Common issues - wrong directory structure, outdated CLI, missing plugin, permission conflicts, failed tests.
**After this skill**: Every deployment meets all criteria exactly, verified by automated tests.
