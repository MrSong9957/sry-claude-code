# Isolation Mode → Sync Mode 迁移指南

## 📋 背景

从版本 2.0.0 开始,`docker-claude-code` 默认使用 **Sync Mode** (实时同步模式),替代之前的 **Isolation Mode** (隔离模式)。

### 架构对比

| 特性 | Isolation Mode (旧) | Sync Mode (新) |
|------|---------------------|----------------|
| 文件位置 | 仅在容器内 | 宿主机实时同步 |
| 备份方式 | `docker cp` 或 backup 脚本 | 无需备份(文件在宿主机) |
| 目录结构 | workspace/、dev-home/ 在根目录 | Docker/ 目录集中管理 |
| 卷挂载 | 3 个独立卷挂载 | 2 个简化卷挂载 |
| 适用场景 | 需要强环境隔离 | 需要实时文件访问 |

### 迁移收益

✅ **实时同步**: 宿主机修改立即在容器内生效
✅ **简化结构**: 单一 Docker/ 目录,更清晰
✅ **无需备份**: 项目文件直接在宿主机
✅ **更好的体验**: 符合 Docker 开发习惯

---

## 🔄 迁移前准备

### 前置检查

在开始迁移前,请确认:

- [ ] 当前使用 Isolation Mode (存在 `workspace/` 和 `dev-home/` 目录)
- [ ] 容器可以正常启动 (`docker-compose ps` 显示 "Up")
- [ ] 重要的项目文件已提交到版本控制
- [ ] Claude Code CLI 版本为最新 (`claude doctor` 验证)
- [ ] 有至少 5GB 可用磁盘空间

### 备份数据

**强烈建议**在迁移前创建完整备份:

```bash
# 1. 停止容器
docker-compose down

# 2. 备份 workspace/ 和 dev-home/ 目录
tar -czf "backup-isolation-$(date +%Y%m%d-%H%M%S).tar.gz" workspace/ dev-home/

# 3. 验证备份文件
tar -tzf backup-isolation-*.tar.gz | head -20
```

---

## 🚀 自动迁移 (推荐)

### 使用迁移脚本

**最简单的方式**: 使用提供的迁移脚本自动完成所有步骤。

```bash
# 1. 确保在项目根目录
cd /path/to/your/project

# 2. 运行迁移脚本
bash .claude/skills/docker-claude-code/scripts/migrate-to-sync-mode.sh

# 3. 按照提示完成迁移
#    - 脚本会自动备份、迁移、验证
```

**脚本会自动**:
1. ✅ 检测当前模式 (必须是 Isolation Mode)
2. ✅ 创建时间戳备份
3. ✅ 从容器导出项目文件到宿主机
4. ✅ 创建新的 Docker/ 目录结构
5. ✅ 更新配置文件 (.env, docker-compose.yml, Dockerfile)
6. ✅ 安装状态栏插件
7. ✅ 验证迁移结果
8. ✅ 清理旧容器

---

## 🔧 手动迁移

如果自动迁移失败或您需要更多控制,可以按照以下步骤手动迁移。

### Step 1: 备份现有数据

```bash
# 创建备份目录
mkdir -p backups
cd backups

# 备份 workspace/ 和 dev-home/
tar -czf "../backup-manual-$(date +%Y%m%d-%H%M%S).tar.gz" \
  ../workspace/ ../dev-home/ \
  ../docker-compose.yml ../Dockerfile ../.env

cd ..
```

### Step 2: 导出项目文件

```bash
# 启动容器(如果未运行)
docker-compose up -d

# 等待容器完全启动
sleep 5

# 从容器导出项目文件到宿主机
docker cp docker-claude-code-app:/workspace/project ./

# 验证导出
ls -la project/
```

### Step 3: 创建新的目录结构

```bash
# 创建 Docker/ 目录
mkdir -p Docker/workspace/.claude

# 移动项目文件到 Docker/ 目录
mv project/* Docker/
rmdir project

# 移动配置文件
mv docker-compose.yml Docker/
mv Dockerfile Docker/
mv .env Docker/
```

### Step 4: 更新 docker-compose.yml

编辑 `Docker/docker-compose.yml`,更新卷挂载:

```yaml
services:
  app:
    build: .
    container_name: docker-claude-code-app
    ports:
      - "8080:8000"
    environment:
      - ENV=development
      - ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}
      - ANTHROPIC_BASE_URL=${ANTHROPIC_BASE_URL}
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

**关键变更**:
- ✅ 移除 `${WORKSPACE_PATH:-./workspace}:/workspace`
- ✅ 移除 `${CLAUDE_CONFIG_PATH:-./dev-home/config}:/home/claude/.config/claude`
- ✅ 移除 `${CLAUDE_HOME_PATH:-./dev-home/claude}:/home/claude`
- ✅ 添加 `..:/workspace/project`
- ✅ 添加 `./workspace/.claude:/workspace/.claude`

### Step 5: 更新 .env 文件

编辑 `Docker/.env`,简化配置:

```bash
# 保留核心配置
ANTHROPIC_API_KEY=dummy
ANTHROPIC_BASE_URL=http://host.docker.internal:15721

# 删除以下行(如果存在)
# WORKSPACE_PATH=./workspace
# CLAUDE_CONFIG_PATH=./dev-home/config
# CLAUDE_HOME_PATH=./dev-home/claude
```

### Step 6: 删除旧容器和镜像

```bash
# 停止并删除旧容器
docker-compose down

