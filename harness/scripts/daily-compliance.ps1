<#
.SYNOPSIS
    Raindeer 日末合规巡检包装脚本（机器证据 + 报告落盘）
.DESCRIPTION
    运行 CodeX self-check、compliance-check、五 lifecycle、双仓库 git 状态、gap list 摘要，
    写入 harness/reports/daily-compliance-YYYYMMDD.md

    退出码：
      0 = 报告已写入（含 compliance finding 亦视为成功落盘）
      1 = 致命错误（无法写报告）
#>

param(
    [string]$TargetPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "."),
    [switch]$SkipLifecycles,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path $TargetPath).Path
$HarnessDir = Join-Path $ProjectRoot "harness"
$ReportsDir = Join-Path $HarnessDir "reports"
$DateStamp = Get-Date -Format "yyyyMMdd"
$ReportPath = Join-Path $ReportsDir "daily-compliance-$DateStamp.md"

function Write-Log {
    param([string]$Message)
    if (-not $Quiet) { Write-Host $Message }
}

function Get-GitStatusSummary {
    param([string]$RepoPath)

    if (-not (Test-Path $RepoPath)) {
        return [pscustomobject]@{ path = $RepoPath; available = $false; summary = "path missing" }
    }

    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) {
        return [pscustomobject]@{ path = $RepoPath; available = $false; summary = "git unavailable" }
    }

    Push-Location $RepoPath
    try {
        if ((git rev-parse --is-inside-work-tree 2>$null) -ne "true") {
            return [pscustomobject]@{ path = $RepoPath; available = $false; summary = "not a git repo" }
        }

        $branch = (git branch --show-current 2>$null)
        $sb = @(git status -sb 2>$null)
        $ahead = 0
        $behind = 0
        if ($sb.Count -gt 0 -and $sb[0] -match '\[ahead (\d+)(?:, behind (\d+))?\]') {
            $ahead = [int]$Matches[1]
            if ($Matches[2]) { $behind = [int]$Matches[2] }
        }
        elseif ($sb.Count -gt 0 -and $sb[0] -match '\[behind (\d+)\]') {
            $behind = [int]$Matches[1]
        }

        $porcelain = @(git status --porcelain 2>$null)
        return [pscustomobject]@{
            path = $RepoPath
            available = $true
            branch = $branch
            ahead = $ahead
            behind = $behind
            dirty_count = $porcelain.Count
            status_sb = ($sb -join "`n")
            summary = "branch=$branch ahead=$ahead behind=$behind dirty=$($porcelain.Count)"
        }
    }
    finally {
        Pop-Location
    }
}

function Get-JsonFileSummary {
    param(
        [string]$Path,
        [string[]]$Fields = @()
    )

    if (-not (Test-Path $Path)) {
        return "missing: $Path"
    }

    try {
        $obj = Get-Content $Path -Raw -Encoding UTF8 | ConvertFrom-Json
        $parts = @()
        foreach ($field in $Fields) {
            if ($field -eq "last_lifecycle.at") {
                if ($obj.PSObject.Properties.Name -contains "last_lifecycle") {
                    $parts += "last_lifecycle.at=$($obj.last_lifecycle.at)"
                }
            }
            elseif ($obj.PSObject.Properties.Name -contains $field) {
                $parts += "$field=$($obj.$field)"
            }
        }
        if ($obj.PSObject.Properties.Name -contains "findings") {
            $warn = @($obj.findings | Where-Object { $_.severity -eq "warning" }).Count
            $err = @($obj.findings | Where-Object { $_.severity -eq "error" }).Count
            $parts += "findings_warn=$warn findings_error=$err"
        }
        return ($parts -join " · ")
    }
    catch {
        return "parse error: $($_.Exception.Message)"
    }
}

