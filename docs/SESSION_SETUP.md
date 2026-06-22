# Session Setup Checklist (CodeX Platform)

CodeX 当前有效入口：日常只开 **AWI / orchestrator**。跨会话 worker 必须通过 CodeX `create_thread` 或 UI 新建线程，并粘贴 `harness/templates/codex-subagent-prompt.md` 的填充版本。`harness/mailbox/` 只作为 portable fallback 和审计轨迹。

导入后请在 CodeX 中创建以下会话（名称与模型见 registry）：

| 会话名 | role_id | kind | model | 源文件 |
|--------|---------|------|-------|--------|
| AWI / orchestrator | orchestrator | orchestrator | opus | agents/orchestrator.md ← **唯一对用户** |
| AWI / architect | architect | worker | opus | agents/architect.md |
| AWI / code-reviewer | code-reviewer | worker | sonnet | agents/code-reviewer.md |
| AWI / constitution-guardian | constitution-guardian | worker | inherit | agents/constitution-guardian.md |
| AWI / critic | critic | worker | opus | agents/critic.md |
| AWI / debugger | debugger | worker | sonnet | agents/debugger.md |
| AWI / designer | designer | worker | sonnet | agents/designer.md |
| AWI / executor | executor | worker | sonnet | agents/executor.md |
| AWI / explore | explore | worker |  | agents/explore.md |
| AWI / explorer | explorer | worker | inherit | agents/explorer.md |
| AWI / git-master | git-master | worker | sonnet | agents/git-master.md |
| AWI / governance-coordinator | governance-coordinator | worker | inherit | agents/governance-coordinator.md |
| AWI / growth-engineer | growth-engineer | worker | sonnet | agents/growth-engineer.md |
| AWI / planner | planner | worker | opus | agents/planner.md |
| AWI / qa-tester | qa-tester | worker | sonnet | agents/qa-tester.md |
| AWI / researcher | researcher | worker | inherit | agents/researcher.md |
| AWI / scientist | scientist | worker | opus | agents/scientist.md |
| AWI / security-reviewer | security-reviewer | worker | sonnet | agents/security-reviewer.md |
| AWI / test-engineer | test-engineer | worker | sonnet | agents/test-engineer.md |
| AWI / tracer | tracer | worker | sonnet | agents/tracer.md |
| AWI / verifier | verifier | worker | sonnet | agents/verifier.md |
| AWI / writer | writer | worker | sonnet | agents/writer.md |

## 使用方式

1. 日常只打开 **orchestrator** 会话。
2. 将 `harness/templates/codex-zero-config-prompt.md` 粘贴到 orchestrator 首条消息。
3. 各 worker 会话粘贴 `harness/templates/codex-subagent-prompt.md`（填入 `ROLE_ID` / `identity_id` / `task_id` / `target_files`）。
4. CodeX 原生跨会话优先使用 `create_thread` / `send_message_to_thread`；文件总线用于 fallback 和审计。
5. CodeX 定时任务由 `automation_update` 创建，登记在 `harness/codex-automation-registry.json`。

## 验证

```powershell
.\harness\scripts\codex-self-check.ps1 -Format markdown
.\harness\compliance-check.ps1 -Mode post-bootstrap
```
