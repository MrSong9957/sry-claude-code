# docker-claude-code

> 在 Docker 容器中使用 Claude Code CLI 的完整解决方案

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)

---

## 🚀 5分钟快速开始

### 前置要求

- Docker Desktop (Windows/macOS) 或 Docker Engine (Linux)
- 基本的命令行操作经验

### 三步启动

```bash
# 1. 初始化项目
bash .claude/skills/docker-claude-code/scripts/init-docker-project.sh
# 选择: 1) New Project

# 2. 启动容器
cd Docker && docker-compose up -d

# 3. 进入容器
docker-compose exec app sh

# 验证安装
claude doctor
```

✅ 完成！你现在在容器中运行 Claude Code CLI 了。

---

## 📖 使用指南

### 日常使用

```bash
# 进入容器
cd Docker && docker-compose exec app sh

# 在容器中使用 Claude Code
claude "帮我创建一个 Python Hello World"

# 查看历史
claude history

# 退出容器
exit
```

### 停止和重启

```bash
# 停止容器
cd Docker && docker-compose down

# 重启容器
cd Docker && docker-compose up -d
```

### 文件实时同步

**重要**: 项目文件在宿主机和容器之间实时同步

- 在宿主机编辑文件 → 立即在容器内可见
- 在容器内创建文件 → 立即在宿主机可见

```bash
# 示例：在宿主机创建文件
echo "console.log('Hello')" > app.js

# 在容器内立即可以访问
docker-compose exec app sh -c "cat app.js"
```

---

## 🏗️ 架构说明

### 目录结构

```
your-project/
├── Docker/                    # 容器配置目录
│   ├── Dockerfile            # 容器镜像定义
│   ├── docker-compose.yml    # 容器编排配置
│   ├── .env                  # 环境变量
│   ├── workspace/
│   │   └── .claude/          # Claude 配置持久化
│   └── .claude/
│       └── skills/
│           └── docker-claude-code/
└── [你的项目文件]            # 实时同步到容器
```

### 核心特性

| 特性 | 说明 |
|------|------|
| **实时同步** | 项目文件自动在宿主机和容器间同步 |
| **配置持久化** | Claude 配置保存在 `Docker/workspace/.claude/` |
| **多用户支持** | 默认 `claude` 用户，必要时可切换 `root` |
| **状态栏插件** | 自动安装并显示最新指令摘要 |

### 卷挂载配置

```yaml
volumes:
  # 项目根目录实时同步
  - ..:/workspace/project
  # Claude 配置持久化
  - ./workspace/.claude:/workspace/.claude
```

---

## 🔧 故障排除

### 容器无法启动

```bash
# 检查端口占用
netstat -ano | findstr :8080  # Windows
lsof -i :8080                  # macOS/Linux

# 查看容器日志
cd Docker && docker-compose logs app

# 重新构建镜像
cd Docker && docker-compose build --no-cache
```

### Claude CLI 无法连接

```bash
# 验证环境变量
cd Docker && grep ANTHROPIC .env

# 测试代理连通性
cd Docker && docker-compose exec app sh -c "curl -v $ANTHROPIC_BASE_URL"

# 检查 CC Switch 是否运行
# Windows: 在任务管理器中查找 "CC Switch"
# macOS/Linux: ps aux | grep cc-switch
```

### 文件权限问题

```bash
# 修复文件所有权
cd Docker && docker-compose exec app sudo chown -R claude:claude /workspace/project

# 或使用 root 用户
cd Docker && docker-compose exec -u root app sh
```

### 配置未持久化

```bash
# 检查卷挂载
cd Docker && docker-compose exec app sh -c "ls -la /workspace/.claude"

# 重新初始化配置
cd Docker && bash .claude/skills/docker-claude-code/scripts/init-docker-project.sh
```

---

## 🛠️ 高级功能

### 运行诊断

```bash
cd Docker && bash .claude/skills/docker-claude-code/scripts/diagnose-docker.sh
```

### 验证配置

```bash
cd Docker && bash .claude/skills/docker-claude-code/scripts/validate-config.sh
```

### 运行测试

```bash
cd Docker && bash .claude/skills/docker-claude-code/scripts/test-docker.sh
```

### 状态栏插件

插件会自动安装，状态栏显示：
```
[最新指令:创建 Python Hello World]
```

---

## 📚 更多资源

### 相关文档

- **完整文档**: [SKILL.md](./SKILL.md) - 详细的验收标准和 TDD 流程
- **迁移指南**: [docs/MIGRATION_GUIDE.md](./docs/MIGRATION_GUIDE.md) - 从旧版本迁移
- **用户文档**: [docs/docker-claude-code.md](../../../docs/docker-claude-code.md)

### 常用脚本

所有脚本位于 `.claude/skills/docker-claude-code/scripts/`：

| 脚本 | 功能 |
|------|------|
| `init-docker-project.sh` | 初始化项目（新建/迁移/备份） |
| `validate-config.sh` | 验证配置文件 |
| `diagnose-docker.sh` | 诊断问题 |
| `test-docker.sh` | 运行验收测试 |
| `backup-project.sh` | 备份容器文件 |
| `migrate-to-sync-mode.sh` | 迁移到 Sync Mode |

---

## ❓ 常见问题

### Q: 这个 SKILL 和直接安装 Claude Code 有什么区别？

**A**: docker-claude-code 提供了：
- 隔离的开发环境
- 配置持久化
- 一键初始化
- 内置状态栏插件
- 完整的测试和诊断工具

### Q: 容器内可以使用宿主机的 API Key 吗？

**A**: 可以。通过 `ANTHROPIC_API_KEY=dummy` 配置，容器会使用宿主机的 API Key（通过 CC Switch 代理）。

### Q: 如何在容器中安装其他工具？

**A**: 使用 `sudo` 安装：
```bash
cd Docker && docker-compose exec app sh
sudo apt-get update && sudo apt-get install -y <package>
```

### Q: 可以在容器中使用 GPU 吗？

**A**: 需要额外配置。参考 Docker 文档配置 GPU 支持。

### Q: 如何升级 Claude Code CLI？

**A**: 在容器内运行：
```bash
cd Docker && docker-compose exec app sh
npm install -g @anthropic-ai/claude-code
```

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

## 📄 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

## ⭐ Star History

如果这个项目对你有帮助，请给个 Star！

---

**Made with ❤️ by the Claude Code community**
