---
name: production-readiness-checklist
description: 最小化且可审计的检查项，确保项目满足生产级标准
---

# ✅ Checklist

```yaml
architecture:
  - 服务边界清晰，遵循单一职责原则
  - 环境隔离一致（dev/staging/prod 配置无漂移）

code_quality:
  - 自动化测试完整（单元、集成、端到端）
  - CI/CD pipeline 全部绿灯
  - 强制编码规范检查（Lint/Formatter）
  - 模块化整合，禁止零散片段
  - 逻辑正确性必须通过边界与异常场景验证

infrastructure:
  - 容器化部署可复现（Docker/K8s）
  - 数据库迁移可回滚并有审计记录
  - 使用 Docker Compose 管理依赖服务（如 Redis、Postgres、消息队列）
  - 所有依赖服务镜像版本固定并可审计
  - 数据持久化通过卷（volumes）挂载，避免数据丢失

security:
  - 密钥与敏感信息通过安全管理系统注入
  - HTTPS/TLS 强制启用
  - 依赖库定期安全审计（npm audit/pip-audit/Snyk）
  - 检查清单覆盖 SQL注入 / 路径遍历 / 凭证 / 反序列化

observability:
  - 结构化日志集中收集
  - 指标监控与告警（CPU、内存、响应时间、错误率）
  - 健康检查与自动恢复机制

documentation_delivery:
  - 文档覆盖安装、运行、API 与用户指南
  - 灾备演练与恢复验证
  - 性能测试达到 SLA 基线
  - 建立 AI 使用日志，记录生成片段与审查结果
  - 定期回顾与优化 SOP
```

---

# ⚙️ 执行流程

1. 准备阶段  
   - 明确项目上线目标与范围  
   - 确认环境隔离已建立  
   - 拉取并固定依赖服务的 Docker 镜像版本  

2. 检查阶段  
   - 按照 Checklist 各维度逐项执行  
   - 每个条目需有对应的审计记录（commit、issue、pipeline log）  
   - 使用 Docker Compose 启动应用与依赖服务（Redis、数据库等）  

3. 验证阶段  
   - 执行自动化测试与性能基线验证  
   - 灾备演练与恢复测试  
   - 验证监控与日志告警机制  
   - 验证容器持久化卷是否正常工作  

4. 审查阶段  
   - Code Review 全部通过  
   - 文档与 SOP 更新完成  
   - AI 使用日志与安全审计归档  

5. 交付阶段  
   - Checklist 全部打勾并存档  
   - 项目进入生产环境  
   - 镜像与配置归档，保证可复现性  

---

# 📌 闭环要求
- 所有检查项必须完成并有审计记录（commit、issue、pipeline log）  
- Checklist 存档作为生产环境准入依据  

---