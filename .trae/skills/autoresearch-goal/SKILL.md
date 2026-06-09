---
name: autoresearch-goal
description: 将 $autoresearch 的有界验证器门控研究流程与 $ultragoal 的持久化目标跟踪框架融合。把研究任务实例化为可跨会话持久化的目标，遵循三阶段门控研究（边界定义→表层扫描→深度探索→综合输出），每阶段通过验证门后在 ledger 中记录不可变审计日志。触发条件：需要对不熟悉的代码库/API/框架开展深入调研，且调研成果需要跨会话持久化、需要目标级进度跟踪、或需要为后续开发提供可追溯的研究证据链。
---

# Autoresearch-Goal — 持久化有界目标研究

## 铁律

> **NO FINDINGS WITHOUT EVIDENCE. NO DEEPER DIVE WITHOUT VERIFICATION. NO PROGRESS WITHOUT LEDGER.**
> 没有证据不得声称发现。未通过验证门不得深入下一层。没有 ledger 记录不得声称进度。

## 定位

`autoresearch-goal` 是 `$autoresearch` 与 `$ultragoal` 的融合技能。它将研究任务提升为一级持久化目标——使用 ultragoal 的工件体系（brief.md、goals/、ledger.md）保持跨会话状态，同时遵循 autoresearch 的严格三阶段门控方法论。本技能适用于那些研究深度深、周期长、需要多会话推进的调研任务。

## 触发条件

- 需要进行跨越多个会话的深入技术调研
- 研究范围广（10+ 文件、2+ 模块、外部依赖复杂）
- 研究结果需要作为后续开发的可追溯证据基础
- 研究结论需要多轮验证和交叉确认
- 需要目标级别的进度追踪和阻塞项管理
- 研究输出需要作为项目知识库的一部分持久保存

## 不触发条件

- 单次会话即可完成的小范围调研 → 使用 `$autoresearch`
- 研究目标本身就是一个完整的产品功能 → 使用 `$ultragoal` + `$autoresearch` 分离
- 只需要快速回答问题而非深入调研 → 使用 `$explore` 或 `$researcher`
- 纯粹的最佳实践调研 → 使用 `$best-practice-research`

---

## 核心概念

### 研究即目标（Research as Goal）

每一项 `autoresearch-goal` 研究都是 ultragoal 体系中的一个持久化目标：

```
skills/autoresearch-goal/SKILL.md     ← 本文件（技能定义）
    ↓ 技能激活
.omx/plans/active/<goal_id>.json     ← OMX 计划实例（从 omx-research.json 模板复制）
    ↓ 同步更新
skills/ultragoal/ 工件体系:
    ├── brief.md                       ← 更新活跃目标列表
    ├── goals/<goal_id>.md             ← 目标定义和进度
    └── ledger.md                      ← 不可变操作日志
```

### 四阶段目标化研究流程

```
STAGE 0: GOAL_INIT → 初始化研究目标
    ↓ G-GOAL-RES-00 门禁
STAGE 1: SURFACE_SCAN → 表层扫描
    ↓ G-GOAL-RES-01 门禁
STAGE 2: DEEP_DIVE → 深度探索
    ↓ G-GOAL-RES-02 门禁
STAGE 3: SYNTHESIS → 综合输出 + 目标完成
    ↓ G-GOAL-RES-03 门禁
HANDOFF → 目标标记完成，产出交接
```

---

## 执行流程

### STAGE 0: 研究目标初始化 (Goal Initialization)

**必须在此阶段完成目标创建，才能开始任何研究操作。**

#### 步骤

1. **创建目标文件** `goals/<goal_id>.md`
2. **确定研究档位**（quick / standard / deep）
3. **定义有界参数**：范围、深度上限、时间盒
4. **写入 brief.md**：将研究目标加入活跃目标列表
5. **追加 ledger 条目**：GOAL_CREATED

#### 输出物

| 产出 | 位置 | 内容 |
|------|------|------|
| 目标定义文件 | `goals/<goal_id>.md` | 完整的目标定义（含研究边界） |
| brief.md 更新 | 项目根目录 | 活跃目标列表中新增此研究目标 |
| ledger 条目 | `ledger.md` | GOAL_CREATED 记录 |
| OMX 项目记忆 | `.omx/memory.md` | NOTE: 研究目标摘要 |

#### 目标定义中的研究边界字段

```markdown
## 研究边界（Autoresearch Bounds）

| 维度 | 设定 |
|------|------|
| 研究档位 | standard |
| 范围（纳入） | <模块A>、<模块B>、<API X> |
| 范围（排除） | <不涉及的模块> |
| 深度上限 | 3 层调用链 |
| 时间盒（总） | 60 分钟 |
| 时间盒（每阶段） | 10 分钟/阶段 |
```

