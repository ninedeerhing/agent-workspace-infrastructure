<#
.SYNOPSIS
    CodeX-effective AWI self-check.
.DESCRIPTION
    Validates the pieces that must be real in CodeX, not just present as Cursor-era prose:
    platform binding, zero-config prompts, subagent roster, critical skills, agent registry,
    CodeX automation registry, and runtime loop state.

    Exit codes:
      0 = no findings
      1 = one or more findings
#>

param(
    [string]$TargetPath = (Get-Location).Path,
    [ValidateSet("text", "json", "markdown")]
    [string]$Format = "text",
    [switch]$Quiet
)

$ErrorActionPreference = "Continue"
$ProjectRoot = (Resolve-Path $TargetPath).Path
$HarnessDir = Join-Path $ProjectRoot "harness"
$DocsDir = Join-Path $ProjectRoot "docs"

$Checks = New-Object System.Collections.Generic.List[object]
$Findings = New-Object System.Collections.Generic.List[object]

function Add-Check {
    param([string]$Name, [string]$Status, [string]$Detail)
    $Checks.Add([pscustomobject]@{ name = $Name; status = $Status; detail = $Detail }) | Out-Null
}

function Add-Finding {
    param([string]$Severity, [string]$Code, [string]$Title, [string]$Detail, [string]$Recommendation)
    $Findings.Add([pscustomobject]@{
        severity = $Severity
        code = $Code
        title = $Title
        detail = $Detail
        recommendation = $Recommendation
    }) | Out-Null
}

function Get-Text {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    return Get-Content -LiteralPath $Path -Raw -Encoding UTF8
}

function Test-RequiredFile {
    param([string]$Path, [string]$Code, [string]$Name, [string]$Recommendation)
    if (Test-Path $Path) {
        Add-Check $Name "PASS" $Path
        return $true
    }
    Add-Check $Name "FAIL" "missing: $Path"
    Add-Finding "error" $Code "$Name missing" "Missing required CodeX file: $Path" $Recommendation
    return $false
}

Test-RequiredFile (Join-Path $DocsDir "PLATFORM-CODEX.md") "CX-001" "CodeX platform doc" "Run .\harness\adapters\Invoke-PlatformAdapter.ps1 -Platform codex and keep docs/PLATFORM-CODEX.md current." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "templates/codex-zero-config-prompt.md") "CX-002" "CodeX zero-config prompt" "Restore harness/templates/codex-zero-config-prompt.md." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "templates/codex-subagent-prompt.md") "CX-003" "CodeX subagent prompt" "Restore harness/templates/codex-subagent-prompt.md." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "reports/EMPLOYEE_ROSTER.md") "CX-004" "Employee roster" "Restore harness/reports/EMPLOYEE_ROSTER.md." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "codex-automation-registry.json") "CX-005" "CodeX automation registry" "Create CodeX automations through the UI/tool and write their ids to harness/codex-automation-registry.json." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "templates/daily-ops-prompt.md") "CX-DAILY-OPS-PROMPT" "Daily ops prompt" "Restore harness/templates/daily-ops-prompt.md." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "scripts/daily-ops.ps1") "CX-DAILY-OPS-SCRIPT" "Daily ops wrapper" "Restore harness/scripts/daily-ops.ps1." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "skill_router.py") "CX-009" "CodeX skill router" "Restore harness/skill_router.py and keep the loop skill routing gate executable." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "tests/test_skill_router.py") "CX-010" "CodeX skill router tests" "Restore harness/tests/test_skill_router.py." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "project-registry.json") "CX-PROJECT-REGISTRY" "AWI project registry" "Restore harness/project-registry.json so Project Registry + Source Index P1 remains machine-readable." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "source-index.json") "CX-SOURCE-INDEX" "AWI source index" "Restore harness/source-index.json so cold-path references are traceable without hot-loading full documents." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "capability-dag.json") "CX-CAPABILITY-DAG" "AWI capability DAG" "Restore harness/capability-dag.json so loop selection remains portfolio-first." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "capability-dag.schema.json") "CX-CAPABILITY-DAG-SCHEMA" "AWI capability DAG schema" "Restore harness/capability-dag.schema.json." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "runtime-task-dag.schema.json") "CX-RUNTIME-DAG-SCHEMA" "AWI runtime task DAG schema" "Restore harness/runtime-task-dag.schema.json." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "validate_awi_dags.py") "CX-DAG-VALIDATOR" "AWI DAG validator" "Restore harness/validate_awi_dags.py and keep DAG invariants executable." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "memory-os.json") "CX-MEMORY-OS" "AWI Memory OS" "Restore harness/memory-os.json so typed memory and retrieval policy remain machine-readable." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "memory-os.schema.json") "CX-MEMORY-OS-SCHEMA" "AWI Memory OS schema" "Restore harness/memory-os.schema.json." | Out-Null
Test-RequiredFile (Join-Path $HarnessDir "validate_awi_memory.py") "CX-MEMORY-VALIDATOR" "AWI Memory OS validator" "Restore harness/validate_awi_memory.py and keep Memory/RAG invariants executable." | Out-Null

