# Claude Code 状态栏插件

在 Claude Code 的状态栏中实时显示用户最新输入的简化版本，方便快速了解当前对话上下文。

## 效果展示

```
用户输入: "好的，请帮我创建一个 Django 项目"
状态栏显示: [最新指令:创建一个 Django 项目...]
```

## 功能特性

- ✅ **实时更新** - 每次用户输入后自动更新状态栏
- ✅ **智能摘要** - 自动去除无意义的前缀词（如"请帮我"、"好的"等）
- ✅ **中英文支持** - 针对中英文分别优化摘要算法
- ✅ **可配置** - 支持自定义显示长度和格式
- ✅ **轻量级** - 纯 Python 实现，无外部依赖

## 安装方法

### 方式一：自动安装（推荐）

```bash
# 1. 克隆或下载此仓库
git clone https://github.com/MrSong9957/sry-skills.git
cd sry-skills/claude-code-statusline-plugin

# 2. 运行安装脚本
chmod +x install.sh
./install.sh
```

### 方式二：手动安装

```bash
# 1. 创建插件目录
mkdir -p ~/.claude/plugins/custom/show-last-prompt/statusline

# 2. 复制脚本文件
cp show-prompt.py ~/.claude/plugins/custom/show-last-prompt/statusline/
chmod +x ~/.claude/plugins/custom/show-last-prompt/statusline/show-prompt.py

# 3. 修改 ~/.claude/settings.json，添加以下内容：
{
  "statusLine": {
    "type": "command",
    "command": "python3 ~/.claude/plugins/custom/show-last-prompt/statusline/show-prompt.py"
  }
}
```

## 配置选项

编辑 `show-prompt.py` 文件顶部的配置参数：

```python
# 中文显示字数限制（默认: 15）
CHINESE_MAX_LENGTH = 15

# 英文显示单词数限制（默认: 10）
ENGLISH_MAX_WORDS = 10

# 状态栏显示格式（默认: "[最新指令:{summary}]"）
STATUS_FORMAT = "[最新指令:{summary}]"
```

## 智能摘要规则

### 中文输入

| 原始输入 | 摘要结果 |
|---------|---------|
| "好的，请帮我创建一个 Django 项目" | "创建一个 Django 项目..." |
| "但是，我要你修改一下配置" | "修改一下配置..." |
| "现在开始写测试用例" | "写测试用例..." |

### 英文输入

| 原始输入 | 摘要结果 |
|---------|---------|
| "Please help me create a React app" | "create a React app..." |
| "Could you please fix the bug" | "fix the bug..." |

## 卸载方法

```bash
# 运行卸载脚本
./install.sh --uninstall

# 或手动删除
rm -rf ~/.claude/plugins/custom/show-last-prompt
# 然后编辑 ~/.claude/settings.json 移除 statusLine 配置
```

## 工作原理

1. Claude Code 在每次状态栏刷新时，将上下文信息通过 stdin 传递给脚本
2. 脚本从传入的 JSON 中获取 `transcript_path`（会话记录文件路径）
3. 读取会话文件，解析 JSONL 格式，找到最新的用户消息
4. 应用智能摘要规则，提取关键信息
5. 输出格式化结果到 stdout，显示在状态栏

## 系统要求

- Python 3.6+
- Claude Code 2.0+

## 故障排除

**状态栏显示为空 `[]`？**
- 检查是否有最近的用户输入（工具返回结果会被跳过）
- 确认脚本路径在 settings.json 中正确配置

**状态栏没有更新？**
- 重启 Claude Code
- 检查 Python 3 是否可用：`python3 --version`

## 许可证

MIT License

## 作者

[MrSong9957](https://github.com/MrSong9957)
