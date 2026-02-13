# **Docker-Claude-Code 技能（完整版）**

## **项目概述**

这是一个为 **Claude Code CLI** 设计的 Docker 开发环境。它提供一个**独立、可持久化、极简实用**的容器，您可以在容器内使用 Claude Code CLI 完成整个项目的开发工作。

**核心特点：**
- ✅ 单容器，单卷挂载，结构清晰
- ✅ 支持新建项目和迁移已有项目
- ✅ 内置最新版 Claude Code CLI
- ✅ 配置自动持久化，无需手动管理
- ✅ 支持 root 和非 root 两种权限进入

---

## **1. 项目文件结构**

在您的宿主机上创建以下目录结构：

```
docker-claude-code/
├── .env                    # 环境变量配置
├── docker-compose.yml      # Docker 编排文件
├── Dockerfile              # 容器构建文件
├── dev-home/               # Claude 配置持久化目录（git ignored）
│   ├── config/             # CLI 配置（→ 容器内 ~/.config/claude）
│   └── claude/             # 用户数据（→ 容器内 /home/claude）
└── README.md               # 本文件（可选）

# ⚠️ **重要**：本项目采用**统一持久化模式**
# 项目文件、配置、数据通过 volume 持久化到宿主机 ./workspace/ 目录
# 容器删除后，所有文件安全保留在宿主机
# 可使用 backup-project.sh 额外备份到其他位置
```

---

## **2. 配置文件内容**

### **2.1 .env 文件**
```env
# Claude Code CLI Configuration
# dummy 表示沿用宿主机的 API KEY
ANTHROPIC_API_KEY=dummy

# 端口要与 CC Switch 本地代理端口一致
ANTHROPIC_BASE_URL=http://host.docker.internal:15721

# 注意：工作区在容器内 /workspace/project/，不需要配置路径
```

**说明：**
- `ANTHROPIC_API_KEY`：设置为 `dummy` 时，容器会尝试使用宿主机的环境变量。如果宿主机没有设置，需要替换为真实的 API Key。
- `ANTHROPIC_BASE_URL`：必须与您的 **Claude Code Switch** 本地代理端口一致（默认 15721）。

### **2.1.1 平台注意事项**

| 平台 | `host.docker.internal` 支持 | 额外配置 |
|------|---------------------------|---------|
| **Windows** (Docker Desktop) | ✅ 原生支持 | 无 |
| **macOS** (Docker Desktop) | ✅ 原生支持 | 无 |
| **Linux** | ⚠️ 不原生支持 | 已通过 `extra_hosts` 配置兼容 |

**Linux 用户说明**：
- 文档中的 `docker-compose.yml` 已包含 `extra_hosts: "host.docker.internal:host-gateway"` 配置
- 此配置在 Windows/macOS 上会被自动忽略，不影响使用
- 如果仍无法连接，可使用宿主机 IP 替代：
  ```bash
  # 获取宿主机 IP
  hostname -I | awk '{print $1}'
  # 然后在 .env 中使用
  ANTHROPIC_BASE_URL=http://<宿主机IP>:15721
  ```

### **2.2 docker-compose.yml 文件**
```yaml
services:
  app:
    build: .
    container_name: docker-claude-code-app
    ports:
      # 容器内应用端口映射（如有 Web 服务需要）
      - "8080:8000"
    environment:
      - ENV=development
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL}
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
    stdin_open: true
    tty: true
    restart: unless-stopped
```

