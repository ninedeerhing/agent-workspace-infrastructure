<#
.SYNOPSIS
    Raindeer 日末 Git push（双仓库 · upstream 感知 · fail-closed · 无 force）
.DESCRIPTION
    双仓库模型（用户确认 2026-06-21）：

    1. Raindeer 根（AWI 架构）
       - GitHub: agent-workspace-infrastructure
       - 仅 AWI Harness / 治理 / 架构；不含 quant_assistant 业务发布
       - 推送到 **upstream 跟踪分支**（常见 origin/raindeer-AWI），
         而非盲目 origin/main

    2. apps/quant_assistant（Quant Assistant 产品）
       - GitHub: raindeer-quant-assistant（独立仓库）
       - 推送到其自身 upstream（常见 origin/main）

    每个仓库：
    - ahead 用 ``git rev-list --count '@{u}..HEAD'``（需已设置 upstream）
    - staged 含密钥文件 → blocked（fail-closed）
    - 仅 ahead > 0 且无密钥 staged 时 ``git push <remote> HEAD:<upstream-branch>``
    - **禁止** ``--force`` / ``--force-with-lease``

    退出码：
      0 = 全部仓库处理完成（含 skip：无 ahead / 无 upstream）
      1 = 非 main 分支 · 密钥 staged 或 push 失败（fail-closed）
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

$RepoDefinitions = @(
    [pscustomobject]@{
        path = $ProjectRoot
        label = "Raindeer-AWI"
        github_repo = "agent-workspace-infrastructure"
        scope = "AWI architecture / Harness / governance only"
    },
    [pscustomobject]@{
        path = (Join-Path $ProjectRoot "apps/quant_assistant")
        label = "Quant Assistant"
        github_repo = "raindeer-quant-assistant"
        scope = "Separate product repo; not part of AWI publish"
    }
)

function Write-Log {
    param([string]$Message)
    if (-not $Quiet) { Write-Host $Message }
}

