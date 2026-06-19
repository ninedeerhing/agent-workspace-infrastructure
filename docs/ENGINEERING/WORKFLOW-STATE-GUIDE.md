# Workflow State 指南

## 文件

`harness/workflow-state.json`

## 关键字段

| 字段 | 用途 |
|------|------|
| `active_workflow` | 当前工作流：`standard` / `complex` / `product` / `tdd` |
| `current_phase` | 当前阶段名 |
| `current_context.tree_id` | 关联 TASK_TREES 主线 |
| `phase_gate_status.gates` | 门禁 PASS 证据 |
| `phase_history` | 阶段切换历史 |

## 阶段推进

使用 `$workflow-phase-advance` 或：

```powershell
.\harness\gate-runner.ps1 -Workflow standard -FromPhase PLAN -ToPhase EXECUTE
```

## 与心流模式

- 心流模式禁止无证据跳阶段。
- gate-runner FAIL 时 orchestrator 不得对用户声称已进入下一阶段。

## 与 compliance

- baseline 检查要求 JSON 可解析且有 `active_workflow`。
- 脏工作区 + 无当日 §5 台账 → LEDGER-002 警告。
