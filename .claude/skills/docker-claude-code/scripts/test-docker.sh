#!/bin/bash
# Test Script for Docker Claude Code - Validates All Acceptance Criteria (Sync Mode)

set -e

# Save current directory
ORIGINAL_DIR="$(pwd)"

# Change to Docker directory for all docker-compose commands
cd Docker 2>/dev/null || {
    echo "ERROR: Docker/ directory not found"
    echo "Please run this script from the project root"
    exit 1
}

# Restore directory on exit
trap "cd \"$ORIGINAL_DIR\"" EXIT

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Docker Claude Code - Acceptance Tests${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

PASS=0
FAIL=0
EXIT_CODE=0

# Platform detection for $DOCKER_COMPOSE command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif $DOCKER_COMPOSE version &> /dev/null; then
    DOCKER_COMPOSE="$DOCKER_COMPOSE"
else
    echo -e "${RED}Error: Neither 'docker compose' nor '$DOCKER_COMPOSE' is available${NC}"
    exit 1
fi

# Criterion 1: Directory Structure
echo "=== Criterion 1: Directory Structure ==="

# Verify Docker/ directory exists
test -d Docker && echo "PASS" || echo "FAIL"

# Verify necessary script files exist
test -f Docker/.claude/skills/docker-claude-code/scripts/init-docker-project.sh && echo "PASS" || echo "FAIL"
test -f Docker/.claude/skills/docker-claude-code/scripts/backup-project.sh && echo "PASS" || echo "FAIL"
test -f Docker/.claude/skills/docker-claude-code/scripts/diagnose-docker.sh && echo "PASS" || echo "FAIL"
test -f Docker/.claude/skills/docker-claude-code/scripts/test-docker.sh && echo "PASS" || echo "FAIL"

# Verify plugin directory exists
test -d Docker/.claude/skills/docker-claude-code/claude-code-statusline-plugin && echo "PASS" || echo "FAIL"

# Verify Docker/workspace/.claude directory exists
test -d Docker/workspace/.claude && echo "PASS" || echo "FAIL"

# Verify config files generated (in Docker/ directory)
test -f Docker/.env && echo "PASS" || echo "FAIL"
test -f Docker/docker-compose.yml && echo "PASS" || echo "FAIL"
test -f Docker/Dockerfile && echo "PASS" || echo "FAIL"
echo ""

# Criterion 2: Persistent Container
echo "=== Criterion 2: Persistent Container ==="

$DOCKER_COMPOSE up -d > /dev/null 2>&1
$DOCKER_COMPOSE exec app sh -c "echo 'container-access-ok'" && echo "PASS" || echo "FAIL"
$DOCKER_COMPOSE exec app sh -c "test -d /workspace/project && echo 'PASS' || echo 'FAIL'"
$DOCKER_COMPOSE exec app sh -c "test -d /workspace/.claude && echo 'PASS' || echo 'FAIL'"
echo ""

# Test 1: Container status
echo -e "${BLUE}Test 1: Checking container status...${NC}"
if docker ps --format '{{.Names}}' | grep -q "docker-claude-code-app"; then
    echo -e "${GREEN}[✓] PASS: Container is running${NC}"
    PASS=$((PASS + 1))
else
    echo -e "${RED}[✗] FAIL: Container is not running${NC}"
    FAIL=$((FAIL + 1))
fi
echo ""

# Test 2: Container access
echo -e "${BLUE}Test 2: Testing container access...${NC}"
if $DOCKER_COMPOSE exec app sh -c "echo 'container-access-ok'" >/dev/null 2>&1; then
    echo -e "${GREEN}[✓] PASS: Can access container${NC}"
    PASS=$((PASS + 1))
else
    echo -e "${RED}[✗] FAIL: Cannot access container${NC}"
    FAIL=$((FAIL + 1))
fi
echo ""

# Test 3: Claude CLI version
echo -e "${BLUE}Test 3: Checking Claude CLI...${NC}"
VERSION=$($DOCKER_COMPOSE exec app claude --version 2>/dev/null || echo "not found")
if [ "$VERSION" != "not found" ]; then
    echo -e "${GREEN}[✓] PASS: Claude CLI is installed - $VERSION${NC}"
    PASS=$((PASS + 1))
else
    echo -e "${RED}[✗] FAIL: Claude CLI is not installed${NC}"
    FAIL=$((FAIL + 1))
fi
echo ""

# File Synchronization Test
echo -e "${BLUE}Test 4: File Synchronization...${NC}"
SYNC_FAIL=0

# Test host to container file sync
cd "$ORIGINAL_DIR"  # Go back to project root
echo "sync-test-$(date +%s)" > test-sync.txt
sleep 2
cd Docker  # Return to Docker directory

if $DOCKER_COMPOSE exec app sh -c "test -f /workspace/project/test-sync.txt" >/dev/null 2>&1; then
    echo -e "${GREEN}[✓] PASS: Host to container sync working${NC}"
    PASS=$((PASS + 1))
else
    echo -e "${RED}[✗] FAIL: Host to container sync not working${NC}"
    FAIL=$((FAIL + 1))
    SYNC_FAIL=1
fi

# Test container to host file sync
$DOCKER_COMPOSE exec app sh -c "echo 'container-test-$(date +%s)' > /workspace/project/container-test.txt" 2>/dev/null
sleep 2
cd "$ORIGINAL_DIR"
if [ -f container-test.txt ]; then
    echo -e "${GREEN}[✓] PASS: Container to host sync working${NC}"
    PASS=$((PASS + 1))
    rm -f container-test.txt
else
    echo -e "${RED}[✗] FAIL: Container to host sync not working${NC}"
    FAIL=$((FAIL + 1))
    SYNC_FAIL=1
fi

# Cleanup test files
cd "$ORIGINAL_DIR"
rm -f test-sync.txt container-test.txt 2>/dev/null || true
cd Docker
echo ""

# Environment Variables Validation
echo -e "${BLUE}Test 5: Environment Variables Validation...${NC}"
ENV_PASS=0
ENV_FAIL=0

if grep -q "ANTHROPIC_API_KEY=dummy" .env 2>/dev/null; then
    echo -e "${GREEN}[✓] PASS: ANTHROPIC_API_KEY is dummy (correct)${NC}"
    ENV_PASS=$((ENV_PASS + 1))
else
    echo -e "${YELLOW}[!] WARN: ANTHROPIC_API_KEY may not be dummy${NC}"
    ENV_FAIL=$((ENV_FAIL + 1))
fi

if grep -q "ANTHROPIC_BASE_URL=http://host.docker.internal:15721" .env 2>/dev/null; then
    echo -e "${GREEN}[✓] PASS: ANTHROPIC_BASE_URL is correct${NC}"
    ENV_PASS=$((ENV_PASS + 1))
else
    echo -e "${YELLOW}[!] WARN: ANTHROPIC_BASE_URL may not be default value${NC}"
    ENV_FAIL=$((ENV_FAIL + 1))
fi

if grep -q "WORKSPACE_PATH\|CLAUDE_CONFIG_PATH\|CLAUDE_HOME_PATH" .env 2>/dev/null; then
    echo -e "${YELLOW}[!] WARN: .env contains legacy path variables (should be removed)${NC}"
    ENV_FAIL=$((ENV_FAIL + 1))
else
    echo -e "${GREEN}[✓] PASS: No legacy path variables in .env${NC}"
    ENV_PASS=$((ENV_PASS + 1))
fi

if [ $ENV_PASS -gt 0 ]; then
    PASS=$((PASS + 1))
else
    FAIL=$((FAIL + 1))
fi
echo ""

# Volume Mounts Validation
echo -e "${BLUE}Test 6: Volume Mounts Validation...${NC}"
VOLUME_PASS=0

# Ensure container is running
$DOCKER_COMPOSE up -d > /dev/null 2>&1

# Check project root mount
PROJECT_MOUNT=$(docker inspect docker-claude-code-app 2>/dev/null | jq -r '.[0].Mounts[] | select(.Destination=="/workspace/project") | .Source' 2>/dev/null)
if [ -n "$PROJECT_MOUNT" ]; then
    echo -e "${GREEN}[✓] PASS: Project mounted: $PROJECT_MOUNT → /workspace/project${NC}"
    VOLUME_PASS=$((VOLUME_PASS + 1))
else
    echo -e "${RED}[✗] FAIL: Project mount not found${NC}"
    EXIT_CODE=1
fi

# Check Claude config mount
CLAUDE_MOUNT=$(docker inspect docker-claude-code-app 2>/dev/null | jq -r '.[0].Mounts[] | select(.Destination=="/workspace/.claude") | .Source' 2>/dev/null)
if [ -n "$CLAUDE_MOUNT" ]; then
    echo -e "${GREEN}[✓] PASS: Claude config mounted: $CLAUDE_MOUNT → /workspace/.claude${NC}"
    VOLUME_PASS=$((VOLUME_PASS + 1))
else
    echo -e "${RED}[✗] FAIL: Claude config mount not found${NC}"
    EXIT_CODE=1
fi

if [ $VOLUME_PASS -gt 0 ]; then
    PASS=$((PASS + 1))
else
    FAIL=$((FAIL + 1))
fi
echo ""

# Test 7: Statusline plugin
echo -e "${BLUE}Test 7: Checking statusline plugin...${NC}"
if $DOCKER_COMPOSE exec app sh -c 'python3 -c "import json; print(json.load(open(\"~/.claude/settings.json\")).get(\"statusLine\", {}) != {})"' >/dev/null 2>&1; then
    echo -e "${GREEN}[✓] PASS: Statusline plugin is registered${NC}"
    PASS=$((PASS + 1))
else
    echo -e "${RED}[✗] FAIL: Statusline plugin is not registered${NC}"
    FAIL=$((FAIL + 1))
fi
echo ""

# Test 8: Configuration persistence
echo -e "${BLUE}Test 8: Testing configuration persistence...${NC}"
$DOCKER_COMPOSE exec app sh -c "echo 'config-test' > ~/.claude/test-config.conf" 2>/dev/null
$DOCKER_COMPOSE restart >/dev/null 2>&1
sleep 3
RESULT=$($DOCKER_COMPOSE exec app sh -c "cat ~/.claude/test-config.conf" 2>/dev/null)
if [ "$RESULT" = "config-test" ]; then
    echo -e "${GREEN}[✓] PASS: Configuration persistence is working${NC}"
    PASS=$((PASS + 1))
else
    echo -e "${RED}[✗] FAIL: Configuration persistence failed${NC}"
    FAIL=$((FAIL + 1))
fi
echo ""

# Summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Test Results Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Passed: $PASS"
echo -e "Failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}[✓] All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}[✗] $FAIL test(s) failed${NC}"
    exit 1
fi
