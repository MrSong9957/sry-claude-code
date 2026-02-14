# Docker + Claude Code 开发环境配置标准文档 (v1.0)

## 1. 环境说明
本方案创建一个**持久化、权限正确、配置一致**的单容器开发环境，将项目代码与 Claude Code 深度集成。容器内使用非 root 用户进行开发，确保无权限问题，且能直接使用项目根目录中的 Claude Code 配置和技能插件。

**核心特性**：
- **统一挂载**：项目根目录整体挂载到容器 `/workspace`，结构清晰。
- **配置优先**：优先使用项目根目录下的 `.claude` 配置和技能插件，避免冲突。
- **权限正确**：容器内使用非 root 用户，与宿主机用户权限对齐。
- **网络互通**：通过 `host.docker.internal` 访问宿主机的 CC Switch 代理服务。

## 2. 配置文件

### 2.1 Dockerfile
```dockerfile
# 使用 Node.js 官方镜像作为基础（Claude Code 依赖 Node）
FROM node:20-alpine

# 设置工作目录
WORKDIR /workspace

# 安装基础工具（如 curl, git）
RUN apk add --no-cache curl git

# 安装 Claude Code（版本可通过 build-arg 指定）
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# 创建非 root 用户（UID 1000 通常对应宿主机的非 root 用户）
RUN addgroup -g 1000 appuser && \
    adduser -u 1000 -G appuser -s /bin/sh -D appuser

# 切换到非 root 用户
USER appuser

# 验证安装
RUN claude doctor
```

### 2.2 docker-compose.yml
```yaml
name: Docker

services:
  app:
    build: .
    container_name: docker-app
    ports:
      - "8080:8000"
    environment:
      - ENV=development
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      # CC Switch 代理端点
      - ANTHROPIC_BASE_URL=http://host.docker.internal:15721
    extra_hosts:
      # 使容器能访问宿主机的 CC Switch 服务
      - "host.docker.internal:host-gateway"
    volumes:
      # 将宿主机项目根目录挂载到容器的 /workspace
      # 此操作会同时挂载 frontend, backend, .claude 等所有目录
      # 包含 .claude/skills/docker-claude-code/claude-code-statusline-plugin 技能插件
      - ..:/workspace
    working_dir: /workspace
    stdin_open: true
    tty: true
    restart: unless-stopped
```

### 2.3 .env 文件
```env
# Claude Code CLI Configuration
# dummy 表示沿用宿主机的 API KEY（由 CC Switch 代理提供）
ANTHROPIC_API_KEY=dummy

# 端口要与 CC Switch 本地代理端口一致
ANTHROPIC_BASE_URL=http://host.docker.internal:15721
```

## 3. 目录结构说明

### 3.1 推荐的目录结构

**重要提示**：推荐使用 `init-docker-project.sh` 脚本自动初始化项目，以下目录结构会在初始化后自动创建。

```
项目根目录/
├── .claude/           # Claude Code 配置
│   ├── skills/        # 技能插件
│   │   └── docker-claude-code/
│   │       └── claude-code-statusline-plugin/  # 状态栏插件
│   └── settings.json  # Claude Code 配置文件
├── .env               # 环境变量（由 init 脚本自动生成）
├── docker-compose.yml # Docker 配置文件（由 init 脚本自动生成）
├── Dockerfile         # Docker 镜像构建文件（由 init 脚本自动生成）
├── workspace/          # 项目工作目录
│   ├── project/      # 实际项目代码目录
│   └── .claude/      # Claude Code 持久化配置（挂载到 ~/.claude）
├── dev-home/          # Claude Code 用户目录持久化
│   ├── config/      # Claude Code 配置持久化（挂载到 ~/.config/claude）
│   └── claude/       # Claude Code 用户数据持久化（挂载到 ~/claude）
└── Docker/            # 仅在使用旧版本文档时存在（已废弃）
```

**说明**：
- 上述结构使用 `init-docker-project.sh` 初始化后自动创建
- `workspace/project` 目录用于放置实际项目代码
- 所有持久化配置通过卷挂载实现，无需手动同步
- 如需迁移现有项目，使用 `bash .claude/skills/docker-claude-code/scripts/init-docker-project.sh migrate`

### 3.2 关于技能插件的说明
- **插件位置**：`./claude/skills/docker-claude-code/claude-code-statusline-plugin`
- **挂载方式**：通过挂载整个项目根目录，插件会自动出现在容器的 `/workspace/.claude/skills/docker-claude-code/claude-code-statusline-plugin` 路径下。
- **插件安装**：如果插件目录包含安装脚本（如 `install.sh`），需要在安装或更新 Claude Code 后执行该脚本。

## 4. 使用步骤

### 4.1 项目初始化

**重要**：推荐使用 `init-docker-project.sh` 脚本自动初始化项目，该脚本会自动生成所有必需的配置文件。

#### 方式一：新建项目（推荐）

```bash
# 从技能目录运行初始化脚本
bash .claude/skills/docker-claude-code/scripts/init-docker-project.sh

# 按提示操作：
# 1. 输入项目名称（或使用默认值 docker-claude-code）
# 2. 选择场景：1) 新建项目
# 3. 脚本会自动生成 Dockerfile、docker-compose.yml 和 .env 文件
# 4. 脚本会自动创建 workspace/、dev-home/ 等必需目录
```

