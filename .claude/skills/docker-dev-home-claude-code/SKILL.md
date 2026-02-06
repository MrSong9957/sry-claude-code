---
name: docker-dev-home-claude-code
description: Initialize Docker container environment with persistent dev-home for Claude Code CLI. Supports multi-project sharing and state persistence across container restarts.
---

# Docker Dev-Home + Claude Code 环境配置

自动初始化包含 Claude Code CLI 的完整 Docker 容器环境,支持持久化 dev-home 和多项目共享。

## 使用方法

```
/docker-dev-home-claude-code [project-type] [dev-home-path]
```

### 参数说明

- **project-type** (可选): 项目类型,默认为 `generic`
- **dev-home-path** (可选): dev-home 路径,默认为 `./dev-home`
  - 使用相对路径实现多项目共享: `../dev-home`
  - 使用绝对路径自定义位置: `/path/to/dev-home`

### 支持的项目类型

| 类型 | 描述 | Docker 基础镜像 |
|------|------|-----------------|
| `claude` | Claude Code CLI 专用环境（推荐） | node:20-alpine |
| `python` | Python + Claude Code CLI | python:3.11-slim |
| `node` | Node.js + Claude Code CLI | node:20-alpine |
| `go` | Go + Claude Code CLI | golang:1.21-alpine |
| `java` | Java + Claude Code CLI | eclipse-temurin:21-jre-alpine |
| `generic` | 通用环境 + Claude Code CLI | alpine:latest |

## 核心特性

### 1. 持久化 Dev-Home

容器内的 `/home/claude` 目录挂载到宿主机的 `dev-home/claude` 目录,实现:

- **配置持久化**: Claude Code CLI 配置和状态在容器重启后保留
- **缓存保留**: 避免每次重启都重新下载依赖
- **数据安全**: 所有重要数据存储在宿主机,不会因容器删除而丢失

### 2. 多项目共享

多个项目可以共享同一个 dev-home 目录:

```bash
# 在父目录创建共享 dev-home
cd ~/PycharmProjects
mkdir dev-home

# 在每个项目中使用相对路径
cd project-a
/docker-dev-home-claude-code python ../dev-home

cd ../project-b
/docker-dev-home-claude-code node ../dev-home
```

**优势**:
- 共享 Claude Code 认证状态
- 共享配置和偏好设置
- 减少磁盘占用

### 3. 灵活的路径配置

通过 `.env` 文件中的 `DEV_HOME_PATH` 环境变量自定义路径:

```bash
# 默认: 项目独立的 dev-home
DEV_HOME_PATH=./dev-home

# 多项目共享: 相对路径
DEV_HOME_PATH=../dev-home

# 自定义位置: 绝对路径
DEV_HOME_PATH=/path/to/shared/dev-home
```

## 执行流程

### 步骤 1: 环境检查

检查 Docker 服务是否安装并运行:
- Linux/Mac: 检查 Docker daemon 状态
- Windows: 检查 Docker Desktop 服务状态

### 步骤 2: 配置生成

根据项目类型和 dev-home 路径生成以下文件:

