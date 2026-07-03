# Daily Compliance Report - 20260703

- **Checked at**: 2026-07-03 20:00:44
- **Project root**: E:\raindeer
- **codex-self-check exit**: 1
- **compliance-check exit**: 1
- **Schedule task id**: `daily-ops` calls `daily-compliance` (not separately scheduled)

## CodeX self-check

# CodeX Self Check

- Checked at: 2026-07-03T20:00:39+08:00
- Project: E:\raindeer
- Checks: 106
- Findings: 6

## Checks
| Name | Status | Detail |
|---|---|---|
| CodeX platform doc | PASS | E:\raindeer\docs\PLATFORM-CODEX.md |
| CodeX zero-config prompt | PASS | E:\raindeer\harness\templates\codex-zero-config-prompt.md |
| CodeX subagent prompt | PASS | E:\raindeer\harness\templates\codex-subagent-prompt.md |
| Employee roster | PASS | E:\raindeer\harness\reports\EMPLOYEE_ROSTER.md |
| CodeX automation registry | PASS | E:\raindeer\harness\codex-automation-registry.json |
| Daily ops prompt | PASS | E:\raindeer\harness\templates\daily-ops-prompt.md |
| Daily ops wrapper | PASS | E:\raindeer\harness\scripts\daily-ops.ps1 |
| CodeX skill router | PASS | E:\raindeer\harness\skill_router.py |
| CodeX skill router tests | PASS | E:\raindeer\harness\tests\test_skill_router.py |
| AWI project registry | PASS | E:\raindeer\harness\project-registry.json |
| AWI source index | PASS | E:\raindeer\harness\source-index.json |
| AWI capability DAG | PASS | E:\raindeer\harness\capability-dag.json |
| AWI capability DAG schema | PASS | E:\raindeer\harness\capability-dag.schema.json |
| AWI runtime task DAG schema | PASS | E:\raindeer\harness\runtime-task-dag.schema.json |
| AWI DAG validator | PASS | E:\raindeer\harness\validate_awi_dags.py |
| AWI Memory OS | PASS | E:\raindeer\harness\memory-os.json |
| AWI Memory OS schema | PASS | E:\raindeer\harness\memory-os.schema.json |
| AWI Memory OS validator | PASS | E:\raindeer\harness\validate_awi_memory.py |
| loop prompt gate:Goal/Plan Gate | PASS | present |
| loop prompt gate:Function-First Loop Gate | PASS | present |
| loop prompt gate:core_function_artifact | PASS | present |
| loop prompt gate:phase_plan | PASS | present |
| loop prompt gate:functional_acceptance | PASS | present |
| loop prompt gate:closing_work_only | PASS | present |
| loop prompt gate:Context Loading Budget Gate | PASS | present |
| loop prompt gate:context_mode | PASS | present |
| loop prompt gate:cold_path_reason | PASS | present |
| loop prompt gate:Skill Routing Gate | PASS | present |
| loop prompt gate:Worker Dispatch Gate | PASS | present |
| loop prompt gate:Planner -> Dispatcher | PASS | present |
| loop prompt gate:assignment_matrix | PASS | present |
| loop prompt gate:orchestrator_self_execution_exception | PASS | present |
| loop prompt gate:Worker Cluster/Rendezvous Gate | PASS | present |
| loop prompt gate:goal_bundle | PASS | present |
| loop prompt gate:slice_family | PASS | present |
| loop prompt gate:no_skill_reason | PASS | present |
| loop prompt gate:no_dispatch_reason | PASS | present |
| loop prompt gate:cluster_manifest | PASS | present |
| loop prompt gate:rendezvous_gate | PASS | present |
| loop prompt gate:worker_report_refs | PASS | present |
| loop prompt gate:no_cluster_reason | PASS | present |
| loop prompt gate:skillification_candidate | PASS | present |
| loop prompt gate:skill_reactivation_note | PASS | present |
| loop prompt gate:capacity_review | PASS | present |
| loop prompt gate:methodology_ref | PASS | present |
| loop prompt gate:model_tier | PASS | present |
| loop prompt gate:tmp/skill-route-events.jsonl | PASS | present |
| methodology visibility:updated_at | PASS | present |
| methodology visibility:latest_digest | PASS | present |
| methodology visibility:latest_permanent_M_GP | PASS | present |
| methodology visibility:methodology_ref | PASS | present |
| QA latest ledger methodology_ref | PASS | present |
| platform-binding codex | PASS | platform=codex adapter_status=installed |
| skill:agent-team-bootstrap | PASS | E:\raindeer\skills\agent-team-bootstrap\SKILL.md |
| skill:workflow-phase-advance | PASS | E:\raindeer\skills\workflow-phase-advance\SKILL.md |
| skill:dispatching-parallel-agents | PASS | E:\raindeer\skills\dispatching-parallel-agents\SKILL.md |
| skill:subagent-driven-dev | PASS | E:\raindeer\skills\subagent-driven-dev\SKILL.md |
| skill:test-driven-development | PASS | E:\raindeer\skills\test-driven-development\SKILL.md |
| skill:verification-before-completion | PASS | E:\raindeer\skills\verification-before-completion\SKILL.md |
| skill:session-retro | PASS | E:\raindeer\skills\session-retro\SKILL.md |
| skill:skillify | PASS | E:\raindeer\skills\skillify\SKILL.md |
| agent-registry roster | PASS | roles=24 workers=23 |
| employee roster workers | PASS | workers=23 |
| PLATFORM-CODEX mentions automation_update | PASS | present |
| PLATFORM-CODEX mentions create_thread | PASS | present |
| PLATFORM-CODEX mentions send_message_to_thread | PASS | present |
| PLATFORM-CODEX mentions codex-subagent-prompt | PASS | present |
| PLATFORM-CODEX mentions codex-self-check | PASS | present |
| PLATFORM-CODEX mentions daily-ops | PASS | present |
| automation:loop-tick | PASS | codex_id=awi-loop-tick-heartbeat; status=PAUSED_BY_USER |
| automation:daily-ops | PASS | codex_id=awi-daily-ops; status=ACTIVE |
| retired automation inactive:daily-compliance | PASS | not active |
| retired automation inactive:daily-git-push | PASS | not active |
| retired automation inactive:codex-self-check | PASS | not active |
| project-registry:raindeer-awi | PASS | registered |
| project-registry:raindeer-quant-assistant | PASS | registered |
| project-registry source-index truth source | PASS | present |
| source-index:openai-harness-engineering | PASS | indexed |
| source-index:anthropic-claude-code-skills | PASS | indexed |
| source-index:anthropic-claude-code-memory | PASS | indexed |
| source-index:langgraph-memory | PASS | indexed |
| source-index:awi-reference-catalog | PASS | indexed |
| source-index:awi-reference-architecture-2026-06-29 | PASS | indexed |
| source-index:douyin-dag-design-transcript | PASS | indexed |
| source-index:douyin-memory-system-transcript | PASS | indexed |
| source-index:douyin-harness-loop-eval-transcript | PASS | indexed |
| source-index:awi-capability-dag | PASS | indexed |
| source-index:awi-runtime-task-dag-schema | PASS | indexed |
| source-index:awi-dag-validator | PASS | indexed |
| source-index:awi-memory-os | PASS | indexed |
| source-index:awi-memory-validator | PASS | indexed |
| source-index:awi-memory-os-adr-005 | PASS | indexed |
| source-index category:harness_loop_eval | PASS | present |
| source-index category:skills | PASS | present |
| source-index category:memory_rag | PASS | present |
| source-index category:dag_runtime | PASS | present |
| source-index category:awi_architecture | PASS | present |
| source-index category:raindeer_quant | PASS | present |
| source-index category:codebase_intelligence | PASS | present |
| source-index transcript:douyin-dag-design-transcript | PASS | docs/ENGINEERING/references/awi-video-transcripts/dag-design.md |
| source-index transcript:douyin-memory-system-transcript | PASS | docs/ENGINEERING/references/awi-video-transcripts/memory-system.md |
| source-index transcript:douyin-harness-loop-eval-transcript | PASS | docs/ENGINEERING/references/awi-video-transcripts/harness-loop-eval.md |
| AWI DAG validator | PASS | checks=7; findings=0 |
| AWI Memory OS validator | PASS | checks=4; findings=0 |
| loop-state next action | PASS | real-scoring-operator-runtime-recheck-regeneration-packet-loop652 |
| base compliance-check | PASS | findings=6 |