### **2.3 Dockerfile 文件**
```dockerfile
# syntax=docker/dockerfile:1
# ============================================
# Docker Claude Code - 容器化开发环境
# ============================================
# 基础镜像：使用 Node.js 20 LTS 版本（slim 变体足够轻量）
# 选择 node:20-slim 而非 alpine 的原因：
#   - 兼容性更好：slim 基于 Debian，与大多数 Node.js 应用兼容
#   - 调试工具：包含更多调试工具（如 bash、ping、curl）
#   - 稳定性：生产环境更常用 slim 而非 alpine
FROM node:20-slim

# ============================================
# 阶段 1：安装 Claude Code CLI
# ============================================
# 使用 npm 全局安装最新版本的 Claude Code CLI
# -g: 全局安装，使 claude 命令在容器任何位置都可用
RUN npm install -g @anthropic-ai/claude-code

# ============================================
# 阶段 2：创建非 root 用户（安全最佳实践）
# ============================================
# 为什么需要非 root 用户？
#   - 安全性：减少容器被攻击时的权限提升风险
#   - 开发规范：符合最小权限原则
#   - 文件管理：避免以 root 身份创建文件导致权限混乱
#
# 为什么选择 UID 1001 而非系统自动分配？
#   - 明确性：明确指定 UID 可以避免环境差异导致的不一致
#   - 避免冲突：node:20-slim 镜像中 node 用户 UID 通常是 1000
#               使用 1001 可以避免与现有用户冲突
#   - 可预测性：在多容器编排时，UID 一致性很重要
#
# 为什么配置 sudo NOPASSWD:ALL？
#   - 自主开发：Claude Code AI 需要能够自主执行需要权限的操作
#               （如安装包、修改系统文件等）
#   - 无人工干预：避免在 AI 开发过程中因为权限问题暂停等待输入
#   - 安全权衡：虽然是 NOPASSWD，但因为是在隔离容器内，风险可控
#   - 验收标准：满足"非 root 用户能自主完成所有开发任务"的要求
RUN groupadd -r claude && \
    useradd -r -u 1001 -g claude -G sudo -m -s /bin/bash claude && \
    echo "claude ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

# ============================================
# 阶段 3：创建工作区目录
# ============================================
# 为什么使用 /workspace/project？
#   - 明确性：更清晰地表明这是项目代码目录
#   - 扩展性：未来可以在 /workspace 下添加其他目录
#   - 与文档一致：与 docker-compose.yml 中的 working_dir 一致
#
# 为什么需要 chown？
#   - 确保非 root 用户（claude）对此目录有完全的读写权限
#   - 避免权限问题：防止以 root 创建的文件导致 claude 用户无法修改
RUN mkdir -p /workspace/project && \
    chown -R claude:claude /workspace

# ============================================
# 阶段 4：设置工作目录
# ============================================
# WORKDIR 指令的作用：
#   - 设置容器启动后的默认工作目录
#   - 与 docker-compose.yml 中的 working_dir 一致
WORKDIR /workspace/project

# ============================================
# 阶段 5：切换到非 root 用户
# ============================================
# 从此开始，所有命令都以 claude 用户身份执行
# 这是 Docker 安全最佳实践：尽可能使用非 root 用户运行应用
USER claude

# ============================================
# 阶段 6：默认启动命令
# ============================================
# 使用 bash 而非 sh 的原因：
#   - 功能更强大：支持数组、更丰富的字符串操作、更好的调试功能
#   - 开发体验：支持 tab 补全、命令历史、别名等
#   - 兼容性：大多数开发脚本和工具都基于 bash 编写
CMD ["bash"]
```

---

## **3. 使用指南**

### **3.1 初始化项目**

#### **场景一：新建项目**
```bash
# 1. 创建项目目录
mkdir -p docker-claude-code
cd docker-claude-code

# 2. 创建配置文件（.env, docker-compose.yml, Dockerfile）
# 3. 启动容器（项目文件会在容器内自动创建）
docker-compose up -d

# 3. 进入容器（默认非 root 用户）
docker-compose exec app sh

# 4. 在容器内，您已经在 /workspace/project 目录
#    可以直接开始使用 Claude Code CLI
claude "帮我创建一个简单的 Node.js Express 应用"
```

#### **场景二：迁移已有项目**
```bash
# 1. 创建项目目录
mkdir -p docker-claude-code
cd docker-claude-code

# 2. 创建配置文件并启动容器
docker-compose up -d

# 3. 将项目复制到容器内
docker cp /path/to/your/actual/project docker-claude-code-app:/workspace/

# 或使用容器内 git clone
docker-compose exec app sh
cd /workspace
git clone https://github.com/yourusername/yourproject.git project

# 4. 在容器内，您已经在 /workspace/project 目录
#    可以继续使用 Claude Code CLI 开发
claude "继续开发这个项目，实现 XX 功能"
```

**重要：文件所有权说明**
- ✅ 文件复制到容器后，由容器用户（claude）拥有
- ✅ 所有开发工作在容器内进行
- ⚠️ 原项目目录可以保留作为备份，但不在宿主机编辑
- ⚠️ 项目文件仅在容器内存在，宿主机无项目文件

### **3.2 进入容器的命令**

- **使用非 root 用户（推荐，更安全）**：
  ```bash
  docker-compose exec app sh
  ```
  进入后，您位于 `/workspace/project` 目录。

