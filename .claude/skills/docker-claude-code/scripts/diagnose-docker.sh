#!/bin/bash
# Diagnostic Script for Docker Claude Code
# Diagnoses Docker environment issues following troubleshooting decision tree

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Mode variable
MODE=""

# Detect Docker mode
detect_docker_mode() {
    echo -e "${BLUE}Detecting Docker mode...${NC}"

    if [ -d "Docker" ]; then
        MODE="Sync"
        echo -e "${GREEN}✓ Mode: Sync Mode (Docker/ directory detected)${NC}"
        return 0
    elif [ -d "workspace" ] && [ -d "dev-home" ]; then
        MODE="Isolation"
        echo -e "${YELLOW}⚠ Mode: Isolation Mode (legacy)${NC}"
        echo -e "${YELLOW}  Consider migrating to Sync Mode for better experience${NC}"
        return 0
    else
        MODE="Unknown"
        echo -e "${RED}✗ Mode: Unknown or not initialized${NC}"
        return 1
    fi
}

# Dependency Check Function
check_dependencies() {
    local missing_deps=()

    # Check for required commands
    local deps=("docker" "uname" "grep")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    # Check for $DOCKER_COMPOSE or docker compose
    if docker compose version &> /dev/null; then
        DOCKER_COMPOSE="docker compose"
    elif $DOCKER_COMPOSE version &> /dev/null; then
        DOCKER_COMPOSE="$DOCKER_COMPOSE"
    else
        missing_deps+=("$DOCKER_COMPOSE")
    fi

    # Check for nc (optional on Windows)
    if ! command -v nc &> /dev/null; then
        if [ "$PLATFORM_ID" != "windows" ]; then
            missing_deps+=("nc")
        else
            echo -e "${YELLOW}[Warning] 'nc' command not found on Windows, skipping connectivity test${NC}"
        fi
    fi

    # Report missing dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}[Error] Missing required dependencies:${NC}"
        for dep in "${missing_deps[@]}"; do
            echo -e "${RED}  - $dep${NC}"
        done
        echo -e "${YELLOW}Please install missing dependencies and try again.${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ All dependencies are installed${NC}"
}

# Check dependencies before main logic
check_dependencies
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Docker Claude Code - Diagnostics${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Detect current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR" || exit 1

echo -e "${BLUE}Working Directory:${NC} $PROJECT_DIR"
echo ""

# Detect Docker mode
detect_docker_mode
echo ""

# Decision Tree: Container not working?
echo -e "${CYAN}Diagnostic Decision Tree:${NC}"
echo "Container not working?"
echo "├─→ API connection fails? → Check ANTHROPIC_BASE_URL"
echo "├─→ Permission denied? → Check sudo NOPASSWD:ALL setup"
echo "├─→ Can't find host? → Verify platform-specific config"
echo "└─→ Config not persisting? → Check volume mounts"
echo ""

# Detect platform
OS_TYPE=$(uname -s)
case "$OS_TYPE" in
    Darwin)
        PLATFORM_ID="macos"
        PLATFORM_NAME="macOS"
        ;;
    Linux)
        PLATFORM_ID="linux"
        PLATFORM_NAME="Linux"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        PLATFORM_ID="windows"
        PLATFORM_NAME="Windows"
        ;;
    *)
        PLATFORM_ID="unknown"
        PLATFORM_NAME="Unknown"
        ;;
esac

echo -e "${CYAN}Platform:${NC} $PLATFORM_NAME"
echo ""

# Check 1: Docker daemon is running
echo -e "${BLUE}Check 1: Docker Daemon Status${NC}"
if docker info >/dev/null 2>&1; then
    echo -e "${GREEN}[✓]${NC} Docker daemon is running"
else
    echo -e "${RED}[✗]${NC} Docker daemon is NOT running"
    echo -e "${YELLOW}Fix:${NC} Start Docker Desktop or Docker Engine"
    echo ""
    exit 1
fi
echo ""

# Check 2: Container status
echo -e "${BLUE}Check 2: Container Status${NC}"
CONTAINER_NAME="docker-claude-code-app"

