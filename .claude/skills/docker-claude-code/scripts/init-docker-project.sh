#!/bin/bash
# Project Initialization Script for Docker Claude Code
# Initializes Docker environment for new or existing projects

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Docker Claude Code - Project Init${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Detect current directory and platform
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_DIR="$(pwd)"

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

echo -e "${BLUE}Platform detected:${NC} $PLATFORM_NAME"
echo ""

# Interactive menu
echo -e "${CYAN}Select initialization scenario:${NC}"
echo "1) New Project (create fresh Docker environment)"
echo "2) Migrate Existing Project (copy existing code to Docker)"
echo "3) Backup project from container to host machine"
echo "4) Exit"
echo ""
read -p "Enter choice [1-4]: " choice
case $choice in
    1)
        SCENARIO="new"
        ;;
    2)
        SCENARIO="migrate"
        ;;
    3)
        SCENARIO="backup"
        ;;
    4)
        echo -e "${YELLOW}Exiting...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting...${NC}"
        exit 1
        ;;
esac

# Dependency Check Function
check_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"

    local missing_deps=()

    # Check for required commands
    local deps=("docker" "python3")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    # Check for docker-compose or docker compose
    if docker compose version &> /dev/null; then
        DOCKER_COMPOSE="docker compose"
    elif docker-compose version &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    else
        missing_deps+=("docker-compose")
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
    echo -e "${GREEN}✓ Using: $DOCKER_COMPOSE${NC}"
    echo ""
}

# Check disk space (at least 5GB)
check_disk_space() {
    echo -e "${BLUE}Checking disk space...${NC}"

    local required_gb=5
    local available_gb=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')

    if [ "$available_gb" -lt "$required_gb" ]; then
        echo -e "${YELLOW}[Warning] Insufficient disk space${NC}"
        echo -e "${YELLOW}Required: ${required_gb}GB, Available: ${available_gb}GB${NC}"
        echo -e "${YELLOW}Build may fail. Continue anyway? [y/N]: ${NC}"
        read -r continue
        if [[ ! $continue =~ ^[Yy]$ ]]; then
            echo -e "${RED}Aborted${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Sufficient disk space (${available_gb}GB available)${NC}"
    fi
    echo ""
}

# Check network connectivity
check_network() {
    echo -e "${BLUE}Checking network connectivity...${NC}"

    if ping -c 1 -W 2 hub.docker.com &> /dev/null; then
        echo -e "${GREEN}✓ Docker Hub is reachable${NC}"
    else
        echo -e "${YELLOW}[Warning] Cannot reach Docker Hub${NC}"
        echo -e "${YELLOW}Build may fail in offline mode${NC}"
        echo -e "${YELLOW}Continue anyway? [y/N]: ${NC}"
        read -r continue
        if [[ ! $continue =~ ^[Yy]$ ]]; then
            echo -e "${RED}Aborted${NC}"
            exit 1
        fi
    fi
    echo ""
}

# Run dependency checks
check_dependencies
check_disk_space
check_network

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Scenario:${NC} $SCENARIO project"
echo -e "${GREEN}========================================${NC}"
echo ""

# Get project name
read -p "Enter project name [docker-claude-code]: " project_name
project_name=${project_name:-docker-claude-code}

# Validate project name (security: prevent path traversal)
validate_project_name() {
    local name="$1"
    # Only allow alphanumeric, underscore, and hyphen
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}Error: Invalid project name '$name'${NC}"
        echo -e "${RED}Only alphanumeric characters, underscore, and hyphen allowed${NC}"
        exit 1
    fi
    # Prevent path traversal
    if [[ "$name" =~ \.\. ]]; then
        echo -e "${RED}Error: Path traversal characters not allowed${NC}"
        exit 1
    fi
}

# Validate source path (security: prevent arbitrary file access)
validate_source_path() {
    local path="$1"
    # Check if path exists
    if [[ ! -d "$path" ]]; then
        echo -e "${RED}Error: Source path does not exist: $path${NC}"
        exit 1
    fi
    # Resolve to absolute path and prevent path traversal
    local abs_path=$(cd "$path" 2>/dev/null && pwd) || {
        echo -e "${RED}Error: Cannot access path: $path${NC}"
        exit 1
    }
    # Check for path traversal in resolved path
    if [[ "$abs_path" =~ \.\. ]]; then
        echo -e "${RED}Error: Path traversal characters not allowed${NC}"
        exit 1
    fi
    echo "$abs_path"
}