- **使用 root 用户（需要系统权限时）**：
  ```bash
  docker-compose exec --user root app sh
  ```
  进入后，您位于 `/workspace/project` 目录。

### **3.3 在容器内使用 Claude Code CLI**

1. 进入容器后，您已经在 `/workspace/project` 目录。
2. 直接运行 `claude` 命令：
   ```bash
   claude "帮我分析当前目录结构"
   ```
3. 配置已自动加载（通过环境变量），历史记录保存在 `/workspace/.claude`。

### **3.4 文件管理与持久化**

**重要架构说明：**
为避免权限冲突和环境隔离，本项目采用**完全容器化隔离模式**。

- **项目代码**：完全存储在容器内 `/workspace/project/`
  - ✅ 所有开发工作在容器内进行
  - ✅ 文件由容器用户拥有，无权限问题
  - ❌ 不在宿主机上编辑项目文件（避免权限冲突）
  - ❌ 不通过 volume 挂载项目目录

- **容器内编辑**：
  ```bash
  # 进入容器后，使用容器内编辑器
  docker-compose exec app sh
  vim /workspace/project/src/index.js  # 在容器内编辑
  ```

- **备份到宿主机**（定期备份建议）：
  ```bash
  # 使用专用的备份脚本（推荐）
  bash .claude/skills/docker-claude-code/scripts/backup-project.sh

  # 备份到指定目录
  bash .claude/skills/docker-claude-code/scripts/backup-project.sh ../my-backup
  ```

  **备份脚本功能：**
  - ✅ 自动检查容器运行状态
  - ✅ 创建带时间戳的备份目录
  - ✅ 统计备份文件数量
  - ✅ 完整的错误处理和提示

**为什么采用隔离模式？**
1. ✅ 避免宿主机-容器用户权限冲突（UID/GID 不匹配）
2. ✅ 确保容器内非 root 用户可以完全自主开发
3. ✅ 符合验收标准：文件只在容器中
4. ✅ 环境完全隔离，可随时重置

- **Claude 配置**：位于宿主机 `dev-home/`，通过 volume 持久化到容器 `/home/claude`
  - 容器重启后，配置和历史记录保留
  - 如需重置，删除 `dev-home/` 目录即可

### **3.5 停止与清理**

```bash
# 停止容器（保留容器，不删除）
docker-compose stop

# 停止并删除容器（保留数据卷）
docker-compose down

# 停止并删除容器及卷（**谨慎使用**，会删除 workspace 目录！）
docker-compose down -v
```

---

## **4. 目录结构详解**

