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
    if ($workerRows -ge 21) {
        Add-Check "employee roster workers" "PASS" "workers=$workerRows"
    }
    else {
        Add-Check "employee roster workers" "FAIL" "workers=$workerRows"
        Add-Finding "error" "CX-ROSTER" "Employee roster incomplete" "Expected at least 21 worker rows." "Refresh harness/reports/EMPLOYEE_ROSTER.md from agent registry."
    }
}

$platformText = Get-Text (Join-Path $DocsDir "PLATFORM-CODEX.md")
if ($null -ne $platformText) {
    foreach ($needle in @("automation_update", "create_thread", "send_message_to_thread", "codex-subagent-prompt", "codex-self-check")) {
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
        $expected = @("loop-tick", "daily-compliance", "daily-git-push", "codex-self-check")
        foreach ($id in $expected) {
            $entry = $auto.automations | Where-Object { $_.id -eq $id } | Select-Object -First 1
            if ($entry -and $entry.codex_id -and $entry.status -eq "ACTIVE") {
                Add-Check "automation:$id" "PASS" "codex_id=$($entry.codex_id)"
            }
            else {
                Add-Check "automation:$id" "WARN" "missing/inactive in registry"
                Add-Finding "warning" "CX-AUTO" "CodeX automation not registered" "$id is not ACTIVE in harness/codex-automation-registry.json." "Create/update the automation with codex_app.automation_update and record the returned id."
            }
        }
    }
    catch {
        Add-Check "CodeX automation registry JSON" "FAIL" $_.Exception.Message
        Add-Finding "error" "CX-AUTO-JSON" "Automation registry parse failed" $_.Exception.Message "Fix harness/codex-automation-registry.json."
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
            Write-Host "CodeX Self Check · $ProjectRoot"
            foreach ($check in $Checks) {
                Write-Host ("[{0}] {1} — {2}" -f $check.status, $check.name, $check.detail)
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
