#!/bin/bash
# =============================================================================
# Claude Code 状态栏插件 - 安装脚本
# =============================================================================
#
# 功能：在状态栏显示用户最新输入的简化版本
#
# 使用方法：
#   ./install.sh              # 自动安装
#   ./install.sh --uninstall   # 卸载
#
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
PLUGIN_NAME="show-last-prompt"
PLUGIN_VERSION="2.3.0"
PLUGIN_DIR="$HOME/.claude/plugins/custom/$PLUGIN_NAME"
STATUSLINE_DIR="$PLUGIN_DIR/statusline"
SETTINGS_FILE="$HOME/.claude/settings.json"

# Python 命令（将自动检测）
PYTHON_CMD=""

# 打印信息
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查依赖
check_dependencies() {
    # 检测 Python 命令（python 或 python3）
    if command -v python &> /dev/null; then
        PYTHON_CMD="python"
    elif command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    else
        error "需要 Python 3"
        exit 1
    fi
    info "检测到 Python: $PYTHON_CMD"
}

# 创建目录结构
create_directories() {
    info "创建插件目录..."
    mkdir -p "$STATUSLINE_DIR"
    mkdir -p "$PLUGIN_DIR/.claude-plugin"
}

# 安装文件
install_files() {
    info "复制插件文件..."

    # 复制脚本（修正路径：show-prompt.py 在 statusline/ 目录下）
    cp "$(dirname "$0")/statusline/show-prompt.py" "$STATUSLINE_DIR/"
    chmod +x "$STATUSLINE_DIR/show-prompt.py"

    # 创建 plugin.json
    cat > "$PLUGIN_DIR/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "show-last-prompt",
  "version": "2.3.0",
  "description": "在状态栏显示用户最后输入的简化版本",
  "license": "MIT",
  "homepage": "https://github.com/MrSong9957/claude-code-statusline-plugin"
}
EOF

    info "文件已安装到: $PLUGIN_DIR"
}

# 配置 settings.json
configure_settings() {
    info "配置 settings.json..."

    # 读取现有配置
    if [ -f "$SETTINGS_FILE" ]; then
        # 备份
        cp "$SETTINGS_FILE" "$SETTINGS_FILE.backup.$(date +%Y%m%d%H%M%S)"
        info "已备份原配置文件"
    fi

    # 使用 jq 合并配置（如果可用）
    if command -v jq &> /dev/null; then
        info "使用 jq 合并配置..."
        temp_file=$(mktemp)
        jq --arg cmd "$PYTHON_CMD $STATUSLINE_DIR/show-prompt.py" \
           '.statusLine = {"type": "command", "command": $cmd}' \
           "$SETTINGS_FILE" > "$temp_file" 2>/dev/null || \
           jq --arg cmd "$PYTHON_CMD $STATUSLINE_DIR/show-prompt.py" \
           '. + {"statusLine": {"type": "command", "command": $cmd}}' \
           "$SETTINGS_FILE" > "$temp_file"
        mv "$temp_file" "$SETTINGS_FILE"
    else
        # jq 不可用，创建新配置（警告用户）
        warn "jq 未安装，将创建新的 settings.json"
        warn "如需保留原有配置，请手动合并以下内容："
        warn '{'
        warn '  "statusLine": {'
        warn "    \"type\": \"command\","
        warn "    \"command\": \"$PYTHON_CMD $STATUSLINE_DIR/show-prompt.py\""
        warn '  }'
        warn '}'

        # 创建新配置（仅包含 statusLine）
        cat > "$SETTINGS_FILE" << EOF
{
  "statusLine": {
    "type": "command",
    "command": "$PYTHON_CMD $STATUSLINE_DIR/show-prompt.py"
  }
}
EOF
    fi

    info "settings.json 已更新"
}

# 卸载
uninstall() {
    info "卸载插件..."

    # 从 settings.json 中移除 statusLine 配置
    if [ -f "$SETTINGS_FILE" ]; then
        if command -v jq &> /dev/null; then
            temp_file=$(mktemp)
            jq 'del(.statusLine)' "$SETTINGS_FILE" > "$temp_file"
            mv "$temp_file" "$SETTINGS_FILE"
            info "已从 settings.json 移除 statusLine 配置"
        else
            warn "请手动从 settings.json 中删除 statusLine 配置"
        fi
    fi

    # 删除插件目录
    if [ -d "$PLUGIN_DIR" ]; then
        rm -rf "$PLUGIN_DIR"
        info "已删除插件目录"
    fi

    info "卸载完成"
}

# 主安装流程
install() {
    info "开始安装 $PLUGIN_NAME 插件..."
    echo ""

    check_dependencies
    create_directories
    install_files
    configure_settings

    echo ""
    info "========================================"
    info "安装完成！"
    info "========================================"
    info "请重启 Claude Code 以使插件生效"
    echo ""
}

# 主函数
main() {
    case "${1:-install}" in
        --uninstall|uninstall)
            uninstall
            ;;
        *)
            install
            ;;
    esac
}

main "$@"
