<#
.SYNOPSIS
    Raindeer 日末 Git push（双仓库 · fail-closed · 无 force）
.DESCRIPTION
    在 raindeer 根与 apps/quant_assistant 分别检查：
    - 是否有待 push 的 commit（ahead > 0）
    - staged 是否含密钥文件（.env / .env.local 等）
    - 仅当 ahead 且无密钥 staged 时执行 git push（禁止 --force）

    用户确认策略（2026-06-20）：仅在有 commit 且 ahead 时 push。

    退出码：
      0 = 全部仓库处理完成（含 skip：无 ahead）
      1 = 密钥 staged 或 push 失败（fail-closed）
#>

param(
    [string]$TargetPath = (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) "."),
    [switch]$DryRun,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path $TargetPath).Path
$HarnessDir = Join-Path $ProjectRoot "harness"
$ReportsDir = Join-Path $HarnessDir "reports"
$DateStamp = Get-Date -Format "yyyyMMdd"
$ReportPath = Join-Path $ReportsDir "daily-git-push-$DateStamp.md"

$SecretPatterns = @(
    "^\.env$",
    "^\.env\.local$",
    "^\.env\..+$",
    "credentials\.json$",
    "secrets?\.(json|yaml|yml)$"
)

function Write-Log {
    param([string]$Message)
    if (-not $Quiet) { Write-Host $Message }
}

function Test-StagedSecrets {
    param([string]$RepoPath)

    Push-Location $RepoPath
    try {
        $staged = @(git diff --cached --name-only 2>$null)
        if ($staged.Count -eq 0) { return @() }

        $hits = @()
        foreach ($file in $staged) {
            $base = Split-Path $file -Leaf
            foreach ($pat in $SecretPatterns) {
                if ($base -match $pat -or $file -match $pat) {
                    $hits += $file
                    break
                }
            }
        }
        return $hits
    }
    finally {
        Pop-Location
    }
}

function Get-RepoPushState {
    param([string]$RepoPath)

    if (-not (Test-Path $RepoPath)) {
        return [pscustomobject]@{
            path = $RepoPath
            ok = $false
            action = "skip"
            reason = "path missing"
        }
    }

    Push-Location $RepoPath
    try {
        if ((git rev-parse --is-inside-work-tree 2>$null) -ne "true") {
            return [pscustomobject]@{
                path = $RepoPath
                ok = $false
                action = "skip"
                reason = "not a git repo"
            }
        }

        $remote = git remote get-url origin 2>$null
        if ([string]::IsNullOrWhiteSpace($remote)) {
            return [pscustomobject]@{
                path = $RepoPath
                ok = $true
                action = "skip"
                reason = "no origin remote"
                branch = (git branch --show-current 2>$null)
                ahead = 0
            }
        }

        $branch = git branch --show-current 2>$null
        git fetch origin $branch 2>$null | Out-Null
        $ahead = [int](git rev-list --count "origin/$branch..HEAD" 2>$null)
        if ($LASTEXITCODE -ne 0) {
            $ahead = 0
        }

        $secretHits = Test-StagedSecrets $RepoPath
        $statusSb = (git status -sb 2>$null) -join "`n"

        if ($secretHits.Count -gt 0) {
            return [pscustomobject]@{
                path = $RepoPath
                ok = $false
                action = "blocked"
                reason = "staged secrets: $($secretHits -join ', ')"
                branch = $branch
                ahead = $ahead
                status_sb = $statusSb
                secret_hits = $secretHits
            }
        }

        if ($ahead -le 0) {
            return [pscustomobject]@{
                path = $RepoPath
                ok = $true
                action = "skip"
                reason = "no commits ahead of origin/$branch"
                branch = $branch
                ahead = $ahead
                status_sb = $statusSb
            }
        }

        return [pscustomobject]@{
            path = $RepoPath
            ok = $true
            action = "push"
            reason = "ahead=$ahead"
            branch = $branch
            ahead = $ahead
            status_sb = $statusSb
            remote = $remote
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-RepoPush {
    param(
        [pscustomobject]$State
    )

    if ($State.action -ne "push") {
        return $State
    }

    if ($DryRun) {
        $State | Add-Member -NotePropertyName push_result -NotePropertyValue "dry-run: would git push" -Force
        return $State
    }

    Push-Location $State.path
    try {
        $output = git push origin $State.branch 2>&1 | Out-String
        $exit = $LASTEXITCODE
        $State | Add-Member -NotePropertyName push_exit -NotePropertyValue $exit -Force
        $State | Add-Member -NotePropertyName push_output -NotePropertyValue $output.Trim() -Force
        if ($exit -ne 0) {
            $State.ok = $false
            $State.action = "push_failed"
            $State.reason = "git push exit $exit"
        }
        else {
            $State.action = "pushed"
        }
        return $State
    }
    finally {
        Pop-Location
    }
}

if (-not (Test-Path $ReportsDir)) {
    New-Item -ItemType Directory -Path $ReportsDir -Force | Out-Null
}

$repos = @(
    $ProjectRoot,
    (Join-Path $ProjectRoot "apps/quant_assistant")
)

$results = @()
$fatal = $false

foreach ($repo in $repos) {
    $state = Get-RepoPushState $repo
    if ($state.action -eq "blocked") {
        $fatal = $true
        $results += $state
        continue
    }
    if ($state.action -eq "push") {
        $state = Invoke-RepoPush $state
        if (-not $state.ok) { $fatal = $true }
    }
    $results += $state
}

$checkedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$rows = ($results | ForEach-Object {
    "| ``$($_.path)`` | $($_.branch) | $($_.ahead) | $($_.action) | $($_.reason) |"
}) -join "`n"

$detailBlocks = ($results | ForEach-Object {
    @"

### $($_.path)

- action: **$($_.action)**
- branch: $($_.branch) · ahead: $($_.ahead)
- reason: $($_.reason)
``````text
$($_.status_sb)
``````
$(if ($_.push_output) { "**push output:**`n``````text`n$($_.push_output)`n``````" })
"@
}) -join "`n"

$report = @"
# Daily Git Push Report · $DateStamp

- **Checked at**: $checkedAt
- **Dry run**: $DryRun
- **Schedule task id**: ``daily-git-push`` (cron ``30 20 * * *`` · after ``daily-compliance``)
- **Policy**: push only when ahead > 0 · no force · fail-closed on staged secrets

## Summary

| Repo | Branch | Ahead | Action | Reason |
|------|--------|-------|--------|--------|
$rows

## Details
$detailBlocks

## Fail-closed rules

- Block push if staged files match: ``.env`` · ``.env.local`` · ``credentials.json`` · ``secrets.*``
- Never use ``git push --force``
- Skip when no commits ahead of ``origin/<branch>``
"@

Set-Content -Path $ReportPath -Value $report -Encoding UTF8
Write-Log "Report written: $ReportPath"

if ($fatal) {
    Write-Log "daily-git-push FAILED (secrets staged or push error). See $ReportPath"
    exit 1
}

Write-Log "daily-git-push completed."
exit 0
