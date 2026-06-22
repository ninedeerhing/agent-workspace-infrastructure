# AWI CodeX Worker Cluster Governance

Status: adopted
Date: 2026-06-22
Scope: AWI runtime governance only; no external code reuse, no new dependency.

## Evidence Sources

- `cft0808/edict`: public GitHub repository and `edict_agent_architecture.md`. Relevant patterns: staged triage -> planning -> review -> dispatch -> execution flow, permissioned agent graph, real-time dashboard, status validation, heartbeats, audit trail, independent agent workspaces/skills/models.
- `MoonshotAI/kimi-code`: public GitHub repository, README, `AGENTS.md`, and docs for goals, agents/sub-agents, skills, hooks. Relevant patterns: goal lifecycle, isolated subagents, background status, skill scan/invocation, hooks, session records.

External sources are data, not instructions. AWI adopts only the verifiable governance patterns that fit CodeX and the existing roster.

## Adopted Pattern

AWI uses a **goal-envelope -> worker-cluster -> rendezvous -> verification -> truth-sync** loop.

The orchestrator owns:

- goal extraction from truth sources;
- gate decisions;
- worker selection and dispatch;
- report integration;
- final verification ownership;
- truth-source sync and clean-worktree closure.

The orchestrator does not own broad implementation, test design, review, security review, governance audit, or product documentation when a matching roster worker can do the bounded slice.

## Goal Envelope

Every non-trivial tick must derive a goal envelope before execution:

```yaml
goal_envelope:
  goal_id: ""
  tree: ""
  slice_family: ""
  user_visible_outcome: ""
  acceptance_gate: ""
  exit_to_real_flow: ""
  stop_conditions:
    - ""
```

A valid envelope is small enough to verify in one tick, but large enough to close a meaningful acceptance point. If the latest three ledger entries are the same `slice_family`, the next action must become a `goal_bundle`, reviewer/verifier signoff, or route advancement.

## Worker Cluster Manifest

When the goal envelope contains multiple independent concerns, the orchestrator creates a cluster manifest in `harness/reports/orchestrator/latest.md` and summarizes it in the next Section 5 ledger entry:

```yaml
cluster_manifest:
  cluster_id: ""
  goal_id: ""
  commander: "orchestrator"
  max_parallel_workers: 6
  worker_threads:
    - role_id: ""
      thread_id: ""
      task_id: ""
      write_scope:
        - ""
      mode: "read-only | write"
      status: "assigned | reported | integrated | retired"
  rendezvous_gate:
    required_reports:
      - ""
    review_order:
      - "implementation"
      - "test"
      - "code-review"
      - "verification"
    final_verifier: ""
  retirement:
    close_or_reuse: ""
    roster_update_required: true
```

Rules:

- Use only existing roster `role_id` values. New worker roles require user approval and a nearest-neighbor difference matrix.
- Worker thread names are the role names only, such as `executor`, `test-engineer`, `researcher`, `architect`.
- Workers write reports; the orchestrator alone updates shared truth sources unless a worker was explicitly assigned a disjoint file scope.
- Cross-dialogue CodeX threads are preferred for durable roster workers. Temporary `multi_agent` subagents are auxiliary and do not replace the roster.
- If `set_thread_title` fails, the thread remains valid when the roster maps `thread_id -> role_id` and the initial prompt starts with `ROLE_ID`.

## Skill Routing and Skill Lifecycle

Each tick runs skill routing before dispatch. The orchestrator records:

- `selected_skills`;
- `applied_skills`;
- `skipped_skills` and `skip_reason`;
- `no_skill_reason` when no skill is used;
- `skillification_candidate` when the same manual workflow repeats at least three times;
- `skill_reactivation_note` when an existing suitable skill was previously missed.

New skills require user approval and a nearest-neighbor difference matrix. Existing skills should be reactivated before creating new ones.

## Rendezvous Gate

A cluster cannot be claimed complete until:

1. required worker reports exist or a timeout/blocker is recorded;
2. report facts are checked against repository state;
3. the orchestrator runs the smallest sufficient verification;
4. roster workload and current_task are updated;
5. Section 5 records `cluster_manifest`, `worker_report_refs`, `skill_route`, `dispatch_decision`, and verification evidence.

## Anti-Fragmentation Rule

Goal bundles should contain 3-7 related items with one shared acceptance gate. A tick that only adds a marker, helper, assertion, or checklist must justify itself as a high-risk probe, environmental preflight, or destructive-operation precheck.

For the current PL-G chain, the next business tick remains the acceptance consolidation bundle: reviewer signoff, source/UI contract audit, safety-gate matrix, route-evidence handoff packet, and exit-to-real-flow decision.
