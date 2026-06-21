# Daily Compliance Report · 20260620

- **Checked at**: 2026-06-20 13:07:25
- **Project root**: E:\raindeer
- **compliance-check exit**: 1
- **Schedule task id**: `daily-compliance` (cron `0 20 * * *`)

## compliance-check

# Compliance Report

- Mode: baseline
- Project: E:\raindeer
- Checked At: 2026-06-20 13:07:24
- Checks: 31 / Findings: 3

## Checks

| Name | Status | Detail |
|------|--------|--------|
| AGENTS-lite | PASS | E:\raindeer\AGENTS-lite.md |
| PROJECT_STATUS | PASS | E:\raindeer\docs\PROJECT_STATUS.md |
| TASK_TREES | PASS | E:\raindeer\docs\TASK_TREES.md |
| FLOW-MODE | PASS | E:\raindeer\docs\FLOW-MODE.md |
| LOOP_ENGINEERING | PASS | E:\raindeer\docs\LOOP_ENGINEERING.md |
| workflow-state | PASS | E:\raindeer\harness\workflow-state.json |
| loop-state | PASS | E:\raindeer\harness\loop-state.json |
| METHODOLOGY_MEMORY | PASS | E:\raindeer\apps\quant_assistant\docs\METHODOLOGY_MEMORY.md |
| 当前主线登记 | PASS | TREE-RT |
| §5 台账条目 | PASS | latest=2026-06-15 |
| workflow-state 当前工作流 | PASS | standard |
| SESSION_BOOT | PASS | E:\raindeer\docs\SESSION_BOOT.md |
| agents roster | PASS | 22 files |
| agent-registry | PASS | E:\raindeer\harness\agent-registry.json |
| Git 工作区 | WARN | 25 dirty entries |
| QA PROJECT_STATUS §5 | PASS | E:\raindeer\apps\quant_assistant\docs\PROJECT_STATUS.md |
| METHODOLOGY 轮次复盘 | PASS | rounds present |
| loop-state next action | PASS | daily_trade_status batch_24mo 2012-06→2014-05 · 或 BENCH-2 ②（env deferred · 需用户 U |
| methodology-memory-index | PASS | E:\raindeer\harness\methodology-memory-index.json |
| MEM-004 last_lifecycle freshness | PASS | at=06/20/2026 05:06:17 age=8.01863324341667h |
| orchestrator-work-report | PASS | E:\raindeer\harness\reports\orchestrator\latest.md |
| worker-work-reports | PASS | count=22 |
| work-reports-index | PASS | E:\raindeer\harness\work-reports-index.json |
| sync-coherence-index | PASS | E:\raindeer\harness\sync-coherence-index.json |
| SYNC-001 freshness | PASS | at=06/20/2026 05:06:17 age=8.01867497858333h |
| verification-snapshot-index | PASS | E:\raindeer\harness\verification-snapshot-index.json |
| VER-001 freshness | PASS | at=06/20/2026 05:06:17 age=8.01871632313889h |
| closure-gate-index | PASS | E:\raindeer\harness\closure-gate-index.json |
| CLO-001 freshness | PASS | at=06/20/2026 05:06:18 age=8.0184774845h |
| SYNC coherence drift | WARN | warnings=1 |
| CLO closure candidates | WARN | open=19 |

## Findings

| Severity | Code | Title | Detail | Recommendation |
|----------|------|-------|--------|----------------|
| warning | LEDGER-002 | 脏工作区缺少当日台账 | 检测到 Git 未提交变更，但最新台账日期不是今天。 | 在 §5 追加今日条目，记录本轮实现/测试/决策。 |
| warning | SYNC-002 | 五真源漂移 | sync-coherence-index 含 1 条 warning | 更新 PROJECT_STATUS 顶部现状概述并与 loop-state/CONTINUATION 对齐 |
| warning | CLO-002 | 收口候选未闭合 | closure-gate-index open_count=19 | 补 synthesis-* 或显式 没有 |


## loop_tick status

```text
{
  "stopped": false,
  "stop_detail": "",
  "next_atomic_action": "daily_trade_status batch_24mo 2012-06→2014-05 · 或 BENCH-2 ②（env deferred · 需用户 Ubuntu）",
  "next_after": "daily_trade_status batch_24mo 续跑 · optional daily_bar_repair stage 接线",
  "updated_at": "2026-06-20T12:15:27Z",
  "last_tick": "loop97-tree2-daily-trade-status-batch24mo-gap004",
  "last_lifecycle_run": {
    "at": "2026-06-20T05:06:17Z",
    "apply": true,
    "dedupe_actions": 0,
    "dream_candidates": 0,
    "closure_candidates": 0,
    "archived_rounds": [],
    "active_step_digests": 9,
    "completed_tasks_hint": [
      "loop97 batch_24mo 583 days daily_trade_status · cnt=3421656 · snapshot 20260620-121527 · GAP-004 首 chunk",
      "daily-trade-status-batch24mo-gap004",
      "loop97-tree2-daily-trade-status-batch24mo-gap004"
    ],
    "ttl_days": 180
  },
  "lifecycle_runs": {
    "methodology_memory": {
      "at": "2026-06-20T05:06:17Z",
      "apply": true,
      "dedupe_actions": 0,
      "dream_candidates": 0,
      "closure_candidates": 0,
      "archived_rounds": [],
      "active_step_digests": 9,
      "completed_tasks_hint": [
        "loop97 batch_24mo 583 days daily_trade_status · cnt=3421656 · snapshot 20260620-121527 · GAP-004 首 chunk",
        "daily-trade-status-batch24mo-gap004",
        "loop97-tree2-daily-trade-status-batch24mo-gap004"
      ],
      "ttl_days": 180
    },
    "work_reports": {
      "at": "2026-06-20T05:06:17Z",
      "apply": true,
      "dedupe_actions": 0,
      "record_count": 22,
      "created": []
    },
    "sync_coherence": {
      "at": "2026-06-20T05:06:17Z",
      "finding_count": 1,
      "warning_count": 1,
      "error_count": 0
    },
    "verification_snapshot": {
      "at": "2026-06-20T05:06:17Z",
      "apply": true,
      "stale": false,
      "git_dirty": true,
      "age_hours": 11.614983840833334
    },
    "closure_gate": {
      "at": "2026-06-20T05:06:18Z",
      "open_count": 19,
      "closed_count": 1,
      "explicit_none_count": 0,
      "candidate_count": 20
    }
  }
}
```