#### 方式二：迁移现有项目

```bash
# 使用迁移模式
bash .claude/skills/docker-claude-code/scripts/init-docker-project.sh migrate

# 按提示操作：
# 1. 输入现有项目路径
# 2. 脚本会自动复制项目文件到 workspace/project/
# 3. 保持现有项目结构不变
```

#### 方式三：备份现有容器配置

```bash
# 使用备份模式
bash .claude/skills/docker-claude-code/scripts/init-docker-project.sh backup

# 按提示操作：
# 1. 输入备份目标路径
# 2. 脚本会备份当前容器配置和项目文件
```

**注意**：`init-docker-project.sh` 会自动：
1. 生成 `Dockerfile`
2. 生成 `docker-compose.yml`
3. 生成 `.env` 文件（参考 `.env.example` 模板）
4. 创建所有必需的目录结构
5. 安装状态栏插件

**文件放置说明**：初始化完成后，`Dockerfile`、`docker-compose.yml` 和 `.env` 文件会位于项目根目录，可以直接使用。
1. **文件放置**：确保 `Dockerfile`、`docker-compose.yml` 和 `.env` 文件位于项目根目录内。
2. **构建镜像**：
   ```bash
   docker-compose build
   ```
3. **启动容器**：
   ```bash
   docker-compose up -d
   ```

### 4.2 进入容器
- **非 Root 用户（推荐）**：
  ```bash
  docker-compose exec app sh
  ```
- **Root 用户（仅用于需要管理员权限的操作）**：
  ```bash
  docker-compose exec --user root app sh
  ```

### 4.3 安装或更新 Claude Code
1. **安装或更新 Claude Code**：
   ```bash
   npm install -g @anthropic-ai/claude-code@latest
   ```
2. **验证版本**：
   ```bash
   claude doctor
   ```

### 4.4 安装技能插件
**重要**：在安装或更新 Claude Code 后，需要执行插件目录内的安装脚本（如果存在）。
```bash
# 进入插件目录
cd .claude/skills/docker-claude-code/claude-code-statusline-plugin

# 检查是否存在安装脚本
ls -la

# 如果存在 install.sh 或其他安装脚本，执行安装
# 示例：
./install.sh
# 或
chmod +x install.sh && ./install.sh
```

### 4.5 验证插件安装
```bash
# 返回项目根目录
cd /workspace

# 验证插件是否安装成功
claude doctor
# 检查技能列表中是否包含 docker-claude-code-statusline-plugin

# 或在 Claude 中查看
claude
# 观察状态栏是否显示插件功能
```

## 5. 验证方法（必须执行）
完成配置后，**必须**执行以下测试以确保环境正确。

### 5.1 目录结构与权限验证
```bash
# 进入容器
docker-compose exec app sh

# 1. 检查当前工作目录
pwd  # 应输出 /workspace

# 2. 检查目录内容（应包含 frontend, backend, .claude 等）
ls -la

# 3. 验证技能插件目录存在
ls -la .claude/skills/docker-claude-code/claude-code-statusline-plugin/
# 应能看到插件相关文件，包括 install.sh（如果存在）

# 4. 验证非 root 用户权限
whoami  # 应输出 appuser

# 5. 测试 frontend 目录读写权限
touch frontend/test.txt && rm frontend/test.txt
echo "✅ Frontend 目录权限测试通过"

# 6. 测试 backend 目录读写权限
touch backend/test.txt && rm backend/test.txt
echo "✅ Backend 目录权限测试通过"
```

### 5.2 Claude Code 安装与插件验证
```bash
# 在容器内继续执行

# 1. 安装或更新 Claude Code（如果需要）
npm install -g @anthropic-ai/claude-code@latest

# 2. 验证 Claude Code 安装
claude doctor
# 期望输出：版本信息正确，配置路径为 /workspace/.claude，无权限错误。

# 3. 执行插件安装脚本（如果存在）
cd .claude/skills/docker-claude-code/claude-code-statusline-plugin
# 检查并执行安装脚本
if [ -f install.sh ]; then
    ./install.sh
    echo "✅ 插件安装脚本执行完成"
else
    echo "⚠️  插件目录中没有找到 install.sh，跳过安装步骤"
fi
cd /workspace

# 4. 验证插件是否加载
claude doctor
# 检查技能列表中是否包含 docker-claude-code-statusline-plugin

# 5. 启动 Claude Code 并验证功能
claude
# 在 Claude 中：
# 1. 观察状态栏是否显示插件功能
# 2. 执行测试命令：
#   "列出当前目录文件"
#   "查看 frontend 目录结构"
#   "检查 backend 目录结构"
```

### 5.3 网络连通性验证（可选）
```bash
# 在容器内测试到宿主机 CC Switch 服务的连通性
curl -I http://host.docker.internal:15721
# 期望：收到 HTTP 响应（如 200 或 404），表明网络通畅。
```

