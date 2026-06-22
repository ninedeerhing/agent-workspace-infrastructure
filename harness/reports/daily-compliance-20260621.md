# Daily Compliance Report · 20260621

- **Checked at**: 2026-06-21 20:01:20 +08:00
- **Project root**: `E:\raindeer`
- **Execution mode**: manual-equivalent fallback
- **Reason**: `harness/scripts/daily-compliance.ps1` parse error at line 210 prevented wrapper execution

## 1. compliance-check 摘要

- `codex-self-check`: **PASS** · exit 0 · findings **0**
- `compliance-check` baseline: **PASS with WARN** · exit 0 · findings **0**
- finding codes: **none**
- note: baseline checks reported `Git 工作区 | WARN | 46 dirty entries`

## 2. Five Lifecycles Freshness

| Lifecycle | last_lifecycle.at | stale? | summary |
|---|---|---:|---|
| methodology_memory | 2026-06-21T12:01:18Z | no | apply=true · dedupe=0 · active_step_digests=11 |
| work_reports | 2026-06-21T12:01:18Z | no | apply=true · record_count=22 |
| sync_coherence | 2026-06-21T12:01:18Z | no | finding_count=0 · warning_count=0 · error_count=0 |
| verification_snapshot | 2026-06-21T12:01:28Z | no | stale=false · git_dirty=true · age_hours=2.46 |
| closure_gate | 2026-06-21T12:01:28Z | no | open_count=0 · closed_count=17 · explicit_none_count=3 |

## 3. Sync / Verification Summary

- `sync_coherence-index.json`: **PASS** · no warnings / no errors
- 六真源对照：`loop-state.next_atomic_action`、`apps/quant_assistant/docs/CONTINUATION_PROMPT.md`、`apps/quant_assistant/docs/TASK_TREES.md`、`apps/quant_assistant/docs/PROJECT_STATUS.md` 顶部均指向监控 `daily_trade_status` tick5（2018-06-01→2020-05-31）并在完成后单实例启动 2020-06→2022-05
- `loop-state.last_tick`: `loop130-codex-tick5-start`
- `PROJECT_STATUS` 顶部 `§5.451` 与 `sync_coherence-index.latest_section5_id=451` 一致
- drift verdict: **SYNC-002 none / aligned**
- `verification_snapshot-index.json`: stale=false · git_dirty=true · latest source=`manual`

## 4. Dual-Repo Git Status

### AWI root

```text
## main...origin/raindeer-AWI
 M AGENTS.md
 m apps/quant_assistant
 M docs/CODEX_ZERO_CONFIG_HANDOFF.md
 M docs/CONTINUATION_PROMPT.md
 M docs/LOOP_ENGINEERING.md
 M docs/PROJECT_STATUS.md
 M docs/SESSION_SETUP.md
 M docs/TASK_TREES.md
 M harness/closure-gate-index.json
 M harness/closure_gate_lifecycle.py
 M harness/loop-state.json
 M harness/methodology-memory-index.json
 M harness/platform-binding.json
 M harness/reports/EMPLOYEE_ROSTER.md
 M harness/reports/orchestrator/latest.md
 M harness/reports/workers/executor.md
 M harness/reports/workers/verifier.md
 M harness/schedule.json
 M harness/scripts/daily-compliance.ps1
 M harness/scripts/daily-git-push.ps1
 M harness/session-handoff.md
 M harness/sync-coherence-index.json
 M harness/templates/awi-daily-audit-prompt.md
 M harness/templates/codex-zero-config-prompt.md
 M harness/templates/daily-compliance-prompt.md
 M harness/templates/daily-git-push-prompt.md
 M harness/templates/loop-tick-prompt.md
 M harness/verification-archive.jsonl
 M harness/verification-latest.json
 M harness/verification-snapshot-index.json
 M harness/work-reports-index.json
?? .mineru-cli/
?? .omx/
?? NINEDEER-WiKi/
?? _worktree_backups/
?? cache/
?? docs/OPERATIONS.md
?? docs/PLATFORM-CODEX.md
?? ecosystem_503.html
?? harness/CODEX_MIGRATION_CHECKLIST.md
?? harness/codex-automation-registry.json
?? harness/reports/daily-git-push-20260621.md
?? harness/scripts/codex-self-check.ps1
?? harness/templates/codex-self-check-prompt.md
?? xcancel_profile.html
?? xcancel_search_results.json
```

### quant_assistant

```text
## main...origin/main [ahead 38]
 M .env.example
 M docs/CONTINUATION_PROMPT.md
 M docs/DATA_RELIABILITY_CHARTER.md
 M docs/ENGINEERING/TREE-2-gap-list.yaml
 M docs/METHODOLOGY_MEMORY.md
 M docs/OPERATIONS.md
 M docs/PROJECT_STATUS.md
 M docs/TASK_TREES.md
 M docs/WORKFLOWS.md
 M scripts/detail_history_browser_smoke_seed.py
 M scripts/factor_evaluation_richer_smoke_sample.py
 M src/qa/db/__init__.py
 M src/qa/quant_rd/bandit_scheduler.py
 M src/qa/quant_rd/experiment_graph.py
 M src/qa/quant_rd/ic_comparison_harness.py
 M src/qa/quant_rd/mining_loop_controller.py
 M src/qa/quant_rd/mining_loop_dispatch_support.py
 M tests/conftest.py
 M tests/test_bandit_scheduler_unit.py
 M tests/test_experiment_graph_unit.py
 M tests/test_factor_evaluation_richer_smoke_sample_unit.py
 M tests/test_ic_comparison_harness_unit.py
 M tests/test_mining_loop_dispatch_support_unit.py
 M tests/test_mining_loop_real_panel_db.py
?? .review_missing_dsn_stdout.txt
?? .review_missing_user_stderr.txt
?? .review_unknown_arg_stderr.txt
?? .streamlit/
?? data/
?? debug-factor-evaluation-submit-fail.md
?? factor-eval-dev-success-restarted.png
?? factor-eval-dev-success.png
?? scripts/ps/ensure_pg_prod_test_databases.ps1
?? src/qa/db/dsn_guard.py
?? tests/test_dsn_guard_unit.py
?? tmp/
?? web/tsconfig.node.tsbuildinfo
?? web/tsconfig.tsbuildinfo
```

## 5. Gap List Summary

- file: `apps/quant_assistant/docs/ENGINEERING/TREE-2-gap-list.yaml`
- `blocker_count`: **0**
- `degraded_count`: **5**
- `future_count`: **4**
- `env_count`: **1**
- note: TREE-2 data blockers remain closed; current daily compliance must not interrupt ongoing tick-style backfill bookkeeping

## 6. Overall Assessment

- risk: **medium**
- rationale:
  - compliance/self-check findings remain **0**
  - sync/verification lifecycles are fresh and coherent
  - both repos are materially dirty
  - `daily-compliance.ps1` wrapper is currently broken by a parse error, so automation relied on manual-equivalent fallback

## 7. Tomorrow Improvements

1. Fix `harness/scripts/daily-compliance.ps1` line-210 parse issue and rerun wrapper path.
2. Reduce dirty working-tree surface or group pending changes for the scheduled `daily-git-push` flow.
3. Keep TREE-2 tick5 monitoring read-only and update evidence only after completion without duplicating any `daily_trade_status` or `daily_bar` chain.