## Findings
| Severity | Code | Title | Detail | Recommendation |
|---|---|---|---|---|
| warning | BASE-LEDGER-002 | 脏工作区缺少当日台账 | 检测到 Git 未提交变更，但最新台账日期不是今天。 | 在 §5 追加今日条目，记录本轮实现/测试/决策。 |
| warning | BASE-MEM-004 | methodology lifecycle index stale | last_lifecycle.at=07/02/2026 12:01:40 exceeds 24h threshold. Git working tree has uncommitted changes. | Run python harness/methodology_memory_lifecycle.py run --apply each loop tick (loop_tick prepare/advance wired). |
| warning | BASE-SYNC-001 | sync-coherence-index stale | last_lifecycle.at=07/02/2026 12:01:41 exceeds 24h. Git dirty. | python harness/sync_coherence_lifecycle.py run --apply |
| warning | BASE-VER-001 | verification-snapshot-index stale | last_lifecycle.at=07/02/2026 12:01:41 exceeds 24h. Git dirty. | python harness/verification_snapshot_lifecycle.py run --apply |
| warning | BASE-CLO-001 | closure-gate-index stale | last_lifecycle.at=07/02/2026 12:01:41 exceeds 24h. Git dirty. | python harness/closure_gate_lifecycle.py run --apply |
| warning | BASE-SYNC-002 | 五真源漂移 | sync-coherence-index 含 2 条 warning | 更新 PROJECT_STATUS 顶部现状概述并与 loop-state/CONTINUATION 对齐 |


