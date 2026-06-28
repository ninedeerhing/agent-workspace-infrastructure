# Daily Compliance Report - 20260628

- **Checked at**: 2026-06-28 20:01:39
- **Project root**: E:\raindeer
- **codex-self-check exit**: 1
- **compliance-check exit**: 1
- **Schedule task id**: `daily-ops` calls `daily-compliance` (not separately scheduled)

## CodeX self-check

# CodeX Self Check

- Checked at: 2026-06-28T20:01:37+08:00
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
| loop-state next action | PASS | operator-reviewer-authorization-evidence-review-loop299 |
| base compliance-check | PASS | findings=5 |

## Findings
| Severity | Code | Title | Detail | Recommendation |
|---|---|---|---|---|
| warning | BASE-LEDGER-002 | 脏工作区缺少当日台账 | 检测到 Git 未提交变更，但最新台账日期不是今天。 | 在 §5 追加今日条目，记录本轮实现/测试/决策。 |
| warning | BASE-SYNC-001 | sync-coherence-index stale | last_lifecycle.at=06/27/2026 12:00:41 exceeds 24h. Git dirty. | python harness/sync_coherence_lifecycle.py run --apply |
| warning | BASE-VER-001 | verification-snapshot-index stale | last_lifecycle.at=06/27/2026 12:00:41 exceeds 24h. Git dirty. | python harness/verification_snapshot_lifecycle.py run --apply |
| warning | BASE-CLO-001 | closure-gate-index stale | last_lifecycle.at=06/27/2026 12:00:41 exceeds 24h. Git dirty. | python harness/closure_gate_lifecycle.py run --apply |
| warning | BASE-SYNC-002 | 五真源漂移 | sync-coherence-index 含 2 条 warning | 更新 PROJECT_STATUS 顶部现状概述并与 loop-state/CONTINUATION 对齐 |


## compliance-check

# Compliance Report

- Mode: baseline
- Project: E:\raindeer
- Checked At: 2026-06-28 20:01:38
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
| Git 工作区 | WARN | 1 dirty entries |
| QA PROJECT_STATUS §5 | PASS | E:\raindeer\apps\quant_assistant\docs\PROJECT_STATUS.md |
| QA 最新 §5 methodology_ref | PASS | present |
| METHODOLOGY 轮次复盘 | PASS | rounds present |
| METHODOLOGY 可见状态:## 当前可见状态 | PASS | present |
| METHODOLOGY 可见状态:updated_at | PASS | present |
| METHODOLOGY 可见状态:latest_digest | PASS | present |
| METHODOLOGY 可见状态:methodology_ref | PASS | present |
| 根最新 §5 methodology_ref | PASS | present |
| loop-state next action | PASS | OPERATOR_REVIEWER_AUTHORIZATION_EVIDENCE_REVIEW_LOOP299：基于 loop298 explicit_auth |
| methodology-memory-index | PASS | E:\raindeer\harness\methodology-memory-index.json |
| MEM-004 last_lifecycle freshness | PASS | at=06/28/2026 11:09:43 age=8.86532659163889h |
| orchestrator-work-report | PASS | E:\raindeer\harness\reports\orchestrator\latest.md |
| worker-work-reports | PASS | count=24 |
| work-reports-index | PASS | E:\raindeer\harness\work-reports-index.json |
| sync-coherence-index | PASS | E:\raindeer\harness\sync-coherence-index.json |
| SYNC-001 freshness | WARN | age=32.0159110483611h dirty=True |
| verification-snapshot-index | PASS | E:\raindeer\harness\verification-snapshot-index.json |
| VER-001 freshness | WARN | age=32.01593973325h dirty=True |
| closure-gate-index | PASS | E:\raindeer\harness\closure-gate-index.json |
| CLO-001 freshness | WARN | age=32.0159682135h dirty=True |
| SYNC coherence drift | WARN | warnings=2 |
| CLO closure candidates | PASS | open=0 |

## Findings