$loopPromptPath = Join-Path $HarnessDir "templates/loop-tick-prompt.md"
$loopPromptText = Get-Text $loopPromptPath
if ($null -ne $loopPromptText) {
    $requiredLoopGateNeedles = @(
        "Goal/Plan Gate",
        "Function-First Loop Gate",
        "core_function_artifact",
        "phase_plan",
        "functional_acceptance",
        "closing_work_only",
        "Context Loading Budget Gate",
        "context_mode",
        "cold_path_reason",
        "Skill Routing Gate",
        "Worker Dispatch Gate",
        "Planner -> Dispatcher",
        "assignment_matrix",
        "orchestrator_self_execution_exception",
        "Worker Cluster/Rendezvous Gate",
        "goal_bundle",
        "slice_family",
        "no_skill_reason",
        "no_dispatch_reason",
        "cluster_manifest",
        "rendezvous_gate",
        "worker_report_refs",
        "no_cluster_reason",
        "skillification_candidate",
        "skill_reactivation_note",
        "capacity_review",
        "methodology_ref",
        "model_tier",
        "tmp/skill-route-events.jsonl"
    )
    foreach ($needle in $requiredLoopGateNeedles) {
        if ($loopPromptText -match [regex]::Escape($needle)) {
            Add-Check "loop prompt gate:$needle" "PASS" "present"
        }
        else {
            Add-Check "loop prompt gate:$needle" "FAIL" "missing"
            Add-Finding "error" "CX-LOOP-GATE" "Loop governance gate missing" "harness/templates/loop-tick-prompt.md does not contain required gate marker: $needle." "Restore the Goal/Plan, Skill Routing, and Worker Dispatch gates in the loop tick prompt."
        }
    }
}

$methodologyPath = Join-Path $ProjectRoot "apps/quant_assistant/docs/METHODOLOGY_MEMORY.md"
$methodologyText = Get-Text $methodologyPath
if ($null -eq $methodologyText) {
    Add-Check "methodology visibility source" "FAIL" "missing"
    Add-Finding "error" "CX-METHODOLOGY-VISIBILITY" "Methodology visibility source missing" "apps/quant_assistant/docs/METHODOLOGY_MEMORY.md is missing." "Restore the methodology memory truth source and its visible status block."
}
else {
    foreach ($needle in @("updated_at", "latest_digest", "latest_permanent_M_GP", "methodology_ref")) {
        if ($methodologyText -match [regex]::Escape($needle)) {
            Add-Check "methodology visibility:$needle" "PASS" "present"
        }
        else {
            Add-Check "methodology visibility:$needle" "FAIL" "missing"
            Add-Finding "error" "CX-METHODOLOGY-VISIBILITY" "Methodology visibility marker missing" "METHODOLOGY_MEMORY.md does not contain required visible status marker: $needle." "Refresh METHODOLOGY_MEMORY.md top visible status and ledger reference rules."
        }
    }
}

$qaProjectStatusPath = Join-Path $ProjectRoot "apps/quant_assistant/docs/PROJECT_STATUS.md"
$qaProjectStatusText = Get-Text $qaProjectStatusPath
if ($null -ne $qaProjectStatusText) {
    $latestQaLedger = [regex]::Match($qaProjectStatusText, '(?s)### 5\.\d+.*?(?=\r?\n### 5\.|\z)')
    if ($latestQaLedger.Success -and $latestQaLedger.Value -match 'methodology_ref') {
        Add-Check "QA latest ledger methodology_ref" "PASS" "present"
    }
    else {
        Add-Check "QA latest ledger methodology_ref" "FAIL" "missing"
        Add-Finding "error" "CX-METHODOLOGY-REF" "Latest QA ledger lacks methodology_ref" "The newest apps/quant_assistant PROJECT_STATUS §5 entry does not include methodology_ref." "Add methodology_ref to every new §5 row: M-17-zero-write, digest, or synthesis."
    }
}

