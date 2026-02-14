#!/bin/bash
# Test Script for Docker Claude Code - Validates All Acceptance Criteria

set -e

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

# Platform detection for $DOCKER_COMPOSE command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif $DOCKER_COMPOSE version &> /dev/null; then
    DOCKER_COMPOSE="$DOCKER_COMPOSE"
else
    echo -e "${RED}Error: Neither 'docker compose' nor '$DOCKER_COMPOSE' is available${NC}"
    exit 1
fi

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

# Test 4: Environment variables
echo -e "${BLUE}Test 4: Verifying environment variables...${NC}"
API_KEY=$($DOCKER_COMPOSE exec app sh -c 'echo $ANTHROPIC_API_KEY' 2>/dev/null)
BASE_URL=$($DOCKER_COMPOSE exec app sh -c 'echo $ANTHROPIC_BASE_URL' 2>/dev/null)

if [ "$API_KEY" = "dummy" ] && [ -n "$BASE_URL" ]; then
    echo -e "${GREEN}[✓] PASS: Environment variables configured correctly${NC}"
    echo -e "  API_KEY: $API_KEY"
    echo -e "  BASE_URL: $BASE_URL"
    PASS=$((PASS + 1))
else
    echo -e "${RED}[✗] FAIL: Environment variables configured incorrectly${NC}"
    FAIL=$((FAIL + 1))
fi
echo ""

# Test 5: Statusline plugin
echo -e "${BLUE}Test 5: Checking statusline plugin...${NC}"
if $DOCKER_COMPOSE exec app sh -c 'python3 -c "import json; print(json.load(open(\"~/.claude/settings.json\")).get(\"statusLine\", {}) != {})"' >/dev/null 2>&1; then
    echo -e "${GREEN}[✓] PASS: Statusline plugin is registered${NC}"
    PASS=$((PASS + 1))
else
    echo -e "${RED}[✗] FAIL: Statusline plugin is not registered${NC}"
    FAIL=$((FAIL + 1))
fi
echo ""

# Test 6: Configuration persistence
echo -e "${BLUE}Test 6: Testing configuration persistence...${NC}"
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
