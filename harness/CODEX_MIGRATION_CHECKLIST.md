# CodeX 迁移清单（Cursor → CodeX · 一页）

> 协议详情见 [docs/CODEX_ZERO_CONFIG_HANDOFF.md](../docs/CODEX_ZERO_CONFIG_HANDOFF.md) · 压缩 handoff 见 [harness/session-handoff.md](./session-handoff.md)

## 1. 关闭 / 切换

- [ ] 在 CodeX 中打开**同一文件夹**: `E:\raindeer`
- [ ] **不要**移动或复制仓库；`.env.local` 留在原位
- [ ] Cursor 可保留；避免两边同时改同一真源文件

## 2. Orchestrator 首聊

- [ ] 新建 CodeX 聊天（总调度唯一对用户接口）
- [ ] 粘贴 `harness/templates/codex-zero-config-prompt.md` **全文**
- [ ] 末尾追加 session-handoff 中的 **CONTEXT 一行**（见 `harness/session-handoff.md` §Codex Migration Block）
- [ ] 等待 orchestrator 读取真源并汇报 `next_atomic_action`

## 3. Worker 子聊（可选）

- [ ] 每个独立任务开新聊天
- [ ] 粘贴 `harness/templates/codex-subagent-prompt.md`
- [ ] 填入 `ROLE_ID`（见 `harness/reports/EMPLOYEE_ROSTER.md`）
- [ ] 完成后把 report 交回 orchestrator 聊天

## 4. 接手验证

```powershell
cd E:\raindeer\apps\quant_assistant
$env:PYTHONPATH='src'
uv run python -c "from qa.env import load_env_files; load_env_files(); from qa.db.dsn_guard import assert_test_dsn_isolated; assert_test_dsn_isolated(); print('OK')"
Get-Process -Id 155060 -ErrorAction SilentlyContinue
Get-Content tmp/daily_trade_status_batch_2014-06_2016-05-loop127.log -Tail 5
```

- [ ] DSN isolation OK
- [ ] tick3 PID 155060 仍 alive（或 log/DB 显示 complete）
- [ ] `harness/loop-state.json` 与 PROJECT_STATUS 顶部一致

## 5. Git 边界（GP-08）

| 仓库 | 分支 | upstream |
|---|---|---|
| AWI 根 | `main` | `origin/raindeer-AWI` |
| quant | `main` | `origin/main` |

- [ ] 确认两仓库均在 `main`
- [ ] **禁止**日常 feature/`cursor/*` 分支

## 6. 禁止事项

- [ ] 不重复启动 daily_bar（3995/3995 complete）
- [ ] 不重复启动 tick3（若 PID alive）
- [ ] 不碰 `.env` / `.env.local`
- [ ] 不 commit/push（除非用户明确要求）

## 7. Automations（用户手动）

- [ ] CodeX/Cursor UI 配置 `loop-tick`（`harness/templates/loop-tick-prompt.md`）
- [ ] 配置 `daily-git-push`（`harness/templates/daily-git-push-prompt.md`）
- [ ] 可选 `awi-daily-audit`

> 文件级 loop-state / backfill 进度**已保留**；Automation 调度需在 UI 重新启用。

## 8. 确认无损

- [ ] `harness/loop-state.json` · `next_atomic_action` 可读
- [ ] `apps/quant_assistant/docs/PROJECT_STATUS.md` §5 台账连续
- [ ] `harness/reports/EMPLOYEE_ROSTER.md` 员工清单 intact
- [ ] backfill log 可续读