$bindingPath = Join-Path $HarnessDir "platform-binding.json"
if (Test-Path $bindingPath) {
    try {
        $binding = Get-Content -LiteralPath $bindingPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($binding.platform -eq "codex" -and $binding.adapter_status -eq "installed") {
            Add-Check "platform-binding codex" "PASS" "platform=codex adapter_status=installed"
        }
        else {
            Add-Check "platform-binding codex" "FAIL" "platform=$($binding.platform) adapter_status=$($binding.adapter_status)"
            Add-Finding "error" "CX-006" "CodeX adapter is not bound" "harness/platform-binding.json does not identify the current platform as codex/installed." "Run .\harness\adapters\Invoke-PlatformAdapter.ps1 -Platform codex."
        }
    }
    catch {
        Add-Check "platform-binding codex" "FAIL" $_.Exception.Message
        Add-Finding "error" "CX-007" "platform-binding JSON parse failed" $_.Exception.Message "Fix harness/platform-binding.json."
    }
}
else {
    Add-Check "platform-binding codex" "FAIL" "missing"
    Add-Finding "error" "CX-008" "platform-binding missing" "harness/platform-binding.json is missing." "Run the CodeX platform adapter."
}

$requiredSkills = @(
    "agent-team-bootstrap",
    "workflow-phase-advance",
    "dispatching-parallel-agents",
    "subagent-driven-dev",
    "test-driven-development",
    "verification-before-completion",
    "session-retro",
    "skillify"
)

foreach ($skill in $requiredSkills) {
    $skillPath = Join-Path $ProjectRoot "skills/$skill/SKILL.md"
    if (Test-Path $skillPath) {
        Add-Check "skill:$skill" "PASS" $skillPath
    }
    else {
        Add-Check "skill:$skill" "FAIL" "missing"
        Add-Finding "error" "CX-SKILL" "Critical skill missing" "$skillPath is missing." "Restore the $skill skill or update AGENTS.md routing to remove it."
    }
}

$registryPath = Join-Path $HarnessDir "agent-registry.json"
if (Test-Path $registryPath) {
    try {
        $registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([int]$registry.worker_count -ge 21 -and [int]$registry.role_count -ge 22) {
            Add-Check "agent-registry roster" "PASS" "roles=$($registry.role_count) workers=$($registry.worker_count)"
        }
        else {
            Add-Check "agent-registry roster" "FAIL" "roles=$($registry.role_count) workers=$($registry.worker_count)"
            Add-Finding "error" "CX-AGENT" "Agent registry incomplete" "Expected at least 22 roles / 21 workers." "Run .\harness\scripts\Build-AgentRegistryFromAgentsDir.ps1 -WriteFiles -EnsureScaffold."
        }
    }
    catch {
        Add-Check "agent-registry roster" "FAIL" $_.Exception.Message
        Add-Finding "error" "CX-AGENT-JSON" "Agent registry parse failed" $_.Exception.Message "Fix harness/agent-registry.json."
    }
}
else {
    Add-Check "agent-registry roster" "FAIL" "missing"
    Add-Finding "error" "CX-AGENT-MISSING" "Agent registry missing" "harness/agent-registry.json is missing." "Run Build-AgentRegistryFromAgentsDir.ps1."
}

$rosterText = Get-Text (Join-Path $HarnessDir "reports/EMPLOYEE_ROSTER.md")
if ($null -ne $rosterText) {
    $workerRows = ([regex]::Matches($rosterText, '^\| [a-z0-9-]+ \| worker:', [System.Text.RegularExpressions.RegexOptions]::Multiline)).Count
    if ($workerRows -ge 22 -and $rosterText.Contains("| dispatcher | worker:dispatcher |")) {
        Add-Check "employee roster workers" "PASS" "workers=$workerRows"
    }
    else {
        Add-Check "employee roster workers" "FAIL" "workers=$workerRows"
        Add-Finding "error" "CX-ROSTER" "Employee roster incomplete" "Expected at least 22 worker rows including dispatcher." "Refresh harness/reports/EMPLOYEE_ROSTER.md from agent registry and add dispatcher."
    }
}