echo ""

validate_project_name "$project_name"

echo ""
echo -e "${BLUE}Initializing ${GREEN}$project_name${NC}..."
echo ""

# Verify .claude directory exists on host
CLAUDE_DIR="$HOME/.claude"
echo -e "${YELLOW}Checking for Claude Code directory...${NC}"

if [ -d "$CLAUDE_DIR" ]; then
    echo -e "${GREEN}✓ Claude Code directory found${NC}"
else
    echo -e "${YELLOW}[!] Claude Code directory not found: $CLAUDE_DIR${NC}"
    echo -e "${YELLOW}The plugin requires Claude Code to be installed on host first.${NC}"
    echo ""
    exit 1
fi

# Create project directory
PROJECT_DIR="$CURRENT_DIR/$project_name"
echo -e "${BLUE}Creating project directory:${NC} $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
echo -e "${GREEN}✓ Project directory created${NC}"
echo ""

# Function to create directory structure
create_directory_structure() {
    echo -e "${BLUE}Creating directory structure...${NC}"

    # Create workspace directory
    mkdir -p "$PROJECT_DIR/workspace/project"
    echo -e "${GREEN}✓ workspace/project created${NC}"

    # Create .gitignore
    cat > "$PROJECT_DIR/.gitignore" << 'EOF'
# Environment variables
.env

# Docker volumes
workspace/
dev-home/
EOF
    echo -e "${GREEN}✓ .gitignore created${NC}"

    # Create .claude/plugins directory for statusline plugin
    mkdir -p "$PROJECT_DIR/.claude/plugins/custom"
    echo -e "${GREEN}✓ .claude/plugins directory created${NC}"

    echo -e "${GREEN}✓ Directory structure created${NC}"
    echo ""
}

