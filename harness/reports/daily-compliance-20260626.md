# Daily Compliance Report - 20260626

- **Checked at**: 2026-06-26 20:01:14
- **Project root**: E:\raindeer
- **codex-self-check exit**: 1
- **compliance-check exit**: 1
- **Schedule task id**: `daily-ops` calls `daily-compliance` (not separately scheduled)

## CodeX self-check

# CodeX Self Check

- Checked at: 2026-06-26T20:01:12+08:00
- Project: E:\raindeer
- Checks: 67
- Findings: 5

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
| loop-state next action | PASS | candidate-promotion-to-factor-library-review-intake-loop292 |
| base compliance-check | PASS | findings=5 |

## Findings
| Severity | Code | Title | Detail | Recommendation |
|---|---|---|---|---|
| warning | BASE-LEDGER-002 | 脏工作区缺少当日台账 | 检测到 Git 未提交变更，但最新台账日期不是今天。 | 在 §5 追加今日条目，记录本轮实现/测试/决策。 |
| warning | BASE-MEM-004 | methodology lifecycle index stale | last_lifecycle.at=06/25/2026 12:01:40 exceeds 24h threshold. Git working tree has uncommitted changes. | Run python harness/methodology_memory_lifecycle.py run --apply each loop tick (loop_tick prepare/advance wired). |
| warning | BASE-SYNC-001 | sync-coherence-index stale | last_lifecycle.at=06/25/2026 12:01:40 exceeds 24h. Git dirty. | python harness/sync_coherence_lifecycle.py run --apply |
| warning | BASE-VER-001 | verification-snapshot-index stale | last_lifecycle.at=06/25/2026 12:01:40 exceeds 24h. Git dirty. | python harness/verification_snapshot_lifecycle.py run --apply |
| warning | BASE-CLO-001 | closure-gate-index stale | last_lifecycle.at=06/25/2026 12:01:40 exceeds 24h. Git dirty. | python harness/closure_gate_lifecycle.py run --apply |


## compliance-check

# Compliance Report

- Mode: baseline
- Project: E:\raindeer
- Checked At: 2026-06-26 20:01:13
- Checks: 37 / Findings: 5

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
| §5 台账条目 | PASS | latest=2026-06-25 |
| workflow-state 当前工作流 | PASS | standard |
| SESSION_BOOT | PASS | E:\raindeer\docs\SESSION_BOOT.md |
| agents roster | PASS | 24 files |
| agent-registry | PASS | E:\raindeer\harness\agent-registry.json |
| Git 工作区 | WARN | 8 dirty entries |
| QA PROJECT_STATUS §5 | PASS | E:\raindeer\apps\quant_assistant\docs\PROJECT_STATUS.md |
| QA 最新 §5 methodology_ref | PASS | present |
| METHODOLOGY 轮次复盘 | PASS | rounds present |
| METHODOLOGY 可见状态:## 当前可见状态 | PASS | present |
| METHODOLOGY 可见状态:updated_at | PASS | present |
| METHODOLOGY 可见状态:latest_digest | PASS | present |
| METHODOLOGY 可见状态:methodology_ref | PASS | present |
| 根最新 §5 methodology_ref | PASS | present |
| loop-state next action | PASS | CANDIDATE_PROMOTION_TO_FACTOR_LIBRARY_REVIEW_INTAKE_LOOP292：在 loop291 已生成同源 cand |
| methodology-memory-index | PASS | E:\raindeer\harness\methodology-memory-index.json |
| MEM-004 last_lifecycle freshness | WARN | age=31.9924567470556h dirty=True at=06/25/2026 12:01:40 |
| orchestrator-work-report | PASS | E:\raindeer\harness\reports\orchestrator\latest.md |
| worker-work-reports | PASS | count=24 |
| work-reports-index | PASS | E:\raindeer\harness\work-reports-index.json |
| sync-coherence-index | PASS | E:\raindeer\harness\sync-coherence-index.json |
| SYNC-001 freshness | WARN | age=31.9924851279722h dirty=True |
| verification-snapshot-index | PASS | E:\raindeer\harness\verification-snapshot-index.json |
| VER-001 freshness | WARN | age=31.9925129107222h dirty=True |
| closure-gate-index | PASS | E:\raindeer\harness\closure-gate-index.json |
| CLO-001 freshness | WARN | age=31.9925407287222h dirty=True |
| SYNC coherence drift | PASS | no warnings |
| CLO closure candidates | PASS | open=0 |

