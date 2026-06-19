---
name: ultragoal-output-spec
description: "$ultragoal 技能的形式化输出规范，定义 brief.md、goals/、ledger.md 的精确定义、JSON 模式、验证规则和与其他 OMX 系统的集成契约。"
version: "1.0.0"
---

# Ultragoal 输出规范

本文件是 `$ultragoal` 技能的形式化输出契约，定义了三种核心工件（brief.md、goals/、ledger.md）的精确定义、验证规则和集成规范。任何 $ultragoal 执行必须产出符合本文档定义的工件。

---

## 1. 工件总览

| 工件 | 格式 | 语义 | 写入约束 |
|------|------|------|----------|
| **brief.md** | 结构化 Markdown | 项目级状态快照 | 可更新，每次会话结束时同步 |
| **goals/<goal_id>.md** | 结构化 Markdown | 单个目标的完整定义和进度 | 可更新，每次推进后同步 |
| **ledger.md** | 仅追加列表 | 不可变操作审计日志 | 仅追加（append-only），禁止修改历史条目 |

### 工件关系

```
brief.md (项目状态快照)
    ├─ 列出活跃目标 ID 列表
    │
    ├─ goals/<goal_id>.md (每个目标)
    │   ├─ 目标定义
    │   ├─ 里程碑和进度
    │   └─ 引用 ledger 条目
    │
    └─ ledger.md (全局操作日志)
        └─ 每个操作日志引用目标 ID
```

---

## 2. brief.md — 项目摘要规范

### 2.1 强制字段

```markdown
# Project Brief

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| 项目名称 | string | 必填 | 项目的简短名称 |
| 一句话描述 | string | 必填，≤200 字符 | 项目核心目标 |
| 当前阶段 | enum(init|active|maintenance|archived) | 必填 | 项目生命周期阶段 |
| 活跃目标 | [goal_id] | 必填，≤5 个 | 当前活跃的目标 ID 列表 |
| 最近更新 | ISO8601 datetime | 必填 | 最后一次修改时间 |
| 下次会话建议 | string | 可选 | 下次启动时建议优先处理的目标 |
| 阻塞项摘要 | string | 可选 | 全局阻塞项（非目标级别的） |
```

### 2.2 完整模板

```markdown
# Project Brief: <项目名称>

- **描述**: <一句话描述>
- **阶段**: <init|active|maintenance|archived>
- **最近更新**: <YYYY-MM-DDTHH:mm:ss±HH:MM>

## 活跃目标

| ID | 目标名称 | 优先级 | 状态 | 进度 |
|----|----------|--------|------|------|
| goal-001 | <名称> | P0 | active | 60% |
| goal-002 | <名称> | P1 | blocked | 30% |

## 阻塞项摘要

- <全局阻塞项 1>
- <全局阻塞项 2>

## 下次会话建议

- 优先推进: <goal_id>
- 建议使用模式: aggregate | per-story

## 已完成目标

| ID | 目标名称 | 完成日期 | 结果摘要 |
|----|----------|----------|----------|
| goal-000 | <名称> | <日期> | <摘要> |
```

### 2.3 验证规则

| 规则 ID | 规则描述 | 严重性 |
|----------|----------|--------|
| BRIEF-V01 | 活跃目标不超过 5 个 | ERROR |
| BRIEF-V02 | 活跃目标 ID 必须在 goals/ 目录中存在对应文件 | ERROR |
| BRIEF-V03 | 最近更新必须是有效的 ISO8601 时间戳 | ERROR |
| BRIEF-V04 | 项目名称不为空且 ≤ 100 字符 | ERROR |
| BRIEF-V05 | 已完成目标与活跃目标无重叠 | WARNING |

---

## 3. goals/<goal_id>.md — 目标定义规范

### 3.1 文件命名规则

```
goals/<goal_id>.md
```

- `goal_id` 格式：`goal-<3位零填充数字>`，例如 `goal-001`、`goal-042`
- 文件名全小写，不含空格

### 3.2 强制字段

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| 目标 ID | string | 必填，格式 goal-NNN | 唯一标识符 |
| 目标名称 | string | 必填，≤200 字符 | 可读名称 |
| 状态 | enum(active|blocked|completed|paused) | 必填 | 当前状态 |
| 优先级 | enum(P0|P1|P2|P3) | 必填 | P0=阻塞所有，P1=高优，P2=正常，P3=低优 |
| 创建日期 | ISO8601 date | 必填 | 目标创建日期 |
| 最后更新 | ISO8601 datetime | 必填 | 最后一次修改时间 |
| 成功标准 | [string] | 必填，≥1 条 | 可验证的完成条件 |
| 当前进度 | percentage (0-100) | 必填 | 完成百分比 |
| 阻塞项 | [{reason, since}] | 可选 | status=blocked 时必填 |

