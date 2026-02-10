# Claude Code Skills Collection

一个精心策划的 Claude Code 技能、代理和命令集合，涵盖现代软件开发的各个领域。

## 📋 概述

本仓库包含了一套完整的 Claude Code 技能系统，旨在提升 AI 辅助编程的效率和质量。涵盖了从架构设计到代码实现、从测试到部署的全流程最佳实践。

## 🎯 核心特性

- **30+ 专业技能** - 涵盖后端、前端、数据库、测试、安全等领域
- **13+ 智能代理** - 自动化代码审查、测试生成、架构设计等任务
- **20+ 自定义命令** - 简化常见工作流程
- **编码规范** - 统一的代码风格和最佳实践指南
- **自动化钩子** - Git 钩子和工具钩子，确保代码质量
- **MCP 集成** - Model Context Protocol 服务器配置
- **实用插件** - 增强 Claude Code 用户体验的工具

## 🧩 实用插件

### Claude Code 状态栏插件 (v2.3.0)

一个智能的状态栏增强插件，使用 Claude Code 配置的 AI 自动提取并显示用户最新指令的摘要。

**核心功能：**
- 🤖 **AI 智能提取** - 使用 Claude Code 理解用户意图
- 📝 **规则提取后备** - 离线模式，无网络延迟
- 🌏 **中英文支持** - 针对不同语言优化
- ⚡ **智能缓存** - 避免执行过程中状态栏频繁变化
- 🔒 **安全可靠** - 路径验证、输入限制、SHA-256 缓存

**使用场景：**

**实际终端效果：**
```
有什么我可以帮你的吗？

──────────────────────────────────────────────────────────────────────────────────────
❯
──────────────────────────────────────────────────────────────────────────────────────
  [最新指令:模型身份查询]
  ⏵⏵ bypass permissions on (shift+tab to cycle)
```

**更多示例：**
```
输入: "遵循规则：创建 agent teams。完成任务：按照建议修复"
显示: [最新指令:按照建议修复]

输入: "请帮我创建一个Django项目"
显示: [最新指令:创建Django项目...]
```

**快速安装：**
```bash
# Windows PowerShell
cd claude-code-statusline-plugin
.\install.ps1

# macOS/Linux
cd claude-code-statusline-plugin
chmod +x install.sh && ./install.sh
```