#### 门禁 G-GOAL-RES-00: GOAL_INIT → SURFACE_SCAN

| 编号 | 条件 | 严重性 |
|------|------|--------|
| G-GOAL-RES-00.1 | 研究目标可用一句话说清 | **必须** |
| G-GOAL-RES-00.2 | 范围已明确界定（纳入 + 排除） | **必须** |
| G-GOAL-RES-00.3 | 深度上限已设定 | **必须** |
| G-GOAL-RES-00.4 | 时间盒已分配 | **必须** |
| G-GOAL-RES-00.5 | goals/<goal_id>.md 已创建 | **必须** |
| G-GOAL-RES-00.6 | brief.md 已更新（活跃目标 ≤ 5） | **必须** |
| G-GOAL-RES-00.7 | ledger GOAL_CREATED 已追加 | **必须** |

---

### STAGE 1: 表层扫描 (Surface Scan)

**目标**：快速建立全局认知，识别关键文件和核心概念。

#### 研究操作

1. **目录结构概览**：列出相关模块的文件树
2. **入口发现**：找到入口文件、主模块、配置文件
3. **符号索引**：识别核心类/函数/接口名称
4. **依赖识别**：列出关键的 import / require / 依赖声明
5. **文档速览**：阅读 README、关键注释、JSDoc/Docstring
6. **OMX 记忆加载**：读取 .omx/memory.md 中已有的技术栈和结构信息

#### 产出物

| 产出 | 格式 | 存放位置 |
|------|------|----------|
| 关键文件列表 | 表格（路径 + 职责 + 重要性） | `goals/<goal_id>.md` 的进度区 |
| 核心符号表 | 表格（符号名 → 文件:行号） | `goals/<goal_id>.md` 的进度区 |
| 依赖概览 | 文本/ASCII 图 | `goals/<goal_id>.md` 的进度区 |
| 未解问题列表 | 项目符号列表 | `goals/<goal_id>.md` 的进度区 |

#### 门禁 G-GOAL-RES-01: SURFACE_SCAN → DEEP_DIVE

> 此门禁与 `$autoresearch` 的验证门 1 对齐。

| 编号 | 条件 | 验证方式 | 严重性 |
|------|------|----------|--------|
| G-GOAL-RES-01.1 | 每个关键文件有绝对路径证据 | 列出文件完整路径 | **必须** |
| G-GOAL-RES-01.2 | 每个核心符号有位置证据 | 列出文件:行号 | **必须** |
| G-GOAL-RES-01.3 | 依赖关系有代码证据 | 列出 import/require 语句所在行 | **必须** |
| G-GOAL-RES-01.4 | 无遗漏明显入口或配置 | 对照目录树检查 | **必须** |
| G-GOAL-RES-01.5 | 不同来源信息交叉验证一致 | 在 ledger 中标注交叉验证结果 | **必须** |

**通过后操作**：
- 追加 ledger 条目（operation_type: RESEARCH_COMPLETED，描述: 表层扫描完成）
- 更新 goals/<goal_id>.md 的进度（建议 +25%）
- 更新 OMX 项目记忆：写回技术栈发现

**不通过处理**：
- 返回阶段 1，补充遗漏的证据
- 如范围边界不合理，回到 STAGE 0 调整边界

---

### STAGE 2: 深度探索 (Deep Dive)

**目标**：在表层基础上，追溯调用链、理解数据流、验证假设。

#### 研究操作

1. **调用链追踪**：从入口函数出发，向下追溯至深度上限
2. **数据流分析**：追踪关键数据从输入到输出的完整变换链
3. **条件分支映射**：识别关键的条件判断和分支逻辑
4. **配置影响分析**：配置项如何影响运行时行为
5. **错误路径探索**：异常处理和边界情况的处理方式

#### 产出物

| 产出 | 格式 | 存放位置 |
|------|------|----------|
| 调用链图 | 文本/ASCII（入口 → N 层深度） | `goals/<goal_id>.md` 进度区 |
| 数据流文档 | 结构化文本 | `goals/<goal_id>.md` 进度区 |
| 关键决策点 | 表格（条件 → 分支 → 后果） | `goals/<goal_id>.md` 进度区 |
| 边界条件汇总 | 列表 | `goals/<goal_id>.md` 进度区 |

#### 门禁 G-GOAL-RES-02: DEEP_DIVE → SYNTHESIS

> 此门禁与 `$autoresearch` 的验证门 2 对齐。