# Change to Docker directory for Sync Mode
if [ "$MODE" = "Sync" ]; then
    cd Docker 2>/dev/null || {
        echo -e "${RED}✗ Cannot access Docker/ directory${NC}"
        exit 1
    }
fi

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${GREEN}[✓]${NC} Container '$CONTAINER_NAME' is running"
    RUNNING=true
elif docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${YELLOW}[!]${NC} Container exists but is STOPPED"
    echo -e "${YELLOW}Fix:${NC} $DOCKER_COMPOSE up -d"
    RUNNING=false
else
    echo -e "${RED}[✗]${NC} Container '$CONTAINER_NAME' does NOT exist"
    echo -e "${YELLOW}Fix:${NC} Run: $DOCKER_COMPOSE up -d"
    RUNNING=false
fi

# Return to project directory for Sync Mode
if [ "$MODE" = "Sync" ]; then
    cd ..
fi
echo ""

# Check 2.5: Environment variables file
echo -e "${BLUE}Check 2.5: Environment Variables File${NC}"

if [ "$MODE" = "Sync" ]; then
    ENV_FILE="Docker/.env"
elif [ "$MODE" = "Isolation" ]; then
    ENV_FILE=".env"
else
    ENV_FILE=""
fi

if [ -n "$ENV_FILE" ] && [ -f "$ENV_FILE" ]; then
    echo -e "${GREEN}[✓]${NC} .env file exists: $ENV_FILE"

    # Check required environment variables
    if grep -q "^ANTHROPIC_API_KEY=" "$ENV_FILE"; then
        echo -e "${GREEN}[✓]${NC} ANTHROPIC_API_KEY configured"
    else
        echo -e "${RED}[✗]${NC} ANTHROPIC_API_KEY not found"
    fi

    if grep -q "^ANTHROPIC_BASE_URL=" "$ENV_FILE"; then
        echo -e "${GREEN}[✓]${NC} ANTHROPIC_BASE_URL configured"
    else
        echo -e "${RED}[✗]${NC} ANTHROPIC_BASE_URL not found"
    fi

    # Check legacy optional path variables
    if grep -q "WORKSPACE_PATH\|CLAUDE_CONFIG_PATH\|CLAUDE_HOME_PATH" "$ENV_FILE" 2>/dev/null; then
        echo -e "${YELLOW}[!]${NC} Legacy path variables found (can be removed in Sync Mode)"
    fi
else
    echo -e "${RED}[✗]${NC} .env file not found"
    if [ -n "$ENV_FILE" ]; then
        echo -e "${YELLOW}Expected location:${NC} $ENV_FILE"
    fi
fi
echo ""

