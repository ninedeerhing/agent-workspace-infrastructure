# AWI Compliance Baseline

**日期**: 2026-06-15  
**主线**: `TREE-RT`  
**范围**: Phase 0 初始基线 + 首批运行时脚手架后复检

## 执行命令

```powershell
.\harness\compliance-check.ps1 -TargetPath .                # baseline
.\harness\scripts\Build-AgentRegistryFromAgentsDir.ps1 `
  -TargetPath . -HubModel "opus" -WriteFiles -EnsureScaffold
.\harness\compliance-check.ps1 -TargetPath . -Mode post-bootstrap
```

## Baseline 结果

初次 baseline 检查发现 2 个缺口：

1. `workflow-state.json` 未设置 `active_workflow`
2. `harness/agent-registry.json` 尚未生成

## 首批脚手架后复检

已落地：

- `docs/SESSION_BOOT.md`
- `harness/compliance-check.ps1`
- `harness/scripts/Build-AgentRegistryFromAgentsDir.ps1`
- `harness/agent-registry.json`
- `harness/team-manifest.default.json`
- `harness/worklogs/*`

post-bootstrap 复检剩余 1 个告警：

1. `workflow-state.json` 未锁定工作流

该问题已在当前轮实现中修复：`active_workflow = "standard"`，并补充 `current_context.active_task/tree_id/active_phase`。

## 当前判断

- Phase 0 基线检查：**已落地**
- Phase 1 最小启动契约：**已落地**
- Phase 7 roster 生成骨架：**已落地（首版）**

未完成项：

- `schedule.json` 已接入 loop-tick / methodology-lifecycle（2026-06-19）；**启用 Automation 后**方为真跨会话循环
- worker 契约批量补强、mailbox 协议文档、平台 adapter 仍待后续 Phase

## Loop / 方法论 / 治理 lifecycle 自检扩展（2026-06-20）

`compliance-check.ps1` baseline 追加（2026-06-19 起 MEM/LOOP；2026-06-20 起 SYNC/VER/CLO）：

| Code | 检查 |
|------|------|
| CFG-006 | `docs/LOOP_ENGINEERING.md` |
| CFG-007 | `harness/loop-state.json` |
| CFG-008 | `apps/quant_assistant/docs/METHODOLOGY_MEMORY.md` |
| LEDGER-003/004 | 业务 `PROJECT_STATUS` §5 |
| MEM-001…004 | 方法论轮次 / index / last_lifecycle |
| LOOP-001…005 | next_atomic_action · orchestrator/worker 汇报 |
| SYNC-001/002 | sync-coherence-index 新鲜度 · 五真源 drift |
| VER-001 | verification-snapshot-index 新鲜度 |
| CLO-001/002 | closure-gate-index · open_count |

日度审计 prompt：`harness/templates/awi-daily-audit-prompt.md`（六真源 + 五 lifecycle + compliance 矩阵 + 八段输出；2026-06-20 架构对齐）。

## Bootstrap Smoke Test

```powershell
.\bootstrap.ps1 -TargetPath <temp> -ProjectName "SmokeProject" -Mode full -ProvisionTeam -Platform generic
```

结果：

- 参数 `-ProvisionTeam` 已实际跑通
- 能生成 `agent-registry.json`、`team-manifest.default.json`、`platform-binding.json`
- 首次 smoke 暴露了 full-mode 拷贝判断中的 PowerShell 逻辑错误，已修复后复跑通过
- `init.ps1` 在新项目上返回若干 warning，但无 fail，不阻塞导入完成

