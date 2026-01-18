---
name: UI-Refactor-Pro（UI 界面重构专家）
description: >
  一个自验证（Self‑Validating）、实时文档驱动（Document‑Driven）的 UI 调整与美化 Skill。执行时自动生成 To‑Do List，并在每一步执行后实时更新文档（SSOT）。下一步执行前必须读取最新文档，确保整个链路可控、可复现、可审计。
---

# UI-Refactor-Pro Skill（Self‑Validating + Real‑Time SSOT Version）

## 1. Skill 目标（最小必要性）
UI-Refactor-Pro 是一个实时文档驱动的自验证 Skill，执行 SOP 的同时自动生成并执行 To‑Do List。  
目标是：

- 自动生成可执行的步骤清单（To‑Do List）
- 每一步执行后实时更新文档（SSOT）
- 下一步执行前必须读取文档
- 每一步执行时自动验证（Step Assertions）
- 所有上下文写入 docs/，确保可复现与可审计
- 避免无效修改、跨文件污染、样式冲突

---

## 2. Skill 输入格式
```yaml
page: <页面路径>          # 必填
goal: <layout|visual|interaction>   # 必填
target: <组件或区域>       # 可选
style: <风格偏好>          # 可选
notes: <补充说明>          # 可选
```

---

## 3. Skill 输出格式
- 修改后的代码片段（来自 Step 5 的 diff）
- 修改说明（变更点列表）
- 文档路径（docs/ui-refactor-context-YYYYMMDD-HHMM.md）
- 自动生成的 To‑Do List（执行步骤 + 状态）

---

## 4. 修改边界规则（Boundary Constraints）
- 不跨页面  
- 不跨平台  
- 不修改无关文件  
- 不覆盖已有设计系统  
- 不生成重复样式  
- 不创建无意义容器  
- 不进行推测性修改  

---

## 5. 文档系统（SSOT）
文档命名：
```
docs/ui-refactor-context-YYYYMMDD-HHMM.md
```

文档必须包含：
- 用户输入  
- 页面结构摘要  
- 问题诊断  
- 修改计划  
- diff（修改内容）  
- 执行日志  
- To‑Do List 状态  
- 变更历史（追加）  

文档使用规则（关键）：
- **每一步执行后必须实时写入文档**
- **下一步执行前必须读取最新文档**
- 文档是唯一事实来源（SSOT）
- 文档缺失信息必须由用户补充
- 文档必须追加，不得覆盖

---

# 6. 自动生成 To‑Do List（实时写入文档）

Skill 在执行前自动生成 To‑Do List：

```yaml
todo:
  - step: parse_input
    status: pending
  - step: analyze_structure
    status: pending
  - step: generate_or_update_doc
    status: pending
  - step: generate_plan_from_doc
    status: pending
  - step: generate_modifications_from_doc
    status: pending
  - step: apply_changes_to_files_from_doc
    status: pending
  - step: closure_validation
    status: pending
```

规则：

- 每一步执行后 → `status: done`（实时写入文档）
- 任意一步失败 → `status: failed`（实时写入文档）并立即停止执行

---

# 7. 自验证 SOP（Self‑Validating SOP）

UI-Refactor-Pro 在执行 SOP 的每一步时，都会自动执行对应的步骤级断言（Step Assertions）。  
任意断言失败 → 立即停止并返回错误。

---

## Step 1：解析输入（parse_input）

**Action**
- 解析 page、goal、target、style、notes。

**Assertions**
- page 不为空  
- goal ∈ {layout, visual, interaction}

**Real‑Time Update**
- 将解析结果写入文档  
- 更新 To‑Do List 状态为 `done`

**On Failure**
- 写入失败状态  
- 返回：`INPUT_VALIDATION_FAILED`

---

## Step 2：构建结构树（analyze_structure）

**Action**
- 解析 DOM/JSX/Vue/Flutter 结构  
- 识别容器层级、布局模式、关键组件  

**Assertions**
- 能成功读取 page  
- 能生成结构树  
- 若 target 存在 → 必须能定位到 target  

**Real‑Time Update**
- 将结构树摘要写入文档  
- 更新 To‑Do List 状态为 `done`