# Only continue checks if container is running
if [ "$RUNNING" = true ]; then
    # Check 3: Environment variables in container
    echo -e "${BLUE}Check 3: Environment Variables${NC}"

        API_KEY=$($DOCKER_COMPOSE exec -T app sh -c 'echo $ANTHROPIC_API_KEY' 2>/dev/null || echo "")
        BASE_URL=$($DOCKER_COMPOSE exec -T app sh -c 'echo $ANTHROPIC_BASE_URL' 2>/dev/null || echo "")

    if [ -n "$API_KEY" ]; then
        echo -e "${GREEN}[✓]${NC} ANTHROPIC_API_KEY is set"
    else
        echo -e "${RED}[✗]${NC} ANTHROPIC_API_KEY is NOT set"
        echo -e "${YELLOW}Fix:${NC} Check .env file and restart container"
    fi

    if [ -n "$BASE_URL" ]; then
        echo -e "${GREEN}[✓]${NC} ANTHROPIC_BASE_URL is set to: $BASE_URL"

        # Check if using host.docker.internal
        if echo "$BASE_URL" | grep -q "host.docker.internal"; then
            echo -e "${GREEN}[✓]${NC} Using host.docker.internal (correct)"

            # Platform-specific check for Linux
            if [ "$PLATFORM_ID" = "linux" ]; then
                echo -e "${YELLOW}[!]${NC} Linux platform detected"
                # Test if host.docker.internal resolves
                if $DOCKER_COMPOSE exec -T app nslookup host.docker.internal >/dev/null 2>&1; then
                    echo -e "${GREEN}[✓]${NC} host.docker.internal resolves correctly (extra_hosts working)"
                else
                    echo -e "${RED}[✗]${NC} host.docker.internal does NOT resolve"
                    echo -e "${YELLOW}Fix:${NC} Add to $DOCKER_COMPOSE.yml:"
                    echo "  extra_hosts:"
                    echo "    - \"host.docker.internal:host-gateway\""
                fi
            fi
        elif echo "$BASE_URL" | grep -q "localhost:15721"; then
            echo -e "${RED}[✗]${NC} Using localhost (won't work from container)"
            echo -e "${YELLOW}Fix:${NC} Change to host.docker.internal in .env"
        fi
    else
        echo -e "${RED}[✗]${NC} ANTHROPIC_BASE_URL is NOT set"
        echo -e "${YELLOW}Fix:${NC} Check .env file and restart container"
    fi
    echo ""

    # Check 4: API connectivity test
    echo -e "${BLUE}Check 4: API Proxy Connectivity${NC}"

    # Extract host and port from BASE_URL
    if echo "$BASE_URL" | grep -q "http://"; then
        PROXY_HOST=$(echo "$BASE_URL" | sed 's|http://||' | sed 's|:.*||')
        PROXY_PORT=$(echo "$BASE_URL" | sed 's|.*:||')

        echo -e "Testing connection to: ${CYAN}$PROXY_HOST:$PROXY_PORT${NC}"

        # Test from within container (skip if nc not available)
        if command -v nc &> /dev/null; then
            if $DOCKER_COMPOSE exec -T app sh -c "nc -z -w5 $PROXY_HOST $PROXY_PORT" 2>/dev/null; then
                echo -e "${GREEN}[✓]${NC} API proxy is reachable from container"
            else
                echo -e "${RED}[✗]${NC} API proxy is NOT reachable"
                echo -e "${YELLOW}Possible causes:${NC}"
                echo "1. CC Switch is not running on host"
                echo "2. Wrong port configured (default: 15721)"
                echo "3. Firewall blocking connection"
                echo ""
                echo -e "${YELLOW}Fix:${NC}"
                echo "- Ensure CC Switch is running on host machine"
                echo "- Verify port: $PROXY_PORT matches CC Switch configuration"
            fi
        else
            echo -e "${YELLOW}[!] nc command not available, skipping connectivity test${NC}"
            echo -e "${YELLOW}Manual test:${NC} $DOCKER_COMPOSE exec app sh -c 'curl -v http://$PROXY_HOST:$PROXY_PORT'"
        fi
    fi

    # Check 5: Volume mounts
    echo ""
    echo -e "${BLUE}Check 5: Volume Mounts${NC}"

    # Change to Docker directory for Sync Mode
    if [ "$MODE" = "Sync" ]; then
        cd Docker 2>/dev/null || {
            echo -e "${RED}✗ Cannot access Docker/ directory${NC}"
            return 1
        }

        echo -e "${CYAN}Sync Mode volume mounts:${NC}"

        # Start container if not running
        if [ "$RUNNING" != true ]; then
            $DOCKER_COMPOSE up -d > /dev/null 2>&1
            sleep 3
        fi

        # Check project root directory mount
        PROJECT_MOUNT=$(docker inspect docker-claude-code-app 2>/dev/null | jq -r '.[0].Mounts[] | select(.Destination=="/workspace/project") | .Source' 2>/dev/null)
        if [ -n "$PROJECT_MOUNT" ]; then
            echo -e "${GREEN}[✓]${NC} Project mounted: $PROJECT_MOUNT → /workspace/project"
        else
            echo -e "${RED}[✗]${NC} Project mount not found"
        fi

        # Check Claude config mount
        CLAUDE_MOUNT=$(docker inspect docker-claude-code-app 2>/dev/null | jq -r '.[0].Mounts[] | select(.Destination=="/workspace/.claude") | .Source' 2>/dev/null)
        if [ -n "$CLAUDE_MOUNT" ]; then
            echo -e "${GREEN}[✓]${NC} Claude config mounted: $CLAUDE_MOUNT → /workspace/.claude"
        else
            echo -e "${RED}[✗]${NC} Claude config mount not found"
        fi

        cd ..
    elif [ "$MODE" = "Isolation" ]; then
        echo -e "${CYAN}Isolation Mode volume mounts:${NC}"
        if docker inspect "$CONTAINER_NAME" --format '{{json .Mounts}}' | grep -q "workspace"; then
            echo -e "${GREEN}[✓]${NC} Workspace volume is mounted"
        else
            echo -e "${RED}[✗]${NC} Workspace volume is NOT mounted"
            echo -e "${YELLOW}Fix:${NC} Check volumes: section in $DOCKER_COMPOSE.yml"
        fi
    fi

    # Check 6: Permission test
    echo ""
    echo -e "${BLUE}Check 6: File Permissions${NC}"

    # Change to Docker directory for Sync Mode
    if [ "$MODE" = "Sync" ]; then
        cd Docker 2>/dev/null || {
            echo -e "${RED}✗ Cannot access Docker/ directory${NC}"
            return 1
        }

        # Start container if not running
        if [ "$RUNNING" != true ]; then
            $DOCKER_COMPOSE up -d > /dev/null 2>&1
            sleep 3
        fi

        # Check container user
        CONTAINER_USER=$($DOCKER_COMPOSE exec -T app sh -c "whoami" 2>/dev/null || echo "unknown")
        if [ "$CONTAINER_USER" = "claude" ]; then
            echo -e "${GREEN}[✓]${NC} Container user: claude"
        else
            echo -e "${YELLOW}[!]${NC} Container user: $CONTAINER_USER (expected: claude)"
        fi

        # Check sudo configuration
        if $DOCKER_COMPOSE exec -T app sh -c "sudo -n whoami" 2>/dev/null | grep -q root; then
            echo -e "${GREEN}[✓]${NC} sudo NOPASSWD:ALL configured"
        else
            echo -e "${RED}[✗]${NC} sudo NOPASSWD:ALL not configured"
        fi

        cd ..
    else
        # Isolation Mode - original check
        # Test write permission
        if $DOCKER_COMPOSE exec -T app sh -c 'touch /workspace/.test_write 2>/dev/null && rm /workspace/.test_write'; then
            echo -e "${GREEN}[✓]${NC} Write permissions are OK"
        else
            echo -e "${RED}[✗]${NC} Write permission DENIED"
            echo -e "${YELLOW}Diagnosing sudo setup...${NC}"

            # Test sudo access
            if $DOCKER_COMPOSE exec -T app sh -c 'sudo whoami' >/dev/null 2>&1; then
                echo -e "${GREEN}[✓]${NC} sudo is configured correctly"
                echo -e "${YELLOW}Fix:${NC}"
                echo "- Try using sudo for write operations"
                echo "- Example: $DOCKER_COMPOSE exec app sh -c 'sudo touch /workspace/test'"
            else
                echo -e "${RED}[✗]${NC} sudo NOT configured or requires password"
                echo -e "${YELLOW}Fix:${NC}"
                echo "- Dockerfile is missing sudo NOPASSWD:ALL configuration"
                echo "- Rebuild image with corrected Dockerfile:"
                echo "  1. Add to Dockerfile: RUN apk add --no-cache sudo"
                echo "  2. Add: echo 'claude ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers"
                echo "  3. Run: $DOCKER_COMPOSE build && $DOCKER_COMPOSE up -d"
            fi
        fi
    fi

    # Check 7: Claude CLI installation
    echo ""
    echo -e "${BLUE}Check 7: Claude CLI Installation${NC}"

    CLI_VERSION=$($DOCKER_COMPOSE exec -T app sh -c 'claude --version 2>/dev/null || echo "not installed"' 2>/dev/null || echo "not installed")

    if [ "$CLI_VERSION" != "not installed" ]; then
        echo -e "${GREEN}[✓]${NC} Claude CLI is installed: $CLI_VERSION"
    else
        echo -e "${RED}[✗]${NC} Claude CLI is NOT installed"
        echo -e "${YELLOW}Fix:${NC} Rebuild Docker image: $DOCKER_COMPOSE build"
    fi

    # Check 7.1: Claude CLI Version Verification (using claude doctor)
    echo ""
    echo -e "${BLUE}Check 7.1: Claude CLI Version Verification${NC}"
    echo -e "${CYAN}Running: claude doctor${NC}"

    # 使用 claude doctor 验证版本和配置
    DOCTOR_OUTPUT=$($DOCKER_COMPOSE exec -T app sh -c 'claude doctor 2>&1' || echo "doctor failed")

    if echo "$DOCTOR_OUTPUT" | grep -q "version"; then
        # 提取版本信息
        VERSION_INFO=$(echo "$DOCTOR_OUTPUT" | grep -i "version" | head -1)
        echo -e "${GREEN}[✓]${NC} Claude Code 版本已验证:"
        echo -e "  ${CYAN}$VERSION_INFO${NC}"

        # 检查是否有更新可用提示
        if echo "$DOCTOR_OUTPUT" | grep -qi "update available\|newer version\|outdated"; then
            echo -e "${YELLOW}[!]${NC} 发现新版本的 Claude Code"
            echo -e "${YELLOW}建议:${NC} 重新构建镜像: $DOCKER_COMPOSE up -d --build"
        fi
    else
        echo -e "${YELLOW}[!]${NC} 无法验证版本信息"
        echo -e "${YELLOW}注意:${NC} claude doctor 命令可能在此版本中不可用"
        echo -e "${CYAN}当前安装的版本:${NC} $CLI_VERSION"
    fi

    echo ""
