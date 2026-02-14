# Claude Code 状态栏插件 (AI 智能版)

在 Claude Code 的状态栏中实时显示用户最新输入的简化版本，**使用 Claude AI 智能提取任务摘要**，真正理解用户意图。

## 快速开始

> ⚠️ **在终端中执行，不要双击文件！**
> 💡 **Windows 用户推荐使用 PowerShell**

**Windows 用户（PowerShell）：**
```powershell
# 注意：执行 .ps1 文件，不是 .sh 文件！
cd E:\Files\PycharmProjects\GitHub\sry-skills\claude-code-statusline-plugin
.\install.ps1
```

**macOS/Linux 用户：**
```bash
cd ~/sry-skills/claude-code-statusline-plugin
chmod +x install.sh
./install.sh
```

看到 `[INFO] Installation completed!` 即表示成功，重启 Claude Code 即可使用。

## 效果展示

### 终端实际效果

```
有什么我可以帮你的吗？

──────────────────────────────────────────────────────────────────────────────────────
❯
──────────────────────────────────────────────────────────────────────────────────────
  [最新指令:模型身份查询]
  ⏵⏵ bypass permissions on (shift+tab to cycle)
```

### 功能演示

**场景 1: 从复杂输入中提取真正任务**
```
用户输入: "遵循规则：创建 agent teams。完成任务：按照建议修复"
状态栏显示: [最新指令:按照建议修复]
         ↑ AI 自动识别真正的任务部分
```

**场景 2: 简单问答**
```
用户输入: "有什么我可以帮你的吗？"
状态栏显示: [最新指令:模型身份查询]
         ↑ AI 理解用户意图并简化
```

**场景 3: 任务请求**
```
用户输入: "请帮我创建一个Django项目，包含用户认证功能"
状态栏显示: [最新指令:创建Django项目...]
         ↑ 自动提取核心任务
```

## 功能特性

- ✅ **AI 智能提取** - 使用 Claude AI 理解用户输入的真正意图
- ✅ **实时更新** - 每次用户输入后自动更新状态栏
- ✅ **智能摘要** - 自动去除规则、要求等非任务内容
- ✅ **混合模式** - AI 优先，规则提取作为后备（无延迟）
- ✅ **中英文支持** - 针对中英文分别优化
- ✅ **可配置** - 支持自定义显示长度和格式
- ✅ **轻量级** - 纯 Python 实现，无外部依赖

## 系统要求

- Python 3.6+
- Claude Code 2.0+

## 安装方法

> ⚠️ **重要提示**：请在终端中执行安装脚本，不要直接双击文件！
> 💡 **文件扩展名说明**：
> - `.ps1` = PowerShell 脚本（Windows）
> - `.sh` = Bash 脚本（macOS/Linux / Git Bash）

### Windows 系统

**方法 1：使用 PowerShell（推荐）**

1. 打开 PowerShell（Win+X → "Windows PowerShell"）
2. 进入项目目录：
   ```powershell
   cd E:\Files\PycharmProjects\GitHub\sry-skills\claude-code-statusline-plugin
   ```
3. 执行安装脚本：
   ```powershell
   .\install.ps1
   ```

> ❌ **不要执行**：`.\install.sh`（PowerShell 不能运行 .sh 文件）

**预期输出：**
```
[INFO] Detected Python: python
[INFO] Installing show-last-prompt plugin...
[INFO] Version: 2.3.0

[INFO] Creating plugin directories...
[INFO] Copying plugin files...
[INFO] Files installed to: C:\Users\你的用户名\.claude\plugins\custom\show-last-prompt
[INFO] Configuring settings.json...
[INFO] Backed up settings.json to: C:\Users\你的用户名\.claude\settings.json.backup.xxxxxx
[INFO] settings.json updated

[INFO] ========================================
[INFO] Installation completed!
[INFO] ========================================
[INFO] Please restart Claude Code
```

**方法 2：使用 Git Bash**

1. 在项目文件夹中右键 → "Git Bash Here"
2. 执行安装脚本：
   ```bash
   ./install.sh
   ```

**方法 3：手动安装**

```powershell
# 1. 创建插件目录
mkdir $env:USERPROFILE\.claude\plugins\custom\show-last-prompt\statusline -Force

# 2. 复制脚本文件
copy statusline\show-prompt.py $env:USERPROFILE\.claude\plugins\custom\show-last-prompt\statusline\

# 3. 编辑配置文件 $env:USERPROFILE\.claude\settings.json，添加以下内容
# 注意：Windows 路径中的反斜杠在 JSON 中需要转义或使用正斜杠
# Windows 系统使用 "python" 命令（不是 python3）
```