$platformText = Get-Text (Join-Path $DocsDir "PLATFORM-CODEX.md")
if ($null -ne $platformText) {
    foreach ($needle in @("automation_update", "create_thread", "send_message_to_thread", "codex-subagent-prompt", "codex-self-check", "daily-ops")) {
        if ($platformText -match [regex]::Escape($needle)) {
            Add-Check "PLATFORM-CODEX mentions $needle" "PASS" "present"
        }
        else {
            Add-Check "PLATFORM-CODEX mentions $needle" "WARN" "missing"
            Add-Finding "warning" "CX-DOC" "CodeX platform doc missing operational primitive" "docs/PLATFORM-CODEX.md does not mention $needle." "Update docs/PLATFORM-CODEX.md with CodeX-native operations."
        }
    }
}

$automationRegistryPath = Join-Path $HarnessDir "codex-automation-registry.json"
if (Test-Path $automationRegistryPath) {
    try {
        $auto = Get-Content -LiteralPath $automationRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $expected = @(
            @{ id = "loop-tick"; allowedStatuses = @("ACTIVE", "PAUSED_BY_USER") },
            @{ id = "daily-ops"; allowedStatuses = @("ACTIVE") }
        )
        foreach ($spec in $expected) {
            $id = $spec.id
            $entry = $auto.automations | Where-Object { $_.id -eq $id } | Select-Object -First 1
            if ($entry -and $entry.codex_id -and ($spec.allowedStatuses -contains $entry.status)) {
                Add-Check "automation:$id" "PASS" "codex_id=$($entry.codex_id); status=$($entry.status)"
            }
            else {
                Add-Check "automation:$id" "WARN" "missing/inactive in registry"
                Add-Finding "warning" "CX-AUTO" "CodeX automation not registered" "$id is not in an allowed status in harness/codex-automation-registry.json." "Create/update the automation with codex_app.automation_update or record the user-approved paused replacement mode."
            }
        }
        foreach ($id in @("daily-compliance", "daily-git-push", "codex-self-check")) {
            $entry = $auto.automations | Where-Object { $_.id -eq $id -and $_.status -eq "ACTIVE" } | Select-Object -First 1
            if ($entry) {
                Add-Check "retired automation inactive:$id" "WARN" "still ACTIVE in registry"
                Add-Finding "warning" "CX-AUTO-DUP" "Retired daily automation still active" "$id should be replaced by daily-ops to avoid duplicate CodeX daily conversations." "Retire $id and route daily work through awi-daily-ops."
            }
            else {
                Add-Check "retired automation inactive:$id" "PASS" "not active"
            }
        }
    }
    catch {
        Add-Check "CodeX automation registry JSON" "FAIL" $_.Exception.Message
        Add-Finding "error" "CX-AUTO-JSON" "Automation registry parse failed" $_.Exception.Message "Fix harness/codex-automation-registry.json."
    }
}

$projectRegistryPath = Join-Path $HarnessDir "project-registry.json"
if (Test-Path $projectRegistryPath) {
    try {
        $projectRegistry = Get-Content -LiteralPath $projectRegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $projectIds = @($projectRegistry.projects | ForEach-Object { $_.project_id })
        foreach ($requiredProjectId in @("raindeer-awi", "raindeer-quant-assistant")) {
            if ($projectIds -contains $requiredProjectId) {
                Add-Check "project-registry:$requiredProjectId" "PASS" "registered"
            }
            else {
                Add-Check "project-registry:$requiredProjectId" "FAIL" "missing"
                Add-Finding "error" "CX-PROJECT-REGISTRY" "Project registry missing project" "harness/project-registry.json does not include project_id=$requiredProjectId." "Add the missing project adapter to harness/project-registry.json."
            }
        }
        $awiProject = $projectRegistry.projects | Where-Object { $_.project_id -eq "raindeer-awi" } | Select-Object -First 1
        if ($awiProject -and $awiProject.truth_sources -contains "harness/source-index.json") {
            Add-Check "project-registry source-index truth source" "PASS" "present"
        }
        else {
            Add-Check "project-registry source-index truth source" "FAIL" "missing"
            Add-Finding "error" "CX-PROJECT-REGISTRY" "Project registry missing source-index truth source" "raindeer-awi truth_sources must include harness/source-index.json." "Add harness/source-index.json to the AWI truth source list."
        }
    }
    catch {
        Add-Check "project-registry JSON" "FAIL" $_.Exception.Message
        Add-Finding "error" "CX-PROJECT-REGISTRY-JSON" "Project registry parse failed" $_.Exception.Message "Fix harness/project-registry.json."
    }
}