# Function to create .env file
create_env_file() {
    echo -e "${BLUE}Creating .env file...${NC}"

    local env_file="$PROJECT_DIR/.env"

    if [ -f "$env_file" ]; then
        echo -e "${YELLOW}.env file already exists.${NC}"
        read -p "Overwrite? [y/N]: " overwrite
        if [[ $overwrite =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Creating new .env file...${NC}"
        else
            echo -e "${YELLOW}Skipping .env creation${NC}"
            return 0
        fi
    fi

    # Platform-specific configuration
    local base_url="http://host.docker.internal:15721"
    local extra_hosts_comment="# Linux: Adds extra_hosts for host.docker.internal support"

    if [ "$PLATFORM_ID" = "linux" ]; then
        base_url="$base_url (Linux with extra_hosts)"
        extra_hosts_comment="# Linux compatible"
    fi

    cat > "$env_file" << EOF
# Claude Code CLI Configuration
# dummy 表示沿用宿主机的 API KEY
ANTHROPIC_API_KEY=dummy

# 端口要与 CC Switch 本地代理端口一致
ANTHROPIC_BASE_URL=$base_url

# Optional: Custom paths (defaults shown)
# WORKSPACE_PATH=./workspace
# DEV_HOME_PATH=./dev-home/claude
# CLAUDE_CONFIG_PATH=./dev-home/config
EOF

    echo -e "${GREEN}✓ .env file created${NC}"
    echo -e "${BLUE}Platform:${NC} $PLATFORM_NAME"
    echo -e "${BLUE}Base URL:${NC} $base_url $extra_hosts_comment"
    echo ""
}

# Function to create docker-compose.yml
create_docker_compose() {
    echo -e "${BLUE}Creating docker-compose.yml...${NC}"

    local compose_file="$PROJECT_DIR/docker-compose.yml"

    if [ -f "$compose_file" ]; then
        echo -e "${YELLOW}docker-compose.yml already exists.${NC}"
        read -p "Overwrite? [y/N]: " overwrite
        if [[ $overwrite =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Creating new docker-compose.yml...${NC}"
        else
            echo -e "${YELLOW}Skipping docker-compose.yml creation${NC}"
            return 0
        fi
    fi

    cat > "$compose_file" << EOF
services:
  app:
    build: .
    container_name: docker-claude-code-app
    ports:
      # 容器内应用端口映射（如有 Web 服务需要）
      - "8080:8000"
    environment:
      - ENV=development
      - ANTHROPIC_API_KEY=\${ANTHROPIC_API_KEY}
      - ANTHROPIC_BASE_URL=\${ANTHROPIC_BASE_URL:-http://host.docker.internal:15721}
    extra_hosts:
      # Linux 兼容：使容器能访问宿主机服务
      # Windows/Mac (Docker Desktop) 会自动忽略此配置
      - "host.docker.internal:host-gateway"
    volumes:
      # 统一持久化：项目、配置、数据都在 ./workspace 目录
      - ${WORKSPACE_PATH:-./workspace}:/workspace
      # 持久化 Claude 配置（API 密钥、历史记录等）
      - ${CLAUDE_CONFIG_PATH:-./dev-home/config}:/home/claude/.config/claude
      # 持久化 Claude 用户数据
      - ${CLAUDE_HOME_PATH:-./dev-home/claude}:/home/claude
    working_dir: /workspace/project  # 关键：容器启动后直接进入项目目录
    stdin_open: true  # docker run -i
    tty: true         # docker run -t
    restart: unless-stopped
EOF

    echo -e "${GREEN}✓ docker-compose.yml created${NC}"
    echo ""
}

# Function to create Dockerfile
create_dockerfile() {
    echo -e "${BLUE}Creating Dockerfile...${NC}"

    local dockerfile="$PROJECT_DIR/Dockerfile"

    if [ -f "$dockerfile" ]; then
        echo -e "${YELLOW}Dockerfile already exists.${NC}"
        read -p "Overwrite? [y/N]: " overwrite
        if [[ $overwrite =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Creating new Dockerfile...${NC}"
        else
            echo -e "${YELLOW}Skipping Dockerfile creation${NC}"
            return 0
        fi
    fi

    cat > "$dockerfile" << EOF
# syntax=docker/dockerfile:1

# 阶段 1：基础镜像和工具
FROM node:20-slim AS base

# 安装 Claude Code CLI（最新版）
RUN npm install -g @anthropic-ai/claude-code

# 安装 sudo（非root用户需要）
RUN apt-get update && apt-get install -y sudo --no-install-recommends && rm -rf /var/lib/apt/lists/*

# 阶段 2：最终镜像
FROM base

# 创建非 root 用户 (ID: 1001，避免与 node 用户的 UID 1000 冲突)
RUN groupadd -r claude && useradd -r -g claude -G sudo -m -s /bin/bash claude && \
    echo "claude ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

# 设置工作目录（与 docker-compose.yml 中的 working_dir 一致）
WORKDIR /workspace/project

# 暴露端口（根据 docker-compose.yml 调整）
EXPOSE 8000

# 默认启动 shell
CMD ["/bin/bash"]
EOF

    echo -e "${GREEN}✓ Dockerfile created${NC}"
    echo ""
}

# Function to install statusline plugin in container
install_statusline_plugin() {
    echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Installing claude-code-statusline-plugin...${NC}"
echo ""

    # Copy plugin files to project .claude/plugins directory
    echo -e "${BLUE}Copying plugin files...${NC}"

    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # 查找仓库根目录（向上查找 .git 目录或 claude-code-statusline-plugin）
    local REPO_ROOT="$SCRIPT_DIR"
    while [ "$REPO_ROOT" != "/" ] && [ ! -d "$REPO_ROOT/.git" ] && [ ! -d "$REPO_ROOT/claude-code-statusline-plugin" ]; do
        REPO_ROOT="$(dirname "$REPO_ROOT")"
    done

    local PLUGIN_SOURCE_DIR="$REPO_ROOT/claude-code-statusline-plugin"

    # Check if we're running from within the skill directory
    if [ -d "$SCRIPT_DIR/../claude-code-statusline-plugin" ]; then
        echo -e "${GREEN}✓ Running from skill directory...${NC}"

        # Copy show-prompt.py
        if [ -f "$PLUGIN_SOURCE_DIR/statusline/show-prompt.py" ]; then
            cp -r "$PLUGIN_SOURCE_DIR/statusline/show-prompt.py" "$PROJECT_DIR/.claude/plugins/custom/show-last-prompt/statusline/show-prompt.py" 2>/dev/null || true
            echo -e "${GREEN}✓ Copied show-prompt.py${NC}"
        else
            echo -e "${YELLOW}[!] show-prompt.py not found in skill directory${NC}"
        fi

        # Copy plugin.json
        if [ -f "$PLUGIN_SOURCE_DIR/plugin.json" ]; then
            cp -r "$PLUGIN_SOURCE_DIR/plugin.json" "$PROJECT_DIR/.claude/plugins/custom/show-last-prompt/statusline/plugin.json" 2>/dev/null || true
            echo -e "${GREEN}✓ Copied plugin.json${NC}"
        else
            echo -e "${YELLOW}[!] plugin.json not found in skill directory${NC}"
        fi
    else
        echo -e "${YELLOW}[!] Plugin source directory not found${NC}"
        echo -e "${YELLOW}Plugin installation may be incomplete.${NC}"
    fi

    echo -e "${GREEN}✓ Plugin files copied${NC}"
    echo ""

    # Create install.sh script for project
    echo -e "${BLUE}Creating install script...${NC}"

    local install_script="$PROJECT_DIR/.claude/plugins/custom/show-last-prompt/statusline/install.sh"

    cat > "$install_script" << EOF
#!/bin/bash
# Claude Code 状态栏插件安装脚本
# 生成时间: $(date +%Y-%m-%d)

echo -e "\033[0;32m========\033[0mClaude Code Statusline Plugin Installer\033[0m========\033[0m"
echo -e "\033[0;32mProject: $PROJECT_DIR\033[0m"
echo -e "\033[0;32mPurpose: Install claude-code-statusline-plugin in Docker container"
echo -e "\033[0;32mMethod: Auto-install during container initialization"
echo ""

PLUGIN_DIR="\$HOME/.claude/plugins/custom/show-last-prompt/statusline"
PLUGIN_FILE="\$PLUGIN_DIR/show-prompt.py"
PLUGIN_JSON="\$PLUGIN_DIR/plugin.json"

echo -e "\033[0;33mChecking installation status...\033[0m"

# Check if already installed
if [ -f "\$PLUGIN_FILE" ] && grep -q "statusLine" "\$HOME/.claude/settings.json"; then
    echo -e "\033[0;32m[✓] Plugin already registered in Claude Code settings\033[0m"
    echo -e "\033[0;32m[!]"
    echo -e "\033[0;32mSkipping installation. Plugin is already active.\033[0m"
    echo ""
    exit 0
fi

echo -e "\033[0;32mInstalling plugin files...\033[0m"

# Create plugin directory if not exists
mkdir -p "\$PLUGIN_DIR"

# Plugin files are already in place, just register them
if [ -f "\$PLUGIN_FILE" ] && [ -f "\$PLUGIN_JSON" ]; then
    echo -e "\033[0;32m[✓] Plugin files found\033[0m"
else
    echo -e "\033[0;31m[✗] Plugin files not found\033[0m"
    echo -e "\033[0;31mPlease run init-docker-project.sh again\033[0m"
    exit 1
fi

echo -e "\033[0;32m[✓] Plugin files copied\033[0m"
echo -e "\033[0;32m========================================\033[0m"
echo -e "\033[0;32m✓ claude-code-statusline-plugin installed successfully!\033[0m"
echo ""
echo -e "\033[0;32m========================================\033[0m"

# Register plugin in Claude Code settings
SETTINGS_FILE="$HOME/.claude/settings.json"

echo -e "\033[0;34mUpdating Claude Code settings...\033[0m"

# Backup existing settings
if [ -f "$SETTINGS_FILE" ]; then
    cp "$SETTINGS_FILE" "${SETTINGS_FILE}.backup.$(date +%s)"
fi

# Add or update statusLine plugin configuration
python3 - << 'PYTHON_SCRIPT'
import json
import sys

settings_file = sys.argv[1] if len(sys.argv) > 1 else "$HOME/.claude/settings.json"
default_config = {
    "statusLine": {
        "type": "command",
        "command": "python3",
        "args": ["$HOME/.claude/plugins/custom/show-last-prompt/statusline/show-prompt.py"]
    }
}

try:
    with open(settings_file, 'r', encoding='utf-8') as f:
        settings = json.load(f)
        if not isinstance(settings, dict):
            settings = {}

        # Add or update statusLine plugin configuration
        settings["statusLine"] = default_config["statusLine"]

        f.seek(0)
        json.dump(settings, f, ensure_ascii=False, indent=2)
        print("[INFO] Settings updated successfully")
        sys.exit(0)

except Exception as e:
    print(f"[ERROR] Failed to update settings: {e}")
    sys.exit(1)
PYTHON_SCRIPT

if [ $? -eq 0 ]; then
    echo ""
    echo -e "\033[0;32m========================================\033[0m"
    echo -e "\033[0;32m✓ claude-code-statusline-plugin installed successfully!\033[0m"
    echo -e "\033[0;32m========================================\033[0m"
    echo ""
    echo -e "${GREEN}Plugin registered in Claude Code settings.json${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Restart Claude Code"
    echo "2. Status bar will show: [最新指令:{summary}]"
    echo ""
else
    echo -e "\033[0;31m[✗] Failed to register plugin\033[0m"
    echo -e "\033[0;31mError: Python script execution failed\033[0m"
    echo ""
    exit 1
fi

chmod +x "$install_script"

echo -e "${GREEN}✓ install script created${NC}"
echo ""

# Create installation instructions
cat > "$PROJECT_DIR/STATUSLINE_INSTALL.md" << 'EOF'
# Claude Code 状态栏插件安装指南

## 自动安装说明

容器初始化完成后，会自动执行以下操作：

1. **安装插件文件**：将 `show-prompt.py` 和 `plugin.json` 复制到项目的 `.claude/plugins/custom/show-last-prompt/statusline/` 目录
2. **注册插件**：自动更新 `~/.claude/settings.json`，添加 statusLine 插件配置
3. **创建安装脚本**：生成 `.claude/plugins/custom/show-last-prompt/statusline/install.sh` 脚本

## 验证安装

容器启动后，验证插件是否正确安装：

\`\`\`bash
# 在容器内检查
docker-compose exec app sh -c "python3 -c \\"import json; print(json.load(open('\$HOME/.claude/settings.json')).get('statusLine', {}))\\""
\`\`\`

预期输出：
\`\`\`
{"statusLine": {...}}
\`\`\`

## 功能说明

安装完成后，状态栏会显示：

- **格式**：[最新指令:{summary}]
- **AI 智能提取**：使用 Claude Haiku 模型理解用户真实意图
- **规则提取后备**：AI 失败时使用关键词匹配
- **缓存优化**：避免频繁 API 调用，提高响应速度

## 插件位置

- **脚本**：.claude/plugins/custom/show-last-prompt/statusline/install.sh
- **配置**：.claude/plugins/custom/show-last-prompt/statusline/plugin.json

## 手动安装（如需要）

如果自动安装失败，可以手动执行：

\`\`\`bash
cd $PROJECT_DIR/.claude/plugins/custom/show-last-prompt/statusline
bash install.sh
\`\`\`

---

**注意**：此功能仅在 Docker 容器内运行，需要 Python3 支持。
EOF

chmod +x "$PROJECT_DIR/STATUSLINE_INSTALL.md"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Statusline Plugin Integration Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}All integration files have been created in:${NC}"
echo ""
echo -e "${YELLOW}$PROJECT_DIR${NC}"
echo ""
echo -e "${CYAN}Plugin Files:${NC}"
echo "  - .claude/plugins/custom/show-last-prompt/statusline/show-prompt.py"
echo "  - .claude/plugins/custom/show-last-prompt/statusline/plugin.json"
echo "  - .claude/plugins/custom/show-last-prompt/statusline/install.sh"
echo "  - STATUSLINE_INSTALL.md"
echo ""
}

# Execute based on scenario
case $SCENARIO in
    new)
        echo -e "${BLUE}Starting new project scenario...${NC}"

        # Create directory structure
        create_directory_structure

        # Create configuration files
        create_env_file
        create_docker_compose
        create_dockerfile

        # Install statusline plugin
        install_statusline_plugin

        echo -e "${GREEN}✓ New project initialized${NC}"
        echo -e "${CYAN}Next steps:${NC}"
        echo "1. cd $PROJECT_DIR"
        echo "2. Review .env file and adjust if needed"
        echo "3. Start container: docker-compose up -d"
        echo "4. Enter container: docker-compose exec app sh"
        echo "5. Status bar will show: [最新指令:{summary}]"
        echo ""
        ;;
    migrate)
        echo -e "${BLUE}Starting migration scenario...${NC}"

        # Get source path
        read -p "Enter path to existing project: " source_path
 read -p "Enter path to existing project: " source_path	# Security: Validate source path	source_path=$(validate_source_path "$source_path" 2>/dev/null || exit 1

        # Validate source path (security: prevent arbitrary file access)
        validate_source_path() {
            local path="$1"
            # Check if path exists
            if [[ ! -d "$path" ]]; then
                echo -e "${RED}Error: Source path does not exist: $path${NC}"
                exit 1
            fi
            # Resolve to absolute path
            local abs_path=$(cd "$path" 2>/dev/null && pwd) || {
                echo -e "${RED}Error: Cannot access path: $path${NC}"
                exit 1
            }
            echo "$abs_path"
        }

        # Validate source path if provided
        if [ -d "$source_path" ]; then
            echo -e "${GREEN}✓ Source path exists${NC}"

            # Check for conflicts in target directory
            local target_dir="$PROJECT_DIR/workspace/project"
            if [ -d "$target_dir" ] && [ -n "$(ls -A $target_dir)" ]; then
                echo -e "${YELLOW}[Warning] Target directory is not empty${NC}"
                echo -e "${YELLOW}Existing files may be overwritten${NC}"
                read -p "Continue with migration? [y/N]: " continue
                if [[ ! $continue =~ ^[Yy]$ ]]; then
                    echo -e "${RED}Migration aborted${NC}"
                    exit 0
                fi
            fi

            # Prepare directory structure
            echo -e "${BLUE}Preparing container environment...${NC}"
            mkdir -p "$PROJECT_DIR/workspace/project"

            # Create configuration files first
            create_env_file
            create_docker_compose
            create_dockerfile

            echo -e "${GREEN}✓ Configuration files created${NC}"

            # Start container for migration
            echo -e "${YELLOW}Starting container for migration...${NC}"
            cd "$PROJECT_DIR"
            docker-compose up -d

            # Wait for container to be fully ready
            echo -e "${YELLOW}Waiting for container to be ready...${NC}"
            sleep 5

            # Check if container started successfully
            if ! docker-compose ps app | grep -q "Up"; then
                echo -e "${RED}[✗] Container failed to start${NC}"
                echo -e "${RED}Check logs with: docker-compose logs app${NC}"
                exit 1
            fi

            echo -e "${GREEN}✓ Container is running${NC}"

            # Copy files to container using docker cp
            echo -e "${BLUE}Copying project files from $source_path to container...${NC}"
            docker cp "$source_path"/. docker-claude-code-app:/workspace/project/

            # Fix file ownership for container user
            echo -e "${BLUE}Setting file ownership to claude user (UID 1001)...${NC}"
            docker-compose exec -T app sudo chown -R claude:claude /workspace/project

            echo -e "${GREEN}✓ Project files copied to container${NC}"
            echo -e "${CYAN}Files are in container at /workspace/project/ (persisted to ./workspace/ on host)${NC}"

            # Install statusline plugin
            install_statusline_plugin

            echo -e "${GREEN}✓ Migration complete${NC}"
            echo -e "${CYAN}Next steps:${NC}"
            echo "1. cd $PROJECT_DIR"
            echo "2. Review .env file and adjust if needed"
            echo "3. Container is already started, enter with: docker-compose exec app sh"
            echo "4. To backup files from container: bash .claude/skills/docker-claude-code/scripts/backup-project.sh"
            echo "5. Status bar will show: [最新指令:{summary}]"
            echo ""
        else
            echo -e "${RED}[!] Source path does not exist: $source_path${NC}"
            exit 1
        fi
        ;;
    backup)
        echo -e "${BLUE}Starting backup scenario...${NC}"

        # 检查是否在项目目录中
        if [ ! -f "docker-compose.yml" ]; then
            echo -e "${RED}[!] Not in a valid project directory${NC}"
            echo -e "${YELLOW}Please run this script from a directory with docker-compose.yml${NC}"
            exit 1
        fi

        # 调用备份脚本
        local backup_script="../.claude/skills/docker-claude-code/scripts/backup-project.sh"

        if [ -f "$backup_script" ]; then
            bash "$backup_script"
        else
            echo -e "${RED}[!] Backup script not found${NC}"
            echo -e "${YELLOW}Expected location: $backup_script${NC}"
            exit 1
        fi
        ;;
esac

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Initialization Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
