<#
.SYNOPSIS
    AWI 导入脚本 — 支持新项目初始化、已有项目最小导入、已有项目完整导入
.DESCRIPTION
    三种模式：
      audit   — 只评估兼容性，不修改任何文件
      minimum — 只添加状态管理层（harness/ + .omx/ + 核心配置），不覆盖任何现有文件
      full    — 完整部署所有文件（代理+技能+文档+规则+缓存+前端架构），-Force 覆盖冲突

.PARAMETER TargetPath
    目标项目路径（默认：当前目录）
.PARAMETER ProjectName
    项目名称（默认：从目录名推断）
.PARAMETER SourcePath
    AWI 框架源目录（默认：脚本自身所在目录）
.PARAMETER Mode
    导入模式：audit / minimum / full（默认：auto — 空目录用full，已有项目用minimum）
.PARAMETER Force
    强制覆盖冲突文件（仅 full 模式有效）
.EXAMPLE
    .\bootstrap.ps1 -TargetPath "D:\new-project" -ProjectName "MyApp"
    自动检测：新项目=full，已有项目=minimum

.EXAMPLE
    .\bootstrap.ps1 -TargetPath "D:\existing-project" -Mode audit
    只审计，不修改

.EXAMPLE
    .\bootstrap.ps1 -TargetPath "D:\existing-project" -Mode minimum
    已有项目最小导入：只添加状态管理

.EXAMPLE
    .\bootstrap.ps1 -TargetPath "D:\existing-project" -Mode full -Force
    已有项目完整导入，覆盖冲突文件
#>

param(
    [string]$TargetPath = (Get-Location).Path,
    [string]$ProjectName = (Split-Path $TargetPath -Leaf),
    [string]$SourcePath = $PSScriptRoot,
    [ValidateSet("auto","audit","minimum","full")]
    [string]$Mode = "auto",
    [switch]$Force
)

$ErrorActionPreference = "Continue"

# ═══════════════════════════════════════════════════════════════
# Source validation
# ═══════════════════════════════════════════════════════════════
if (-not (Test-Path (Join-Path $SourcePath "CONSTITUTION.md"))) {
    Write-Host "[ERROR] CONSTITUTION.md not found in source. Run this script from AWI root." -ForegroundColor Red
    exit 1
}

# ═══════════════════════════════════════════════════════════════
# Auto-detect mode
# ═══════════════════════════════════════════════════════════════
if ($Mode -eq "auto") {
    $existingItems = Get-ChildItem -Path $TargetPath -Exclude ".git","node_modules","__pycache__" -EA SilentlyContinue
    if ($null -eq $existingItems -or $existingItems.Count -eq 0) {
        $Mode = "full"
    } else {
        # Run audit to check compatibility
        $auditScript = Join-Path $SourcePath "harness\audit.ps1"
        Write-Host ""
        Write-Host "Auto-detected existing project. Running compatibility audit..." -ForegroundColor Cyan
        if (Test-Path $auditScript) {
            & $auditScript -TargetPath $TargetPath -ProjectName $ProjectName -SourcePath $SourcePath
        }
        Write-Host ""
        Write-Host "Auto-selected mode: minimum (safe for existing projects)" -ForegroundColor Cyan
        Write-Host "Use -Mode full -Force to install all agents/skills/docs/rules." -ForegroundColor Gray
        $Mode = "minimum"
    }
}

# ═══════════════════════════════════════════════════════════════
# Banner
# ═══════════════════════════════════════════════════════════════
$Banner = @"

  ╔══════════════════════════════════════════════════════╗
  ║   AWI v1.0.0-raindeer — Mode: $($Mode.ToUpper().PadRight(23)) ║
  ║   AI Engineering Workspace Infrastructure            ║
  ╚══════════════════════════════════════════════════════╝

"@
Write-Host $Banner -ForegroundColor Cyan

Write-Host "Project:   $ProjectName" -ForegroundColor White
Write-Host "Target:    $TargetPath" -ForegroundColor Gray
Write-Host "Mode:      $Mode" -ForegroundColor $(if ($Mode -eq "audit") { "Yellow" } elseif ($Mode -eq "minimum") { "Cyan" } else { "Green" })

# ═══════════════════════════════════════════════════════════════
# MODE: audit — delegate to harness/audit.ps1, exit
# ═══════════════════════════════════════════════════════════════
if ($Mode -eq "audit") {
    $auditScript = Join-Path $SourcePath "harness\audit.ps1"
    if (Test-Path $auditScript) {
        & $auditScript -TargetPath $TargetPath -ProjectName $ProjectName -SourcePath $SourcePath
    } else {
        Write-Host "[ERROR] harness/audit.ps1 not found" -ForegroundColor Red
        exit 1
    }
    exit 0
}

