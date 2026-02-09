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
PLUGIN_DIR="$HOME/.claude/plugins/custom/$PLUGIN_NAME"
STATUSLINE_DIR="$PLUGIN_DIR/statusline"
SETTINGS_FILE="$HOME/.claude/settings.json"

# 打印信息
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查依赖
check_dependencies() {
    if ! command -v python3 &> /dev/null; then
        error "需要 Python 3"
        exit 1
    fi
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

    # 复制脚本
    cp "$(dirname "$0")/show-prompt.py" "$STATUSLINE_DIR/"
    chmod +x "$STATUSLINE_DIR/show-prompt.py"

    # 创建 plugin.json
    cat > "$PLUGIN_DIR/.claude-plugin/plugin.json" << 'EOF'
{
  "name": "show-last-prompt",
  "version": "1.0.0",
  "description": "在状态栏显示用户最后输入的简化版本",
  "license": "MIT",
  "homepage": "https://github.com/your-username/claude-code-statusline-plugin"
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

    # 创建新配置（保留原有设置）
    cat > "$SETTINGS_FILE" << EOF
{
  "statusLine": {
    "type": "command",
    "command": "python3 $STATUSLINE_DIR/show-prompt.py"
  }
}
EOF

    info "settings.json 已更新"
}

# 卸载
uninstall() {
    info "卸载插件..."

    # 删除插件目录
    if [ -d "$PLUGIN_DIR" ]; then
        rm -rf "$PLUGIN_DIR"
        info "已删除插件目录"
    fi

    # 恢复 settings.json（如果有备份）
    LATEST_BACKUP=$(ls -t "$SETTINGS_FILE.backup"* 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        cp "$LATEST_BACKUP" "$SETTINGS_FILE"
        info "已恢复 settings.json"
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