## Findings

| Severity | Code | Title | Detail | Recommendation |
|----------|------|-------|--------|----------------|
| warning | LEDGER-002 | 脏工作区缺少当日台账 | 检测到 Git 未提交变更，但最新台账日期不是今天。 | 在 §5 追加今日条目，记录本轮实现/测试/决策。 |
| warning | MEM-004 | methodology lifecycle index stale | last_lifecycle.at=06/25/2026 12:01:40 exceeds 24h threshold. Git working tree has uncommitted changes. | Run python harness/methodology_memory_lifecycle.py run --apply each loop tick (loop_tick prepare/advance wired). |
| warning | SYNC-001 | sync-coherence-index stale | last_lifecycle.at=06/25/2026 12:01:40 exceeds 24h. Git dirty. | python harness/sync_coherence_lifecycle.py run --apply |
| warning | VER-001 | verification-snapshot-index stale | last_lifecycle.at=06/25/2026 12:01:40 exceeds 24h. Git dirty. | python harness/verification_snapshot_lifecycle.py run --apply |
| warning | CLO-001 | closure-gate-index stale | last_lifecycle.at=06/25/2026 12:01:40 exceeds 24h. Git dirty. | python harness/closure_gate_lifecycle.py run --apply |


## loop_tick status

```text
{
  "stopped": true,
  "stop_detail": "closure_gate=closed",
  "next_atomic_action": "CANDIDATE_PROMOTION_TO_FACTOR_LIBRARY_REVIEW_INTAKE_LOOP292���� loop291 ������ͬԴ candidate_promotion_decision_v1 �Ļ����ϣ�ʵ���˹����ӿ⸴�� intake/read-model��ֻ���� decision=advance_to_factor_library_review �ĺ�ѡ������ hold_for_recheck/reject �ĸ����ܾ����ɣ���ͨ����ѡ�� factor_version_id��A-E taxonomy��safe_sim run/audit refs��reviewed plan/F6 evidence��quality reasons ����һ���˹��������� Factor Library �ɸ�����ڣ�ȱʧ candidate_promotion_decision_v1��source job/audit��target ids��safety matrix �� evidence refs ���� fail-closed���Խ�ֹ�Զ���⡢�Զ����ա�live/default runner��adapter invocation��actual adapter dry-run��DB-backed real batch��PL-H��background/migration/backfill��secret �����",
  "next_after": "After factor-library review intake is generated from candidate_promotion_decision_v1, wire explicit human acceptance/promote-to-library decision and then controlled dry-run readiness without enabling automatic execution.",
  "updated_at": "2026-06-25T09:18:05+08:00",
  "last_tick": "loop291-safe-sim-result-to-candidate-promotion-decision",
  "last_lifecycle_run": {
    "at": "2026-06-25T12:01:40Z",
    "apply": true,
    "dedupe_actions": 0,
    "dream_candidates": 0,
    "closure_candidates": 0,
    "archived_rounds": [],
    "active_step_digests": 33,
    "completed_tasks_hint": [
      "loop291 safe simulation result to candidate promotion decision complete. Added qa.quant_mining.candidate_promotion_decision.build_candidate_promotion_decision_v1 and wired candidate_promotion_decision_v1 into MiningJob observability, Factor Library review rows, Chat notes, Jobs cards, and Factor Library UI. The read-model converts completed server-owned safe_sim result/audit plus reviewed plan/F6 evidence/A-E taxonomy/target ids into advance_to_factor_library_review, hold_for_recheck, or reject, with reasons/evidence refs/next action and ready_for_execution=false. Verification: RED missing module failed as expected; candidate promotion unit 4 passed; focused related regression 27 passed; expanded related regression 112 passed; targeted Ruff pass; web build pass; Jobs smoke pass pageLoadTriggerRequests=[] duplicateTriggerUrls=[]; web lint pass with one pre-existing ShellLayoutContext warning. Next_atomic_action is CANDIDATE_PROMOTION_TO_FACTOR_LIBRARY_REVIEW_INTAKE_LOOP292.",
      "candidate-promotion-to-factor-library-review-intake-loop292",
      "loop291-safe-sim-result-to-candidate-promotion-decision"
    ],
    "ttl_days": 180
  },
  "lifecycle_runs": {
    "methodology_memory": {
      "at": "2026-06-25T12:01:40Z",
      "apply": true,
      "dedupe_actions": 0,
      "dream_candidates": 0,
      "closure_candidates": 0,
      "archived_rounds": [],
      "active_step_digests": 33,
      "completed_tasks_hint": [
        "loop291 safe simulation result to candidate promotion decision complete. Added qa.quant_mining.candidate_promotion_decision.build_candidate_promotion_decision_v1 and wired candidate_promotion_decision_v1 into MiningJob observability, Factor Library review rows, Chat notes, Jobs cards, and Factor Library UI. The read-model converts completed server-owned safe_sim result/audit plus reviewed plan/F6 evidence/A-E taxonomy/target ids into advance_to_factor_library_review, hold_for_recheck, or reject, with reasons/evidence refs/next action and ready_for_execution=false. Verification: RED missing module failed as expected; candidate promotion unit 4 passed; focused related regression 27 passed; expanded related regression 112 passed; targeted Ruff pass; web build pass; Jobs smoke pass pageLoadTriggerRequests=[] duplicateTriggerUrls=[]; web lint pass with one pre-existing ShellLayoutContext warning. Next_atomic_action is CANDIDATE_PROMOTION_TO_FACTOR_LIBRARY_REVIEW_INTAKE_LOOP292.",
        "candidate-promotion-to-factor-library-review-intake-loop292",
        "loop291-safe-sim-result-to-candidate-promotion-decision"
      ],
      "ttl_days": 180
    },
    "work_reports": {
      "at": "2026-06-25T12:01:40Z",
      "apply": true,
      "dedupe_actions": 0,
      "record_count": 22,
      "created": []
    },
    "sync_coherence": {
      "at": "2026-06-25T12:01:40Z",
      "finding_count": 0,
      "warning_count": 0,
      "error_count": 0
    },
    "verification_snapshot": {
      "at": "2026-06-25T12:01:40Z",
      "apply": true,
      "stale": false,
      "git_dirty": true,
      "age_hours": 10.862719393333332
    },
    "closure_gate": {
      "at": "2026-06-25T12:01:40Z",
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
  "finding_count": 0,
  "latest_section5": "620",
  "top_section5_ref": "620",
  "findings": []
... |
| verification_snapshot | 0 | {
  "apply": true,
  "stale": true,
  "git_dirty": true,
  "age_hours": 34.85518886166667,
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
| methodology-memory-index | last_lifecycle.at=06/26/2026 12:01:13 |
| work-reports-index | last_lifecycle.at=06/26/2026 12:01:13 |
| sync-coherence-index | last_lifecycle.at=06/26/2026 12:01:13 | findings_warn=0 findings_error=0 |
| verification-snapshot-index | last_lifecycle.at=06/26/2026 12:01:13 | findings_warn=1 findings_error=0 |
| closure-gate-index | open_count=0 | last_lifecycle.at=06/26/2026 12:01:13 | findings_warn=0 findings_error=0 |

## Git status (dual repos)

### Raindeer root

- branch=main ahead=0 behind=0 dirty=8
- status -sb:
```text
## main...origin/raindeer-AWI
 M harness/closure-gate-index.json
 M harness/methodology-memory-index.json
 M harness/sync-coherence-index.json
 M harness/verification-snapshot-index.json
 M harness/work-reports-index.json
?? harness/reports/daily-compliance-20260625.md
?? harness/reports/daily-git-push-20260625.md
?? harness/reports/daily-ops-20260625.md
```

### quant_assistant

- branch=main ahead=0 behind=0 dirty=0
- status -sb:
```text
## main...origin/main
```

## TREE-2 gap list

- Path: `apps/quant_assistant/docs/ENGINEERING/TREE-2-gap-list.yaml`
- Summary: **env_count=1 | blocker_count=0 | degraded_count=5 | future_count=4**

## Notes

- `sync_coherence_lifecycle` validates prose drift read-only even with `--apply`.
- Full agent audit prompt: `harness/templates/daily-compliance-prompt.md`
- Daily scheduler: `daily-ops` calls `daily-git-push` after this wrapper succeeds