function Get-GapListSummary {
    param([string]$GapPath)

    if (-not (Test-Path $GapPath)) {
        return "missing: $GapPath"
    }

    $text = Get-Content $GapPath -Raw -Encoding UTF8
    $summary = @{}
    foreach ($key in @("blocker_count", "degraded_count", "future_count", "env_count")) {
        if ($text -match "${key}:\s*(\d+)") {
            $summary[$key] = [int]$Matches[1]
        }
    }
    if ($summary.Count -eq 0) {
        return "no summary counts parsed"
    }
    return ($summary.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join " · "
}

function Invoke-Lifecycle {
    param(
        [string]$ScriptRel,
        [string]$Label
    )

    $scriptPath = Join-Path $ProjectRoot $ScriptRel
    if (-not (Test-Path $scriptPath)) {
        return [pscustomobject]@{ label = $Label; exit_code = 99; output = "missing $ScriptRel" }
    }

    $output = & python $scriptPath run --apply 2>&1 | Out-String
    return [pscustomobject]@{
        label = $Label
        exit_code = $LASTEXITCODE
        output = $output.Trim()
    }
}

if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

Write-Log "Daily compliance wrapper · root=$ProjectRoot"

$complianceScript = Join-Path $HarnessDir "compliance-check.ps1"
$codexSelfCheckScript = Join-Path $HarnessDir "scripts/codex-self-check.ps1"
$codexSelfCheckMd = ""
$codexSelfCheckExit = 0
if (Test-Path $codexSelfCheckScript) {
    $codexSelfCheckMd = & $codexSelfCheckScript -TargetPath $ProjectRoot -Format markdown 2>&1 | Out-String
    $codexSelfCheckExit = $LASTEXITCODE
}
else {
    $codexSelfCheckMd = "codex-self-check.ps1 missing"
    $codexSelfCheckExit = 99
}

$complianceMd = ""
$complianceExit = 0
if (Test-Path $complianceScript) {
    $complianceMd = & $complianceScript -TargetPath $ProjectRoot -Mode baseline -Format markdown 2>&1 | Out-String
    $complianceExit = $LASTEXITCODE
}
else {
    $complianceMd = "compliance-check.ps1 missing"
    $complianceExit = 99
}

$loopStatus = ""
$loopTick = Join-Path $HarnessDir "loop_tick.py"
if (Test-Path $loopTick) {
    $loopStatus = & python $loopTick status 2>&1 | Out-String
}

$lifecycleResults = @()
if (-not $SkipLifecycles) {
    $lifecycleResults += Invoke-Lifecycle "harness/methodology_memory_lifecycle.py" "methodology_memory"
    $lifecycleResults += Invoke-Lifecycle "harness/work_report_lifecycle.py" "work_report"
    $lifecycleResults += Invoke-Lifecycle "harness/sync_coherence_lifecycle.py" "sync_coherence"
    $lifecycleResults += Invoke-Lifecycle "harness/verification_snapshot_lifecycle.py" "verification_snapshot"
    $lifecycleResults += Invoke-Lifecycle "harness/closure_gate_lifecycle.py" "closure_gate"
}

$syncSummary = Get-JsonFileSummary (Join-Path $HarnessDir "sync-coherence-index.json") @("last_lifecycle.at")
$verSummary = Get-JsonFileSummary (Join-Path $HarnessDir "verification-snapshot-index.json") @("last_lifecycle.at")
$cloSummary = Get-JsonFileSummary (Join-Path $HarnessDir "closure-gate-index.json") @("open_count", "last_lifecycle.at")
$memSummary = Get-JsonFileSummary (Join-Path $HarnessDir "methodology-memory-index.json") @("last_lifecycle.at")
$wrSummary = Get-JsonFileSummary (Join-Path $HarnessDir "work-reports-index.json") @("last_lifecycle.at")

$gitRoot = Get-GitStatusSummary $ProjectRoot
$qaRoot = Get-GitStatusSummary (Join-Path $ProjectRoot "apps/quant_assistant")

$gapPath = Join-Path $ProjectRoot "apps/quant_assistant/docs/ENGINEERING/TREE-2-gap-list.yaml"
$gapSummary = Get-GapListSummary $gapPath

$checkedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$lifecycleTable = ($lifecycleResults | ForEach-Object {
    "| $($_.label) | $($_.exit_code) | $(if ($_.output.Length -gt 120) { $_.output.Substring(0, 120) + '…' } else { $_.output }) |"
}) -join "`n"

$report = @"
# Daily Compliance Report · $DateStamp

- **Checked at**: $checkedAt
- **Project root**: $ProjectRoot
- **codex-self-check exit**: $codexSelfCheckExit
- **compliance-check exit**: $complianceExit
- **Schedule task id**: ``daily-ops`` calls ``daily-compliance`` (not separately scheduled)

## CodeX self-check

$codexSelfCheckMd

## compliance-check

$complianceMd

## loop_tick status

``````text
$($loopStatus.Trim())
``````

## Five lifecycles (run --apply)

| Lifecycle | Exit | Output (truncated) |
|-----------|------|-------------------|
$lifecycleTable

## Index summaries

| Index | Summary |
|-------|---------|
| methodology-memory-index | $memSummary |
| work-reports-index | $wrSummary |
| sync-coherence-index | $syncSummary |
| verification-snapshot-index | $verSummary |
| closure-gate-index | $cloSummary |

## Git status (dual repos)

### Raindeer root

- $($gitRoot.summary)
- status -sb:
``````text
$($gitRoot.status_sb)
``````

### quant_assistant

- $($qaRoot.summary)
- status -sb:
``````text
$($qaRoot.status_sb)
``````

## TREE-2 gap list

- Path: ``apps/quant_assistant/docs/ENGINEERING/TREE-2-gap-list.yaml``
- Summary: **$gapSummary**

## Notes

- ``sync_coherence_lifecycle`` validates prose drift read-only even with ``--apply``.
- Full agent audit prompt: ``harness/templates/daily-compliance-prompt.md``
- Daily scheduler: ``daily-ops`` calls ``daily-git-push`` after this wrapper succeeds
"@

Set-Content -Path $ReportPath -Value $report -Encoding UTF8
Write-Log "Report written: $ReportPath"

if ($complianceExit -ne 0) {
    Write-Log "compliance-check reported findings (exit $complianceExit) — report still written."
}

exit 0