**仓库地址:** [claude-code-statusline-plugin](https://github.com/MrSong9957/claude-code-statusline-plugin)

## 📁 目录结构

```
.
├── .claude/
│   ├── skills/           # 技能定义
│   ├── agents/           # 代理配置
│   ├── commands/         # 自定义命令
│   ├── rules/            # 编码规范
│   ├── hooks/            # 自动化钩子
│   ├── contexts/         # 上下文配置
│   ├── mcp-configs/      # MCP 服务器配置
│   ├── scripts/          # 实用脚本
│   └── tests/            # 测试文件
├── claude-code-statusline-plugin/  # Claude Code 状态栏插件
│   ├── statusline/
│   │   └── show-prompt.py         # 主插件脚本
│   ├── install.ps1                # Windows 安装脚本
│   ├── install.sh                 # Unix/macOS 安装脚本
│   └── README.md                  # 插件文档
└── README.md
```

## 🚀 技能分类

### 核心工作流

| 技能 | 描述 |
|------|------|
| `brainstorming` | 在实施前探究用户意图、需求和设计 |
| `tdd-workflow` | 测试驱动开发工作流程（80%+ 覆盖率） |
| `systematic-debugging` | 结构化调试方法论 |
| `code-simplifier` | 代码简化和优化 |
| `security-review` | 安全审查最佳实践 |
| `coding-standards` | 通用编码标准和规范 |

### 后端开发

| 技能 | 描述 |
|------|------|
| `backend-patterns` | Node.js、Express、Next.js API 后端架构模式 |
| `django-patterns` | Django 架构模式和 DRF API 设计 |
| `django-security` | Django 安全最佳实践 |
| `django-tdd` | Django 测试策略（pytest-django） |
| `springboot-patterns` | Spring Boot 架构和 REST API 设计 |
| `springboot-security` | Spring Security 配置和最佳实践 |
| `springboot-tdd` | Spring Boot TDD 工作流程 |

### 前端开发

| 技能 | 描述 |
|------|------|
| `frontend-patterns` | React、Next.js、状态管理和 UI 最佳实践 |
| `ui-ux-pro-max` | 50+ 设计风格、21 套配色方案、9 大技术栈 |

### 数据库

| 技能 | 描述 |
|------|------|
| `postgres-patterns` | PostgreSQL 查询优化、架构设计、索引 |
| `jpa-patterns` | JPA/Hibernate 实体设计、关系、事务 |
| `clickhouse-io` | ClickHouse 分析型数据库最佳实践 |

### 编程语言

| 技能 | 描述 |
|------|------|
| `python-patterns` | Pythonic 习惯用法、PEP 8、类型提示 |
| `python-testing` | pytest、TDD、fixtures、mocking |
| `golang-patterns` | 地道 Go 模式和最佳实践 |
| `golang-testing` | Go 表驱动测试、基准测试、模糊测试 |
| `java-coding-standards` | Java 编码标准和规范 |

### 高级功能

| 技能 | 描述 |
|------|------|
| `continuous-learning` | 从会话中提取可重用模式并保存为技能 |
| `continuous-learning-v2` | 基于本能的学习系统 |
| `iterative-retrieval` | 逐步改进上下文检索的模式 |
| `eval-harness` | 会话的正式评估框架 |
| `strategic-compact` | 智能上下文压缩策略 |

### Docker

| 技能 | 描述 |
|------|------|
| `docker-claude-code` | 为 Claude Code CLI 创建隔离、持久的 Docker 环境（多用户支持、API 代理配置） |
| `docker-dev-home-claude-code` | Docker 开发环境配置和管理 |

## 🤖 智能代理

### 开发代理

| 代理 | 用途 |
|------|------|
| `planner` | 实施规划 |
| `architect` | 系统设计 |
| `tdd-guide` | 测试驱动开发指导 |
| `code-reviewer` | 代码审查 |
| `security-reviewer` | 安全分析 |
| `build-error-resolver` | 构建错误修复 |
| `e2e-runner` | E2E 测试 |
| `refactor-cleaner` | 死代码清理 |
| `doc-updater` | 文档更新 |

### 专项代理

| 代理 | 用途 |
|------|------|
| `database-reviewer` | PostgreSQL 数据库审查 |
| `go-build-resolver` | Go 构建错误修复 |
| `go-reviewer` | Go 代码审查 |
| `python-reviewer` | Python 代码审查 |

## 🛠️ 自定义命令

### 代码质量

- `/code-review` - 全面的代码审查
- `/tdd` - 强制 TDD 工作流程
- `/python-review` - Python 代码审查
- `/go-review` - Go 代码审查

### 工作流程

- `/plan` - 创建实施计划
- `/orchestrate` - 编排复杂任务
- `/verify` - 验证实施
- `/checkpoint` - 创建检查点

### 测试

- `/e2e` - 生成并运行 Playwright E2E 测试
- `/test-coverage` - 检查测试覆盖率
- `/go-test` - Go TDD 工作流程

### 构建和修复

- `/go-build` - 修复 Go 构建错误
- `/build-fix` - 通用构建修复
- `/refactor-clean` - 清理死代码

### 学习和进化

- `/learn` - 提取可重用模式
- `/evolve` - 将本能聚合成技能
- `/instinct-status` - 显示已学习的本能
- `/instinct-export` - 导出本能
- `/instinct-import` - 导入本能

### 评估

- `/eval` - 运行评估框架
- `/skill-create` - 从 git 历史生成技能

## 📚 编码规范

项目包含以下编码规范文件：

- **[agents.md](.claude/rules/agents.md)** - 代理编排指南
- **[coding-style.md](.claude/rules/coding-style.md)** - 代码风格指南
- **[git-workflow.md](.claude/rules/git-workflow.md)** - Git 工作流程
- **[hooks.md](.claude/rules/hooks.md)** - 钩子系统说明
- **[patterns.md](.claude/rules/patterns.md)** - 通用开发模式
- **[performance.md](.claude/rules/performance.md)** - 性能优化指南
- **[security.md](.claude/rules/security.md)** - 安全指南
- **[testing.md](.claude/rules/testing.md)** - 测试要求

## 🔧 安装

### Claude Code 状态栏插件

1. 进入插件目录：
   ```bash
   cd claude-code-statusline-plugin
   ```

2. 根据系统选择安装方式：

   **Windows (PowerShell):**
   ```powershell
   .\install.ps1
   ```

   **macOS/Linux:**
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

3. 重启 Claude Code，状态栏将显示您的最新指令摘要

### 方法 1: 克隆仓库

```bash
git clone https://github.com/MrSong9957/sry-claude-code.git
cd sry-claude-code
```

### 方法 2: 复制到现有项目

将 `.claude` 目录复制到你的项目根目录：

```bash
cp -r /path/to/sry-claude-code/.claude /path/to/your/project/
```

## 📖 使用方法

### 使用技能

技能会在对话中自动触发，也可以显式调用：

```
使用 backend-patterns 技能设计一个 REST API
```

### 使用代理

代理会根据任务复杂度自动启动，或通过 `/plan` 等命令触发：

```
/plan
```

### 使用命令

直接在 Claude Code 中输入命令：

```
/code-review
/tdd
/learn
```

## 🤝 贡献指南

欢迎贡献！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingSkill`)
3. 提交更改 (`git commit -m 'feat: add amazing skill'`)
4. 推送到分支 (`git push origin feature/AmazingSkill`)
5. 创建 Pull Request

### 添加新技能

1. 在 `.claude/skills/` 下创建新目录
2. 创建 `SKILL.md` 文件，包含：
   ```yaml
   ---
   name: your-skill-name
   description: Brief description
   ---
   ```
3. 添加示例和文档
4. 更新本 README

## 📝 技能模板

创建新技能时使用此模板：

```yaml
---
name: skill-name
description: Clear, concise description of what this skill does
---

# Skill Name

Brief introduction to the skill.

## When to Use

- Use case 1
- Use case 2

## Key Patterns

### Pattern 1

```typescript
// Example code
```

## Best Practices

1. Practice 1
2. Practice 2

## Examples

See [examples/](examples/) directory for detailed examples.
```

## 🔍 相关资源

- [Claude Code Documentation](https://github.com/anthropics/claude-code)
- [Claude Agent SDK](https://github.com/anthropics/claude-agent-sdk)
- [MCP Protocol](https://modelcontextprotocol.io/)

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

感谢 Anthropic 团队开发的 Claude Code 工具，以及所有贡献者的支持。

---

**注意**: 本仓库处于活跃开发中，技能和代理会持续更新。建议定期拉取最新更改。