else
    echo -e "${YELLOW}Skipping container checks - container is not running${NC}"
fi

# Test file synchronization (Sync Mode only)
if [ "$MODE" = "Sync" ] && [ "$RUNNING" = true ]; then
    echo ""
    echo -e "${BLUE}Check 7.5: File Synchronization Test${NC}"

    cd Docker 2>/dev/null || {
        echo -e "${RED}✗ Cannot access Docker/ directory${NC}"
    }

    # Test host to container sync
    echo "sync-test-$(date +%s)" > test-sync.txt 2>/dev/null || {
        echo -e "${YELLOW}[!]${NC} Cannot create test file in project directory"
        cd ..
    }

    sleep 2

    if $DOCKER_COMPOSE exec -T app sh -c "test -f /workspace/project/test-sync.txt" 2>/dev/null; then
        echo -e "${GREEN}[✓]${NC} Host → Container sync working"
        rm -f test-sync.txt
    else
        echo -e "${RED}[✗]${NC} Host → Container sync failed"
        rm -f test-sync.txt
    fi

    # Test container to host sync
    $DOCKER_COMPOSE exec -T app sh -c "echo 'container-test-$(date +%s)' > /workspace/project/container-test.txt" 2>/dev/null
    sleep 2

    if [ -f container-test.txt ]; then
        echo -e "${GREEN}[✓]${NC} Container → Host sync working"
        rm -f container-test.txt
    else
        echo -e "${RED}[✗]${NC} Container → Host sync failed"
        rm -f container-test.txt 2>/dev/null
    fi

    cd ..
    echo ""