### 3.3 可选字段

| 字段 | 类型 | 说明 |
|------|------|------|
| 描述 | string | 目标的详细背景说明 |
| 依赖 | [goal_id] | 依赖的其他目标 ID |
| 里程碑 | [{title, target_progress, completed}] | 进度检查点 |
| 完成日期 | ISO8601 datetime | status=completed 时的完成时间 |
| 执行模式 | aggregate \| per-story | 推荐的执行模式 |
| 关联故事 | [{story_id, title, status}] | 单故事模式下的故事列表 |
| 估计工作量 | string | 人天估算 |
| 标签 | [string] | 分类标签（如 research、build、refactor） |

### 3.4 完整模板

```markdown
# Goal: <目标ID> — <目标名称>

| 属性 | 值 |
|------|-----|
| **状态** | active |
| **优先级** | P1 |
| **创建日期** | 2026-06-09 |
| **最后更新** | 2026-06-09T14:30:00+08:00 |
| **进度** | 40% |
| **估计工作量** | 3 人天 |

## 描述

<目标的详细背景说明，1-3 段>

## 依赖

| 依赖目标 | 状态 | 说明 |
|----------|------|------|
| goal-000 | completed | 前置基础 |

## 成功标准

- [ ] <可验证的完成条件 1>
- [ ] <可验证的完成条件 2>
- [ ] <可验证的完成条件 3>

## 里程碑

| 里程碑 | 目标进度 | 状态 | 预计日期 |
|--------|----------|------|----------|
| M1: <名称> | 25% | completed | 2026-06-10 |
| M2: <名称> | 50% | active | 2026-06-12 |
| M3: <名称> | 75% | pending | 2026-06-14 |
| M4: <名称> | 100% | pending | 2026-06-16 |

## 当前进度

<当前进展的简要描述，1-2 段>

## 阻塞项

| 阻塞原因 | 起始日期 | 解决方案 |
|----------|----------|----------|
| <原因> | <日期> | <方案> |

## 关联故事 (单故事模式)

| 故事 ID | 标题 | 状态 |
|---------|------|------|
| story-01 | <标题> | completed |
| story-02 | <标题> | active |
| story-03 | <标题> | pending |

## 相关 Ledger 条目

- [2026-06-09T10:00:00Z] <操作类型> — <摘要>
- [2026-06-09T14:00:00Z] <操作类型> — <摘要>
```

### 3.5 验证规则

| 规则 ID | 规则描述 | 严重性 |
|----------|----------|--------|
| GOAL-V01 | 目标 ID 必须匹配文件名 | ERROR |
| GOAL-V02 | status=blocked 时阻塞项不能为空 | ERROR |
| GOAL-V03 | status=completed 时进度必须为 100% | ERROR |
| GOAL-V04 | 优先级必须是 P0/P1/P2/P3 之一 | ERROR |
| GOAL-V05 | 成功标准至少一条 | ERROR |
| GOAL-V06 | 里程碑进度必须递增 | WARNING |
| GOAL-V07 | 依赖目标的状态与 brief.md 一致 | WARNING |
| GOAL-V08 | 完成日期与最后更新日期的差值合理 | WARNING |

---

## 4. ledger.md — 操作日志规范

### 4.1 核心约束

ledger.md 是不可变的审计日志：
- **仅追加（Append-Only）**：只能添加新条目，不得修改或删除已有条目
- **不可变（Immutable）**：历史条目永远保持不变
- **时间倒序（Reverse Chronological）**：最新条目在最前面
- **每条必含证据**：每个操作条目必须包含验证结果或证据引用

### 4.2 条目字段定义

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| timestamp | ISO8601 datetime | 必填 | 操作发生时间，精确到秒 |
| operation_type | enum | 必填 | 操作类型（见 4.3） |
| affected_goal | goal_id | 必填 | 影响的目标 ID |
| description | string | 必填，≤500 字符 | 操作描述 |
| result | enum(success|failure|partial) | 必填 | 操作结果 |
| evidence | string | 必填 | 验证证据（测试输出、文件变更、审查结论等） |
| next_action | string | 可选 | 建议的下一步（failure 时必填） |
| related_files | [string] | 可选 | 操作涉及的文件路径列表 |

### 4.3 操作类型枚举

