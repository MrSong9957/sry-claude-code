---
name: superpowers
description: 任何用户输入都适用，自动匹配技能并按动态流程执行的工程系统。
---

# 输入
- user_request: string
- context: object (JSON，可选)

# 输出
- plan（最小必要上下文 + 执行步骤）
- 执行日志与验证结果

# 目标
执行任务，而不是生成内容

# 读取范围（按需选择）
superpowers 仅可读取以下目录，并可按需选择其中的所有内容（技能、脚本、配置、工具等）：
- skills
- agents
- commands
- hooks
- lib
- tests

禁止虚构内容，所有执行必须通过 commands/。

# 目录内容与作用

## agents/
- code-reviewer.md - 代码审查代理配置

## commands/
- brainstorm.md - 头脑风暴命令
- execute-plan.md - 执行计划命令
- write-plan.md - 编写计划命令

## hooks/
- hooks.json - 钩子配置文件
- run-hook.cmd - 运行钩子命令的跨平台包装器
- session-start.sh - 会话启动脚本

## lib/
- skills-core.js - 技能核心库
  - extractFrontmatter: 提取技能文件前置内容
  - findSkillsInDir: 递归查找技能文件
  - resolveSkillPath: 解析技能名称到路径
  - checkForUpdates: 检查 git 仓库更新
  - stripFrontmatter: 剥离技能内容前置内容

## tests/
- claude-code/ - Claude Code 技能测试
  - README.md: 测试套件说明
  - test-helpers.sh: 测试辅助函数
  - test-subagent-driven-development.sh: 子代理驱动开发测试
- explicit-skill-requests/ - 显式技能请求测试
  - prompts/: 技能请求提示
  - run-test.sh: 测试运行脚本
- opencode/ - OpenCode 插件测试
  - test-plugin-loading.sh: 插件加载测试
  - test-skills-core.sh: 技能核心库测试
- skill-triggering/ - 技能触发测试
  - prompts/: 技能触发提示
  - run-test.sh: 测试运行脚本
- subagent-driven-dev/ - 子代理驱动开发测试
  - go-fractals/: Go 分形示例
  - svelte-todo/: Svelte Todo 示例

# 必用技能
- **using-superpowers**（skills/using-superpowers）
- **brainstorming**（skills/brainstorming）
- **writing-plans**（skills/writing-plans）
- **executing-plans**（skills/executing-plans）

# 执行流程（TRAE必须严格遵守）

## 1. 匹配技能（using-superpowers）
- TRAE必须首先调用 using-superpowers 技能，全面扫描 skills 目录
- 基于用户需求匹配所有可能相关的技能，不仅仅是必用技能
- 考虑 agents、commands、hooks、lib 目录下的工具和配置文件

## 2. 分析需求（brainstorming）
- TRAE必须调用 brainstorming 技能，分析用户需求和目标
- 生成需求分析和可能的解决方案

## 3. 建立执行计划（writing-plans）
- TRAE必须调用 writing-plans 技能，基于需求分析和技能匹配结果生成详细的执行计划
- 计划必须包含具体的执行步骤、验证方法，以及相关技能和工具的调用
- 确保计划中包含对 agents、commands、hooks、lib 目录下相关文件的使用

## 4. 执行计划（executing-plans）
- TRAE必须调用 executing-plans 技能，严格按照执行计划执行任务
- 每步执行后必须验证结果，确保任务完成

# 执行原则（TRAE必须遵守）
1. **流程优先**：TRAE必须严格按照执行流程执行，不得跳过任何步骤
2. **结果导向**：所有执行必须以完成用户任务为目标
3. **验证原则**：每步执行后必须验证结果，确保任务正确完成
4. **错误处理**：遇到错误时必须分析原因并采取适当的修复措施
5. **简洁有效**：执行流程必须简洁明了，避免不必要的复杂性
6. **灵活性原则**：TRAE必须根据用户需求和上下文灵活调整执行流程，合理使用相关技能和工具
7. **全面扫描**：TRAE必须全面扫描 skills 目录，发现并使用相关技能
8. **工具利用**：TRAE必须充分利用 agents、commands、hooks、lib、tests 目录下的工具和配置

# 输出格式
执行完成后，必须向用户提供：
- 任务执行结果
- 执行过程的简要说明
- 验证结果和建议（如有）

每步执行后必须验证，失败时必须立即采取修复措施。

---