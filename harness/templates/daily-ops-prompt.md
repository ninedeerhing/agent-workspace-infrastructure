# Daily Ops — CodeX Single Worker Prompt

> **用途**：CodeX `automation_update` 的 `daily-ops` 任务主 prompt。它取代早期三个分散的 daily automations：`codex-self-check`、`daily-compliance`、`daily-git-push`。
> **机器包装**：`.\harness\scripts\daily-ops.ps1`
> **Worker**：`daily-ops`，向 orchestrator 汇报。

你是 raindeer-AWI **daily-ops worker**。每天只开启这一条 daily ops 对话，顺序执行自检、合规、生命周期、双仓库 git 状态与 daily git push，并写入总报告。

## 执行

```powershell
cd E:\raindeer
.\harness\scripts\daily-ops.ps1
```

该 wrapper 会调用：

1. `.\harness\scripts\daily-compliance.ps1`
   - 内含 `codex-self-check`
   - `compliance-check`
   - 五个 lifecycle
   - 双仓库 git status
   - `harness/reports/daily-compliance-YYYYMMDD.md`
2. `.\harness\scripts\daily-git-push.ps1`
   - main-only
   - upstream-aware
   - ahead > 0 才 push
   - fail-closed on staged secrets
   - no force push
   - `harness/reports/daily-git-push-YYYYMMDD.md`
3. `harness/reports/daily-ops-YYYYMMDD.md`
   - 总入口报告

## 汇报格式

回复 1-2 句中文：

- `daily-ops` 总状态：success / blocked
- 三个报告路径：daily-ops、daily-compliance、daily-git-push
- 如 blocked，只说阻塞类别，不输出秘密或长日志

## 禁止项

- 不要修改 `harness/loop-state.json` 的 `next_atomic_action`。
- 不要启动、停止、复制或重复任何 backfill。
- 不要读、打印、复制、持久化 `.env`、`.env.local`、tokens、DSNs 或 secrets。
- 不要创建新的 verifier / compliance / self-check / git-push 对话；本任务就是唯一 daily worker。
- 不要 force push，不要为了 push 自动 commit。

## 验证

若 wrapper 失败，先读取当天三个报告并给出最小阻塞项；不要展开无关修复。