$sourceIndexPath = Join-Path $HarnessDir "source-index.json"
if (Test-Path $sourceIndexPath) {
    try {
        $sourceIndex = Get-Content -LiteralPath $sourceIndexPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $sourceIds = @($sourceIndex.sources | ForEach-Object { $_.id })
        foreach ($requiredSourceId in @($sourceIndex.required_source_ids)) {
            if ($sourceIds -contains $requiredSourceId) {
                Add-Check "source-index:$requiredSourceId" "PASS" "indexed"
            }
            else {
                Add-Check "source-index:$requiredSourceId" "FAIL" "missing"
                Add-Finding "error" "CX-SOURCE-INDEX" "Required source missing" "harness/source-index.json required_source_ids includes $requiredSourceId, but sources does not contain it." "Add or correct the missing source index entry."
            }
        }
        $categories = @($sourceIndex.sources | ForEach-Object { $_.category } | Sort-Object -Unique)
        foreach ($requiredCategory in @($sourceIndex.required_categories)) {
            if ($categories -contains $requiredCategory) {
                Add-Check "source-index category:$requiredCategory" "PASS" "present"
            }
            else {
                Add-Check "source-index category:$requiredCategory" "FAIL" "missing"
                Add-Finding "error" "CX-SOURCE-INDEX-CATEGORY" "Required source category missing" "harness/source-index.json lacks category=$requiredCategory." "Add at least one source entry for this category."
            }
        }
        foreach ($transcriptId in @("douyin-dag-design-transcript", "douyin-memory-system-transcript", "douyin-harness-loop-eval-transcript")) {
            $entry = $sourceIndex.sources | Where-Object { $_.id -eq $transcriptId } | Select-Object -First 1
            if ($entry -and $entry.path) {
                $transcriptPath = Join-Path $ProjectRoot $entry.path
                if (Test-Path $transcriptPath) {
                    Add-Check "source-index transcript:$transcriptId" "PASS" $entry.path
                }
                else {
                    Add-Check "source-index transcript:$transcriptId" "FAIL" "missing file"
                    Add-Finding "error" "CX-SOURCE-INDEX-TRANSCRIPT" "Transcript file missing" "$transcriptId points to missing path: $($entry.path)." "Restore the transcript file or update harness/source-index.json."
                }
            }
        }
    }
    catch {
        Add-Check "source-index JSON" "FAIL" $_.Exception.Message
        Add-Finding "error" "CX-SOURCE-INDEX-JSON" "Source index parse failed" $_.Exception.Message "Fix harness/source-index.json."
    }
}

$dagValidatorPath = Join-Path $HarnessDir "validate_awi_dags.py"
if (Test-Path $dagValidatorPath) {
    $dagRaw = & python $dagValidatorPath --repo-root $ProjectRoot --json 2>&1 | Out-String
    try {
        $dagReport = $dagRaw | ConvertFrom-Json
        if ([int]$dagReport.summary.findings -eq 0) {
            Add-Check "AWI DAG validator" "PASS" "checks=$($dagReport.summary.checks); findings=0"
        }
        else {
            Add-Check "AWI DAG validator" "FAIL" "findings=$($dagReport.summary.findings)"
            foreach ($finding in @($dagReport.findings)) {
                Add-Finding $finding.severity "DAG-$($finding.code)" $finding.title $finding.detail "Fix harness/capability-dag.json or runtime task DAG files before continuing loop selection."
            }
        }
    }
    catch {
        Add-Check "AWI DAG validator" "FAIL" $_.Exception.Message
        Add-Finding "error" "CX-DAG-VALIDATOR" "AWI DAG validator output parse failed" $_.Exception.Message "Run python harness/validate_awi_dags.py --repo-root . --json and fix its output/errors."
    }
}

$memoryValidatorPath = Join-Path $HarnessDir "validate_awi_memory.py"
if (Test-Path $memoryValidatorPath) {
    $memoryRaw = & python $memoryValidatorPath --repo-root $ProjectRoot --json 2>&1 | Out-String
    try {
        $memoryReport = $memoryRaw | ConvertFrom-Json
        if ([int]$memoryReport.summary.findings -eq 0) {
            Add-Check "AWI Memory OS validator" "PASS" "checks=$($memoryReport.summary.checks); findings=0"
        }
        else {
            Add-Check "AWI Memory OS validator" "FAIL" "findings=$($memoryReport.summary.findings)"
            foreach ($finding in @($memoryReport.findings)) {
                Add-Finding $finding.severity "MEM-$($finding.code)" $finding.title $finding.detail "Fix harness/memory-os.json, memory-os.schema.json, or source-index references before continuing memory/RAG work."
            }
        }
    }
    catch {
        Add-Check "AWI Memory OS validator" "FAIL" $_.Exception.Message
        Add-Finding "error" "CX-MEMORY-VALIDATOR" "AWI Memory OS validator output parse failed" $_.Exception.Message "Run python harness/validate_awi_memory.py --repo-root . --json and fix its output/errors."
    }
}