# 删除旧镜像(可选,节省空间)
docker rmi docker-claude-code-app 2>/dev/null || true
```

### Step 7: 启动新容器

```bash
# 进入 Docker/ 目录
cd Docker

# 启动容器
docker-compose up -d

# 验证容器启动
docker-compose ps
```

### Step 8: 验证迁移

```bash
# 1. 验证容器访问
docker-compose exec app sh -c "whoami"  # 预期: claude
docker-compose exec app sh -c "pwd"     # 预期: /workspace/project

# 2. 验证文件同步
echo "test-$(date +%s)" > test-sync.txt
sleep 2
docker-compose exec app sh -c "cat /workspace/project/test-sync.txt"
rm -f test-sync.txt

# 3. 验证 Claude CLI
docker-compose exec app sh -c "claude --version"
docker-compose exec app sh -c "claude doctor"

# 4. 验证状态栏插件
docker-compose exec app sh -c 'python3 -c "import json; print(json.load(open(\"~/.claude/settings.json\")).get(\"statusLine\"))"'

# 5. 运行完整测试
cd ..
bash .claude/skills/docker-claude-code/scripts/test-docker.sh
```

---

## 🧹 清理旧目录 (可选)

### 迁移成功后

如果所有测试通过,可以删除旧目录:

```bash
# 确认所有文件已迁移
ls -la Docker/

# 删除旧目录
rm -rf workspace/ dev-home/

# 删除备份文件(可选,建议保留至少一周)
# rm backup-*.tar.gz
```

---

## ⏪ 回滚步骤

如果迁移失败或您想回到 Isolation Mode:

### 自动回滚

如果使用迁移脚本,脚本会在失败时自动提示回滚选项:

```bash
# 1. 停止新容器
cd Docker && docker-compose down

# 2. 删除 Docker/ 目录
cd ..
rm -rf Docker/

# 3. 恢复备份
tar -xzf backup-isolation-YYYYMMDD-HHMMSS.tar.gz

# 4. 重启旧容器
docker-compose up -d
```

### 手动回滚

```bash
# 1. 停止并删除新容器
cd Docker && docker-compose down
cd ..

# 2. 删除 Docker/ 目录
rm -rf Docker/

# 3. 恢复备份
tar -xzf backup-isolation-YYYYMMDD-HHMMSS.tar.gz

# 4. 验证恢复
ls -la workspace/ dev-home/

# 5. 重启旧容器
docker-compose up -d
docker-compose ps
```

---

## ❓ 常见问题

### Q1: 迁移会丢失数据吗?

**A**: 不会。迁移脚本会自动创建备份,并将所有文件从容器导出到宿主机。建议额外使用 `tar` 备份 `workspace/` 和 `dev-home/` 目录。

### Q2: 迁移需要多长时间?

**A**: 通常 5-10 分钟,取决于项目大小和网络速度。主要时间花在:
- 备份: 1-2 分钟
- 文件导出: 2-5 分钟
- 容器重建: 2-3 分钟

### Q3: 迁移失败怎么办?

**A**:
1. 检查日志: `cd Docker && docker-compose logs app`
2. 运行诊断: `bash .claude/skills/docker-claude-code/scripts/diagnose-docker.sh`
3. 查看回滚步骤(上文)

### Q4: Sync Mode 有什么限制?

**A**:
- **文件权限**: 宿主机和容器的 UID/GID 可能不匹配,建议使用 Docker Desktop
- **性能**: 大量文件同步可能略慢于 Isolation Mode
- **兼容性**: Linux 用户需要配置 `extra_hosts`

### Q5: 可以保留 Isolation Mode 吗?

**A**: 可以。Isolation Mode 仍受支持,但:
- 不再推荐用于新项目
- 文档和示例将基于 Sync Mode
- 建议长期迁移到 Sync Mode

### Q6: 迁移后插件需要重新安装吗?

**A**: 不需要。迁移脚本会自动重新安装状态栏插件。如果手动迁移,运行:

```bash
cd Docker
bash .claude/skills/docker-claude-code/scripts/init-docker-project.sh
# 选择: 4) Exit (跳过初始化)
# 然后手动安装插件
```

---

## 📞 获取帮助

如果遇到问题:

1. **查看文档**: [SKILL.md](../SKILL.md)
2. **运行诊断**: `bash .claude/skills/docker-claude-code/scripts/diagnose-docker.sh`
3. **查看日志**: `cd Docker && docker-compose logs app`
4. **提交 Issue**: [GitHub Issues](https://github.com/your-repo/issues)

---

## ✅ 迁移清单

完成迁移后,请验证以下项目:

- [ ] 容器可以正常启动 (`cd Docker && docker-compose ps`)
- [ ] 可以进入容器 (`cd Docker && docker-compose exec app sh`)
- [ ] Claude CLI 可用 (`claude doctor`)
- [ ] 文件实时同步工作 (编辑文件立即在容器内可见)
- [ ] 状态栏插件已安装并生效
- [ ] 所有测试通过 (`bash .claude/skills/docker-claude-code/scripts/test-docker.sh`)
- [ ] 旧目录已清理 (`workspace/`, `dev-home/` 已删除)
- [ ] 备份文件已安全保存

---

**迁移完成后,恭喜您升级到 Sync Mode!** 🎉