| Severity | Code | Title | Detail | Recommendation |
|----------|------|-------|--------|----------------|
| warning | LEDGER-002 | 脏工作区缺少当日台账 | 检测到 Git 未提交变更，但最新台账日期不是今天。 | 在 §5 追加今日条目，记录本轮实现/测试/决策。 |
| warning | SYNC-001 | sync-coherence-index stale | last_lifecycle.at=06/27/2026 12:00:41 exceeds 24h. Git dirty. | python harness/sync_coherence_lifecycle.py run --apply |
| warning | VER-001 | verification-snapshot-index stale | last_lifecycle.at=06/27/2026 12:00:41 exceeds 24h. Git dirty. | python harness/verification_snapshot_lifecycle.py run --apply |
| warning | CLO-001 | closure-gate-index stale | last_lifecycle.at=06/27/2026 12:00:41 exceeds 24h. Git dirty. | python harness/closure_gate_lifecycle.py run --apply |
| warning | SYNC-002 | 五真源漂移 | sync-coherence-index 含 2 条 warning | 更新 PROJECT_STATUS 顶部现状概述并与 loop-state/CONTINUATION 对齐 |


## loop_tick status

```text
{
  "stopped": true,
  "stop_detail": "closure_gate=closed",
  "next_atomic_action": "OPERATOR_REVIEWER_AUTHORIZATION_EVIDENCE_REVIEW_LOOP299������ loop298 explicit_authorization_config_rollback_audit_boundary_v1��ʵ�� explicit operator/reviewer authorization evidence review packet��ֻ���� boundary planning/readiness ֤�ݣ�У�� boundary_status��required_authorization_artifacts��operator_authorization still required_not_granted��reviewer_authorization still required_not_approved��runner_config still not_connected��rollback/audit still not_ready��source blockers/fail-closed evidence��candidate refs��A-E taxonomy��safe_sim/audit/F6 refs �� no-execution matrix����� evidence_review_status��operator_authorization_evidence_status��reviewer_authorization_evidence_status��blockers �� manual next actions�����ð� evidence review ����Ϊ authorization grant��manual acceptance��runner/adapter connection��actual dry-run��DB-backed real batch��PL-H �� execution permission��",
  "next_after": "After explicit operator/reviewer evidence review remains review-only without grants, continue toward config/rollback evidence package review while no execution is authorized.",
  "updated_at": "2026-06-28T19:32:04+08:00",
  "last_tick": "loop298-explicit-authorization-config-rollback-audit-boundary",
  "last_lifecycle_run": {
    "at": "2026-06-28T11:09:43Z",
    "apply": true,
    "dedupe_actions": 0,
    "dream_candidates": 0,
    "closure_candidates": 0,
    "archived_rounds": [],
    "active_step_digests": 34,
    "completed_tasks_hint": [
      "loop297 Manual request artifact capture/review complete. Added qa.quant_mining.manual_request_artifact_capture_review.build_manual_request_artifact_capture_review_v1, wired manual_request_artifact_capture_review_v1 into MiningJob observability, Factor Library rows, Chat notes, and mining API assertion surfaces. The read-model converts controlled_dry_run_request_intake_review_v1 into review-only artifact review with accepted/malformed/missing artifacts, artifact_review_status, blockers, candidate refs, A-E taxonomy, safe_sim/audit refs, reviewed plan/F6 evidence, and manual next actions; it never grants automatic publication, backtest execution, runner/adapter connection, actual dry-run, DB-backed real batch, PL-H authority, manual acceptance, or execution permission. P2 closures: source hard blockers, source_gate_ref drift, missing/wrong F6 evidence_kind, artifact role/provenance drift, and artifact-level pl_h_batch_execution_allowed fail-close as blocked and clear candidate refs. Verification: focused tests 20 passed; loop293-297 related regression 182 passed; executor related 184 passed; verifier subset 121 passed; targeted Ruff pass; git diff --check pass with CRLF warnings only; exact enabling assignment scan clean; Planner, Dispatcher, Test Engineer, Executor, Code Reviewer, and Verifier all used permanent worker identities. Next_atomic_action is EXPLICIT_AUTHORIZATION_CONFIG_ROLLBACK_AUDIT_BOUNDARY_LOOP298.",
      "explicit-authorization-config-rollback-audit-boundary-loop298",
      "loop297-manual-request-artifact-capture-review"
    ],
    "ttl_days": 180
  },
  "lifecycle_runs": {
    "methodology_memory": {
      "at": "2026-06-28T11:09:43Z",
      "apply": true,
      "dedupe_actions": 0,
      "dream_candidates": 0,
      "closure_candidates": 0,
      "archived_rounds": [],
      "active_step_digests": 34,
      "completed_tasks_hint": [
        "loop297 Manual request artifact capture/review complete. Added qa.quant_mining.manual_request_artifact_capture_review.build_manual_request_artifact_capture_review_v1, wired manual_request_artifact_capture_review_v1 into MiningJob observability, Factor Library rows, Chat notes, and mining API assertion surfaces. The read-model converts controlled_dry_run_request_intake_review_v1 into review-only artifact review with accepted/malformed/missing artifacts, artifact_review_status, blockers, candidate refs, A-E taxonomy, safe_sim/audit refs, reviewed plan/F6 evidence, and manual next actions; it never grants automatic publication, backtest execution, runner/adapter connection, actual dry-run, DB-backed real batch, PL-H authority, manual acceptance, or execution permission. P2 closures: source hard blockers, source_gate_ref drift, missing/wrong F6 evidence_kind, artifact role/provenance drift, and artifact-level pl_h_batch_execution_allowed fail-close as blocked and clear candidate refs. Verification: focused tests 20 passed; loop293-297 related regression 182 passed; executor related 184 passed; verifier subset 121 passed; targeted Ruff pass; git diff --check pass with CRLF warnings only; exact enabling assignment scan clean; Planner, Dispatcher, Test Engineer, Executor, Code Reviewer, and Verifier all used permanent worker identities. Next_atomic_action is EXPLICIT_AUTHORIZATION_CONFIG_ROLLBACK_AUDIT_BOUNDARY_LOOP298.",
        "explicit-authorization-config-rollback-audit-boundary-loop298",
        "loop297-manual-request-artifact-capture-review"
      ],
      "ttl_days": 180
    },
    "work_reports": {
      "at": "2026-06-27T12:00:41Z",
      "apply": true,
      "dedupe_actions": 0,
      "record_count": 22,
      "created": []
    },
    "sync_coherence": {
      "at": "2026-06-27T12:00:41Z",
      "finding_count": 3,
      "warning_count": 2,
      "error_count": 0
    },
    "verification_snapshot": {
      "at": "2026-06-27T12:00:41Z",
      "apply": true,
      "stale": true,
      "git_dirty": true,
      "age_hours": 58.84635098388889
    },
    "closure_gate": {
      "at": "2026-06-27T12:00:41Z",
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
  "finding_count": 3,
  "latest_section5": "629",
  "top_section5_ref": "629",
  "findings": [
... |
| verification_snapshot | 0 | {
  "apply": true,
  "stale": true,
  "git_dirty": true,
  "age_hours": 82.86222152472222,
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
| methodology-memory-index | last_lifecycle.at=06/28/2026 12:01:38 |
| work-reports-index | last_lifecycle.at=06/28/2026 12:01:38 |
| sync-coherence-index | last_lifecycle.at=06/28/2026 12:01:38 | findings_warn=2 findings_error=0 |
| verification-snapshot-index | last_lifecycle.at=06/28/2026 12:01:38 | findings_warn=1 findings_error=0 |
| closure-gate-index | open_count=0 | last_lifecycle.at=06/28/2026 12:01:39 | findings_warn=0 findings_error=0 |

## Git status (dual repos)

### Raindeer root

- branch=main ahead=3 behind=0 dirty=6
- status -sb:
```text
## main...origin/raindeer-AWI [ahead 3]
 m apps/quant_assistant
 M harness/closure-gate-index.json
 M harness/methodology-memory-index.json
 M harness/sync-coherence-index.json
 M harness/verification-snapshot-index.json
 M harness/work-reports-index.json
```

### quant_assistant

- branch=main ahead=3 behind=0 dirty=6
- status -sb:
```text
## main...origin/main [ahead 3]
 M src/qa/quant_mining/mining_runner.py
 M src/qa/ui/chat_brain.py
 M src/qa/ui/factor_library_insights.py
?? src/qa/quant_mining/operator_reviewer_authorization_evidence_review.py
?? tests/test_operator_reviewer_authorization_evidence_review_surface_unit.py
?? tests/test_operator_reviewer_authorization_evidence_review_unit.py
```

## TREE-2 gap list

- Path: `apps/quant_assistant/docs/ENGINEERING/TREE-2-gap-list.yaml`
- Summary: **env_count=1 | future_count=4 | degraded_count=5 | blocker_count=0**

## Notes

- `sync_coherence_lifecycle` validates prose drift read-only even with `--apply`.
- Full agent audit prompt: `harness/templates/daily-compliance-prompt.md`
- Daily scheduler: `daily-ops` calls `daily-git-push` after this wrapper succeeds