fi

# Check 8: Image build issues (even if container not running)
echo ""
echo -e "${BLUE}Check 8: Docker Image Build Status${NC}"

if docker images | grep -q "docker-claude-code-app"; then
    echo -e "${GREEN}[✓]${NC} Docker image exists"

    # Check image size
    IMAGE_SIZE=$(docker images docker-claude-code-app --format '{{.Size}}' 2>/dev/null)
    if [ -n "$IMAGE_SIZE" ]; then
        echo -e "${CYAN}Image size:${NC} $IMAGE_SIZE"
    fi

    # Check image creation time
    IMAGE_AGE=$(docker images docker-claude-code-app --format '{{.CreatedSince}}' 2>/dev/null)
    if [ -n "$IMAGE_AGE" ]; then
        echo -e "${CYAN}Image age:${NC} $IMAGE_AGE"

        # Warn if image is very old (> 30 days)
        if echo "$IMAGE_AGE" | grep -q "[0-9]\+ days ago"; then
            days=$(echo "$IMAGE_AGE" | grep -o "[0-9]\+ days ago" | grep -o "[0-9]\+")
            if [ "$days" -gt 30 ]; then
                echo -e "${YELLOW}[!] Image is $days days old, consider rebuilding${NC}"
            fi
        fi
    fi