## compliance-check

# Compliance Report

- Mode: baseline
- Project: E:\raindeer
- Checked At: 2026-07-03 20:00:41
- Checks: 37 / Findings: 6

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
| 当前主线登记 | PASS | TREE-6 / PL-G |
| §5 台账条目 | PASS | latest=2026-06-29 |
| workflow-state 当前工作流 | PASS | standard |
| SESSION_BOOT | PASS | E:\raindeer\docs\SESSION_BOOT.md |
| agents roster | PASS | 24 files |
| agent-registry | PASS | E:\raindeer\harness\agent-registry.json |
| Git 工作区 | WARN | 1 dirty entries |
| QA PROJECT_STATUS §5 | PASS | E:\raindeer\apps\quant_assistant\docs\PROJECT_STATUS.md |
| QA 最新 §5 methodology_ref | PASS | present |
| METHODOLOGY 轮次复盘 | PASS | rounds present |
| METHODOLOGY 可见状态:## 当前可见状态 | PASS | present |
| METHODOLOGY 可见状态:updated_at | PASS | present |
| METHODOLOGY 可见状态:latest_digest | PASS | present |
| METHODOLOGY 可见状态:methodology_ref | PASS | present |
| 根最新 §5 methodology_ref | PASS | present |
| loop-state next action | PASS | REAL_SCORING_OPERATOR_RUNTIME_RECHECK_INPUT_READINESS_LOOP653：基于 loop652 real_sc |
| methodology-memory-index | PASS | E:\raindeer\harness\methodology-memory-index.json |
| MEM-004 last_lifecycle freshness | WARN | age=31.9834308246944h dirty=True at=07/02/2026 12:01:40 |
| orchestrator-work-report | PASS | E:\raindeer\harness\reports\orchestrator\latest.md |
| worker-work-reports | PASS | count=25 |
| work-reports-index | PASS | E:\raindeer\harness\work-reports-index.json |
| sync-coherence-index | PASS | E:\raindeer\harness\sync-coherence-index.json |
| SYNC-001 freshness | WARN | age=31.9832069314444h dirty=True |
| verification-snapshot-index | PASS | E:\raindeer\harness\verification-snapshot-index.json |
| VER-001 freshness | WARN | age=31.9832719445278h dirty=True |
| closure-gate-index | PASS | E:\raindeer\harness\closure-gate-index.json |
| CLO-001 freshness | WARN | age=31.9833844037222h dirty=True |
| SYNC coherence drift | WARN | warnings=2 |
| CLO closure candidates | PASS | open=0 |

## Findings

