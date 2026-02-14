#!/bin/bash
# 插件功能回归测试 - 确保修改不破坏现有功能

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PLUGIN_DIR=".claude/skills/docker-claude-code/claude-code-statusline-plugin"
PLUGIN_CONFIG="$PLUGIN_DIR/.claude-plugin/plugin.json"
PYTHON_SCRIPT="$PLUGIN_DIR/statusline/show-prompt.py"

echo "=== 插件功能完整性测试 ==="

# 1. 检查插件目录结构
echo -n "1. 检查插件目录结构..."
REQUIRED_DIRS=(".claude-plugin" "statusline")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [[ ! -d "$PLUGIN_DIR/$dir" ]]; then
        echo -e "${RED}FAIL${NC} - 缺失目录 $dir"
        exit 1
    fi
done
echo -e "${GREEN}PASS${NC}"

# 2. 检查插件文件完整性
echo -n "2. 检查插件文件..."
REQUIRED_FILES=(".claude-plugin/plugin.json" "install.sh" "statusline/show-prompt.py")
for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$PLUGIN_DIR/$file" ]]; then
        echo -e "${RED}FAIL${NC} - 缺失 $file"
        exit 1
    fi
done
echo -e "${GREEN}PASS${NC}"

# 3. 验证 plugin.json 格式
echo -n "3. 验证 plugin.json..."
# 检查 python3 是否真的可用
if python3 --version &> /dev/null 2>&1; then
    # 使用 Python 的 json.load 验证
    if python3 -c "import json; json.load(open('$PLUGIN_CONFIG'))" 2>&1; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC} - JSON 格式错误"
        exit 1
    fi
else
    echo -e "${YELLOW}SKIP${NC} - python3 未安装或不可用"
fi

# 4. 验证插件元数据
echo -n "4. 验证插件元数据..."
if grep -q '"name"' "$PLUGIN_CONFIG" && \
   grep -q '"version"' "$PLUGIN_CONFIG" && \
   grep -q '"description"' "$PLUGIN_CONFIG"; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC} - plugin.json 缺失必需字段"
    exit 1
fi

# 5. 检查 install.sh 可执行性
echo -n "5. 检查 install.sh 可执行..."
if [[ -x "$PLUGIN_DIR/install.sh" ]]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${YELLOW}WARN${NC} - install.sh 不可执行"
fi

# 6. 验证 Python 脚本语法
echo -n "6. 验证 Python 脚本..."
if python3 --version &> /dev/null 2>&1; then
    if python3 -m py_compile "$PYTHON_SCRIPT" > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC} - Python 脚本语法错误"
        exit 1
    fi
else
    echo -e "${YELLOW}SKIP${NC} - python3 未安装或不可用"
fi

echo ""
echo -e "${GREEN}✓ 所有插件功能测试通过${NC}"