function Get-UpstreamPushTarget {
    param([string]$RepoPath)

    Push-Location $RepoPath
    try {
        $upstreamFull = git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($upstreamFull)) {
            return $null
        }

        $slash = $upstreamFull.IndexOf('/')
        if ($slash -lt 1) {
            return $null
        }

        $remoteName = $upstreamFull.Substring(0, $slash)
        $upstreamBranch = $upstreamFull.Substring($slash + 1)
        if ([string]::IsNullOrWhiteSpace($remoteName) -or [string]::IsNullOrWhiteSpace($upstreamBranch)) {
            return $null
        }

        return [pscustomobject]@{
            upstream_full = $upstreamFull
            remote_name = $remoteName
            upstream_branch = $upstreamBranch
            push_ref = "${remoteName}:HEAD:${upstreamBranch}"
        }
    }
    finally {
        Pop-Location
    }
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
    param(
        [pscustomobject]$RepoDef
    )

    $RepoPath = $RepoDef.path

    if (-not (Test-Path $RepoPath)) {
        return [pscustomobject]@{
            path = $RepoPath
            label = $RepoDef.label
            github_repo = $RepoDef.github_repo
            scope = $RepoDef.scope
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
                label = $RepoDef.label
                github_repo = $RepoDef.github_repo
                scope = $RepoDef.scope
                ok = $false
                action = "skip"
                reason = "not a git repo"
            }
        }

        $remote = git remote get-url origin 2>$null
        if ([string]::IsNullOrWhiteSpace($remote)) {
            return [pscustomobject]@{
                path = $RepoPath
                label = $RepoDef.label
                github_repo = $RepoDef.github_repo
                scope = $RepoDef.scope
                ok = $true
                action = "skip"
                reason = "no origin remote"
                branch = (git branch --show-current 2>$null)
                ahead = 0
            }
        }

        $branch = git branch --show-current 2>$null
        $statusSbEarly = (git status -sb 2>$null) -join "`n"

        if ($branch -ne "main") {
            return [pscustomobject]@{
                path = $RepoPath
                label = $RepoDef.label
                github_repo = $RepoDef.github_repo
                scope = $RepoDef.scope
                ok = $false
                action = "blocked"
                reason = "policy: main-only development; merge/delete branch $branch and checkout main"
                branch = $branch
                ahead = 0
                remote = $remote
                status_sb = $statusSbEarly
            }
        }

        $upstream = Get-UpstreamPushTarget $RepoPath
        if ($null -eq $upstream) {
            return [pscustomobject]@{
                path = $RepoPath
                label = $RepoDef.label
                github_repo = $RepoDef.github_repo
                scope = $RepoDef.scope
                ok = $true
                action = "skip"
                reason = "no upstream tracking branch (set with git push -u)"
                branch = $branch
                ahead = 0
                remote = $remote
                status_sb = ((git status -sb 2>$null) -join "`n")
            }
        }

        $prevEap = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        git fetch $upstream.remote_name $upstream.upstream_branch 2>&1 | Out-Null
        $ErrorActionPreference = $prevEap
        $aheadRaw = git rev-list --count "$($upstream.upstream_full)..HEAD" 2>$null
        $ahead = 0
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($aheadRaw)) {
            $ahead = [int]$aheadRaw
        }

        $secretHits = Test-StagedSecrets $RepoPath
        $statusSb = (git status -sb 2>$null) -join "`n"

        if ($secretHits.Count -gt 0) {
            return [pscustomobject]@{
                path = $RepoPath
                label = $RepoDef.label
                github_repo = $RepoDef.github_repo
                scope = $RepoDef.scope
                ok = $false
                action = "blocked"
                reason = "staged secrets: $($secretHits -join ', ')"
                branch = $branch
                upstream = $upstream.upstream_full
                upstream_branch = $upstream.upstream_branch
                push_target = "git push $($upstream.remote_name) HEAD:$($upstream.upstream_branch)"
                ahead = $ahead
                status_sb = $statusSb
                secret_hits = $secretHits
                remote = $remote
            }
        }

        if ($ahead -le 0) {
            return [pscustomobject]@{
                path = $RepoPath
                label = $RepoDef.label
                github_repo = $RepoDef.github_repo
                scope = $RepoDef.scope
                ok = $true
                action = "skip"
                reason = "no commits ahead of $($upstream.upstream_full)"
                branch = $branch
                upstream = $upstream.upstream_full
                upstream_branch = $upstream.upstream_branch
                push_target = "git push $($upstream.remote_name) HEAD:$($upstream.upstream_branch)"
                ahead = $ahead
                status_sb = $statusSb
                remote = $remote
            }
        }

        return [pscustomobject]@{
            path = $RepoPath
            label = $RepoDef.label
            github_repo = $RepoDef.github_repo
            scope = $RepoDef.scope
            ok = $true
            action = "push"
            reason = "ahead=$ahead"
            branch = $branch
            upstream = $upstream.upstream_full
            upstream_branch = $upstream.upstream_branch
            push_target = "git push $($upstream.remote_name) HEAD:$($upstream.upstream_branch)"
            remote_name = $upstream.remote_name
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

    $pushCmd = "git push $($State.remote_name) HEAD:$($State.upstream_branch)"

    if ($DryRun) {
        $State | Add-Member -NotePropertyName push_result -NotePropertyValue "dry-run: would $pushCmd" -Force
        return $State
    }

    Push-Location $State.path
    try {
        $output = git push $State.remote_name "HEAD:$($State.upstream_branch)" 2>&1 | Out-String
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

$results = @()
$fatal = $false

foreach ($repoDef in $RepoDefinitions) {
    $state = Get-RepoPushState $repoDef
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
    "| ``$($_.label)`` | ``$($_.github_repo)`` | $($_.branch) | $($_.upstream) | $($_.ahead) | $($_.action) | $($_.reason) |"
}) -join "`n"

$detailBlocks = ($results | ForEach-Object {
    @"

### $($_.label) - ``$($_.github_repo)``

- scope: $($_.scope)
- path: ``$($_.path)``
- action: **$($_.action)**
- local branch: $($_.branch) | upstream: $($_.upstream) | ahead: $($_.ahead)
- push target: ``$($_.push_target)``
- reason: $($_.reason)
``````text
$($_.status_sb)
``````
$(if ($_.push_result) { "**dry-run:** $($_.push_result)" })
$(if ($_.push_output) { "**push output:**`n``````text`n$($_.push_output)`n``````" })
"@
}) -join "`n"

$report = @"
# Daily Git Push Report - $DateStamp

- **Checked at**: $checkedAt
- **Dry run**: $DryRun
- **Schedule task id**: ``daily-ops`` calls ``daily-git-push`` after ``daily-compliance``
- **Policy**: main-only local branch | dual-repo | upstream-aware ahead count | push only when ahead > 0 | no force | fail-closed on non-main / staged secrets

## Dual-repo model

| Label | GitHub repo | Scope |
|-------|-------------|-------|
| Raindeer-AWI | ``agent-workspace-infrastructure`` | AWI architecture only |
| Quant Assistant | ``raindeer-quant-assistant`` | Separate product repo |

## Summary

| Repo | GitHub | Local branch | Upstream | Ahead | Action | Reason |
|------|--------|--------------|----------|-------|--------|--------|
$rows

## Details
$detailBlocks

## Fail-closed rules

- Block if local branch is not ``main`` (policy: main-only development; merge/delete branch and checkout main)
- Block push if staged files match: ``.env`` | ``.env.local`` | ``credentials.json`` | ``secrets.*``
- Never use ``git push --force`` or ``--force-with-lease``
- Skip when no upstream tracking branch or no commits ahead of upstream
- AWI root must **not** assume ``origin/main`` when upstream is ``origin/raindeer-AWI``
- Do **not** auto-delete user branches; blocked exit 1 surfaces in Automation
"@

$normalizedReport = $report -replace "`r`n", "`n"
$normalizedReport = $normalizedReport -replace "`r", "`n"
$normalizedReport = (($normalizedReport -split "`n") | ForEach-Object { $_ -replace '\s+$', '' }) -join "`n"
if (-not $normalizedReport.EndsWith("`n")) {
    $normalizedReport += "`n"
}
[System.IO.File]::WriteAllText($ReportPath, $normalizedReport, [System.Text.UTF8Encoding]::new($false))
Write-Log "Report written: $ReportPath"

if ($fatal) {
    Write-Log "daily-git-push FAILED (non-main branch, secrets staged, or push error). See $ReportPath"
    exit 1
}

Write-Log "daily-git-push completed."
exit 0