| 编号 | 条件 | 验证方式 | 严重性 |
|------|------|----------|--------|
| G-GOAL-RES-02.1 | 调用链每步有代码证据 | 列出每个调用点文件:行号 | **必须** |
| G-GOAL-RES-02.2 | 数据流完整闭环 | 输入到输出无断点 | **必须** |
| G-GOAL-RES-02.3 | 分支逻辑可复现 | 给定输入可预测分支走向 | **必须** |
| G-GOAL-RES-02.4 | 核心结论交叉验证通过 | ≥2 处独立证据支撑 | **必须** |
| G-GOAL-RES-02.5 | 追溯层数 ≤ 深度上限 | 计数 ≤ boundary.max_depth | **必须** |
| G-GOAL-RES-02.6 | ledger 中每条深度发现可追溯到代码行 | 每条证据含文件:行号 | **必须** |

**通过后操作**：
- 追加 ledger 条目（operation_type: RESEARCH_COMPLETED，描述: 深度探索完成）
- 更新 goals/<goal_id>.md 进度（建议 +50%，累计 75%）
- 更新 OMX 项目记忆

---

### STAGE 3: 综合输出 (Synthesis)

**目标**：将研究发现转化为结构化、可消费的最终输出，并完成目标。

#### 必须产出

1. **执行摘要**：一至两段话概括核心发现
2. **架构概览图**：ASCII 模块关系图（≥3 个模块）
3. **关键文件清单**：表格（路径 + 职责 + 重要性 + 证据引用）
4. **核心调用链**：从入口到关键节点的完整路径
5. **已知未知**：因边界限制未能探索的问题
6. **风险与建议**：发现的潜在问题和改进机会
7. **证据索引**：所有发现的文件:行号索引

#### 门禁 G-GOAL-RES-03: SYNTHESIS → HANDOFF

> 此门禁与 `$autoresearch` 的验证门 3 对齐，并附加 ultragoal 目标完成条件。

| 编号 | 条件 | 验证方式 | 严重性 |
|------|------|----------|--------|
| G-GOAL-RES-03.1 | 执行摘要可独立理解 | 无"如上所述"等依赖前文引用 | **必须** |
| G-GOAL-RES-03.2 | 所有断言有可追溯证据链 | 每个断言→门禁 01/02 证据 | **必须** |
| G-GOAL-RES-03.3 | 已知未知诚实标注 | 未探索区域明确标注 | **必须** |
| G-GOAL-RES-03.4 | 无过度推断 | 区分"代码做了什么"和"推测为什么" | **必须** |
| G-GOAL-RES-03.5 | 7 类交付物全部包含 | 逐一核对清单 | **必须** |
| G-GOAL-RES-03.6 | 目标成功标准全部满足 | 对照 STAGE 0 定义的标准 | **必须** |
| G-GOAL-RES-03.7 | goals/<goal_id>.md 进度更新为 100% | 进度字段检查 | **必须** |

**通过后操作**：
- 追加 ledger 条目（operation_type: GOAL_COMPLETED，result: success）
- 将目标状态从 active 改为 completed
- 更新 brief.md：从活跃目标移至已完成目标
- 写入 OMX 记忆：研究结论作为 DECISION 或 NOTE 持久化
- 发出完成声明（含验证证据）

---

## 与其他技能的协作

### 前置技能

| 技能 | 关系 |
|------|------|
| `$deep-interview` | 研究目标不清晰时先用深度访谈澄清 |
| `$brainstorming` | 研究方向和边界不明确时先头脑风暴 |
| `$best-practice-research` | 需要先确定最佳实践方向时使用 |

### 并行技能（研究期间可调用的辅助技能）

| 技能 | 关系 |
|------|------|
| `$dispatching-parallel-agents` | 多模块可并行研究时启用并行模式 |
| `$sciomc` | 多 scientist 代理并行分析多个模块 |

### 后置技能

| 技能 | 关系 |
|------|------|
| `$writing-plans` | 研究输出直接作为实现计划的证据输入 |
| `$ralplan` | 研究结论需要多方共识时使用 |
| `$executing-plans` | 研究完成后直接进入实现阶段 |
| `$code-review` | 研究产出可作为代码审查的参考基线 |

---

## 并行研究模式

当研究目标涉及多个独立模块时，可启用并行模式：

1. STAGE 0 统一初始化一个研究目标
2. STAGE 1 为每个模块并行执行（使用 `$dispatching-parallel-agents`）
3. 汇总阶段交叉验证不同分支发现的一致性
4. STAGE 2 按需并行或串行（取决于模块间是否有依赖）

**约束**：
- 最多 3 个并行研究分支
- 每个分支有独立的时间盒
- ledger 中标注每个分支的执行代理和证据来源

---

## 研究档位与 ultragoal 映射

| 档位 | 深度 | 文件数 | 单阶段时间 | 目标优先级建议 | 目标完成周期 |
|------|------|--------|-----------|---------------|-------------|
| **Quick** | 1-2 层 | <10 文件 | 5 分钟 | P2 | 单次会话 |
| **Standard** | 2-3 层 | 10-30 文件 | 10 分钟 | P1 | 1-2 次会话 |
| **Deep** | 3-5 层 | 30+ 文件 | 15 分钟 | P0 | 2-4 次会话 |

