<#
.SYNOPSIS
    Raindeer-AWI daily ops wrapper.
.DESCRIPTION
    Runs the daily CodeX self-check/compliance/lifecycle wrapper and the
    upstream-aware daily git push wrapper from one scheduled worker surface.

    This script does not read .env files and does not change loop-state
    next_atomic_action. The daily git push step keeps its own fail-closed
    main-only, upstream, no-force, and staged-secret checks.
#>

param(
    [string]$TargetPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "."),
    [switch]$DryRunPush,
    [switch]$SkipGitPush,
    [switch]$SkipLifecycles,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path $TargetPath).Path
$HarnessDir = Join-Path $ProjectRoot "harness"
$ReportsDir = Join-Path $HarnessDir "reports"
$DateStamp = Get-Date -Format "yyyyMMdd"
$ReportPath = Join-Path $ReportsDir "daily-ops-$DateStamp.md"

function Write-Log {
    param([string]$Message)
    if (-not $Quiet) { Write-Host $Message }
}

function Invoke-DailyStep {
    param(
        [string]$Label,
        [string]$ScriptPath,
        [hashtable]$Parameters
    )

    if (-not (Test-Path $ScriptPath)) {
        return [pscustomobject]@{
            label = $Label
            exit_code = 99
            output = "missing: $ScriptPath"
        }
    }

    $output = & $ScriptPath @Parameters 2>&1 | Out-String
    return [pscustomobject]@{
        label = $Label
        exit_code = $LASTEXITCODE
        output = $output.Trim()
    }
}

if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

Write-Log "Daily ops wrapper · root=$ProjectRoot"

$complianceScript = Join-Path $HarnessDir "scripts/daily-compliance.ps1"
$gitPushScript = Join-Path $HarnessDir "scripts/daily-git-push.ps1"

$complianceArgs = @{ TargetPath = $ProjectRoot }
if ($SkipLifecycles) { $complianceArgs.SkipLifecycles = $true }
if ($Quiet) { $complianceArgs.Quiet = $true }

$compliance = Invoke-DailyStep "daily-compliance" $complianceScript $complianceArgs

$gitPush = [pscustomobject]@{
    label = "daily-git-push"
    exit_code = 0
    output = "skipped by -SkipGitPush"
}

if (-not $SkipGitPush) {
    $gitArgs = @{ TargetPath = $ProjectRoot }
    if ($DryRunPush) { $gitArgs.DryRun = $true }
    if ($Quiet) { $gitArgs.Quiet = $true }
    $gitPush = Invoke-DailyStep "daily-git-push" $gitPushScript $gitArgs
}

$checkedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$complianceReport = Join-Path $ReportsDir "daily-compliance-$DateStamp.md"
$gitReport = Join-Path $ReportsDir "daily-git-push-$DateStamp.md"
$status = if ($compliance.exit_code -eq 0 -and $gitPush.exit_code -eq 0) { "success" } else { "blocked" }

$report = @"
# Daily Ops Report · $DateStamp

- **Checked at**: $checkedAt
- **Worker**: ``daily-ops``
- **Status**: **$status**
- **Project root**: $ProjectRoot
- **DryRunPush**: $DryRunPush
- **SkipGitPush**: $SkipGitPush
- **SkipLifecycles**: $SkipLifecycles

## Step Summary

| Step | Exit | Report |
|------|------|--------|
| daily-compliance | $($compliance.exit_code) | ``$complianceReport`` |
| daily-git-push | $($gitPush.exit_code) | ``$gitReport`` |

## daily-compliance output

``````text
$($compliance.output)
``````

## daily-git-push output

``````text
$($gitPush.output)
``````

## Contract

- One CodeX daily worker surface owns CodeX self-check, daily compliance, five lifecycles, dual-repo git status, and daily git push reporting.
- ``codex-self-check`` is not scheduled separately because ``daily-compliance.ps1`` runs it first.
- ``daily-compliance`` and ``daily-git-push`` remain callable scripts, but CodeX scheduling should use ``awi-daily-ops`` only.
- Do not modify ``harness/loop-state.json`` ``next_atomic_action`` from daily ops.
- Do not read or print ``.env``, ``.env.local``, tokens, DSNs, or secrets.
"@

Set-Content -Path $ReportPath -Value $report -Encoding UTF8
Write-Log "Report written: $ReportPath"

if ($status -ne "success") {
    exit 1
}

exit 0