| 操作类型 | 说明 | 使用场景 |
|----------|------|----------|
| GOAL_CREATED | 创建新目标 | 目标初始化 |
| GOAL_ACTIVATED | 激活一个 paused 目标 | 恢复暂停的目标 |
| GOAL_PAUSED | 暂停目标 | 暂时搁置 |
| GOAL_BLOCKED | 标记目标为阻塞 | 遇到阻塞项 |
| GOAL_UNBLOCKED | 清除阻塞状态 | 阻塞解除 |
| GOAL_COMPLETED | 标记目标完成 | 成功标准全部满足 |
| MILESTONE_REACHED | 达到里程碑 | 里程碑检查点通过 |
| STORY_STARTED | 开始一个用户故事 | 单故事模式开始 |
| STORY_COMPLETED | 完成一个用户故事 | 单故事模式结束 |
| CODE_CHANGED | 代码变更 | 实现代码修改 |
| REVIEW_PASSED | 审查通过 | 代码/设计审查通过 |
| REVIEW_FAILED | 审查未通过 | 需要修改 |
| TEST_PASSED | 测试通过 | 测试套件通过 |
| TEST_FAILED | 测试失败 | 需要修复 |
| RESEARCH_COMPLETED | 研究完成 | 调研阶段完成 |
| DECISION_RECORDED | 记录决策 | 架构/技术决策 |
| DEPENDENCY_RESOLVED | 依赖解除 | 前置目标完成 |
| SESSION_HANDOFF | 会话交接 | 会话结束时的状态交接 |
| NOTE | 一般笔记 | 不改变状态的观察记录 |

### 4.4 完整模板

```markdown
# Ledger — 不可变操作日志

> 仅追加。不修改历史条目。

---

## [2026-06-09T14:30:15+08:00] GOAL_ACTIVATED

- **影响目标**: goal-001
- **描述**: 启动目标 — 搭建用户认证系统
- **结果**: success
- **证据**:
  - 读取了 goals/goal-001.md，状态从 paused 改为 active
  - 读取了 .omx/memory.md 获取项目上下文
  - 验证：无阻塞依赖，goal-001 依赖的 goal-000 已完成
- **下一步**: 开始 story-03 — 实现 JWT 令牌刷新

---

## [2026-06-09T14:15:00+08:00] SESSION_HANDOFF

- **影响目标**: goal-001
- **描述**: 上次会话交接 — story-02 完成，story-03 待开始
- **结果**: success
- **证据**:
  - story-02 的单元测试全部通过（15/15）
  - 代码审查通过，无阻塞问题
- **下一步**: 从 story-03 继续

---

## [2026-06-09T10:00:00+08:00] CODE_CHANGED

- **影响目标**: goal-001
- **描述**: 实现密码哈希和存储逻辑
- **结果**: success
- **证据**:
  - 文件变更: src/auth/password.ts (新增), src/auth/types.ts (修改)
  - 单元测试: 8/8 通过
  - Lint 检查: 0 错误
  - 安全审查: 使用 bcrypt，盐轮数 12
- **相关文件**:
  - src/auth/password.ts
  - src/auth/types.ts
  - tests/auth/password.test.ts
```

### 4.5 验证规则

| 规则 ID | 规则描述 | 严重性 |
|----------|----------|--------|
| LEDGER-V01 | 每一条目必须有 timestamp | ERROR |
| LEDGER-V02 | timestamp 必须递增（新条目时间 ≥ 最新条目时间） | ERROR |
| LEDGER-V03 | 不得修改或删除已有条目 | FATAL |
| LEDGER-V04 | result=failure 时 next_action 不能为空 | ERROR |
| LEDGER-V05 | affected_goal 必须存在于 goals/ 目录 | ERROR |
| LEDGER-V06 | operation_type 必须是 4.3 中定义的枚举值之一 | ERROR |
| LEDGER-V07 | evidence 字段不能为空 | ERROR |
| LEDGER-V08 | 连续两条同类型 entry 无实际进展时合并 | WARNING |

---

## 5. JSON Schema 定义

为了机器可读和自动校验，以下提供三种核心工件的 JSON Schema 表示。

