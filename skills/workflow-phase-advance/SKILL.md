---
name: workflow-phase-advance
description: Raindeer-AWI 工作流阶段推进。触发条件：切换 INTAKE/RESEARCH/PLAN/EXECUTE 等阶段、gate-runner 门禁、更新 workflow-state.json、心流模式阶段切换。
---

# Workflow Phase Advance

## 定位

在切换工作流阶段前，强制门禁检查并更新 `harness/workflow-state.json`。

## 标准流阶段

```text
INTAKE → RESEARCH → PLAN → EXECUTE → REVIEW → VERIFY → HANDOFF
```

## 推进协议

1. 确认当前阶段与目标阶段（只能 **+1** 顺序推进）。
2. 运行 gate-runner：

```powershell
.\harness\gate-runner.ps1 -Workflow standard -FromPhase RESEARCH -ToPhase PLAN
```

3. 若 FAIL：补齐 `workflow-state.json` 中 `phase_gate_status.gates[G-STD-xx].result = PASS` 及证据。
4. 更新 `workflow-state.json`：
   - `current_phase` → 新阶段
   - `phase_history` 追加条目
5. 有实现/测试/决策 → 写 `docs/PROJECT_STATUS.md` §5。

## 门禁映射

| 跳转 | Gate ID |
|------|---------|
| INTAKE→RESEARCH | G-STD-01 |
| RESEARCH→PLAN | G-STD-02 |
| PLAN→EXECUTE | G-STD-03 |
| EXECUTE→REVIEW | G-STD-04 |
| REVIEW→VERIFY | G-STD-05 |
| VERIFY→HANDOFF | G-STD-06 |

## orchestrator 职责

- 只有 orchestrator 可决定对用户报告阶段切换。
- worker 阶段内工作完成后通过 mailbox 回报，不自行跳阶段。

## 验证

- gate-runner 返回 exit 0
- workflow-state 与 TASK_TREES 主线一致