### Linux / macOS 系统

**方式一：自动安装（推荐）**

1. 打开终端
2. 进入项目目录：
   ```bash
   cd ~/sry-skills/claude-code-statusline-plugin
   ```
3. 执行安装脚本：
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

**预期输出：**
```
[INFO] 检测到 Python: python3
[INFO] 创建插件目录...
[INFO] 复制插件文件...
[INFO] 文件已安装到: /home/你的用户名/.claude/plugins/custom/show-last-prompt
[INFO] 使用 jq 合并配置...
[INFO] settings.json 已更新
[INFO] ========================================
[INFO] 安装完成！
[INFO] ========================================
[INFO] 请重启 Claude Code 以使插件生效
```

**方式二：手动安装**

```bash
# 1. 创建插件目录
mkdir -p ~/.claude/plugins/custom/show-last-prompt/statusline

# 2. 复制脚本文件（注意路径：statusline/show-prompt.py）
cp statusline/show-prompt.py ~/.claude/plugins/custom/show-last-prompt/statusline/
chmod +x ~/.claude/plugins/custom/show-last-prompt/statusline/show-prompt.py

# 3. 修改 ~/.claude/settings.json，添加以下内容：
# 注意：Unix 系统使用 python3 命令
{
  "statusLine": {
    "type": "command",
    "command": "python3 ~/.claude/plugins/custom/show-last-prompt/statusline/show-prompt.py"
  }
}
```

### 验证安装

安装完成后，可以验证插件是否正确安装：

**Windows PowerShell：**
```powershell
# 检查插件文件是否存在
Test-Path "$env:USERPROFILE\.claude\plugins\custom\show-last-prompt\statusline\show-prompt.py"

# 查看配置文件
Get-Content "$env:USERPROFILE\.claude\settings.json" | ConvertFrom-Json | Select-Object -ExpandProperty statusLine
```

**Linux / macOS：**
```bash
# 检查插件文件是否存在
ls -l ~/.claude/plugins/custom/show-last-prompt/statusline/show-prompt.py

# 查看配置文件
cat ~/.claude/settings.json | grep -A 3 statusLine
```

**预期结果：**
- 插件文件存在且可执行
- settings.json 中包含 statusLine 配置

## 配置选项

编辑 `show-prompt.py` 文件顶部的配置参数：

```python
# 中文显示字数限制（默认: 15）
CHINESE_MAX_LENGTH = 15

# 英文显示单词数限制（默认: 10）
ENGLISH_MAX_WORDS = 10

# 状态栏显示格式（默认: "[最新指令:{summary}]"）
STATUS_FORMAT = "[最新指令:{summary}]"

# 是否启用 AI 摘要（默认: true）
# 设为 false 则只使用规则提取，无网络延迟
ENABLE_AI_SUMMARY = True
```

### AI 模式说明

- **启用 AI**（默认）：使用 Claude Code 已有的 API 配置调用 Claude Haiku 进行智能提取，准确率高
- **禁用 AI**：只使用规则提取，完全离线，无延迟
- **自动回退**：AI 调用失败时自动切换到规则提取，确保状态栏始终可用

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

### Windows 系统

在 PowerShell 中执行：

```powershell
cd e:\Files\PycharmProjects\GitHub\sry-skills\claude-code-statusline-plugin
.\install.ps1 -Uninstall
```

**预期输出：**
```
[INFO] Uninstalling plugin...
[INFO] Removed statusLine from settings.json
[INFO] Deleted plugin directory
[INFO] Uninstallation completed
```

或手动删除：
```powershell
Remove-Item -Recurse -Force $env:USERPROFILE\.claude\plugins\custom\show-last-prompt
# 然后编辑 $env:USERPROFILE\.claude\settings.json 移除 statusLine 配置
```

### Linux / macOS 系统

```bash
cd ~/sry-skills/claude-code-statusline-plugin
./install.sh --uninstall
```

**预期输出：**
```
[INFO] Uninstalling plugin...
[INFO] Removed statusLine from settings.json
[INFO] Deleted plugin directory
[INFO] Uninstallation completed
```