else
    echo -e "${RED}[✗]${NC} Docker image does NOT exist"
    echo -e "${YELLOW}Fix:${NC} Build the image:"
    echo "  cd $PROJECT_DIR"
    echo "  $DOCKER_COMPOSE build"
    echo ""
    echo -e "${CYAN}Common build failures:${NC}"
    echo "  - ${YELLOW}Network timeout:${NC} Cannot reach Docker Hub"
    echo "    ${CYAN}Test:${NC} ping -c 2 hub.docker.com"
    echo "    ${CYAN}Fix:${NC} Check internet connection or use mirror"
    echo ""
    echo "  ${YELLOW}Base image not found:${NC} node:20-slim unavailable"
    echo "    ${CYAN}Test:${NC} docker pull node:20-slim"
    echo "    ${CYAN}Fix:${NC} Pull base image first: docker pull node:20-slim"
    echo ""
    echo "  ${YELLOW}Build context errors:${NC} Missing files or wrong paths"
    echo "    ${CYAN}Test:${NC} ls -la Dockerfile $DOCKER_COMPOSE.yml"
    echo "    ${CYAN}Fix:${NC} Ensure all required files exist"
fi

# Check 9: Container startup issues
echo ""
echo -e "${BLUE}Check 9: Container Startup History${NC}"

if [ "$RUNNING" = false ]; then
    # Check recent container exits
    EXITED_CONTAINER=$(docker ps -a --filter "name=docker-claude-code-app" --format "{{.Status}}" | head -1)

    if [ -n "$EXITED_CONTAINER" ]; then
        echo -e "${YELLOW}[!] Container exited with status:${NC} $EXITED_CONTAINER"
        echo -e "${CYAN}Recent container logs (last 20 lines):${NC}"
        docker logs docker-claude-code-app 2>&1 | tail -20

        echo ""
        echo -e "${CYAN}Common startup failures:${NC}"

        # Check for specific error patterns in logs
        FULL_LOGS=$(docker logs docker-claude-code-app 2>&1)

        if echo "$FULL_LOGS" | grep -qi "permission denied"; then
            echo -e "  ${YELLOW}Permission denied:${NC} Volume mount permissions issue"
            echo "    ${CYAN}Fix:${NC} sudo chown -R $USER:$USER ./dev-home"
        fi

        if echo "$FULL_LOGS" | grep -qi "cannot connect"; then
            echo -e "  ${YELLOW}Connection failed:${NC} API proxy or network issue"
            echo "    ${CYAN}Fix:${NC} Check ANTHROPIC_BASE_URL and CC Switch"
        fi

        if echo "$FULL_LOGS" | grep -qi "cannot find.*claude"; then
            echo -e "  ${YELLOW}Claude CLI not found:${NC} Image build incomplete"
            echo "    ${CYAN}Fix:${NC} Rebuild image: $DOCKER_COMPOSE build --no-cache"
        fi
    else
        echo -e "${YELLOW}[!] Container never created${NC}"
        echo -e "${YELLOW}Fix:${NC} Run: $DOCKER_COMPOSE up -d"
    fi
elif [ -z "$RUNNING" ]; then
    echo -e "${YELLOW}[!] Container does not exist${NC}"
    echo -e "${YELLOW}Fix:${NC} Run: $DOCKER_COMPOSE up -d"
fi

# Check 10: System resource limits
echo ""
echo -e "${BLUE}Check 10: System Resources${NC}"

# Check disk space
DISK_AVAILABLE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$DISK_AVAILABLE" -lt 5 ]; then
    echo -e "${RED}[✗]${NC} Low disk space: ${DISK_AVAILABLE}GB available"
    echo -e "${YELLOW}Impact:${NC} May cause build failures or container crashes"
    echo -e "${YELLOW}Fix:${NC} Clean up Docker resources:"
    echo "  docker system prune -a"
    echo "  docker volume prune"
else
    echo -e "${GREEN}[✓]${NC} Sufficient disk space: ${DISK_AVAILABLE}GB available"
fi

