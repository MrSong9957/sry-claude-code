#!/bin/bash
# Migration Script: Isolation Mode → Sync Mode
# Migrates existing docker-claude-code projects from Isolation Mode to Sync Mode

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Isolation Mode → Sync Mode Migration${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Detect current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Check if we're in the correct directory
if [ ! -f "$PROJECT_DIR/docker-compose.yml" ] && [ ! -f "$PROJECT_DIR/Docker/docker-compose.yml" ]; then
    echo -e "${RED}[Error] Not in a valid docker-claude-code project directory${NC}"
    echo -e "${YELLOW}Please run this script from the project root directory${NC}"
    exit 1
fi

# Detect Docker mode
echo -e "${BLUE}Detecting current Docker mode...${NC}"
if [ -d "$PROJECT_DIR/Docker" ]; then
    echo -e "${YELLOW}[Warning] Already in Sync Mode (Docker/ directory exists)${NC}"
    read -p "Continue anyway? [y/N]: " continue_anyway
    if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}Exiting...${NC}"
        exit 0
    fi
elif [ -d "$PROJECT_DIR/workspace" ] && [ -d "$PROJECT_DIR/dev-home" ]; then
    echo -e "${GREEN}✓ Isolation Mode detected${NC}"
    MODE="Isolation"
else
    echo -e "${RED}[Error] Unknown Docker mode or not initialized${NC}"
    echo -e "${YELLOW}Expected workspace/ and dev-home/ directories for Isolation Mode${NC}"
    exit 1
fi
echo ""

# Step 1: Backup existing data
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 1: Creating Backup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

BACKUP_FILE="$PROJECT_DIR/backup-isolation-$(date +%Y%m%d-%H%M%S).tar.gz"
echo -e "${CYAN}Creating backup: $BACKUP_FILE${NC}"

tar -czf "$BACKUP_FILE" \
    -C "$PROJECT_DIR" \
    workspace/ \
    dev-home/ \
    docker-compose.yml \
    Dockerfile \
    .env 2>/dev/null || {
    echo -e "${RED}[Error] Backup failed${NC}"
    exit 1
}

echo -e "${GREEN}✓ Backup created successfully${NC}"
echo -e "${CYAN}Backup file: $BACKUP_FILE${NC}"
echo ""