| Severity | Code | Title | Detail | Recommendation |
|----------|------|-------|--------|----------------|
| warning | LEDGER-002 | 脏工作区缺少当日台账 | 检测到 Git 未提交变更，但最新台账日期不是今天。 | 在 §5 追加今日条目，记录本轮实现/测试/决策。 |
| warning | MEM-004 | methodology lifecycle index stale | last_lifecycle.at=07/02/2026 12:01:40 exceeds 24h threshold. Git working tree has uncommitted changes. | Run python harness/methodology_memory_lifecycle.py run --apply each loop tick (loop_tick prepare/advance wired). |
| warning | SYNC-001 | sync-coherence-index stale | last_lifecycle.at=07/02/2026 12:01:41 exceeds 24h. Git dirty. | python harness/sync_coherence_lifecycle.py run --apply |
| warning | VER-001 | verification-snapshot-index stale | last_lifecycle.at=07/02/2026 12:01:41 exceeds 24h. Git dirty. | python harness/verification_snapshot_lifecycle.py run --apply |
| warning | CLO-001 | closure-gate-index stale | last_lifecycle.at=07/02/2026 12:01:41 exceeds 24h. Git dirty. | python harness/closure_gate_lifecycle.py run --apply |
| warning | SYNC-002 | 五真源漂移 | sync-coherence-index 含 2 条 warning | 更新 PROJECT_STATUS 顶部现状概述并与 loop-state/CONTINUATION 对齐 |


## loop_tick status