### 5.1 brief.json (项目摘要 JSON 表示)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://trae.workspace/ultragoal/brief.json",
  "title": "Ultragoal Project Brief",
  "type": "object",
  "required": ["project_name", "description", "phase", "active_goals", "last_updated"],
  "properties": {
    "project_name": {"type": "string", "maxLength": 100},
    "description": {"type": "string", "maxLength": 200},
    "phase": {
      "type": "string",
      "enum": ["init", "active", "maintenance", "archived"]
    },
    "active_goals": {
      "type": "array",
      "maxItems": 5,
      "items": {"type": "string", "pattern": "^goal-\\d{3}$"},
      "uniqueItems": true
    },
    "last_updated": {"type": "string", "format": "date-time"},
    "next_session_recommendation": {"type": "string"},
    "blocker_summary": {"type": "string"},
    "completed_goals": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["goal_id", "name", "completed_date"],
        "properties": {
          "goal_id": {"type": "string", "pattern": "^goal-\\d{3}$"},
          "name": {"type": "string"},
          "completed_date": {"type": "string", "format": "date-time"},
          "result_summary": {"type": "string"}
        }
      }
    }
  },
  "additionalProperties": false
}
```

### 5.2 goal.json (目标 JSON 表示)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://trae.workspace/ultragoal/goal.json",
  "title": "Ultragoal Goal Definition",
  "type": "object",
  "required": ["goal_id", "name", "status", "priority", "created_date", "last_updated", "success_criteria", "current_progress"],
  "properties": {
    "goal_id": {"type": "string", "pattern": "^goal-\\d{3}$"},
    "name": {"type": "string", "maxLength": 200},
    "status": {
      "type": "string",
      "enum": ["active", "blocked", "completed", "paused"]
    },
    "priority": {
      "type": "string",
      "enum": ["P0", "P1", "P2", "P3"]
    },
    "created_date": {"type": "string", "format": "date"},
    "last_updated": {"type": "string", "format": "date-time"},
    "success_criteria": {
      "type": "array",
      "minItems": 1,
      "items": {"type": "string"}
    },
    "current_progress": {
      "type": "integer",
      "minimum": 0,
      "maximum": 100
    },
    "description": {"type": "string"},
    "dependencies": {
      "type": "array",
      "items": {"type": "string", "pattern": "^goal-\\d{3}$"}
    },
    "milestones": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["title", "target_progress", "completed"],
        "properties": {
          "title": {"type": "string"},
          "target_progress": {"type": "integer", "minimum": 0, "maximum": 100},
          "completed": {"type": "boolean"},
          "target_date": {"type": "string", "format": "date"}
        }
      }
    },
    "completion_date": {"type": "string", "format": "date-time"},
    "execution_mode": {
      "type": "string",
      "enum": ["aggregate", "per-story"]
    },
    "stories": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["story_id", "title", "status"],
        "properties": {
          "story_id": {"type": "string"},
          "title": {"type": "string"},
          "status": {"type": "string", "enum": ["pending", "active", "completed"]}
        }
      }
    },
    "effort_estimate": {"type": "string"},
    "tags": {
      "type": "array",
      "items": {"type": "string"}
    },
    "blocked_by": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["reason", "since"],
        "properties": {
          "reason": {"type": "string"},
          "since": {"type": "string", "format": "date"},
          "solution": {"type": "string"}
        }
      }
    }
  },
  "additionalProperties": false
}
```

### 5.3 ledger-entry.json (单条日志 JSON 表示)

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://trae.workspace/ultragoal/ledger-entry.json",
  "title": "Ultragoal Ledger Entry",
  "type": "object",
  "required": ["timestamp", "operation_type", "affected_goal", "description", "result", "evidence"],
  "properties": {
    "timestamp": {"type": "string", "format": "date-time"},
    "operation_type": {
      "type": "string",
      "enum": [
        "GOAL_CREATED", "GOAL_ACTIVATED", "GOAL_PAUSED", "GOAL_BLOCKED",
        "GOAL_UNBLOCKED", "GOAL_COMPLETED", "MILESTONE_REACHED",
        "STORY_STARTED", "STORY_COMPLETED", "CODE_CHANGED",
        "REVIEW_PASSED", "REVIEW_FAILED", "TEST_PASSED", "TEST_FAILED",
        "RESEARCH_COMPLETED", "DECISION_RECORDED", "DEPENDENCY_RESOLVED",
        "SESSION_HANDOFF", "NOTE"
      ]
    },
    "affected_goal": {"type": "string", "pattern": "^goal-\\d{3}$"},
    "description": {"type": "string", "maxLength": 500},
    "result": {
      "type": "string",
      "enum": ["success", "failure", "partial"]
    },
    "evidence": {"type": "string"},
    "next_action": {"type": "string"},
    "related_files": {
      "type": "array",
      "items": {"type": "string"}
    }
  },
  "additionalProperties": false
}
```

---

## 6. 与 OMX 系统的集成契约

### 6.1 OMX 记忆同步

| 触发事件 | 同步操作 |
|----------|----------|
| 目标创建 (GOAL_CREATED) | 写入 OMX 记忆: category=NOTE, content=目标摘要 |
| 决策记录 (DECISION_RECORDED) | 写入 OMX 记忆: category=DECISION, content=决策内容 |
| 研究完成 (RESEARCH_COMPLETED) | 写入 OMX 记忆: category=TECH_STACK 或 NOTE |
| 会话交接 (SESSION_HANDOFF) | 更新 .omx/notepad.md: #PRIORITY + #WORKING |
| 目标完成 (GOAL_COMPLETED) | 写入 OMX 记忆: category=DECISION, 记录经验教训 |

### 6.2 OMX 计划集成

当 $ultragoal 与 .omx/plans/ 系统协作时：

- 目标初始化时，复制 `omx-goal.json` 模板到 `plans/goals/<goal_id>.json`
- 目标执行过程中，同步更新 JSON 计划的 phases、evidence_log
- 目标完成时，JSON 计划的 completed_at 与 goals/<goal_id>.md 的 completion_date 保持一致

### 6.3 技能链集成

```
$deep-interview / $brainstorming
    ↓ (需求输出)