# ═══════════════════════════════════════════════════════════════
# PS version check
# ═══════════════════════════════════════════════════════════════
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "[ERROR] PowerShell 5.0+ required. Current: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] PS $($PSVersionTable.PSVersion)" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# Ensure target directory exists
# ═══════════════════════════════════════════════════════════════
if (-not (Test-Path $TargetPath)) {
    New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
    Write-Host "[OK] Target directory created" -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════════
# Common: create directory structure (both minimum and full)
# ═══════════════════════════════════════════════════════════════
$MinimumDirs = @(
    "harness/archive",
    ".omx/plans"
)

$FullDirs = @(
    "agents",
    "skills",
    "docs/adr",
    "cache/scripts",
    "rules/common"
)

$dirs = $MinimumDirs
if ($Mode -eq "full") {
    $dirs += $FullDirs
}

foreach ($dir in $dirs) {
    $fullPath = Join-Path $TargetPath $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    }
}
Write-Host "[OK] Directories created ($($dirs.Count))" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# Minimum mode files (always safe — never overwrite existing)
# ═══════════════════════════════════════════════════════════════
$MinimumFiles = @(
    "harness/init.ps1",
    "harness/audit.ps1",
    "harness/schedule.ps1",
    "harness/schedule.json",
    "harness/workflow-gates.md",
    "harness/workflow-state.json",
    "harness/grader-types.md",
    "harness/clean-state-checklist.md",
    "harness/ci-cd-template.yml",
    "harness/archive/store.ps1",
    "harness/archive/index.json",
    ".omx/memory.md",
    ".omx/memory-index.md",
    ".omx/memory-search.ps1",
    "CONSTITUTION.md",
    "SECURITY-ZONES.md",
    "SECURITY.md",
    "SOUL.md",
    "AGENTS.md",
    "AGENTS-lite.md",
    "RULES.md",
    "docs/scaling-guide.md",
    "docs/project-init-checklist.md",
    "docs/context-preload.md",
    "docs/personal-growth-framework.md",
    "docs/frontend-architecture.md",
    "docs/task-queue.md",
    "docs/inter-agent-comm.md",
    "docs/TASK_TREES.md",
    "docs/FLOW-MODE.md",
    "docs/PROJECT_STATUS.md",
    "docs/CONTINUATION_PROMPT.md",
    "docs/ENGINEERING/HARNESS_CHANGE_TEMPLATE.md",
    "docs/ENGINEERING/HARNESS_REVIEW_CHECKLIST.md",
    "docs/ENGINEERING/DIRTY_WORKTREE_CLEANUP_LEDGER.md",
    "harness/sandbox.ps1",
    "bootstrap.ps1"
)

$FullFiles = @(
    @{ SrcDir = "agents"; Exclude = $null; Recursive = $false },
    @{ SrcDir = "skills"; Exclude = $null; Recursive = $true },
    @{ SrcDir = "docs/adr"; Exclude = $null; Recursive = $false },
    @{ SrcDir = "cache"; Exclude = $null; Recursive = $true },
    @{ SrcDir = "rules/common"; Exclude = $null; Recursive = $false },
    @{ SrcDir = "design-architecture"; Exclude = $null; Recursive = $true },
    @{ SrcDir = ".omx/plans"; Exclude = $null; Recursive = $false }
)

# Copy minimum files
$added = 0
$skipped = 0
$overwritten = 0

foreach ($f in $MinimumFiles) {
    $src = Join-Path $SourcePath $f
    $dst = Join-Path $TargetPath $f

    if (-not (Test-Path $src)) { continue }

    if (Test-Path $dst) {
        $srcHash = (Get-FileHash $src -Algorithm MD5).Hash
        $dstHash = (Get-FileHash $dst -Algorithm MD5).Hash
        if ($srcHash -eq $dstHash) {
            $skipped++
            continue
        }
        if ($Mode -eq "minimum") {
            $skipped++
            continue
        }
        if ($Mode -eq "full" -and -not $Force) {
            $skipped++
            continue
        }
        $overwritten++
    }

    $parent = Split-Path $dst -Parent
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Copy-Item -Path $src -Destination $dst -Force
    $added++
}

Write-Host "[OK] Core files: $added added, $skipped skipped, $overwritten overwritten" -ForegroundColor Green