# Step 2: Export project files from container
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 2: Exporting Project Files${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if container is running
if docker ps | grep -q docker-claude-code-app; then
    echo -e "${GREEN}✓ Container is running${NC}"
    CONTAINER_RUNNING=true
else
    echo -e "${YELLOW}⚠ Container is not running${NC}"
    echo -e "${CYAN}Starting container...${NC}"
    cd "$PROJECT_DIR"
    docker-compose up -d > /dev/null 2>&1
    sleep 5
    if docker ps | grep -q docker-claude-code-app; then
        echo -e "${GREEN}✓ Container started${NC}"
        CONTAINER_RUNNING=true
    else
        echo -e "${RED}[Error] Failed to start container${NC}"
        echo -e "${YELLOW}You may need to export files manually${NC}"
        read -p "Continue anyway? [y/N]: " continue_no_export
        if [[ ! $continue_no_export =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}Exiting...${NC}"
            exit 1
        fi
        CONTAINER_RUNNING=false
    fi
fi

if [ "$CONTAINER_RUNNING" = true ]; then
    echo -e "${CYAN}Exporting files from container...${NC}"

    # Export project files
    docker cp docker-claude-code-app:/workspace/project "$PROJECT_DIR/" 2>/dev/null || {
        echo -e "${YELLOW}[Warning] Failed to export files from container${NC}"
        echo -e "${YELLOW}Files may not exist in container yet${NC}"
    }

    # Fix file ownership
    docker-compose exec -T app sudo chown -R $(id -u):$(id -g) /workspace/project 2>/dev/null || true

    echo -e "${GREEN}✓ Files exported${NC}"
fi
echo ""

# Step 3: Create new directory structure
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 3: Creating New Directory Structure${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Create Docker directory
mkdir -p "$PROJECT_DIR/Docker/workspace/.claude"
echo -e "${GREEN}✓ Created Docker/ directory${NC}"
echo -e "${GREEN}✓ Created Docker/workspace/.claude/ directory${NC}"
echo ""

# Step 4: Move project files
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 4: Moving Project Files${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ -d "$PROJECT_DIR/project" ]; then
    echo -e "${CYAN}Moving project files to Docker/ directory...${NC}"
    mv "$PROJECT_DIR/project"/* "$PROJECT_DIR/Docker/" 2>/dev/null || {
        echo -e "${YELLOW}[Warning] Failed to move some project files${NC}"
        WARNINGS=$((WARNINGS + 1))
    }
    rmdir "$PROJECT_DIR/project" 2>/dev/null || true
    echo -e "${GREEN}✓ Project files moved${NC}"
else
    echo -e "${YELLOW}[Warning] No project files to move (project/ directory not found)${NC}"
    echo -e "${YELLOW}This is normal if you haven't created any files yet${NC}"
fi
echo ""

# Step 5: Move configuration files
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 5: Moving Configuration Files${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [ -f "$PROJECT_DIR/docker-compose.yml" ]; then
    mv "$PROJECT_DIR/docker-compose.yml" "$PROJECT_DIR/Docker/docker-compose.yml"
    echo -e "${GREEN}✓ Moved docker-compose.yml${NC}"
fi

if [ -f "$PROJECT_DIR/Dockerfile" ]; then
    mv "$PROJECT_DIR/Dockerfile" "$PROJECT_DIR/Docker/Dockerfile"
    echo -e "${GREEN}✓ Moved Dockerfile${NC}"
fi

if [ -f "$PROJECT_DIR/.env" ]; then
    mv "$PROJECT_DIR/.env" "$PROJECT_DIR/Docker/.env"
    echo -e "${GREEN}✓ Moved .env${NC}"
fi
echo ""

# Step 6: Update docker-compose.yml
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 6: Updating docker-compose.yml${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

COMPOSE_FILE="$PROJECT_DIR/Docker/docker-compose.yml"
if [ -f "$COMPOSE_FILE" ]; then
    echo -e "${CYAN}Updating volume mounts in docker-compose.yml...${NC}"

    # Backup original
    cp "$COMPOSE_FILE" "$COMPOSE_FILE.bak"

    # Update volumes using sed
    sed -i 's|- ${WORKSPACE_PATH:-./workspace}:/workspace|- # 项目根目录实时同步\n      - ..:/workspace/project|' "$COMPOSE_FILE"
    sed -i 's|- ${CLAUDE_CONFIG_PATH:-./dev-home/config}:/home/claude/.config/claude|- # Claude 配置持久化\n      - ./workspace/.claude:/workspace/.claude|' "$COMPOSE_FILE"
    sed -i '/| *- ${CLAUDE_HOME_PATH:-.*$/d' "$COMPOSE_FILE"

    # Remove duplicate volume mounts if any
    sed -i '/^ *- .*\/workspace$/d' "$COMPOSE_FILE"

    echo -e "${GREEN}✓ Updated docker-compose.yml${NC}"
    echo -e "${CYAN}Original backed up as: docker-compose.yml.bak${NC}"
else
    echo -e "${RED}[Error] docker-compose.yml not found${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Step 7: Update .env file
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 7: Updating .env File${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

ENV_FILE="$PROJECT_DIR/Docker/.env"
if [ -f "$ENV_FILE" ]; then
    echo -e "${CYAN}Simplifying .env configuration...${NC}"

    # Backup original
    cp "$ENV_FILE" "$ENV_FILE.bak"

    # Remove optional path variables
    sed -i '/^WORKSPACE_PATH=/d' "$ENV_FILE"
    sed -i '/^CLAUDE_CONFIG_PATH=/d' "$ENV_FILE"
    sed -i '/^CLAUDE_HOME_PATH=/d' "$ENV_FILE"
    sed -i '/^# WORKSPACE_PATH=/d' "$ENV_FILE"
    sed -i '/^# CLAUDE_CONFIG_PATH=/d' "$ENV_FILE"
    sed -i '/^# CLAUDE_HOME_PATH=/d' "$ENV_FILE"

    echo -e "${GREEN}✓ Updated .env${NC}"
    echo -e "${CYAN}Original backed up as: .env.bak${NC}"
else
    echo -e "${YELLOW}[Warning] .env file not found${NC}"
    echo -e "${CYAN}Creating new .env from template...${NC}"

    cat > "$ENV_FILE" << 'EOF'
# Claude Code CLI Configuration
ANTHROPIC_API_KEY=dummy
ANTHROPIC_BASE_URL=http://host.docker.internal:15721
EOF

    echo -e "${GREEN}✓ Created new .env${NC}"
fi
echo ""

# Step 8: Stop and remove old container
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 8: Removing Old Container${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${CYAN}Stopping old container...${NC}"
cd "$PROJECT_DIR"
if docker-compose ps | grep -q docker-claude-code-app; then
    docker-compose down
    echo -e "${GREEN}✓ Old container stopped and removed${NC}"
else
    echo -e "${YELLOW}[Warning] Container was not running${NC}"
fi
echo ""

# Step 9: Start new container
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 9: Starting New Container${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

cd "$PROJECT_DIR/Docker"
echo -e "${CYAN}Building new container...${NC}"
docker-compose build > /dev/null 2>&1
echo -e "${GREEN}✓ Container built${NC}"

echo -e "${CYAN}Starting new container...${NC}"
docker-compose up -d
sleep 5

if docker ps | grep -q docker-claude-code-app; then
    echo -e "${GREEN}✓ New container started successfully${NC}"
else
    echo -e "${RED}[Error] Failed to start new container${NC}"
    echo -e "${YELLOW}Check logs with: cd Docker && docker-compose logs app${NC}"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Step 10: Install statusline plugin
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 10: Installing Statusline Plugin${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${CYAN}Installing plugin...${NC}"
bash "$SCRIPT_DIR/../init-docker-project.sh" 2>/dev/null || {
    echo -e "${YELLOW}[Warning] Plugin installation may have failed${NC}"
    echo -e "${YELLOW}You can install it manually later${NC}"
    WARNINGS=$((WARNINGS + 1))
}
echo ""

# Step 11: Verification
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 11: Verifying Migration${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${CYAN}Running verification tests...${NC}"
cd "$PROJECT_DIR"

# Test 1: Container access
if docker-compose exec -T app sh -c "whoami" | grep -q claude; then
    echo -e "${GREEN}✓ Test 1: Container access OK${NC}"
else
    echo -e "${RED}✗ Test 1: Container access FAILED${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Test 2: Working directory
if docker-compose exec -T app sh -c "pwd" | grep -q "/workspace/project"; then
    echo -e "${GREEN}✓ Test 2: Working directory OK${NC}"
else
    echo -e "${RED}✗ Test 2: Working directory FAILED${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Test 3: File sync
echo "test-sync-$(date +%s)" > test-sync.txt
sleep 2
if docker-compose exec -T app sh -c "test -f /workspace/project/test-sync.txt"; then
    echo -e "${GREEN}✓ Test 3: File sync OK${NC}"
    rm -f test-sync.txt
else
    echo -e "${RED}✗ Test 3: File sync FAILED${NC}"
    rm -f test-sync.txt
    ERRORS=$((ERRORS + 1))
fi

# Test 4: Claude CLI
if docker-compose exec -T app sh -c "claude --version" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Test 4: Claude CLI OK${NC}"
else
    echo -e "${YELLOW}⚠ Test 4: Claude CLI not yet installed${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""

# Step 12: Cleanup old directories (optional)
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 12: Cleanup Old Directories${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

echo -e "${YELLOW}The following old directories can be safely removed:${NC}"
echo -e "${YELLOW}  - workspace/${NC}"
echo -e "${YELLOW}  - dev-home/${NC}"
echo ""
read -p "Remove them now? [y/N]: " remove_old
if [[ $remove_old =~ ^[Yy]$ ]]; then
    rm -rf "$PROJECT_DIR/workspace" "$PROJECT_DIR/dev-home"
    echo -e "${GREEN}✓ Old directories removed${NC}"
else
    echo -e "${CYAN}Skipped. You can remove them later manually.${NC}"
fi
echo ""

# Final summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Migration Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All critical tests passed!${NC}"
else
    echo -e "${RED}✗ $ERRORS error(s) occurred${NC}"
fi

if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warning(s) generated${NC}"
fi

echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "1. cd Docker"
echo "2. docker-compose exec app sh  # Enter container"
echo "3. claude doctor              # Verify Claude CLI"
echo "4. Verify your project files are present"
echo ""
echo -e "${CYAN}For issues, see:${NC}"
echo "- Migration guide: .claude/skills/docker-claude-code/docs/MIGRATION_GUIDE.md"
echo "- Diagnostic script: bash .claude/skills/docker-claude-code/scripts/diagnose-docker.sh"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${YELLOW}To rollback:${NC}"
    echo "1. cd Docker && docker-compose down"
    echo "2. cd .. && rm -rf Docker/"
    echo "3. tar -xzf $(basename "$BACKUP_FILE")"
    echo "4. docker-compose up -d"
    echo ""
    exit 1
else
    exit 0
fi