### **dev-home/**（宿主机配置目录）
- **config/**：Claude Code CLI 的配置文件
  - 通过 volume 挂载到容器内 `~/.config/claude`
- **claude/**：用户数据目录
  - 通过 volume 挂载到容器内 `/home/claude`

### **容器内工作区**（不在宿主机）
- **/workspace/project/**：项目代码目录，仅在容器内存在
- **/home/claude/.claude/**：会话历史记录（通过 volume 持久化）

**为什么这样设计？**
1. **配置与项目分离**：配置通过 volume 持久化到宿主机 `dev-home/`，项目代码仅存储在容器内
2. **工作目录明确**：`working_dir` 直接指向 `/workspace/project`，进入容器即可开始工作
3. **权限隔离**：项目文件由容器用户（claude, UID 1001）拥有，避免宿主机-容器权限冲突
4. **环境纯净**：每次启动都是干净的开发环境，配置可随时重置（删除 `dev-home/`）
5. **备份策略**：
   - 配置备份：复制 `dev-home/` 目录
   - 项目备份：使用 `docker cp` 从容器导出

---

### **架构模式说明**

本项目采用**完全容器化隔离模式**，而非传统的 volume 挂载同步模式。

**对比：**

| 特性 | 同步模式（传统） | 隔离模式（本项目） |
|------|----------------|------------------|
| 文件位置 | 宿主机和容器同步 | 仅在容器内 |
| 宿主机编辑 | ✅ 支持 | ❌ 不推荐 |
| 权限问题 | ⚠️ 常见 | ✅ 无 |
| 环境隔离 | ❌ 弱 | ✅ 强 |
| 符合验收标准 | ❌ 否 | ✅ 是 |

**为什么选择隔离模式？**
1. **避免权限冲突**：宿主机用户（UID 1000）与容器用户（UID 1001）的文件所有权冲突
2. **自主开发**：容器内非 root 用户可完全自主操作，无需手动 chown
3. **环境纯净**：每次启动都是干净的开发环境
4. **验收合规**：符合"文件只在容器中"的验收标准

---

## **5. 常见问题与解决**

### **Q1: Claude Code CLI 无法连接到 API**
**检查：**
1. 确保 `ANTHROPIC_BASE_URL` 端口与宿主机的 Claude Code Switch 代理端口一致。
2. 在容器内检查环境变量：
   ```bash
   echo $ANTHROPIC_API_KEY
   echo $ANTHROPIC_BASE_URL
   ```
3. 如果使用 `dummy`，确保宿主机已设置 `ANTHROPIC_API_KEY` 环境变量。

### **Q2: 文件权限问题**
**解决：**
```bash
# 验证非 root 用户的 sudo 配置
docker-compose exec app sh -c 'sudo whoami'
# 应该返回 "root" 且不提示输入密码

# 如果提示密码，说明 Dockerfile 配置有问题
# 需要在 Dockerfile 中添加：
# RUN apk add --no-cache sudo
# RUN echo "claude ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers

# 然后重建镜像
docker-compose build
docker-compose up -d
```

**重要：** 非 root 用户必须配置 `NOPASSWD:ALL`，否则 Claude Code 无法自主执行需要提升权限的操作，违背了容器化开发的初衷。

### **Q3: 如何更新 Claude Code CLI？**
**解决：**
```bash
# 进入容器（非 root 用户，使用 sudo）
docker-compose exec app sh

# 使用官方推荐更新 CLI
sudo claude install

# 退出容器，重启
exit
docker-compose restart
```

**注意：** 由于配置了 sudo NOPASSWD:ALL，非 root 用户可以直接执行需要提升权限的操作。

### **Q4: 如何扩展容器功能（如安装其他工具）？**
**解决：**
在 `Dockerfile` 中添加安装命令，然后重建镜像：
```bash
# 修改 Dockerfile，添加工具安装
# 例如：RUN apk add --no-cache git curl

# 重建镜像
docker-compose build

# 重启服务
docker-compose up -d
```

---

## **6. 进阶配置**

### **6.1 自定义端口**
如果需要更改 Web 服务端口（例如容器内运行一个 Web 应用）：
1. 修改 `docker-compose.yml` 中的 `ports` 部分。
2. 确保容器内应用监听相应端口。

---

## **7. 最佳实践提示**

1. **版本控制**：在 `workspace/project` 中初始化 Git，跟踪项目代码。
2. **配置管理**：将重要的配置（如数据库连接）放在 `.env` 或环境变量中。
3. **定期备份**：定期备份整个 `workspace` 目录。
4. **清理历史**：定期清理 `workspace/.claude/history/` 中的旧会话文件。
5. **镜像构建**：如果需要在多个机器上使用，考虑将镜像推送到 Docker Registry。

---

## 8. 与 Claude Code 技能集成

### 8.1 技能自动激活

当您在使用 Claude Code CLI 时，`docker-claude-code` 技能会自动激活，如果：

- 您提到需要设置 Docker 环境
- 需要配置 API 代理（如 CC Switch）
- 需要跨平台支持（Windows/macOS/Linux）
- 需要多用户支持（root 和非 root）

### 8.2 Agent 编排

`docker-claude-code` 技能包含智能任务难度评估：

**简单任务**（单文件修改）
- 直接处理，无需启动其他 agent

**中等任务**（多个相关文件）
- 启动 3 个并行子代理：
  1. 配置验证器 - 验证 Docker 文件语法
  2. 平台专家 - 检查平台特定设置
  3. 连接性测试器 - 验证 API 代理连接

**复杂任务**（跨领域关注点）
- 创建 agent 团队：
  - migration-architect - 分析项目结构
  - docker-configurer - 创建 Dockerfile/docker-compose.yml
  - platform-specialist - 处理平台差异
  - test-validator - 验证容器功能

### 8.3 自动技能委托

`docker-claude-code` 技能会自动委托给相关技能：

- **tdd-workflow** → 测试 Docker 环境设置
- **verification-loop** → 验证容器功能
- **security-review** → 部署前审查容器安全
- **backend-patterns** → 设置容器化 API 服务

### 8.4 技能参考

快速参考和诊断流程图请参见：[docker-claude-code 技能](../.claude/skills/docker-claude-code/SKILL.md)

技能文件包含：
- 平台特定配置表格
- 诊断故障排除决策树
- Agent 编排逻辑
- 常见错误模式

---

## 9. 辅助脚本使用指南

### 9.1 脚本目录结构

`docker-claude-code` 技能包含一组辅助脚本，位于技能目录下的 `scripts/` 文件夹：

```
.claude/skills/docker-claude-code/
├── SKILL.md                    # 主要技能文件
├── scripts/                    # 辅助脚本
│   ├── detect-platform.sh       # 平台检测
│   ├── validate-config.sh       # 配置验证
│   ├── diagnose-docker.sh       # 诊断脚本
│   ├── init-docker-project.sh  # 项目初始化
│   └── README.md             # 脚本使用说明
└── ...
```

### 9.2 可用脚本

#### 1. 平台检测脚本 (detect-platform.sh)

**用途**：自动检测当前平台并提供推荐配置

**使用方法**：
```bash
cd .claude/skills/docker-claude-code
bash scripts/detect-platform.sh
```

**输出内容**：
- 平台检测表格（macOS/Linux/Windows）
- Docker Desktop 兼容性信息
- 推荐的 ANTHROPIC_BASE_URL 配置
- 平台特定操作项
- 导出 `DETECTED_PLATFORM` 环境变量供其他脚本使用

#### 2. 配置验证脚本 (validate-config.sh)

**用途**：验证 Docker 配置文件和平台兼容性

**使用方法**：
```bash
cd .claude/skills/docker-claude-code
bash scripts/validate-config.sh
```

**验证项目**：
- ✓ .env 文件存在
- ✓ docker-compose.yml 存在
- ✓ Dockerfile 存在
- ✓ ANTHROPIC_API_KEY 已设置
- ✓ ANTHROPIC_BASE_URL 已配置
- ✓ host.docker.internal 使用（平台特定）
- ✓ stdin_open 和 tty 已设置
- ✓ 卷挂载已配置
- ✓ 用户权限（多用户支持）

**退出代码**：
- `0` - 所有检查通过或仅有警告
- `1` - 发现错误（需要修复）

#### 3. 诊断脚本 (diagnose-docker.sh)

**用途**：使用故障排除决策树诊断 Docker 环境问题

**使用方法**：
```bash
cd .claude/skills/docker-claude-code
bash scripts/diagnose-docker.sh
```

**诊断流程**：
```
容器不工作？
│
├─→ API 连接失败？ → 检查 ANTHROPIC_BASE_URL
├─→ 权限被拒绝？ → 切换到 root 用户
├─→ 找不到主机？ → 验证平台特定配置
└─→ 配置不持久？ → 检查卷挂载
```

**执行检查**：
1. Docker 守护进程状态
2. 容器状态（运行/停止/存在）
3. 环境变量（API_KEY, BASE_URL）
4. API 代理连接性（从容器内测试）
5. 卷挂载（workspace 已挂载？）
6. 文件权限（写入测试）
7. Claude CLI 安装

**提供的快速修复**：
- 重启容器：`docker-compose restart`
- 重建镜像：`docker-compose build && docker-compose up -d`
- 查看日志：`docker-compose logs -f`
- 以 root 身份进入：`docker-compose exec -u root app bash`

#### 4. 项目初始化脚本 (init-docker-project.sh)

**用途**：初始化新项目或将现有项目迁移到 Docker 环境

**使用方法**：
```bash
cd .claude/skills/docker-claude-code
bash scripts/init-docker-project.sh
```

**交互式菜单**：
```
选择初始化场景：
1) 新项目（创建全新的 Docker 环境）
2) 迁移现有项目（复制现有代码到 Docker）
3) 退出
```

**创建内容**：
- 目录结构（workspace/project/）
- 配置文件（.env, docker-compose.yml, Dockerfile）
- .gitignore 文件（包含适当的排除项）
- 平台感知配置（为 Linux 自动添加 extra_hosts）

### 9.3 典型工作流

#### 新建项目

```bash
# 1. 初始化项目
cd .claude/skills/docker-claude-code
bash scripts/init-docker-project.sh
# 选择：1) 新项目

# 2. 查看并自定义 .env
vim .env  # 或您偏好的编辑器

# 3. 启动容器
docker-compose up -d

# 4. 验证配置（可选）
bash scripts/validate-config.sh

# 5. 进入容器并开始工作
docker-compose exec app sh
claude "帮我创建一个 Node.js Express 应用"
```

#### 迁移现有项目

```bash
# 1. 初始化项目
cd .claude/skills/docker-claude-code
bash scripts/init-docker-project.sh
# 选择：2) 迁移现有项目

# 2. 启动容器
docker-compose up -d

# 3. 验证设置（可选）
bash scripts/validate-config.sh

# 4. 诊断任何问题（如需要）
bash scripts/diagnose-docker.sh

# 5. 进入容器并继续开发
docker-compose exec app sh
claude "继续开发这个项目"
```

### 9.4 脚本集成说明

**快速参考**：完整的脚本文档请参见 [scripts/README.md](../.claude/skills/docker-claude-code/scripts/README.md)

**技能集成**：这些脚本设计为与主 `docker-claude-code` 技能协同工作：

1. **平台检测**：在设置前运行 `detect-platform.sh` 以了解平台需求
2. **验证**：在创建/修改配置文件后使用 `validate-config.sh`
3. **诊断**：故障排除时运行 `diagnose-docker.sh`
4. **初始化**：使用 `init-docker-project.sh` 进行快速项目脚手架

---

## 10. 验收标准

### 10.1 完整验收清单

使用 `docker-claude-code` 技能创建容器后，应该满足以下验收标准：

#### ✅ 标准 1：最简单的容器进入命令

**要求**：用户能够使用最简单的命令进入容器

**验证命令**：
```bash
docker-compose exec app sh
```

**预期结果**：
- ✅ 成功进入容器
- ✅ 工作目录为 `/workspace/project`
- ✅ 用户为 `claude`（UID 1001）
- ✅ 无任何错误信息

#### ✅ 标准 2：Claude Code 开箱即用

**要求**：容器启动后，Claude Code CLI 立即可用，无需额外配置

**验证命令**：
```bash
# 1. 启动容器
docker-compose up -d

# 2. 进入容器
docker-compose exec app sh

# 3. 测试 Claude CLI
claude --version
```

**预期结果**：
- ✅ Claude Code CLI 已安装
- ✅ 显示版本号（如 `claude-code version x.x.x`）
- ✅ API 代理配置正确（`ANTHROPIC_BASE_URL`）
- ✅ 无配置错误

**附加检查 - 状态栏插件**

**状态栏插件自动安装：**

使用 `init-docker-project.sh` 初始化项目时，脚本会自动安装状态栏插件：

1. 复制 `show-prompt.py` 到容器插件目录
2. 配置 `~/.claude/settings.json` 中的 `statusLine` 条目
3. 生成容器内安装脚本 `install.sh`

**插件功能：**
- AI 驱动的任务提取（使用 Claude Haiku）
- 离线规则回退支持
- 中文和英文任务摘要
- 状态栏显示：`[最新指令:创建Django项目...]`

**手动安装（如需要）：**
如果初始化时未自动安装，可手动执行：
```bash
docker-compose exec app sh
cd /workspace/project/.claude/plugins/custom/show-last-prompt/statusline
bash install.sh
```

```bash：
```bash
# 检查插件是否已注册
docker-compose exec app sh -c 'python3 -c "import json; print(json.load(open(\"~/.claude/settings.json\")).get(\"statusLine\", {}))"'
```

**预期结果**：
- ✅ `statusLine` 配置存在
- ✅ 指向 `show-prompt.py` 脚本
- ✅ 状态栏显示：`[最新指令:{summary}]`

#### ✅ 标准 3：容器实现持久化和实时更新

**要求**：容器重启后，配置和代码更改保持持久

**验证项目**：

**3.1 项目代码在容器内**：
```bash
# 1. 在容器内创建项目文件
docker-compose exec app sh -c "echo 'project content' > /workspace/project/test.txt"

# 2. 验证文件存在（仅容器内）
docker-compose exec app sh -c "cat /workspace/project/test.txt"
```

**预期结果**：
- ✅ 输出：`project content`
- ✅ 文件存储在容器内
- ⚠️ 注意：容器删除后文件会丢失（符合隔离模式设计）

**3.2 Claude 配置持久化**：
```bash
# 1. 设置 Claude 配置
docker-compose exec app sh -c "echo 'test-config' > ~/.claude/config/test.conf"

# 2. 重启容器
docker-compose restart

# 3. 检查配置是否持久
docker-compose exec app sh -c "cat ~/.claude/config/test.conf"
```

**预期结果**：
- ✅ 输出：`test-config`
- ✅ 配置在容器重启后仍然存在

**3.3 配置持久化到宿主机**：
```bash
# 1. 在容器内创建配置文件
docker-compose exec app sh -c "echo 'config-value' > ~/.claude/test-config.conf"

# 2. 在宿主机上验证配置已持久化
cat ./dev-home/claude/.claude/test-config.conf
```

**预期结果**：
- ✅ 配置文件已持久化到宿主机 `dev-home/` 目录
- ✅ 容器重启后配置仍然保留

#### ✅ 标准 4：无任何报错

**要求**：整个工作流程中无错误信息

**验证检查清单**：

**4.1 Docker 守护进程状态**：
```bash
docker info
```

**预期结果**：
- ✅ Docker 守护进程正在运行
- ✅ 无错误信息

**4.2 容器启动日志**：
```bash
docker-compose logs app
```

**预期结果**：
- ✅ 无 ERROR 级别日志
- ✅ 无 CRITICAL 级别日志
- ✅ 无异常堆栈跟踪

**4.3 API 连接测试**：
```bash
# 测试 API 代理连接
docker-compose exec app sh -c "curl -s -o /dev/null -w '%{http_code}' $ANTHROPIC_BASE_URL/v1/messages || echo 'failed'"
```

**预期结果**：
- ✅ 返回 `401`（需要认证）或 `200`（成功）
- ❌ 不是 `000`（连接失败）
- ❌ 不是 `ENOTFOUND`（主机未找到）

**4.4 环境变量验证**：
```bash
docker-compose exec app sh -c 'echo "API_KEY: $ANTHROPIC_API_KEY" && echo "BASE_URL: $ANTHROPIC_BASE_URL"'
```

**预期结果**：
- ✅ `ANTHROPIC_API_KEY=dummy`
- ✅ `ANTHROPIC_BASE_URL=http://host.docker.internal:15721`（或平台特定 URL）
- ✅ 无空值

### 10.2 快速验证脚本

运行以下脚本进行自动验证：

```bash
#!/bin/bash
# 快速验证脚本

echo "========================================="
echo "Docker Claude Code - 验收测试"
echo "========================================="
echo ""

PASS=0
FAIL=0

# 测试 1: 容器状态
echo "测试 1: 检查容器状态..."
if docker ps --format '{{.Names}}' | grep -q "docker-claude-code-app"; then
    echo "✓ PASS: 容器正在运行"
    PASS=$((PASS + 1))
else
    echo "✗ FAIL: 容器未运行"
    FAIL=$((FAIL + 1))
fi
echo ""

# 测试 2: 进入容器
echo "测试 2: 测试容器访问..."
if docker-compose exec app sh -c "echo 'container access OK'" >/dev/null 2>&1; then
    echo "✓ PASS: 可以进入容器"
    PASS=$((PASS + 1))
else
    echo "✗ FAIL: 无法进入容器"
    FAIL=$((FAIL + 1))
fi
echo ""

# 测试 3: Claude CLI 版本
echo "测试 3: 检查 Claude CLI..."
VERSION=$(docker-compose exec app claude --version 2>/dev/null || echo "not found")
if [ "$VERSION" != "not found" ]; then
    echo "✓ PASS: Claude CLI 已安装 - $VERSION"
    PASS=$((PASS + 1))
else
    echo "✗ FAIL: Claude CLI 未安装"
    FAIL=$((FAIL + 1))
fi
echo ""

# 测试 4: 环境变量
echo "测试 4: 验证环境变量..."
API_KEY=$(docker-compose exec app sh -c 'echo $ANTHROPIC_API_KEY' 2>/dev/null)
BASE_URL=$(docker-compose exec app sh -c 'echo $ANTHROPIC_BASE_URL' 2>/dev/null)

if [ "$API_KEY" = "dummy" ] && [ -n "$BASE_URL" ]; then
    echo "✓ PASS: 环境变量配置正确"
    echo "  API_KEY: $API_KEY"
    echo "  BASE_URL: $BASE_URL"
    PASS=$((PASS + 1))
else
    echo "✗ FAIL: 环境变量配置错误"
    FAIL=$((FAIL + 1))
fi
echo ""

# 测试 5: 状态栏插件
echo "测试 5: 检查状态栏插件..."
if docker-compose exec app sh -c 'python3 -c "import json; print(json.load(open(\"~/.claude/settings.json\")).get(\"statusLine\", {}) != {})"' >/dev/null 2>&1; then
    echo "✓ PASS: 状态栏插件已注册"
    PASS=$((PASS + 1))
else
    echo "✗ FAIL: 状态栏插件未注册"
    FAIL=$((FAIL + 1))
fi
echo ""

# 测试 6: 配置持久化
echo "测试 6: 测试配置持久化..."
docker-compose exec app sh -c "echo 'config-test' > ~/.claude/test-config.conf" 2>/dev/null
docker-compose restart >/dev/null 2>&1
sleep 3
RESULT=$(docker-compose exec app sh -c "cat ~/.claude/test-config.conf" 2>/dev/null)
if [ "$RESULT" = "config-test" ]; then
    echo "✓ PASS: 配置持久化正常"
    PASS=$((PASS + 1))
else
    echo "✗ FAIL: 文件持久化失败"
    FAIL=$((FAIL + 1))
fi
echo ""

# 总结
echo "========================================="
echo "测试结果汇总"
echo "========================================="
echo "通过: $PASS"
echo "失败: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
    echo "✓ 所有测试通过！"
    exit 0
else
    echo "✗ 有 $FAIL 个测试失败"
    exit 1
fi
```

### 10.3 常见问题排查

| 问题 | 诊断 | 解决方案 |
|------|------|----------|
| 容器无法启动 | Dockerfile 语法错误 | 运行 `docker-compose build` 查看错误 |
| API 连接失败 | `ANTHROPIC_BASE_URL` 配置错误 | 检查 `.env` 文件和平台配置 |
| 配置未持久化 | 卷挂载配置错误 | 检查 `docker-compose.yml` 中的 `volumes:` 部分，确认 `dev-home/` 路径正确 |
| 项目文件丢失 | 容器被删除 | 正常行为：项目文件仅在容器内，需定期用 `docker cp` 备份 |
| 状态栏不显示 | 插件未安装 | 运行 `.claude/plugins/custom/show-last-prompt/statusline/install.sh` |
| 权限被拒绝 | sudo NOPASSWD:ALL 未配置 | 检查 Dockerfile 是否包含 `RUN apk add --no-cache sudo` 和 `NOPASSWD:ALL` 配置，然后重建镜像 |

### 10.4 最终确认

所有标准满足后：

1. ✅ 用户可以使用 `docker-compose exec app sh` 进入容器
2. ✅ Claude Code CLI 开箱即用，已注册状态栏插件
3. ✅ 容器实现持久化和实时更新
4. ✅ 无任何报错

**验收通过！** 🎉

---

## **11. 项目文件管理**

### **11.1 文件存储位置**

本项目采用**统一持久化模式**：
- ✅ **项目文件**：通过 volume 持久化到 `./workspace/` 目录
- ✅ **Claude 配置**：持久化到 `./dev-home/config/` 目录
- ✅ **用户数据**：持久化到 `./dev-home/claude/` 目录

**优点**：
1. 📁 所有内容统一在 `./workspace/` 目录，易于管理和备份
2. 🛡️ 容器删除后，项目文件安全保留在宿主机
3. 🔄 可在宿主机直接编辑文件（也可在容器内开发）
4. 💾 定期备份 `./workspace/` 目录即可保护所有数据

### **11.2 备份项目**

#### 方法 1：使用主脚本菜单（推荐）
```bash
cd your-project
bash ../.claude/skills/docker-claude-code/scripts/init-docker-project.sh
# 选择 3) Backup project from container to host machine
```

#### 方法 2：直接调用备份脚本
```bash
# 备份到时间戳目录（默认）
bash .claude/skills/docker-claude-code/scripts/backup-project.sh

# 备份到指定目录
bash .claude/skills/docker-claude-code/scripts/backup-project.sh ../my-backup
```

### **11.3 迁移老项目**

老项目迁移时会：
1. 使用 `docker cp` 复制文件到容器内 `/workspace/project/`
2. 通过 volume 挂载，文件自动持久化到宿主机 `./workspace/`
3. 自动修复文件所有权为容器用户（claude:claude）
4. 非 root 用户可正常读写，无权限问题

---

**相关文档**：
- [SKILL.md](../.claude/skills/docker-claude-code/SKILL.md) - 技能文件
- [scripts/README.md](../.claude/skills/docker-claude-code/scripts/README.md) - 脚本文档
- [ACCEPTANCE_CRITERIA.md](../.claude/skills/docker-claude-code/ACCEPTANCE_CRITERIA.md) - 验收标准