1. **Dockerfile** - 包含 Claude Code CLI 安装
2. **docker-compose.yml** - 包含 dev-home 卷挂载配置
3. **.dockerignore** - 排除不必要的文件
4. **.env.example** - API Key 和 dev-home 路径配置示例
5. **dev-home/** - 持久化目录结构
   - `claude/.config/` - 配置文件
   - `claude/.cache/` - 缓存数据
   - `claude/.local/` - 本地数据
   - `config/` - Claude Code 配置
   - `logs/` - 日志文件
   - `README.md` - 使用说明

### 步骤 3: 构建容器

- 构建包含 Claude Code CLI 的 Docker 镜像
- 启动容器并配置 dev-home 卷挂载
- 验证 dev-home 挂载是否成功

### 步骤 4: 验证安装

- 验证容器运行状态
- 确认 Claude Code CLI 已安装
- 测试状态持久化功能

## 输出结果

成功完成后,你将获得:

```
✓ Docker 环境检查通过
✓ dev-home 目录结构已创建
  - dev-home/claude/.config/
  - dev-home/claude/.cache/
  - dev-home/claude/.local/
  - dev-home/config/
  - dev-home/logs/
  - dev-home/README.md
✓ 配置文件已生成
  - Dockerfile
  - docker-compose.yml
  - .dockerignore
  - .env.example
  - .env

✓ Docker 镜像构建完成
✓ 容器已启动
✓ dev-home 挂载验证成功

📦 容器名称: docker-claude-code-app
📌 端口映射: 8080:8000
👤 运行用户: claude (UID 1000, 非 root)
🏠 工作目录: /workspace
🔑 环境变量: ANTHROPIC_API_KEY 已配置

✓ Claude Code CLI 已安装
  版本: 2.x.x

🚀 下一步:
  1. 配置 API Key: 编辑 .env 文件添加你的密钥
  2. 进入容器: docker-compose exec app sh
  3. 启动 Claude: claude
```

## 环境变量配置

创建 `.env` 文件并添加:

```bash
# Anthropic API Key for Claude Code CLI
ANTHROPIC_API_KEY=your_api_key_here

# Anthropic Base URL (optional)
# ANTHROPIC_BASE_URL=http://host.docker.internal:15721

# Workspace path (optional, default: ./workspace)
WORKSPACE_PATH=./workspace

# Dev-home path (optional, default: ./dev-home)
DEV_HOME_PATH=./dev-home

# Claude config path (optional, default: ./dev-home/config)
CLAUDE_CONFIG_PATH=./dev-home/config

# Environment
ENV=development
```

## 容器使用命令

```bash
# 进入容器
docker-compose exec app sh

# 验证用户
whoami  # 输出: claude

# 验证工作目录
pwd  # 输出: /workspace

# 查看 Claude Code CLI 版本
docker-compose exec app claude --version

# 在容器内启动 Claude Code
docker-compose exec app claude

# 查看 dev-home 磁盘使用
du -sh dev-home/
```

## Dev-Home 管理

### 查看持久化状态

```bash
# 检查 dev-home 目录内容
ls -la dev-home/claude/

# 检查磁盘使用情况
du -sh dev-home/
du -sh dev-home/claude/*
```

### 备份 Dev-Home

```bash
# 创建时间戳备份
tar -czf dev-home-backup-$(date +%Y%m%d-%H%M%S).tar.gz dev-home/

# 使用 rsync 备份
rsync -av dev-home/ /path/to/backup/dev-home/
```

### 恢复 Dev-Home

```bash
# 解压备份
tar -xzf dev-home-backup-YYYYMMDD-HHMMSS.tar.gz

# 使用 rsync 恢复
rsync -av /path/to/backup/dev-home/ dev-home/
```

### 清理 Dev-Home

```bash
# 清理缓存(安全)
rm -rf dev-home/claude/.cache/*

# 清理日志(安全)
rm -rf dev-home/logs/*

# 清理所有数据(会重置 Claude Code 状态)
rm -rf dev-home/claude/*
```

**警告**: 删除 `dev-home/claude/.config/` 会重置所有 Claude Code 配置。

## 故障排查

### Docker 服务未运行

**错误**: Cannot connect to the Docker daemon

**解决**:
- Mac: 打开 Docker Desktop
- Linux: `sudo systemctl start docker`
- Windows: 启动 Docker Desktop

### Dev-Home 目录不存在

**错误**: dev-home 目录不存在: ./dev-home/root

**解决**:
```bash
# 重新运行配置生成脚本
python3 scripts/generate-config.py [project-type] [dev-home-path]
```

### 数据未持久化

**检查**:
1. 确认 `.env` 文件中 `DEV_HOME_PATH` 设置正确
2. 验证 `docker-compose.yml` volumes 部分包含 dev-home 挂载
3. 重启容器: `docker-compose restart`

### 文件权限问题(Linux/Mac)

**现象**: 宿主机上无法编辑 `dev-home/claude/` 中的文件

**原因**: 容器以 claude 用户运行,创建的文件属于 claude

**解决**:
```bash
# 获取文件所有权
sudo chown -R $USER:$USER dev-home/claude/

# 或使用特定用户/组
sudo chown -R 1000:1000 dev-home/claude/
```

### 磁盘空间不足

**检查**:
```bash
# 查看 dev-home 大小
du -sh dev-home/

# 查看最大目录
du -sh dev-home/claude/* | sort -hr
```

**解决**:
- 清理缓存: `rm -rf dev-home/claude/.cache/*`
- 清理日志: `rm -rf dev-home/logs/*`

## 技术细节

### Dockerfile 特性

- 使用最小化基础镜像 (Alpine Linux)
- 预装 Node.js（Claude Code CLI 依赖）
- 全局安装 @anthropic-ai/claude-code
- 创建非 root 用户 (claude, UID 1000)
- 配置工作目录为 /workspace
- 保持容器运行用于交互模式

### docker-compose.yml 特性

- 端口映射: 8080:8000
- 配置文件只读挂载: `.:/app:ro`（避免热重载扫描）
- 工作区可写挂载: `${WORKSPACE_PATH:-./workspace}:/workspace`
- **Dev-home 挂载**: `dev-home/claude` 到 `/home/claude`
- **配置持久化**: `dev-home/config` 到 `/home/claude/.config/claude`
- 环境变量注入: ANTHROPIC_API_KEY, ANTHROPIC_BASE_URL
- 交互模式支持: stdin_open 和 tty
- 工作目录: `/workspace`

### Dev-Home 目录结构

```
dev-home/
├── claude/            # 容器 /home/claude 挂载点
│   ├── .config/       # 配置文件
│   ├── .cache/        # 缓存数据
│   ├── .local/        # 本地数据
│   └── .ssh/          # SSH 密钥(如已生成)
├── config/            # Claude Code 配置
├── logs/              # 日志文件
├── .gitignore         # Git 忽略规则
└── README.md          # 使用说明
```

## 示例

### 创建独立的 Claude Code 项目

```bash
mkdir my-claude-project
cd my-claude-project
/docker-dev-home-claude-code claude
```

### 创建多项目共享 dev-home

```bash
# 1. 创建共享 dev-home
cd ~/PycharmProjects
mkdir dev-home

# 2. 在项目 A 中使用
cd project-a
/docker-dev-home-claude-code python ../dev-home

# 3. 在项目 B 中使用
cd ../project-b
/docker-dev-home-claude-code node ../dev-home
```

### 使用自定义 dev-home 路径

```bash
mkdir my-custom-project
cd my-custom-project
/docker-dev-home-claude-code go /opt/shared/dev-home
```

## 注意事项

- 确保在项目根目录运行此技能
- Windows 用户需要 PowerShell 5.1 或更高版本
- Linux/Mac 用户需要 Bash 4.0 或更高版本
- 首次运行需要下载 Docker 镜像,可能需要几分钟
- 建议配置 Docker 资源限制(内存建议 2GB+)
- 多项目共享 dev-home 时,避免同时运行容器(可能冲突)
- 定期备份 dev-home 目录以防数据丢失

## 迁移指南

如果从旧版 `docker-claude-setup` 迁移:

1. **备份现有数据**:
   ```bash
   # 备份 named volumes
   docker run --rm -v claude-config:/data -v $(pwd):/backup alpine tar -czf /backup/claude-config-backup.tar.gz -C /data .
   docker run --rm -v claude-cache:/data -v $(pwd):/backup alpine tar -czf /backup/claude-cache-backup.tar.gz -C /data .
   ```

2. **运行新技能生成配置**:
   ```bash
   /docker-dev-home-claude-code [project-type]
   ```

3. **恢复数据到 dev-home**:
   ```bash
   mkdir -p dev-home/root/.config
   mkdir -p dev-home/root/.cache
   tar -xzf claude-config-backup.tar.gz -C dev-home/root/.config/
   tar -xzf claude-cache-backup.tar.gz -C dev-home/root/.cache/
   ```

4. **删除旧 volumes** (可选):
   ```bash
   docker volume rm claude-config claude-cache
   ```
