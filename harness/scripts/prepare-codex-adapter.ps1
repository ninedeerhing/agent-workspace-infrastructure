<#
.SYNOPSIS
    Prepare a minimal AWI / CodeX zero-config adapter in an existing or new project.
.DESCRIPTION
    Generates a small, project-local AWI core for a target software project:
    AGENTS.md, docs status/task/continuation files, harness loop state, handoff,
    and CodeX orchestrator/subagent prompts.

    The script never copies secrets from the source workspace. Existing target
    files are not overwritten; candidate replacements are written under
    .awi-adapter/proposed/ and listed in .awi-adapter/adapter-report.json.
.PARAMETER TargetPath
    Project directory to adapt.
.PARAMETER ProjectName
    Human-readable project name. Defaults to the target directory name.
.PARAMETER CreateTarget
    Create TargetPath when it does not exist.
.PARAMETER PassThru
    Return the report object in addition to writing adapter-report.json.
.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\harness\scripts\prepare-codex-adapter.ps1 -TargetPath D:\work\my-app -ProjectName my-app -WhatIf
.EXAMPLE
    powershell -NoProfile -ExecutionPolicy Bypass -File .\harness\scripts\prepare-codex-adapter.ps1 -TargetPath D:\work\my-app -ProjectName my-app
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetPath,

    [string]$ProjectName,

    [switch]$CreateTarget,

    [switch]$PassThru
)

$ErrorActionPreference = "Stop"