# Check Docker memory limits (if Docker Desktop is being used)
if command -v docker &> /dev/null; then
    # Check if Docker Desktop is running and get its memory limit
    if docker info 2>/dev/null | grep -q " operating system"; then
        echo -e "${CYAN}Docker Desktop detected${NC}"

        # Try to get memory limit (may not work on all platforms)
        if docker info 2>/dev/null | grep -q "Memory"; then
            echo -e "${CYAN}Check Docker Desktop settings → Resources → Memory${NC}"
        fi
    fi
fi

# Check if container has resource limits
if [ "$RUNNING" = true ]; then
    # Check container memory limit
    CONTAINER_MEMORY=$(docker inspect "$CONTAINER_NAME" --format '{{.HostConfig.Memory}}' 2>/dev/null || echo "0")

    if [ "$CONTAINER_MEMORY" != "0" ] && [ -n "$CONTAINER_MEMORY" ]; then
        MEMORY_MB=$((CONTAINER_MEMORY / 1024 / 1024))
        echo -e "${CYAN}Container memory limit:${NC} ${MEMORY_MB}MB"

        if [ "$MEMORY_MB" -lt 1024 ]; then
            echo -e "${YELLOW}[!] Memory limit is low (< 1GB)${NC}"
            echo -e "${YELLOW}Impact:${NC} May cause OOM errors during builds"
            echo -e "${CYAN}Recommendation:${NC} Increase to at least 2GB in $DOCKER_COMPOSE.yml:"
            echo "  deploy:"
            echo "    resources:"
            echo "      limits:"
            echo "        memory: 2048M"
        fi
    else
        echo -e "${GREEN}[✓]${NC} No memory limit set (uses host memory)"
    fi
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Diagnostic Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Mode-specific recommendations
echo -e "${CYAN}=== Mode-Specific Recommendations ===${NC}"

if [ "$MODE" = "Isolation" ]; then
    echo -e "${YELLOW}[!]${NC} You are using Isolation Mode (legacy)"
    echo -e "${BLUE}  → Consider migrating to Sync Mode for better experience${NC}"
    echo -e "${BLUE}  → Run: bash .claude/skills/docker-claude-code/scripts/migrate-to-sync-mode.sh${NC}"
fi

if [ "$MODE" = "Sync" ] && [ ! -d "Docker/workspace/.claude" ]; then
    echo -e "${YELLOW}[!]${NC} Docker/workspace/.claude directory not found"
    echo -e "${BLUE}  → Run init script: bash .claude/skills/docker-claude-code/scripts/init-docker-project.sh${NC}"
fi

if [ "$MODE" = "Unknown" ]; then
    echo -e "${RED}[!]${NC} Docker environment not initialized"
    echo -e "${BLUE}  → Run: bash .claude/skills/docker-claude-code/scripts/init-docker-project.sh${NC}"
fi

echo ""
echo ""

# Common quick fixes
echo -e "${CYAN}Common Quick Fixes:${NC}"
echo ""

# Add directory prefix for Sync Mode
COMPOSE_PREFIX=""
if [ "$MODE" = "Sync" ]; then
    COMPOSE_PREFIX="cd Docker && "
fi

echo "1. ${YELLOW}Restart container:${NC}"
echo "   ${COMPOSE_PREFIX}$DOCKER_COMPOSE restart"
echo ""
echo "2. ${YELLOW}Rebuild image:${NC}"
echo "   ${COMPOSE_PREFIX}$DOCKER_COMPOSE build"
echo "   ${COMPOSE_PREFIX}$DOCKER_COMPOSE up -d"
echo ""
echo "3. ${YELLOW}View logs:${NC}"
echo "   ${COMPOSE_PREFIX}$DOCKER_COMPOSE logs -f"
echo ""
echo "4. ${YELLOW}Test sudo configuration (non-root user):${NC}"
echo "   ${COMPOSE_PREFIX}$DOCKER_COMPOSE exec app sh -c 'sudo whoami'"
echo "   # Should return 'root' without password prompt"
echo ""
echo "5. ${YELLOW}Enter container as non-root (PRIMARY):${NC}"
echo "   ${COMPOSE_PREFIX}$DOCKER_COMPOSE exec app sh"
echo ""
echo "6. ${YELLOW}Enter container as root (EMERGENCY ONLY):${NC}"
echo "   ${COMPOSE_PREFIX}$DOCKER_COMPOSE exec -u root app sh"
echo ""
