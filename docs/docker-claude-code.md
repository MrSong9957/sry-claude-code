# docker-claude-code SKILL 技能

## 目标
使用 Docker 创建一个可持久化、可实时同步的开发环境，使宿主机与容器之间的文件保持实时更新，并确保 Claude Code CLI 与状态栏插件在容器中可用。

---

## 核心原则

1. 持久化优先  
   - `.claude` 配置必须持久化  
   - 容器内的工作区必须持久化  

2. 挂载项目根目录  
   - 宿主机项目根目录挂载到容器内，即可实现实时同步  
   - 不需要额外同步工具  

3. 结构简洁  
   - 项目根目录只保留一个 `Docker/` 文件夹  
   - 所有容器相关文件集中管理  

4. 容器内开发无权限问题  
   - 非 root 用户必须能正常开发  
   - root 用户仅用于维护操作  

5. Claude Code CLI + 状态栏插件必须可用  
   - 容器内安装最新版 Claude Code  
   - 使用 `claude doctor` 验证  
   - 安装 SKILL 目录下的 `claude-code-statusline-plugin` 状态栏插件

---

## 目录结构要求

```
project-root/
  Docker/
    Dockerfile
    docker-compose.yml
    workspace/
      .claude/        ← 持久化 Claude 配置
  .claude/skills/
    claude-code-statusline-plugin/   ← 必须安装的状态栏插件
```

---

## 必要配置

### `.env`
```
ANTHROPIC_API_KEY=dummy
ANTHROPIC_BASE_URL=http://host.docker.internal:15721
```

---

## docker-compose.yml（核心：挂载 + 持久化）

```
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
      - ANTHROPIC_BASE_URL=http://host.docker.internal:15721
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      # 项目根目录实时同步
      - ..:/workspace/project
      # Claude 配置持久化
      - ./workspace/.claude:/workspace/.claude
    working_dir: /workspace/project
    stdin_open: true
    tty: true
    restart: unless-stopped
```

---

## 进入容器

| 用户 | 命令 |
|------|------|
| 非 root 用户 | `docker-compose exec app sh` |
| root 用户 | `docker-compose exec --user root app sh` |

要求：  
- 非 root 用户必须能完成所有开发任务，无权限问题  

---

## Claude Code 安装要求

### 1. 安装最新版 Claude Code CLI
- 在容器内执行安装  
- 使用 `claude doctor` 验证版本是否为最新  

### 2. 安装状态栏插件（新增要求）
- SKILL 目录中存在：  
  ```
  .claude/skills/claude-code-statusline-plugin/
  ```
- 在安装完最新版 Claude Code 后，必须安装此插件  
- 插件安装脚本已包含在项目中（按脚本执行即可）

---

## 验证要求（禁止头口通过）

任务完成后必须通过以下验证：

- 容器可正常启动  
- 宿主机 ↔ 容器文件实时同步  
- `.claude` 配置持久化正常  
- Claude Code CLI 可用（`claude doctor`）  
- 状态栏插件已成功安装并生效  
- 非 root 用户可正常开发  
- CC Switch 代理可访问  

---