## Five lifecycles (run --apply)

| Lifecycle | Exit | Output (truncated) |
|-----------|------|-------------------|
| methodology_memory | 0 | {
  "apply": true,
  "dedupe_actions": [],
  "dream_candidates": [],
  "closure_candidates": [],
  "archived_rounds… |
| work_report | 0 | {
  "apply": true,
  "dedupe_actions": [],
  "record_count": 22,
  "created": [],
  "worker_ids": [
    "architect… |
| sync_coherence | 0 | {
  "apply": true,
  "finding_count": 2,
  "latest_section5": "411",
  "top_section5_ref": "411",
  "findings": [
… |
| verification_snapshot | 0 | {
  "apply": true,
  "stale": false,
  "git_dirty": true,
  "age_hours": 11.633657995277778,
  "findings": [],
  "… |
| closure_gate | 0 | {
  "apply": true,
  "open_count": 19,
  "closed_count": 1,
  "explicit_none_count": 0,
  "findings": [
    {
   … |

## Index summaries

| Index | Summary |
|-------|---------|
| methodology-memory-index | last_lifecycle.at=06/20/2026 05:07:24 |
| work-reports-index | last_lifecycle.at=06/20/2026 05:07:24 |
| sync-coherence-index | last_lifecycle.at=06/20/2026 05:07:25 · findings_warn=1 findings_error=0 |
| verification-snapshot-index | last_lifecycle.at=06/20/2026 05:07:25 · findings_warn=0 findings_error=0 |
| closure-gate-index | open_count=19 · last_lifecycle.at=06/20/2026 05:07:25 · findings_warn=6 findings_error=0 |

## Git status (dual repos)

### Raindeer root

- branch=main ahead=0 behind=0 dirty=25
- status -sb:
```text
## main
 m apps/quant_assistant
 M docs/ENGINEERING/AWI-COMPLIANCE-BASELINE.md
 M docs/LOOP_ENGINEERING.md
 M harness/closure-gate-index.json
 M harness/loop-state.json
 M harness/methodology-memory-index.json
 M harness/schedule.json
 M harness/sync-coherence-index.json
 M harness/templates/awi-daily-audit-prompt.md
 M harness/templates/loop-tick-prompt.md
 M harness/verification-snapshot-index.json
 M harness/work-reports-index.json
?? .mineru-cli/
?? .omx/
?? .trae/
?? NINEDEER-WiKi/
?? _worktree_backups/
?? cache/
?? ecosystem_503.html
?? harness/scripts/daily-compliance.ps1
?? harness/scripts/daily-git-push.ps1
?? harness/templates/daily-compliance-prompt.md
?? harness/templates/daily-git-push-prompt.md
?? xcancel_profile.html
?? xcancel_search_results.json
```

### quant_assistant

- branch=main ahead=31 behind=0 dirty=18
- status -sb:
```text
## main...origin/main [ahead 31]
 M docs/CONTINUATION_PROMPT.md
 M docs/DATA_RELIABILITY_CHARTER.md
 M docs/ENGINEERING/TREE-2-gap-list.yaml
 M docs/ENGINEERING/WORKER_SKILL_GOVERNANCE.md
 M docs/PROJECT_STATUS.md
 M docs/TASK_TREES.md
 M docs/WORKFLOWS.md
?? .review_missing_dsn_stdout.txt
?? .review_missing_user_stderr.txt
?? .review_unknown_arg_stderr.txt
?? .streamlit/
?? data/
?? debug-factor-evaluation-submit-fail.md
?? factor-eval-dev-success-restarted.png
?? factor-eval-dev-success.png
?? tmp/
?? web/tsconfig.node.tsbuildinfo
?? web/tsconfig.tsbuildinfo
```

## TREE-2 gap list

- Path: `apps/quant_assistant/docs/ENGINEERING/TREE-2-gap-list.yaml`
- Summary: **env_count=1 · blocker_count=1 · future_count=4 · degraded_count=5**

## Notes

- `sync_coherence_lifecycle` validates prose drift read-only even with `--apply`.
- Full agent audit prompt: `harness/templates/daily-compliance-prompt.md`
- Next scheduled task: `daily-git-push` @ `30 20 * * *`