**On Failure**
- 写入失败状态  
- 返回：`STRUCTURE_ANALYSIS_FAILED`

---

## Step 3：生成或更新文档（generate_or_update_doc）

**Action**
- 创建或更新文档  
- 写入输入、结构摘要、问题诊断占位符  

**Assertions**
- 文档文件存在  
- 文档包含输入与结构摘要  
- 若文档已存在 → 必须追加变更历史  

**Real‑Time Update**
- 写入文档  
- 更新 To‑Do List 状态为 `done`

**On Failure**
- 写入失败状态  
- 返回：`DOC_GENERATION_FAILED`

---

# ⭐ Step 4：基于文档生成修改计划（generate_plan_from_doc）  
### —— 文档是唯一事实来源（SSOT）  
### —— 下一步必须读取文档

**Action**
- 读取文档（必须）  
- 基于文档中的结构摘要、问题诊断、设计系统决策生成修改计划  
- 将修改计划写入文档  

**Assertions**
- 文档成功读取  
- 修改计划不为空  
- 修改计划必须与文档内容一致  
- 若 target 存在 → 修改计划必须包含 target  
- 修改计划不得跨页面  

**Real‑Time Update**
- 将修改计划写入文档  
- 更新 To‑Do List 状态为 `done`

**On Failure**
- 写入失败状态  
- 返回：`PLAN_GENERATION_FAILED`

---

# ⭐ Step 5：基于文档生成修改内容（generate_modifications_from_doc）  
### —— 逻辑层（diff 层），不写文件  
### —— diff 必须基于文档中的修改计划  
### —— 下一步必须读取文档

**Action**
- 读取文档（必须）  
- 基于文档中的修改计划生成 diff / patch  
- 将 diff 写入文档  

**Assertions**
- 文档成功读取  
- diff 不为空  
- diff 与文档中的修改计划一致  
- diff 不跨页面  
- diff 不覆盖 design tokens  
- diff 不生成重复样式  
- diff 不创建无意义容器  

**Real‑Time Update**
- 将 diff 写入文档  
- 更新 To‑Do List 状态为 `done`

**On Failure**
- 写入失败状态  
- 返回：`MODIFICATION_GENERATION_FAILED`

---

# ⭐ Step 6：基于文档执行修改（apply_changes_to_files_from_doc）  
### —— 物理层（文件写入层）  
### —— 必须读取文档中的 diff  
### —— 执行日志必须写入文档

**Action**
- 读取文档（必须）  
- 从文档中提取 diff  
- 将 diff 应用到真实文件  
- 将执行日志写入文档  

**Assertions**
- 文档成功读取  
- diff 存在且合法  
- 写入文件必须与 diff 完全一致  
- 未修改无关文件  
- 未跨页面修改  
- 写入成功（无冲突、无权限错误）

**Real‑Time Update**
- 将执行日志写入文档  
- 更新 To‑Do List 状态为 `done`

**On Failure**
- 写入失败状态  
- 返回：`FILE_WRITE_FAILED`

---

## Step 7：闭环验证（closure_validation）

**Action**
- 验证整个执行链路是否完整  
- 验证所有步骤是否基于文档执行  
- 验证文档是否追加变更历史  

**Assertions**
- 输入 → 分析 → 文档 → 计划 → diff → 文件写入 → 文档更新 全部存在  
- 文档包含变更历史  
- 所有步骤均读取文档  
- 无未解释的修改  
- 无边界规则违规  

**Real‑Time Update**
- 更新 To‑Do List 状态为 `done`

**On Failure**
- 写入失败状态  
- 返回：`CLOSURE_VALIDATION_FAILED`

---

# 8. 自验证机制说明

UI-Refactor-Pro 是一个实时文档驱动的自验证 Skill。  
Skill 执行 = To‑Do List 执行 = 文档实时更新 = 测试执行。  
每一步执行后必须实时写入文档。  
每一步执行前必须读取文档。  
文档是唯一事实来源（SSOT）。  
任意步骤失败 → 立即停止。  
所有步骤通过 → Skill 执行成功。

---