或手动删除：
```bash
rm -rf ~/.claude/plugins/custom/show-last-prompt
# 然后编辑 ~/.claude/settings.json 移除 statusLine 配置
```

## 工作原理

1. Claude Code 在每次状态栏刷新时，将上下文信息通过 stdin 传递给脚本
2. 脚本从传入的 JSON 中获取 `transcript_path`（会话记录文件路径）
3. 读取会话文件，解析 JSONL 格式，找到最新的用户消息
4. 应用智能摘要规则，提取关键信息
5. 输出格式化结果到 stdout，显示在状态栏

## 故障排除

### 安装相关问题

**Q: 在 PowerShell 中执行 `.\install.sh` 没有任何反应？**
- **原因**：PowerShell 不能直接执行 `.sh` 文件（Bash 脚本）
- **解决**：在 PowerShell 中应该执行 `.\install.ps1`，或者使用 Git Bash 执行 `./install.sh`

**Q: 双击 .sh 或 .ps1 文件弹出"选择打开方式"对话框？**
- **原因**：这些是脚本文件，需要在终端中执行，不能直接双击
- **解决**：按照上方"快速开始"的说明，在终端（PowerShell 或 Git Bash）中执行命令

**Q: PowerShell 提示"无法加载文件，因为在此系统上禁止运行脚本"？**
- **原因**：Windows 默认禁止运行 PowerShell 脚本
- **解决**：以管理员身份运行 PowerShell，执行：
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```
  然后重新运行安装脚本

**Q: 提示"未找到 Python 3"？**
- **原因**：系统未安装 Python 或未添加到 PATH
- **解决**：
  - Windows：从 [python.org](https://www.python.org/downloads/) 下载安装
  - macOS：`brew install python3`
  - Linux：`sudo apt install python3` 或 `sudo yum install python3`

**Q: Git Bash 提示"command not found: python3"？**
- **原因**：Windows 上 Python 可能只注册为 `python` 命令
- **解决**：安装脚本会自动检测 `python3` 或 `python`，确保 Python 已正确安装

### 使用相关问题

**Q: 状态栏显示为空 `[]`？**
- 检查是否有最近的用户输入（工具返回结果会被跳过）
- 确认脚本路径在 settings.json 中正确配置
- 在终端中测试脚本是否可执行：
  ```bash
  # Windows
  python "$env:USERPROFILE\.claude\plugins\custom\show-last-prompt\statusline\show-prompt.py"

  # Linux/macOS
  python3 ~/.claude/plugins/custom/show-last-prompt/statusline/show-prompt.py
  ```

**Q: 状态栏没有更新？**
- 重启 Claude Code
- 检查 Python 是否可用：
  ```bash
  python --version   # 或 python3 --version
  ```
- 检查 settings.json 中 statusLine 配置是否正确

**Q: 安装脚本执行但没有提示"安装完成"？**
- 检查是否有错误信息（红色文字）
- 确认有足够的文件系统权限
- Windows 用户尝试以管理员身份运行终端

## 开发与测试

### 虚拟环境设置

项目使用 Python 虚拟环境来管理开发依赖：

**激活虚拟环境：**
```bash
# Windows PowerShell
cd E:\Files\PycharmProjects\GitHub\sry-skills
.\.venv\Scripts\Activate.ps1

# Linux/macOS
cd ~/sry-skills
source .venv/bin/activate
```

**安装开发依赖：**
```bash
pip install -r requirements-dev.txt
```

### 运行测试

项目使用 pytest 进行测试：

```bash
# 运行所有测试
pytest

# 运行单个测试文件
pytest tests/test_show_prompt.py

# 查看详细输出
pytest -v

# 查看测试覆盖率
pytest --cov=statusline --cov-report=html
```

### 验证修复

运行验证脚本检查所有代码修复：

```bash
python verify_fixes.py
```

该脚本会验证：
- ✅ 版本号一致性
- ✅ API 模型更新
- ✅ 安全修复（SHA-256、路径验证）
- ✅ 配置选项
- ✅ 日志记录功能
- ✅ .gitignore 规则

### 测试文件结构

```
claude-code-statusline-plugin/
├── tests/
│   ├── test_show_prompt.py    # 主要测试套件
│   └── __init__.py
├── pytest.ini                 # pytest 配置
└── verify_fixes.py            # 快速验证脚本
```

## 许可证

MIT License

## 作者

[MrSong9957](https://github.com/MrSong9957)