function New-DirectoryIfMissing {
    param([string]$Path)

    if (Test-Path $Path) {
        return
    }

    if ($PSCmdlet.ShouldProcess($Path, "Create directory")) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Get-TemplateMap {
    param(
        [string]$Name,
        [string]$GeneratedAt
    )

    $loopState = @"
{
  "version": "0.1.0",
  "updated_at": "$GeneratedAt",
  "mode": "codex-zero-config",
  "stop_reason": null,
  "current_tree": "BOOTSTRAP",
  "current_slice": "codex-zero-config-handoff",
  "next_atomic_action": "Read minimal truth sources, identify the current mainline, and run the smallest safe verification.",
  "next_after": "Update PROJECT_STATUS, CONTINUATION_PROMPT, session-handoff, and continue the next atomic action.",
  "blockers": [],
  "last_tick": "bootstrap",
  "closure_gate": {
    "status": "open",
    "note": "Fresh AWI adapter bootstrap; close only after project-specific verification is recorded."
  }
}
"@

    $agents = @"
# AGENTS.md

You are the AWI orchestrator for $Name.

## Operating Contract

- Read `docs/PROJECT_STATUS.md`, `docs/TASK_TREES.md`, `docs/CONTINUATION_PROMPT.md`, `harness/loop-state.json`, `harness/session-handoff.md`, and `harness/reports/EMPLOYEE_ROSTER.md` before substantive work.
- Treat `docs/PROJECT_STATUS.md` as the status truth; `CONTINUATION_PROMPT.md` is only a resumable view.
- Do not copy or expose secrets. Never edit `.env`, `.env.local`, credentials, tokens, or private keys unless the user explicitly authorizes a safe placeholder-only change.
- Do not overwrite existing user files without an explicit request.
- Use cross-chat subagents only for bounded independent tasks; require structured reports.
- Verify before claiming completion.
- Update the status ledger after implementation, testing, process changes, or handoff decisions.
"@

    $projectStatus = @"
# Project Status

Updated: $GeneratedAt

This file is the status truth for $Name.

## Current Round

- **Mode**: CodeX zero-config AWI bootstrap.
- **Current mainline**: BOOTSTRAP.
- **Next atomic action**: Read truth sources, inspect the project shape, identify the first safe task, and run minimal verification.
- **Blockers**: None recorded yet.

## 5) Execution Ledger

### 5.1 CodeX AWI adapter bootstrap ($GeneratedAt)

**Action**: Generated minimal AWI truth sources and CodeX prompts.

**Files**: See `.awi-adapter/adapter-report.json`.

**Verification**: Run project-specific checks after reading the native build/test docs.

**Methodology gate**: No project-specific methodology yet.
"@

    $taskTrees = @"
# Task Trees

Updated: $GeneratedAt

## Rules

- Keep one foreground mainline unless the user explicitly starts parallel work.
- New ideas go to `parking_lot` before implementation.
- Do not mix unrelated task trees in one commit.
- Record every meaningful action in `docs/PROJECT_STATUS.md`.

## BOOTSTRAP

- **Status**: in_progress
- **Goal**: Adapt $Name to AWI / CodeX zero-config operation.
- **Next atomic action**: Read native project docs and identify the smallest safe verification.

## parking_lot

- Empty.
"@

    $continuation = @"
# Continuation Prompt

Updated: $GeneratedAt

## Copyable Prompt

You are the AWI orchestrator for $Name. Read:

1. `AGENTS.md`
2. `docs/PROJECT_STATUS.md`
3. `docs/TASK_TREES.md`
4. `harness/loop-state.json`
5. `harness/session-handoff.md`
6. `harness/reports/EMPLOYEE_ROSTER.md`
7. `harness/templates/codex-zero-config-prompt.md`

Then identify the current mainline, blockers, minimal verification command, and next atomic action. Do not overwrite user files or copy secrets.

## Current State

- BOOTSTRAP in progress.
- No completed project-specific verification recorded yet.

## Do Not Redo

- Do not regenerate adapter files over existing project files. Use `.awi-adapter/proposed/` for conflicts.
"@

    $handoff = @"
# Session Handoff

updated_at: $GeneratedAt

## Current Objective

Adapt $Name to AWI / CodeX zero-config operation.

## Next Step

Read minimal truth sources, inspect native project docs, and run the smallest safe verification.

## Compression Rules

- Keep handoff short.
- Preserve current goal, changed files, verification evidence, blockers, next action, and do-not-repeat items.
- Store facts in repository files, not chat memory.
"@

    $employeeRoster = @"
# AWI Employee Roster

Updated: $GeneratedAt

This roster is the stable cross-chat inventory for AWI managers and workers in $Name. It indexes identity, responsibility boundary, report location, workload, mistake/lesson counts, and current assignment state.

## Field Contract

| Field | Meaning |
|---|---|
| role_id | Stable worker role used in prompts, reports, and assignments. |
| identity_id | Stable cross-chat identity key; default worker:<role_id> or manager:orchestrator. |
| display_name | Human-readable name. |
| responsibility | Responsibility boundary for dispatch. |
| report_path | Canonical worker report file. |
| status | active, idle, blocked, or retired. |
| workload | 0 idle, 1 light, 2 medium, or 3 high. |
| intensity | low, normal, high, or surge. |
| performance | Recent evidence-based delivery signal. |
| mistake_count | Confirmed mistakes requiring correction. |
| lesson_count | Lessons absorbed into reports, methodology, or handoff notes. |
| last_assigned_at | Last assignment timestamp. |
| last_report_at | Last report timestamp. |
| current_task | Current task id or summary. |
| handoff_notes | Notes the next orchestrator must preserve. |
| risk_notes | Escalation or dispatch risk notes. |

## Maintenance Rules

- Read this file before dispatching subagents.
- Prefer idle or light workers whose responsibility matches the task.
- After each subagent report, update last_report_at, workload, performance, mistake_count, lesson_count, current_task, and handoff_notes.
- New workers or skills require AskQuestion/user approval; do not create them silently.
- report_path remains the detailed evidence source; this roster is an index.

## Manager

| role_id | identity_id | display_name | responsibility | report_path | status | workload | intensity | performance | mistake_count | lesson_count | last_assigned_at | last_report_at | current_task | handoff_notes | risk_notes |
|---|---|---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|
| orchestrator | manager:orchestrator | Orchestrator | User-facing coordinator, dispatch, synthesis, verification ownership, truth-source sync | harness/reports/orchestrator/latest.md | active | 1 light | normal | bootstrap | 0 | 0 | $GeneratedAt | $GeneratedAt | Bootstrap AWI adapter | Keep user-facing authority centralized | Escalate destructive ops, secrets, or new worker creation |

## Workers

| role_id | identity_id | display_name | responsibility | report_path | status | workload | intensity | performance | mistake_count | lesson_count | last_assigned_at | last_report_at | current_task | handoff_notes | risk_notes |
|---|---|---|---|---|---|---|---|---|---:|---:|---|---|---|---|---|
| architect | worker:architect | Architect | System boundaries, dependency direction, architecture decisions | harness/reports/workers/architect.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for architecture changes | Escalate broad boundary changes |
| code-reviewer | worker:code-reviewer | Code Reviewer | Logic defects, maintainability, performance, style review | harness/reports/workers/code-reviewer.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use after implementation | Avoid assigning implementation ownership |
| constitution-guardian | worker:constitution-guardian | Constitution Guardian | Constitution and governance compliance | harness/reports/workers/constitution-guardian.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for rule conflicts | Escalate governance conflicts |
| critic | worker:critic | Critic | Devil's advocate review of plans and implementations | harness/reports/workers/critic.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use before high-impact plan closure | Avoid routine mechanical checks |
| debugger | worker:debugger | Debugger | Root cause analysis, reproduction, regression isolation | harness/reports/workers/debugger.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for failures | Require fresh evidence |
| designer | worker:designer | Designer | UI/UX, interface usability, design systems | harness/reports/workers/designer.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for UI changes | Browser evidence required |
| executor | worker:executor | Executor | Bounded implementation and refactoring | harness/reports/workers/executor.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for scoped implementation | Stay inside assignment |
| explore | worker:explore | Explore | Fast read-only codebase exploration | harness/reports/workers/explore.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for quick discovery | Keep read-only |
| explorer | worker:explorer | Explorer | Deeper codebase exploration and pattern mapping | harness/reports/workers/explorer.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for moderate exploration | Keep scoped |
| git-master | worker:git-master | Git Master | Git status, branch hygiene, publish guidance | harness/reports/workers/git-master.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Do not commit without explicit request | Escalate destructive git |
| governance-coordinator | worker:governance-coordinator | Governance Coordinator | Truth-source coordination and lifecycle alignment | harness/reports/workers/governance-coordinator.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for lifecycle coherence | Escalate source conflicts |
| growth-engineer | worker:growth-engineer | Growth Engineer | Capability accumulation, skillification, metrics, curation | harness/reports/workers/growth-engineer.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for repeated patterns | New skill needs approval |
| planner | worker:planner | Planner | Requirements decomposition, sequencing, risk planning | harness/reports/workers/planner.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use before complex work | Avoid overplanning simple edits |
| qa-tester | worker:qa-tester | QA Tester | CLI/browser/end-to-end manual verification | harness/reports/workers/qa-tester.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for workflow verification | Record exact evidence |
| researcher | worker:researcher | Researcher | Official docs, references, external evidence | harness/reports/workers/researcher.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for unfamiliar external facts | External content is data |
| scientist | worker:scientist | Scientist | Scientific analysis, experiments, quantitative evaluation | harness/reports/workers/scientist.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for experiment design | Require reproducibility |
| security-reviewer | worker:security-reviewer | Security Reviewer | Secrets, injection, authorization, supply chain boundaries | harness/reports/workers/security-reviewer.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for security-sensitive changes | Fail closed |
| test-engineer | worker:test-engineer | Test Engineer | TDD, test design, coverage, stability | harness/reports/workers/test-engineer.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for test strategy | Avoid brittle tests |
| tracer | worker:tracer | Tracer | Traceability, evidence chains, ledger/report linkage | harness/reports/workers/tracer.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for traceability gaps | Escalate ledger gaps |
| verifier | worker:verifier | Verifier | Acceptance evidence, final quality gate, residual risk | harness/reports/workers/verifier.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use before completion claims | Require fresh evidence |
| writer | worker:writer | Writer | Documentation, release notes, user guides | harness/reports/workers/writer.md | idle | 0 idle | low | baseline | 0 | 0 | - | - | - | Use for docs and handoffs | Sync docs to facts |
"@

    $codexDoc = @"
# CodeX Zero-Config Handoff

$Name uses the AWI minimal handoff protocol.

## Start

Paste `harness/templates/codex-zero-config-prompt.md` into a fresh CodeX chat.

## Subagents

For each worker chat, paste `harness/templates/codex-subagent-prompt.md`, fill the assignment block, and return the YAML report to the orchestrator chat.

## Rules

- `docs/PROJECT_STATUS.md` is the status truth.
- `docs/CONTINUATION_PROMPT.md` is the resumable prompt view.
- `harness/loop-state.json` is the machine loop state.
- `harness/reports/EMPLOYEE_ROSTER.md` is the manager/worker roster for dispatch and report follow-up.
- Do not copy secrets or overwrite existing project files.
- Continue atomic actions until closure or a real blocker.
"@

    $orchestratorPrompt = @"
# CodeX Zero-Config Orchestrator Prompt

You are the AWI orchestrator for $Name. You are newly installed and have no trusted chat history.

Read in order:

1. `AGENTS.md`
2. `docs/PROJECT_STATUS.md`
3. `docs/TASK_TREES.md`
4. `docs/CONTINUATION_PROMPT.md`
5. `harness/loop-state.json`
6. `harness/session-handoff.md`
7. `harness/reports/EMPLOYEE_ROSTER.md`
8. Native build/test/security docs relevant to the task

Rules:

- Use repository truth over memory.
- Do not copy or expose secrets.
- Do not overwrite user files.
- Use cross-chat subagents only for bounded independent tasks after checking the employee roster for responsibility, workload, mistakes, lessons, and risk notes.
- Require report YAML from every subagent.
- Verify before completion.
- Update status truth sources and `harness/reports/EMPLOYEE_ROSTER.md` after meaningful work.
- New workers or skills require AskQuestion/user approval; do not create them silently.
- Continue the next safe atomic action until closure or a real blocker.

First action: report current mainline, blockers, minimal verification command, and next atomic action; then execute the next safe atomic action.
"@

    $subagentPrompt = @"
# CodeX Cross-Chat Subagent Prompt

You are an AWI subagent for $Name. You are not the user-facing orchestrator.

Fill this assignment before work:

```yaml
assignment:
  role_id: ""
  identity_id: "worker:<role_id>"
  task_id: ""
  objective: ""
  target_files: []
  invariants: []
  verification_required: []
  do_not_touch:
    - ".env"
    - ".env.local"
    - "credentials"
    - "secrets"
```

Rules:

- Stay inside the assignment.
- Read the minimal truth sources before acting.
- Read `harness/reports/EMPLOYEE_ROSTER.md`; do not exceed your responsibility boundary.
- Do not expose secrets or overwrite unrelated files.
- Verify with the smallest relevant command.
- Do not create new workers or skills; report blocked if expansion seems necessary.
- Return only this YAML report:

```yaml
report:
  role_id: ""
  identity_id: ""
  status: "success | partial | blocked | failed"
  task_id: ""
  summary: ""
  changes:
    - file: ""
      type: "add | modify | delete | none"
      summary: ""
  verification:
    - command: ""
      result: ""
  roster_update:
    workload_delta: "unchanged | increased | decreased | cleared"
    mistakes: []
    lessons: []
    performance_note: ""
    current_task_status: "active | idle | blocked | retired"
  blockers: []
  risks: []
  next: ""
```
"@

    $map = [ordered]@{}
    $map["AGENTS.md"] = $agents
    $map["docs/PROJECT_STATUS.md"] = $projectStatus
    $map["docs/TASK_TREES.md"] = $taskTrees
    $map["docs/CONTINUATION_PROMPT.md"] = $continuation
    $map["docs/CODEX_ZERO_CONFIG_HANDOFF.md"] = $codexDoc
    $map["harness/loop-state.json"] = $loopState
    $map["harness/session-handoff.md"] = $handoff
    $map["harness/reports/EMPLOYEE_ROSTER.md"] = $employeeRoster
    $map["harness/templates/codex-zero-config-prompt.md"] = $orchestratorPrompt
    $map["harness/templates/codex-subagent-prompt.md"] = $subagentPrompt
    return $map
}

function Write-AdapterFile {
    param(
        [string]$Root,
        [string]$AdapterDir,
        [string]$RelativePath,
        [string]$Content
    )

    $targetFile = Join-Path $Root $RelativePath
    $exists = Test-Path $targetFile
    $writePath = $targetFile
    $status = "created"

    if ($exists) {
        $writePath = Join-Path (Join-Path $AdapterDir "proposed") $RelativePath
        $status = "conflict_proposed"
    }

    $parent = Split-Path $writePath -Parent
    New-DirectoryIfMissing $parent

    if ($PSCmdlet.ShouldProcess($writePath, "Write adapter file")) {
        Set-Content -Path $writePath -Value $Content -Encoding UTF8
    }
    elseif ($WhatIfPreference) {
        $status = if ($exists) { "whatif_conflict" } else { "whatif_create" }
    }

    return [pscustomobject]@{
        relative_path = $RelativePath
        target_path = $targetFile
        written_path = $writePath
        status = $status
        target_existed = $exists
    }
}

$targetExists = Test-Path $TargetPath
if (-not $targetExists) {
    if (-not $CreateTarget) {
        throw "TargetPath does not exist. Re-run with -CreateTarget to initialize: $TargetPath"
    }
    New-DirectoryIfMissing $TargetPath
}

if (-not (Test-Path $TargetPath) -and -not $WhatIfPreference) {
    throw "TargetPath was not created: $TargetPath"
}

$resolvedTarget = if (Test-Path $TargetPath) {
    (Resolve-Path $TargetPath).Path
}
else {
    [System.IO.Path]::GetFullPath($TargetPath)
}

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectName = Split-Path $resolvedTarget -Leaf
}

$generatedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
$adapterDir = Join-Path $resolvedTarget ".awi-adapter"
$reportDir = Join-Path $adapterDir "reports"
New-DirectoryIfMissing $adapterDir
New-DirectoryIfMissing $reportDir

$results = @()
$templates = Get-TemplateMap -Name $ProjectName -GeneratedAt $generatedAt
foreach ($entry in $templates.GetEnumerator()) {
    $results += Write-AdapterFile -Root $resolvedTarget -AdapterDir $adapterDir -RelativePath $entry.Key -Content $entry.Value
}

$created = @($results | Where-Object { $_.status -eq "created" })
$conflicts = @($results | Where-Object { $_.status -eq "conflict_proposed" -or $_.status -eq "whatif_conflict" })
$planned = @($results | Where-Object { $_.status -like "whatif_*" })

$report = [pscustomobject]@{
    version = "0.1.0"
    generated_at = $generatedAt
    target_path = $resolvedTarget
    project_name = $ProjectName
    secret_policy = "No .env, .env.local, credentials, tokens, private keys, caches, data files, or source project secrets are copied."
    overwrite_policy = "Existing target files are never overwritten; candidates are written under .awi-adapter/proposed/."
    created_count = $created.Count
    conflict_count = $conflicts.Count
    whatif_count = $planned.Count
    files = $results
    next_steps = @(
        "Open a fresh CodeX chat in the target project.",
        "Paste harness/templates/codex-zero-config-prompt.md.",
        "If using worker chats, paste harness/templates/codex-subagent-prompt.md and return the YAML report to the orchestrator.",
        "Run the target project's native lint/test command and record it in docs/PROJECT_STATUS.md."
    )
}

$reportPath = Join-Path $adapterDir "adapter-report.json"
if ($PSCmdlet.ShouldProcess($reportPath, "Write adapter report")) {
    $report | ConvertTo-Json -Depth 8 | Set-Content -Path $reportPath -Encoding UTF8
}

Write-Host "AWI CodeX adapter prepared for: $resolvedTarget"
Write-Host "Created: $($created.Count) · Conflicts/proposals: $($conflicts.Count) · WhatIf: $($planned.Count)"
Write-Host "Report: $reportPath"
Write-Host "Next: paste harness/templates/codex-zero-config-prompt.md into a fresh CodeX chat."

if ($PassThru) {
    $report
}
