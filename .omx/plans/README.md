# .omx/plans/ — OMX 工作流模板

> 本目录存放 OMX 标准工作流的 JSON 模板。
> 每个模板定义对应工作流的阶段序列和质量门禁。

---

## 模板清单

| 文件 | 模板 ID | 描述 | 阶段 | 门禁 |
|------|---------|------|------|------|
| `omx-standard.json` | `omx-standard` | 标准开发流 | 7 阶段 | G-OMX-STD-01 ~ 07 |
| `omx-research.json` | `omx-research` | 研究探索流 | 4 阶段 | G-OMX-RES-01 ~ 04 |
| `omx-goal.json` | `omx-goal` | 目标执行流 | 4 阶段 | G-OMX-GOAL-01 ~ 04 |

---

## 1. omx-standard.json — 标准开发流

**阶段序列**：INTAKE → RESEARCH → PLAN → EXECUTE → REVIEW → VERIFY → HANDOFF

| 阶段 | 名称 | 门禁 | 说明 |
|------|------|------|------|
| 1 | INTAKE | G-OMX-STD-01 | 需求接收与澄清 |
| 2 | RESEARCH | G-OMX-STD-02 | 研究与调研 |
| 3 | PLAN | G-OMX-STD-03 | 方案设计 |
| 4 | EXECUTE | G-OMX-STD-04 | 编码实现 |
| 5 | REVIEW | G-OMX-STD-05 | 代码审查 |
| 6 | VERIFY | G-OMX-STD-06 | 验证测试 |
| 7 | HANDOFF | G-OMX-STD-07 | 交付移交 |

**适用场景**：功能开发、Bug 修复、重构、性能优化、基础设施变更。

---

## 2. omx-research.json — 研究探索流

**阶段序列**：SURFACE_SCAN → DEEP_DIVE → CROSS_VALIDATION → SYNTHESIS

| 阶段 | 名称 | 门禁 | 说明 |
|------|------|------|------|
| 1 | SURFACE_SCAN | G-OMX-RES-01 | 表层扫描（广度） |
| 2 | DEEP_DIVE | G-OMX-RES-02 | 深度探索 |
| 3 | CROSS_VALIDATION | G-OMX-RES-03 | 交叉验证（信度） |
| 4 | SYNTHESIS | G-OMX-RES-04 | 综合合成（价值） |

**适用场景**：因子发现与评估、策略回测研究、数据特征探索、假设检验。

**对齐技能**：`$autoresearch`

---

## 3. omx-goal.json — 目标执行流

**阶段序列**：GOAL_INIT → EXECUTE_LOOP → VERIFY_COMPLETE → HANDOFF

| 阶段 | 名称 | 门禁 | 说明 |
|------|------|------|------|
| 1 | GOAL_INIT | G-OMX-GOAL-01 | 目标初始化 |
| 2 | EXECUTE_LOOP | G-OMX-GOAL-02 | 执行循环（支持跨会话续跑） |
| 3 | VERIFY_COMPLETE | G-OMX-GOAL-03 | 完成验证 |
| 4 | HANDOFF | G-OMX-GOAL-04 | 交付移交 |

**适用场景**：多会话长期目标执行、中大型功能开发、数据管道搭建。

**对齐技能**：`$ultragoal`

---

## 模板公共字段

所有模板均包含以下标准字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `template_id` | string | 模板唯一标识 |
| `name` | string | 模板名称 |
| `version` | string | 模板版本号 |
| `description` | string | 模板详细描述 |
| `applicable_scenarios` | string[] | 适用场景列表 |
| `_usage` | object | 使用说明（含 OMX 记忆上下文） |
| `phases[]` | array | 阶段序列 |
| `phases[].phase_id` | string | 阶段标识 |
| `phases[].gates[]` | array | 门禁序列 |
| `phases[].evidence_log[]` | array | 证据日志 |
| `phases[].outputs[]` | array | 阶段产出物 |
| `governance_references` | object | 治理文档引用 |
| `omx_memory_context` | object | OMX 记忆系统读写配置 |

---

## 门禁编号体系

```
G-OMX-STD-01 ~ 07   标准工作流
G-OMX-RES-01 ~ 04   研究工作流
G-OMX-GOAL-01 ~ 04  目标工作流
```

模板由 Agent 在运行时读取并实例化。门禁通过结果和阶段证据写入 `evidence_log[]`。