```text
{
  "stopped": true,
  "stop_detail": "closure_gate=closed",
  "next_atomic_action": "REAL_SCORING_OPERATOR_RUNTIME_RECHECK_INPUT_READINESS_LOOP653������ loop652 real_scoring_operator_runtime_recheck_regeneration_packet������ֻ�� recheck input readiness ���㣺ȷ�� required_material_ids=3��input_slot_refs=3��acceptance_hint_refs=3 �Ƿ��뱸������� ready_for_operator_runtime_recheck_input / missing_refs���Բ��� env/DB�������� Docker/��������������� DB�������� runner/adapter����д DB/���С������� scorer/backtest�������� PL-H��",
  "next_after": "After loop653, continue no-execution input-readiness path and only then regenerate operator-runtime recheck state as a read-model.",
  "updated_at": "2026-07-04T09:50:00+08:00",
  "last_tick": "SYNC-664-real-scoring-operator-runtime-recheck-regeneration-packet",
  "last_lifecycle_run": {
    "at": "2026-07-02T12:01:40Z",
    "apply": true,
    "dedupe_actions": 0,
    "dream_candidates": 0,
    "closure_candidates": 0,
    "archived_rounds": [],
    "active_step_digests": 36,
    "completed_tasks_hint": [
      "loop400 Factor batch scoring plan complete after Code Reviewer P2 semantic wording/source-safety fixes and final recheck success. Added FactorBatchScoringPlanV1 and bridged factor_batch_scoring_plan into user_facing_batch_mining_creation_plan_v1; completion review surface now exposes batch_scoring_candidate_refs_for_review from survived_candidate_refs, and batch scoring plan chunks 184 review-only candidates into 4 planned scoring-authorization-review chunks with budget/default-runner/backtest/pool-write all fail-closed. Verification: RED missing module; RED wrong source contract not blocked; RED missing creation-plan bridge; focused+adjacent creation-plan chain 18 passed; targeted Ruff pass; targeted compileall pass; payload smoke status=planned_for_scoring_authorization_review candidates=184 planned=184 dropped=0 chunks=4 chunk_size=50 first_ref=fg_0b3e276c2be5 candidate_ref_permission=review_only_not_execution_eligible requires_injected_runner=True default_runner_allowed=False runs_backtest=not_allowed all side effects false; forbidden active execution scan clean. Next: FACTOR_BATCH_SCORING_AUTHORIZATION_REVIEW_LOOP401.",
      "original-qa-pg-alt-evidence-handoff-successor-sync497",
      "SYNC-497-original-qa-pg-alt-evidence-handoff-successor"
    ],
    "ttl_days": 180
  },
  "lifecycle_runs": {
    "methodology_memory": {
      "at": "2026-07-02T12:01:40Z",
      "apply": true,
      "dedupe_actions": 0,
      "dream_candidates": 0,
      "closure_candidates": 0,
      "archived_rounds": [],
      "active_step_digests": 36,
      "completed_tasks_hint": [
        "loop400 Factor batch scoring plan complete after Code Reviewer P2 semantic wording/source-safety fixes and final recheck success. Added FactorBatchScoringPlanV1 and bridged factor_batch_scoring_plan into user_facing_batch_mining_creation_plan_v1; completion review surface now exposes batch_scoring_candidate_refs_for_review from survived_candidate_refs, and batch scoring plan chunks 184 review-only candidates into 4 planned scoring-authorization-review chunks with budget/default-runner/backtest/pool-write all fail-closed. Verification: RED missing module; RED wrong source contract not blocked; RED missing creation-plan bridge; focused+adjacent creation-plan chain 18 passed; targeted Ruff pass; targeted compileall pass; payload smoke status=planned_for_scoring_authorization_review candidates=184 planned=184 dropped=0 chunks=4 chunk_size=50 first_ref=fg_0b3e276c2be5 candidate_ref_permission=review_only_not_execution_eligible requires_injected_runner=True default_runner_allowed=False runs_backtest=not_allowed all side effects false; forbidden active execution scan clean. Next: FACTOR_BATCH_SCORING_AUTHORIZATION_REVIEW_LOOP401.",
        "original-qa-pg-alt-evidence-handoff-successor-sync497",
        "SYNC-497-original-qa-pg-alt-evidence-handoff-successor"
      ],
      "ttl_days": 180
    },
    "work_reports": {
      "at": "2026-07-02T12:01:40Z",
      "apply": true,
      "dedupe_actions": 0,
      "record_count": 22,
      "created": []
    },
    "sync_coherence": {
      "at": "2026-07-02T12:01:41Z",
      "finding_count": 3,
      "warning_count": 2,
      "error_count": 0
    },
    "verification_snapshot": {
      "at": "2026-07-02T12:01:41Z",
      "apply": true,
      "stale": true,
      "git_dirty": true,
      "age_hours": 67.77783377055556
    },
    "closure_gate": {
      "at": "2026-07-02T12:01:41Z",
      "open_count": 0,
      "closed_count": 17,
      "explicit_none_count": 3,
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
  "archived_rounds... |
| work_report | 0 | {
  "apply": true,
  "dedupe_actions": [],
  "record_count": 22,
  "created": [],
  "worker_ids": [
    "architect... |
| sync_coherence | 0 | {
  "apply": true,
  "finding_count": 2,
  "latest_section5": "988",
  "top_section5_ref": "988",
  "findings": [
... |
| verification_snapshot | 0 | {
  "apply": true,
  "stale": true,
  "git_dirty": true,
  "age_hours": 91.76148136333333,
  "findings": [
    {
... |
| closure_gate | 0 | {
  "apply": true,
  "open_count": 0,
  "closed_count": 17,
  "explicit_none_count": 3,
  "findings": [],
  "candi... |

## Index summaries

| Index | Summary |
|-------|---------|
| methodology-memory-index | last_lifecycle.at=07/03/2026 12:00:41 |
| work-reports-index | last_lifecycle.at=07/03/2026 12:00:41 |
| sync-coherence-index | last_lifecycle.at=07/03/2026 12:00:42 | findings_warn=1 findings_error=0 |
| verification-snapshot-index | last_lifecycle.at=07/03/2026 12:00:42 | findings_warn=1 findings_error=0 |
| closure-gate-index | open_count=0 | last_lifecycle.at=07/03/2026 12:00:42 | findings_warn=0 findings_error=0 |

## Git status (dual repos)

### Raindeer root

- branch=main ahead=282 behind=0 dirty=6
- status -sb:
```text
## main...origin/raindeer-AWI [ahead 282]
 ? apps/quant_assistant
 M harness/closure-gate-index.json
 M harness/methodology-memory-index.json
 M harness/sync-coherence-index.json
 M harness/verification-snapshot-index.json
 M harness/work-reports-index.json
```

### quant_assistant

- branch=main ahead=167 behind=0 dirty=1
- status -sb:
```text
## main...origin/main [ahead 167]
?? tests/test_real_scoring_operator_runtime_recheck_input_readiness_unit.py
```

## TREE-2 gap list

- Path: `apps/quant_assistant/docs/ENGINEERING/TREE-2-gap-list.yaml`
- Summary: **degraded_count=5 | future_count=4 | blocker_count=0 | env_count=1**

## Notes

- `sync_coherence_lifecycle` validates prose drift read-only even with `--apply`.
- Full agent audit prompt: `harness/templates/daily-compliance-prompt.md`
- Daily scheduler: `daily-ops` calls `daily-git-push` after this wrapper succeeds