## 6. 验证通过标准
**必须同时满足以下所有条件**，才视为配置任务完成：
1. 容器内 `/workspace` 目录结构清晰，能正常访问 `frontend` 和 `backend`。
2. 容器内非 root 用户对所有代码文件有读写权限（无 `Permission denied` 错误）。
3. `claude doctor` 命令显示版本信息正确，配置路径为 `/workspace/.claude`，且无异常。
4. 技能插件目录 `./claude/skills/docker-claude-code/claude-code-statusline-plugin` 存在且可访问。
5. 如果插件目录包含安装脚本（如 `install.sh`），已成功执行且无错误。
6. Claude Code 能正常启动，状态栏插件加载成功，并能响应基础查询（如列出目录）。
7. 项目根目录的 `.claude` 配置（如果存在）能被正确加载。

## 7. 常见问题处理

### 7.1 容器内用户权限问题
**现象**：容器内无法读写项目文件。
**解决方案**：确保宿主机项目目录的权限允许容器用户（UID 1000）访问。
```bash
# 在宿主机项目根目录执行（选择一种）
sudo chown -R 1000:1000 .
# 或
sudo chown -R $(id -u):$(id -g) .
```

### 7.2 容器内用户 UID/GID 与宿主机不匹配
**现象**：权限问题持续存在，即使执行了上述 chown 命令。
**解决方案**：修改 Dockerfile，使用宿主机用户的 UID/GID。
```dockerfile
# 在 Dockerfile 中添加构建参数
ARG HOST_UID=1000
ARG HOST_GID=1000
RUN addgroup -g ${HOST_GID} appuser && \
    adduser -u ${HOST_UID} -G appuser -s /bin/sh -D appuser
```
**重新构建**：`docker-compose build --no-cache`

### 7.3 Claude Code 版本或配置不正确
**现象**：`claude doctor` 显示版本过旧或配置路径错误。
**解决方案**：
1. 更新 Dockerfile 中的 `ARG CLAUDE_CODE_VERSION` 为最新版本。
2. 重新构建镜像：`docker-compose build --no-cache`。
3. 重启容器：`docker-compose restart`。

### 7.4 缺少系统依赖
**现象**：Claude Code 或项目依赖无法运行（如缺少 Python、GCC 等）。
**解决方案**：在 Dockerfile 中安装所需系统包。
```dockerfile
# 示例：添加 Python 和编译工具
RUN apk add --no-cache python3 py3-pip build-base
```
**重新构建镜像**：`docker-compose build --no-cache`。

### 7.5 CC Switch 代理无法访问
**现象**：Claude Code 无法连接到 API。
**解决方案**：
1. 确保 CC Switch 正在运行且端口 `15721` 可用。
2. 检查宿主机防火墙是否阻止了容器访问。
3. 在容器内测试连通性：`curl http://host.docker.internal:15721`。

### 7.6 Claude Code 更新后状态栏插件未加载
**现象**：更新 Claude Code 后，状态栏插件不再显示或无法使用。
**解决方案**：
1. **检查插件目录**：确认 `./claude/skills/docker-claude-code/claude-code-statusline-plugin` 是否仍存在。
2. **重新执行插件安装脚本**：在容器内执行：
   ```bash
   cd .claude/skills/docker-claude-code/claude-code-statusline-plugin
   # 如果有 install.sh，重新执行
   ./install.sh
   # 或者检查是否有其他安装方式
   ```
3. **重启 Claude Code**：
   ```bash
   claude
   ```
4. **验证插件路径**：确保插件目录结构正确，包含必要的配置文件。

### 7.7 插件安装脚本执行失败
**现象**：插件目录中的 `install.sh` 脚本执行失败。
**解决方案**：
1. **检查脚本权限**：确保脚本有执行权限。
   ```bash
   chmod +x .claude/skills/docker-claude-code/claude-code-statusline-plugin/install.sh
   ```
2. **检查脚本内容**：查看脚本内容，了解需要什么依赖或环境。
3. **安装依赖**：根据脚本要求，在容器内安装所需工具。
4. **手动安装**：如果自动安装失败，参考插件文档手动安装。

### 7.8 Docker 配置文件在容器内可见
**现象**：在容器内可以看到 `Dockerfile` 和 `docker-compose.yml`。
**说明**：这是预期行为，因为这些文件位于项目根目录内，而项目根目录已被挂载。通常不影响开发，但建议不要在容器内修改这些文件。
**解决方案**：如果希望避免挂载，可以将这些配置文件移出项目根目录（例如放在与项目根目录并列的目录中），然后修改 `docker-compose.yml` 的挂载路径。

## 8. 停止与清理
```bash
# 停止容器
docker-compose down

# 停止容器并移除卷（谨慎使用，会删除持久化数据）
docker-compose down -v

# 重建镜像（当 Dockerfile 修改后）
docker-compose build --no-cache
```

---
**文档版本**：1.0  
**最后更新**：2026-02-14  
**说明**：此文档为标准化配置指南，按步骤操作即可完成环境搭建。所有验证步骤为强制要求，未通过验证则配置未完成。特别强调了 Claude Code 更新后状态栏插件的安装和验证步骤。