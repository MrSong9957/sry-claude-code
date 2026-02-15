#!/bin/bash
# Configuration Validation Script for Docker Claude Code
# Validates Docker configuration files and platform compatibility

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
CHECKS=0

# Dependency Check Function
check_dependencies() {
    local missing_deps=()

    # Check for required commands
    local deps=("uname" "grep")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

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
echo -e "${GREEN}Docker Claude Code - Config Validator${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Function to print check result
print_result() {
    CHECKS=$((CHECKS + 1))
    local status=$1
    local message=$2

    if [ "$status" = "OK" ]; then
        echo -e "${GREEN}[✓]${NC} $message"
    elif [ "$status" = "WARN" ]; then
        echo -e "${YELLOW}[!]${NC} $message"
        WARNINGS=$((WARNINGS + 1))
    elif [ "$status" = "ERROR" ]; then
        echo -e "${RED}[✗]${NC} $message"
        ERRORS=$((ERRORS + 1))
    fi
}

# Detect current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}Scanning configuration files in:${NC}"
echo "$PROJECT_DIR"
echo ""

# Detect Docker mode (Sync vs Isolation)
if [ -d "$PROJECT_DIR/Docker" ]; then
    DOCKER_MODE="sync"
    print_result "OK" "Sync Mode detected (Docker/ directory exists)"
elif [ -d "$PROJECT_DIR/workspace" ] && [ -d "$PROJECT_DIR/dev-home" ]; then
    DOCKER_MODE="isolation"
    print_result "WARN" "Isolation Mode detected (legacy mode)"
    print_result "WARN" "Consider migrating to Sync Mode for better experience"
else
    DOCKER_MODE="unknown"
    print_result "ERROR" "Unknown Docker mode or not initialized"
fi

echo ""
echo -e "${BLUE}Docker Configuration Checks:${NC}"
echo ""

# Check 1: Docker/ directory exists (for Sync Mode)
if [ "$DOCKER_MODE" = "sync" ]; then
    if [ -d "$PROJECT_DIR/Docker" ]; then
        print_result "OK" "Docker/ directory exists (Sync Mode)"
    else
        print_result "ERROR" "Docker/ directory not found"
    fi

    # Check 2: .env file exists in Docker/
    if [ -f "$PROJECT_DIR/Docker/.env" ]; then
        print_result "OK" ".env file exists in Docker/ directory"
    else
        print_result "ERROR" ".env file not found in Docker/ directory"
    fi

    # Check 3: docker-compose.yml exists in Docker/
    if [ -f "$PROJECT_DIR/Docker/docker-compose.yml" ]; then
        print_result "OK" "docker-compose.yml exists in Docker/ directory"
    elif [ -f "$PROJECT_DIR/Docker/docker-compose.yaml" ]; then
        print_result "WARN" "docker-compose.yaml found in Docker/ (should be .yml for consistency)"
    else
        print_result "ERROR" "docker-compose.yml not found in Docker/ directory"
    fi

    # Check 4: Dockerfile exists in Docker/
    if [ -f "$PROJECT_DIR/Docker/Dockerfile" ]; then
        print_result "OK" "Dockerfile exists in Docker/ directory"
    else
        print_result "ERROR" "Dockerfile not found in Docker/ directory"
    fi

    # Check 5: workspace/.claude directory exists
    if [ -d "$PROJECT_DIR/Docker/workspace/.claude" ]; then
        print_result "OK" "Docker/workspace/.claude directory exists"
    else
        print_result "WARN" "Docker/workspace/.claude directory not found (will be created on init)"
    fi
else
    # Legacy Isolation Mode checks
    if [ -f "$PROJECT_DIR/.env" ]; then
        print_result "OK" ".env file exists (legacy mode)"
    else
        print_result "ERROR" ".env file not found"
    fi

    if [ -f "$PROJECT_DIR/docker-compose.yml" ]; then
        print_result "OK" "docker-compose.yml exists (legacy mode)"
    elif [ -f "$PROJECT_DIR/docker-compose.yaml" ]; then
        print_result "WARN" "docker-compose.yaml found (should be .yml for consistency)"
    else
        print_result "ERROR" "docker-compose.yml not found"
    fi

    if [ -f "$PROJECT_DIR/Dockerfile" ]; then
        print_result "OK" "Dockerfile exists (legacy mode)"
    else
        print_result "ERROR" "Dockerfile not found"
    fi
fi

echo ""
echo -e "${BLUE}Platform Compatibility Checks:${NC}"
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

print_result "OK" "Platform detected: $PLATFORM_NAME"

# Check 4: Validate .env content if exists
if [ "$DOCKER_MODE" = "sync" ]; then
    ENV_FILE="$PROJECT_DIR/Docker/.env"
elif [ "$DOCKER_MODE" = "isolation" ]; then
    ENV_FILE="$PROJECT_DIR/.env"
fi

if [ -f "$ENV_FILE" ]; then
    echo ""
    echo -e "${BLUE}Environment Variable Checks:${NC}"

    # Check for ANTHROPIC_API_KEY
    if grep -q "^ANTHROPIC_API_KEY=" "$ENV_FILE" 2>/dev/null; then
        print_result "OK" "ANTHROPIC_API_KEY is set"
    else
        print_result "ERROR" "ANTHROPIC_API_KEY not found in .env"
    fi

    # Check for ANTHROPIC_BASE_URL
    if grep -q "^ANTHROPIC_BASE_URL=" "$ENV_FILE" 2>/dev/null; then
        print_result "OK" "ANTHROPIC_BASE_URL is set"

        # Check if using host.docker.internal
        if grep -q "host.docker.internal" "$ENV_FILE" 2>/dev/null; then
            if [ "$PLATFORM_ID" = "linux" ]; then
                # Linux needs extra_hosts for host.docker.internal
                COMPOSE_FILE=""
                if [ "$DOCKER_MODE" = "sync" ]; then
                    COMPOSE_FILE="$PROJECT_DIR/Docker/docker-compose.yml"
                elif [ "$DOCKER_MODE" = "isolation" ]; then
                    COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
                fi

                if [ -f "$COMPOSE_FILE" ] && grep -q "extra_hosts" "$COMPOSE_FILE" 2>/dev/null; then
                    print_result "OK" "Linux with extra_hosts configured"
                else
                    print_result "ERROR" "Linux platform needs extra_hosts in docker-compose.yml"
                fi
            else
                print_result "OK" "Using host.docker.internal (correct for $PLATFORM_NAME)"
            fi
        elif grep -q "localhost:15721" "$ENV_FILE" 2>/dev/null; then
            print_result "ERROR" "Using localhost (won't work from container)"
        fi
    else
        print_result "ERROR" "ANTHROPIC_BASE_URL not found in .env"
    fi

    # Check for legacy path variables (Sync Mode only)
    if [ "$DOCKER_MODE" = "sync" ]; then
        if grep -q "WORKSPACE_PATH\|CLAUDE_CONFIG_PATH\|CLAUDE_HOME_PATH" "$ENV_FILE" 2>/dev/null; then
            print_result "WARN" ".env contains legacy path variables (optional, can be removed)"
        fi
    fi
fi

# Check 5: Validate docker-compose.yml if exists
if [ "$DOCKER_MODE" = "sync" ]; then
    COMPOSE_FILE="$PROJECT_DIR/Docker/docker-compose.yml"
elif [ "$DOCKER_MODE" = "isolation" ]; then
    COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
fi

if [ -f "$COMPOSE_FILE" ]; then
    echo ""
    echo -e "${BLUE}Docker Compose Configuration Checks:${NC}"

    # Check for stdin_open and tty
    if grep -q "stdin_open: true" "$COMPOSE_FILE" 2>/dev/null; then
        print_result "OK" "stdin_open: true (required for interactive CLI)"
    else
        print_result "ERROR" "Missing stdin_open: true"
    fi

    if grep -q "tty: true" "$COMPOSE_FILE" 2>/dev/null; then
        print_result "OK" "tty: true (required for interactive CLI)"
    else
        print_result "ERROR" "Missing tty: true"
    fi

    # Sync Mode specific checks
    if [ "$DOCKER_MODE" = "sync" ]; then
        # Check container name
        if grep -q "container_name: docker-claude-code-app" "$COMPOSE_FILE"; then
            print_result "OK" "Container name is docker-claude-code-app"
        else
            print_result "WARN" "Container name may not be docker-claude-code-app"
        fi

        # Check for project root mount (Sync Mode)
        if grep -q "\.\./workspace/project" "$COMPOSE_FILE" || grep -q "\.\.:\/workspace\/project" "$COMPOSE_FILE" || grep -q "\.\/workspace\/project:\/workspace\/project" "$COMPOSE_FILE"; then
            print_result "OK" "Project root mount configured (Sync Mode)"
        else
            print_result "WARN" "Project root mount may not be configured correctly"
        fi

        # Check for Claude config mount (Sync Mode)
        if grep -q "\./workspace/.claude:/workspace/.claude" "$COMPOSE_FILE" || grep -q "\./\.claude:\.\/\.claude" "$COMPOSE_FILE"; then
            print_result "OK" "Claude config mount configured"
        else
            print_result "WARN" "Claude config mount may not be configured correctly"
        fi

        # Check for working_dir (Sync Mode)
        if grep -q "working_dir: /workspace/project" "$COMPOSE_FILE"; then
            print_result "OK" "Working directory is /workspace/project"
        else
            print_result "WARN" "Working directory may not be /workspace/project"
        fi

        # Check for extra_hosts (Linux compatibility)
        if grep -q "extra_hosts:" "$COMPOSE_FILE" && grep -q "host.docker.internal:host-gateway" "$COMPOSE_FILE"; then
            print_result "OK" "extra_hosts configured for Linux compatibility"
        else
            print_result "WARN" "extra_hosts not configured (may be needed for Linux)"
        fi
    else
        # Isolation Mode checks
        if grep -q "working_dir:" "$COMPOSE_FILE" 2>/dev/null; then
            print_result "OK" "working_dir is set"
        else
            print_result "WARN" "working_dir not set (container may start in wrong directory)"
        fi
    fi

    # Check for volume mounts
    if grep -q "volumes:" "$COMPOSE_FILE" 2>/dev/null; then
        print_result "OK" "volumes are configured"
    else
        print_result "ERROR" "No volumes found (config won't persist)"
    fi
fi

# Check 6: Validate Dockerfile if exists
if [ "$DOCKER_MODE" = "sync" ]; then
    DOCKERFILE="$PROJECT_DIR/Docker/Dockerfile"
elif [ "$DOCKER_MODE" = "isolation" ]; then
    DOCKERFILE="$PROJECT_DIR/Dockerfile"
fi

if [ -f "$DOCKERFILE" ]; then
    echo ""
    echo -e "${BLUE}Dockerfile Checks:${NC}"

    # Check for USER instruction
    if grep -q "USER" "$DOCKERFILE" 2>/dev/null; then
        print_result "OK" "User is set (multi-user support)"
    else
        print_result "WARN" "No USER instruction (running as root)"
    fi

    # Check for WORKDIR
    if grep -q "WORKDIR" "$DOCKERFILE" 2>/dev/null; then
        print_result "OK" "WORKDIR is set"
    else
        print_result "WARN" "No WORKDIR set"
    fi

    # Check for sudo installation
    if grep -q "sudo" "$DOCKERFILE" 2>/dev/null; then
        print_result "OK" "sudo package installation found"
    else
        print_result "ERROR" "sudo not installed - non-root user will lack autonomy"
    fi

    # Check for NOPASSWD:ALL configuration
    if grep -q "NOPASSWD:ALL" "$DOCKERFILE" 2>/dev/null; then
        print_result "OK" "sudo NOPASSWD:ALL configured (autonomous operations)"
    else
        print_result "ERROR" "NOPASSWD:ALL not configured - manual intervention will be required"
    fi
fi

# Summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Validation Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Total Checks: ${BLUE}$CHECKS${NC}"
echo -e "${GREEN}Passed:${NC} $((CHECKS - ERRORS - WARNINGS))"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo -e "${RED}Errors:${NC} $ERRORS"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed! Configuration is valid.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Validation passed with warnings. Review recommended.${NC}"
    exit 0
else
    echo -e "${RED}✗ Validation failed! Please fix errors above.${NC}"
    exit 1
fi