$loopStatePath = Join-Path $HarnessDir "loop-state.json"
if (Test-Path $loopStatePath) {
    try {
        $loop = Get-Content -LiteralPath $loopStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ([string]::IsNullOrWhiteSpace([string]$loop.next_atomic_action)) {
            Add-Check "loop-state next action" "FAIL" "empty"
            Add-Finding "error" "CX-LOOP" "Loop next action missing" "harness/loop-state.json has no next_atomic_action." "Update loop-state.json after every tick."
        }
        else {
            Add-Check "loop-state next action" "PASS" $loop.current_slice
        }
    }
    catch {
        Add-Check "loop-state JSON" "FAIL" $_.Exception.Message
        Add-Finding "error" "CX-LOOP-JSON" "loop-state parse failed" $_.Exception.Message "Fix harness/loop-state.json."
    }
}

$complianceJson = $null
$compliancePath = Join-Path $HarnessDir "compliance-check.ps1"
if (Test-Path $compliancePath) {
    $raw = & $compliancePath -TargetPath $ProjectRoot -Mode post-bootstrap -Format json 2>&1 | Out-String
    try {
        $complianceJson = $raw | ConvertFrom-Json
        Add-Check "base compliance-check" "PASS" "findings=$($complianceJson.summary.findings)"
        foreach ($finding in @($complianceJson.findings)) {
            Add-Finding $finding.severity "BASE-$($finding.code)" $finding.title $finding.detail $finding.recommendation
        }
    }
    catch {
        Add-Check "base compliance-check" "WARN" "could not parse output"
        Add-Finding "warning" "CX-BASE" "Base compliance output not parsed" $_.Exception.Message "Run .\harness\compliance-check.ps1 -Mode post-bootstrap -Format text manually."
    }
}

$report = [pscustomobject]@{
    checked_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    project_root = $ProjectRoot
    summary = [pscustomobject]@{
        checks = $Checks.Count
        pass = @($Checks | Where-Object { $_.status -eq "PASS" }).Count
        warn = @($Checks | Where-Object { $_.status -eq "WARN" }).Count
        fail = @($Checks | Where-Object { $_.status -eq "FAIL" }).Count
        findings = $Findings.Count
    }
    checks = $Checks
    findings = $Findings
}

switch ($Format) {
    "json" {
        $report | ConvertTo-Json -Depth 8
    }
    "markdown" {
        "# CodeX Self Check"
        ""
        "- Checked at: $($report.checked_at)"
        "- Project: $ProjectRoot"
        "- Checks: $($report.summary.checks)"
        "- Findings: $($report.summary.findings)"
        ""
        "## Checks"
        "| Name | Status | Detail |"
        "|---|---|---|"
        foreach ($check in $Checks) { "| $($check.name) | $($check.status) | $($check.detail) |" }
        ""
        "## Findings"
        "| Severity | Code | Title | Detail | Recommendation |"
        "|---|---|---|---|---|"
        foreach ($finding in $Findings) { "| $($finding.severity) | $($finding.code) | $($finding.title) | $($finding.detail) | $($finding.recommendation) |" }
    }
    default {
        if (-not $Quiet) {
            Write-Host "CodeX Self Check - $ProjectRoot"
            foreach ($check in $Checks) {
                Write-Host ("[{0}] {1} - {2}" -f $check.status, $check.name, $check.detail)
            }
            if ($Findings.Count -gt 0) {
                Write-Host "Findings:"
                foreach ($finding in $Findings) {
                    Write-Host ("- [{0}] {1}: {2}" -f $finding.code, $finding.title, $finding.detail)
                    Write-Host ("  -> {0}" -f $finding.recommendation)
                }
            }
            Write-Host ("Summary: pass={0} warn={1} fail={2} findings={3}" -f $report.summary.pass, $report.summary.warn, $report.summary.fail, $report.summary.findings)
        }
    }
}

if ($Findings.Count -gt 0) { exit 1 }
exit 0