# Copy full-mode files
if ($Mode -eq "full") {
    foreach ($item in $FullFiles) {
        $srcDir = Join-Path $SourcePath $item.SrcDir
        if (-not (Test-Path $srcDir)) { continue }

        $dstDir = Join-Path $TargetPath $item.SrcDir
        if (-not (Test-Path $dstDir)) {
            New-Item -ItemType Directory -Path $dstDir -Force | Out-Null
        }

        $files = Get-ChildItem -Path $srcDir
        foreach ($fi in $files) {
            $dst = Join-Path $dstDir $fi.Name
            if (Test-Path $dst -and -not $Force) { continue }
            Copy-Item -Path $fi.FullName -Destination $dst -Recurse -Force
        }
    }
    Write-Host "[OK] Full-mode files deployed" -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════════
# Initialize/update harness state files (never overwrite if they exist)
# ═══════════════════════════════════════════════════════════════
$harnessDir = Join-Path $TargetPath "harness"

$stateFiles = @{
    "feature_list.json" = @"
{
  "features": [],
  "current_feature": null,
  "last_updated": "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')",
  "project": "$ProjectName"
}
"@
    "progress.md" = @"
# $ProjectName — Progress Log

## Session History

### $(Get-Date -Format 'yyyy-MM-dd') — AWI Import

- Imported AWI v1.0.0 via bootstrap.ps1 (mode: $Mode)
- Framework ready for AI-agent-driven development

## Next Steps

Run `harness/init.ps1` to verify infrastructure.
"@
    "session-handoff.md" = @"
# $ProjectName — Session Handoff

## Current State

- Stage: initialized (AWI imported)
- Active feature: none
- Blockers: none

## Next Tasks

1. Tell your AI agent: "Load workspace, tell me current status"
2. Start your first feature module

## Notes

- Framework deployed, CONSTITUTION.md is highest priority
- 46 skills available, invoke with `\$skill-name`
- Agent roles in agents/ directory
"@
    "workflow-state.json" = @"
{
  "project": "$ProjectName",
  "current_stage": "init",
  "current_workflow": "standard",
  "active_feature": null,
  "stage_gates_passed": [],
  "next_stage": "ready",
  "last_updated": "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')",
  "blockers": []
}
"@
}

foreach ($key in $stateFiles.Keys) {
    $path = Join-Path $harnessDir $key
    if (Test-Path $path) {
        Write-Host "  [skip] $key already exists, preserved" -ForegroundColor DarkGray
    } else {
        Set-Content -Path $path -Value $stateFiles[$key] -Encoding UTF8
        Write-Host "  [init] $key created" -ForegroundColor DarkGray
    }
}
Write-Host "[OK] State files initialized (preserving existing)" -ForegroundColor Green

# ═══════════════════════════════════════════════════════════════
# .gitignore — merge, never overwrite
# ═══════════════════════════════════════════════════════════════
$gitignorePath = Join-Path $TargetPath ".gitignore"
$awiGitignore = @"
node_modules/
.env
*.log
.omx/project-memory.json
.omx/memory-index.json
harness/health-log.json
harness/task-queue.json
"@

if (Test-Path $gitignorePath) {
    $existing = Get-Content $gitignorePath -Raw
    if ($existing -notmatch "\.omx/project-memory") {
        Add-Content -Path $gitignorePath -Value "`r`n$awiGitignore"
        Write-Host "[OK] .gitignore augmented (existing preserved)" -ForegroundColor Green
    } else {
        Write-Host "[skip] .gitignore already has AWI entries" -ForegroundColor DarkGray
    }
} else {
    Set-Content -Path $gitignorePath -Value $awiGitignore -Encoding UTF8
    Write-Host "[OK] .gitignore created" -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════════
# Run verification
# ═══════════════════════════════════════════════════════════════
$initScript = Join-Path $harnessDir "init.ps1"
if (Test-Path $initScript) {
    Write-Host ""
    Write-Host "=== Running infrastructure verification ===" -ForegroundColor Yellow
    try {
        Push-Location $TargetPath
        & $initScript -Quiet
        Pop-Location
    } catch {
        Write-Host "[WARN] Verification encountered non-fatal issue, continuing..." -ForegroundColor Yellow
    }
}

# ═══════════════════════════════════════════════════════════════
# Success output
# ═══════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   Import complete! AWI is ready.                    ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Project:  $ProjectName" -ForegroundColor Cyan
Write-Host "Path:     $TargetPath" -ForegroundColor Cyan
Write-Host "Mode:     $Mode" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next:" -ForegroundColor Yellow
Write-Host "  1. Open your AI coding tool in this directory" -ForegroundColor White
Write-Host '  2. Tell the agent: "Load workspace, tell me current status"' -ForegroundColor White

if ($Mode -eq "minimum") {
    Write-Host ""
    Write-Host "  Minimum mode note:" -ForegroundColor DarkGray
    Write-Host "  - Your existing code and config files are NOT modified" -ForegroundColor DarkGray
    Write-Host "  - agents/ and skills/ were NOT installed (use -Mode full for that)" -ForegroundColor DarkGray
    Write-Host "  - The agent can still read agents/skills from the AWI source directory" -ForegroundColor DarkGray
}

Write-Host ""
