<#
.SYNOPSIS
    AWI 一键初始化脚本
.DESCRIPTION
    将 AWI 框架部署到目标项目目录。
    自动创建所有必要的目录、复制核心文件、初始化状态文件。
.PARAMETER TargetPath
    目标项目路径（默认：当前目录）
.PARAMETER ProjectName
    项目名称（默认：从目录名推断）
.PARAMETER SourcePath
    框架源目录（默认：脚本自身所在目录）
.EXAMPLE
    .\bootstrap.ps1 -TargetPath "D:\my-new-project" -ProjectName "MyProject"
#>

param(
    [string]$TargetPath = (Get-Location).Path,
    [string]$ProjectName = (Split-Path $TargetPath -Leaf),
    [string]$SourcePath = $PSScriptRoot
)

$ErrorActionPreference = "Stop"
$Banner = @"

  ╔══════════════════════════════════════════════════════╗
  ║   AWI v1.0.0             ║
  ║   AI 工程工作区底层架构 — 一键初始化                  ║
  ╚══════════════════════════════════════════════════════╝

"@

Write-Host $Banner -ForegroundColor Cyan

# 检查 PowerShell 版本
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "[错误] 需要 PowerShell 5.0 或更高版本。当前版本: $($PSVersionTable.PSVersion)" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] PowerShell 版本: $($PSVersionTable.PSVersion)" -ForegroundColor Green

# 验证源路径
if (-not (Test-Path (Join-Path $SourcePath "CONSTITUTION.md"))) {
    Write-Host "[错误] 未在源路径找到 CONSTITUTION.md，请确保在 AWI 根目录运行此脚本。" -ForegroundColor Red
    exit 1
}

# 创建目标目录
Write-Host ""
Write-Host "=== 初始化目标项目: $ProjectName ===" -ForegroundColor Yellow
Write-Host "目标路径: $TargetPath" -ForegroundColor Gray

if (-not (Test-Path $TargetPath)) {
    New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
    Write-Host "[OK] 创建目标目录" -ForegroundColor Green
}

# 创建目录结构
$Directories = @(
    "agents",
    "skills",
    "harness/archive",
    "harness/templates",
    "docs/adr",
    "docs/research",
    ".omx/plans",
    "cache/scripts",
    "rules/common",
    ".trae/rules",
    ".trae/skills"
)

foreach ($dir in $Directories) {
    $fullPath = Join-Path $TargetPath $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    }
}
Write-Host "[OK] 目录结构已创建 ($($Directories.Count) 个目录)" -ForegroundColor Green

# 复制核心文件（排除 .git/、node_modules/ 等）
$ExcludeDirs = @(".git", "node_modules", "__pycache__", ".venv", "venv", "dist", "build", ".next", ".nuxt")
$ExcludeFiles = @("*.log", "*.env", ".DS_Store")

$coreFiles = Get-ChildItem -Path $SourcePath -Exclude $ExcludeDirs | Where-Object {
    $_.Name -notin $ExcludeDirs -and
    $_.Name -notin @("bootstrap.ps1", ".gitignore") -and
    $_.Extension -notin @(".log")
}

$copiedCount = 0
foreach ($item in $coreFiles) {
    $dest = Join-Path $TargetPath $item.Name
    try {
        Copy-Item -Path $item.FullName -Destination $dest -Recurse -Force -ErrorAction Stop
        $copiedCount++
    } catch {
        Write-Host "[警告] 复制失败: $($item.Name) — $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
Write-Host "[OK] 核心文件已复制 ($copiedCount 项)" -ForegroundColor Green

# 初始化 harness/ 状态文件
$harnessDir = Join-Path $TargetPath "harness"

# feature_list.json 空模板
$featureList = @"
{
  "features": [],
  "current_feature": null,
  "last_updated": "$(Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')",
  "project": "$ProjectName"
}
"@
Set-Content -Path (Join-Path $harnessDir "feature_list.json") -Value $featureList -Encoding UTF8

# progress.md 空模板
$progress = @"
# $ProjectName — 进度日志

## 会话记录

### $(Get-Date -Format 'yyyy-MM-dd') — 项目初始化

- 通过 bootstrap.ps1 初始化 AWI
- 框架版本: v1.0.0
- 状态: 就绪

## 下一步

运行 `harness/init.ps1` 验证基础设施完整性，然后开始第一个功能模块。
"@
Set-Content -Path (Join-Path $harnessDir "progress.md") -Value $progress -Encoding UTF8

# session-handoff.md 空模板
$handoff = @"
# $ProjectName — 会话交接

## 当前状态

- 工作流阶段: 初始化完成
- 活跃功能: 无
- 阻塞项: 无

## 下一步任务

1. 对 AI 代理说 "加载 workspace，告诉我当前状态"
2. 开始第一个功能模块（使用 deep-interview → ralplan → ultragoal 工作流）

## 注意事项

- 框架已部署，CONSTITUTION.md 处于最高优先级
- 45 个技能可用，使用 `\$技能名` 语法调用
- 所有代理角色位于 agents/ 目录
"@
Set-Content -Path (Join-Path $harnessDir "session-handoff.md") -Value $handoff -Encoding UTF8

# workflow-state.json 默认值
$workflowState = @"
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
Set-Content -Path (Join-Path $harnessDir "workflow-state.json") -Value $workflowState -Encoding UTF8

Write-Host "[OK] 状态文件已初始化" -ForegroundColor Green

# 运行验证
$initScript = Join-Path $harnessDir "init.ps1"
if (Test-Path $initScript) {
    Write-Host ""
    Write-Host "=== 运行基础设施验证 ===" -ForegroundColor Yellow
    try {
        & $initScript -ProjectName $ProjectName -ErrorAction Continue
    } catch {
        Write-Host "[警告] 验证脚本执行时出现非致命错误，继续..." -ForegroundColor Yellow
    }
} else {
    Write-Host "[警告] 未找到 harness/init.ps1，跳过自动验证" -ForegroundColor Yellow
}

# 输出成功消息
Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║  导入成功！AWI 已就绪    ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "项目名称: $ProjectName" -ForegroundColor Cyan
Write-Host "项目路径: $TargetPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步:" -ForegroundColor Yellow
Write-Host "  1. 在目标目录中打开 AI 编码工具（Trae / Claude Code / Codex CLI）" -ForegroundColor White
Write-Host '  2. 对 AI 代理说："加载 workspace，告诉我当前状态"' -ForegroundColor White
Write-Host "  3. 代理将自动加载上下文并报告当前工作流状态" -ForegroundColor White
Write-Host ""
Write-Host "快速命令:" -ForegroundColor Yellow
Write-Host "  启动新功能: deep-interview → brainstorming → ralplan → TDD" -ForegroundColor Gray
Write-Host "  继续开发:   说“继续上次的开发”恢复上下文" -ForegroundColor Gray
Write-Host "  安全审计:   使用 security-review 技能（" -ForegroundColor Gray -NoNewline
Write-Host '$security-review' -ForegroundColor DarkCyan -NoNewline
Write-Host "）" -ForegroundColor Gray
Write-Host ""