$prometheus-strict (可选: 严格规划)
    ↓ (规划工件)
$ultragoal (本技能) ← 本文档定义的输出规范适用
    ↓ (目标状态)
$autoresearch / $executor / $ralph-loop
    ↓ (实现)
$code-review / $qa-testing / $security-review
    ↓ (质量验证)
$ultragoal (回到目标: 更新进度、记录 ledger)
```

---

## 7. 状态机

### 7.1 目标状态转换

```
                    ┌──────────┐
                    │  paused  │
                    └────┬─────┘
                         │ GOAL_ACTIVATED
                         ▼
   GOAL_CREATED     ┌──────────┐    GOAL_BLOCKED     ┌──────────┐
   ──────────────►  │  active   │ ─────────────────►  │ blocked  │
                    └────┬─────┘                     └────┬─────┘
                         │ GOAL_COMPLETED                 │ GOAL_UNBLOCKED
                         ▼                                ▼
                    ┌──────────┐                     ┌──────────┐
                    │completed │ ◄─────────────────── │  active  │
                    └──────────┘    GOAL_COMPLETED    └──────────┘
```

### 7.2 转换规则

| 当前状态 | 允许的操作类型 | 禁止的操作类型 |
|----------|---------------|----------------|
| (不存在) | GOAL_CREATED | 所有其他 |
| active | 全部（除 GOAL_CREATED） | GOAL_CREATED |
| blocked | GOAL_UNBLOCKED, GOAL_COMPLETED, GOAL_PAUSED, NOTE | GOAL_ACTIVATED, CODE_CHANGED |
| paused | GOAL_ACTIVATED | 所有改变状态的（除 GOAL_ACTIVATED） |
| completed | 仅 NOTE | GOAL_ACTIVATED, GOAL_BLOCKED 等 |

---

## 8. 反模式 / 红牌

| 反模式 | 严重性 | 说明 |
|--------|--------|------|
| 不更新 brief.md 就结束会话 | FATAL | 每次会话必须同步 brief.md |
| 修改 ledger.md 历史条目 | FATAL | ledger 是仅追加的不可变日志 |
| 不追加 ledger 条目就声称完成 | FATAL | 每个操作必须有 ledger 记录 |
| 活跃目标超过 5 个不处理 | ERROR | 超过上限必须暂停或完成 |
| goal 文件名与内部 goal_id 不一致 | ERROR | 必须匹配 |
| 状态转换不符合状态机 | ERROR | 遵循 7.1 状态转换图 |
| success_criteria 不可验证 | ERROR | 每条标准必须可客观验证 |
| evidence 字段为空 | ERROR | 每个 ledger 条目必须有证据 |

---

## 9. 工具函数参考

为支持规范的程序化校验，推荐实现以下工具函数：

| 函数 | 用途 |
|------|------|
| `validate_brief(brief)` → ValidationResult | 校验 brief.md 或 brief.json |
| `validate_goal(goal)` → ValidationResult | 校验 goals/<id>.md 或 goal.json |
| `validate_ledger_entry(entry)` → ValidationResult | 校验单条 ledger |
| `validate_state_transition(from, to)` → boolean | 校验目标状态转换合法性 |
| `sync_to_omx_memory(artifacts)` → void | 将 ultragoal 工件同步到 .omx/ 记忆系统 |
| `generate_goal_id()` → string | 生成下一个 goal-NNN ID |

---

## 10. 版本

**当前版本:** 1.0.0
**最后更新:** 2026-06-09
**关联技能:** `$ultragoal` @ `skills/ultragoal/SKILL.md`
**关联模板:** `.omx/plans/omx-goal.json`