---

## 反模式 / 红牌

| 反模式 | 严重性 | 说明 |
|--------|--------|------|
| 未创建 ultragoal 目标就开始研究 | **FATAL** | 必须先初始化目标（STAGE 0） |
| 跳过验证门 | **FATAL** | 每阶段结束必须通过门禁检查 |
| 仅凭记忆声称发现 | **FATAL** | 所有发现必须有文件:行号或 URL 证据 |
| 无限深挖 | **FATAL** | 触达深度上限后必须停止，记录为"已知未知" |
| 不追加 ledger 条目 | **FATAL** | 每阶段结束、每次门禁通过必须追加 ledger |
| 不更新 brief.md 就结束会话 | **FATAL** | 每次会话结束必须同步 brief.md |
| 范围蔓延 | **FATAL** | 发现"应该也看看 X"，必须更新边界定义后才能继续 |
| 不产出结构化报告 | **ERROR** | 研究结束必须产出 7 类交付物 |
| 单点证据断言 | **ERROR** | 关键结论应有交叉验证（≥2 处独立证据） |
| 超过时间盒不停止 | **WARNING** | 到时间必须输出当前发现，记录未完成项 |
| 目标状态转换不合法 | **ERROR** | 必须遵循 ultragoal 状态机 |

---

## 输出物模板（完整研究产出）

```markdown
# 研究目标完成产出: <研究目标一句话>

## 执行摘要

<1-2 段话概括核心发现，确保可独立阅读>

---

## 架构概览

```
┌─────────┐    ┌─────────┐    ┌─────────┐
│ Module A │───▶│ Module B │───▶│ Module C │
└─────────┘    └─────────┘    └─────────┘
```

---

## 关键文件清单

| 文件 | 职责 | 重要性 | 证据 |
|------|------|--------|------|
| `path/to/file.ts` | 核心入口 | 高 | 入口文件 / L12-L45 |

---

## 核心调用链

**入口**: `entryFunction()` → `file.ts:42`
1. `stepOne()` → `file2.ts:15`
2. `stepTwo()` → `file3.ts:88`

---

## 已知未知

- [因边界限制未探索的问题]

---

## 风险与建议

- [发现的风险 / 改进建议]

---

## 证据索引

- [证据 1]: `file.ts:42-55`
- [证据 2]: `config.json:12-18`

---

## 关联 Ledger 条目

- [2026-06-09T10:00:00Z] GOAL_CREATED
- [2026-06-09T10:30:00Z] RESEARCH_COMPLETED — 表层扫描
- [2026-06-09T11:00:00Z] RESEARCH_COMPLETED — 深度探索
- [2026-06-09T11:30:00Z] GOAL_COMPLETED — 综合输出完成
```

---

## ledger 条目模板（每阶段追加）

```markdown
## [2026-06-09T11:00:00+08:00] RESEARCH_COMPLETED

- **影响目标**: goal-XXX
- **描述**: 深度探索阶段完成 — 已追溯调用链至深度 3，数据流完整闭环
- **结果**: success
- **证据**:
  - 调用链: `funcA()`(file1.ts:42) → `funcB()`(file2.ts:15) → `funcC()`(file3.ts:88)
  - 数据流: 输入 UserRequest → transform → Repository.save() → DB
  - 分支逻辑: 已验证 3 条关键分支路径
  - 交叉验证: 结论 A 被 file1.ts:42 和 API 文档 v2.3 双重确认
- **下一步**: 进入 SYNTHESIS 阶段，产出结构化研究报告
- **相关文件**:
  - src/module/file1.ts
  - src/module/file2.ts
  - src/module/file3.ts
  - docs/api-reference.md
```

---

## 与 OMX 系统的集成

| 集成点 | 触发时机 | 操作 |
|--------|----------|------|
| `.omx/memory.md` | 每阶段结束时 | 写入研究发现（NOTE + TECH_STACK） |
| `.omx/notepad.md` | 会话交接时 | 更新 PRIORITY 和 WORKING 区 |
| `.omx/plans/active/<goal_id>.json` | 目标初始化时 | 从 omx-research.json 模板复制 |
| `project-memory.json` | 研究完成时 | 写入架构发现（STRUCTURE + DECISION） |

---

## 版本

**当前版本:** 1.0.0
**最后更新:** 2026-06-09
**依赖技能:** `$autoresearch`、`$ultragoal`
**关联模板:** `.omx/plans/omx-research.json`、`.omx/plans/omx-goal.json`
**关联规范:** `skills/ultragoal/OUTPUT_SPEC.md`
