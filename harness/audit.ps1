<#
.SYNOPSIS
    AWI 兼容性审计脚本 — 用于已有项目的导入评估
.DESCRIPTION
    扫描目标项目目录，检测现有文件与 AWI 的兼容性。
    输出三部分：
      1. 已存在且兼容 — 无需操作
      2. 可安全添加 — AWI 文件不存在，可导入
      3. 潜在冲突 — 同名文件存在，需人工确认

    不修改任何文件（只读操作）。

.PARAMETER TargetPath
    目标项目路径（默认：当前目录）
.PARAMETER ProjectName
    项目名称（默认：从目录名推断）
.EXAMPLE
    .\harness\audit.ps1 -TargetPath "D:\my-existing-project" -ProjectName "MyProject"
#>

param(
    [string]$TargetPath = (Get-Location).Path,
    [string]$ProjectName = (Split-Path $TargetPath -Leaf),
    [string]$SourcePath = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   AWI 兼容性审计 — 已有项目导入评估                  ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "项目名称: $ProjectName" -ForegroundColor White
Write-Host "目标路径: $TargetPath" -ForegroundColor Gray
Write-Host "AWI 源:   $SourcePath" -ForegroundColor Gray
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 确认目标目录存在
# ═══════════════════════════════════════════════════════════════
if (-not (Test-Path $TargetPath)) {
    Write-Host "[错误] 目标路径不存在: $TargetPath" -ForegroundColor Red
    Write-Host "  这是一个新项目 — 使用 bootstrap.ps1 -Mode full 进行完整初始化。" -ForegroundColor Yellow
    exit 1
}

# ═══════════════════════════════════════════════════════════════
# 确认是已有项目（非空目录）
# ═══════════════════════════════════════════════════════════════
$existingItems = Get-ChildItem -Path $TargetPath -Exclude ".git","node_modules","__pycache__" -ErrorAction SilentlyContinue
if ($null -eq $existingItems -or $existingItems.Count -eq 0) {
    Write-Host "[信息] 目标目录为空 — 这是一个新项目" -ForegroundColor Cyan
    Write-Host "  建议: bootstrap.ps1 -Mode full" -ForegroundColor Yellow
    exit 0
}

# ═══════════════════════════════════════════════════════════════
# 检测已有项目特征
# ═══════════════════════════════════════════════════════════════
Write-Host "=== 1. 已有项目特征检测 ===" -ForegroundColor Yellow
Write-Host ""

$hasPackageJson = Test-Path (Join-Path $TargetPath "package.json")
$hasGit = Test-Path (Join-Path $TargetPath ".git")
$hasTsConfig = Test-Path (Join-Path $TargetPath "tsconfig.json")
$hasSrc = Test-Path (Join-Path $TargetPath "src")
$langFiles = Get-ChildItem -Path $TargetPath -Filter "*.py" -Recurse -Depth 1 -ErrorAction SilentlyContinue
$hasPython = $langFiles.Count -gt 0
$jsFiles = Get-ChildItem -Path $TargetPath -Filter "*.js" -Recurse -Depth 1 -ErrorAction SilentlyContinue
$tsFiles = Get-ChildItem -Path $TargetPath -Filter "*.ts" -Recurse -Depth 1 -ErrorAction SilentlyContinue

Write-Host "  Node.js 项目:    $(if ($hasPackageJson) { '是' } else { '否' })" -ForegroundColor $(if ($hasPackageJson) { 'Green' } else { 'Gray' })
Write-Host "  TypeScript:       $(if ($tsFiles.Count -gt 0) { '是' } else { '否' })" -ForegroundColor $(if ($tsFiles.Count -gt 0) { 'Green' } else { 'Gray' })
Write-Host "  Python:           $(if ($hasPython) { '是' } else { '否' })" -ForegroundColor $(if ($hasPython) { 'Green' } else { 'Gray' })
Write-Host "  Git 仓库:         $(if ($hasGit) { '是' } else { '否' })" -ForegroundColor $(if ($hasGit) { 'Green' } else { 'Yellow' })
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# AWI 核心文件检测 — 三级分类
# ═══════════════════════════════════════════════════════════════
Write-Host "=== 2. AWI 框架文件状态 ===" -ForegroundColor Yellow
Write-Host ""

$AWI_Files = @(
    # Tier 1: 宪法级（最高优先级，不可覆盖）
    @{ File = "CONSTITUTION.md"; Tier = 1; Desc = "系统宪法（不可协商规则）"; Risk = "HIGH" },
    @{ File = "SECURITY-ZONES.md"; Tier = 1; Desc = "运行时安全区（三级边界）"; Risk = "HIGH" },
    @{ File = "SECURITY.md"; Tier = 1; Desc = "安全策略"; Risk = "HIGH" },
    # Tier 2: 操作契约（可调和）
    @{ File = "AGENTS.md"; Tier = 2; Desc = "代理指令主入口（16原则+路由表）"; Risk = "MEDIUM" },
    @{ File = "AGENTS-lite.md"; Tier = 2; Desc = "轻量执行层版本"; Risk = "LOW" },
    @{ File = "SOUL.md"; Tier = 2; Desc = "核心身份定义"; Risk = "LOW" },
    @{ File = "RULES.md"; Tier = 2; Desc = "规则契约"; Risk = "MEDIUM" },
    # Tier 3: 状态与工具（几乎无冲突风险）
    @{ File = "bootstrap.ps1"; Tier = 3; Desc = "初始化脚本"; Risk = "LOW" },
    @{ File = ".gitignore"; Tier = 3; Desc = "Git 忽略规则"; Risk = "MEDIUM" }
)

$compatible = @()
$safeToAdd = @()
$conflicts = @()

foreach ($item in $AWI_Files) {
    $srcFile = Join-Path $SourcePath $item.File
    $dstFile = Join-Path $TargetPath $item.File

    $srcExists = Test-Path $srcFile
    $dstExists = Test-Path $dstFile

    if ($srcExists -and $dstExists) {
        # 同名文件存在 — 检测是否内容相同
        $srcHash = (Get-FileHash $srcFile -Algorithm MD5).Hash
        $dstHash = (Get-FileHash $dstFile -Algorithm MD5).Hash

        if ($srcHash -eq $dstHash) {
            $compatible += [PSCustomObject]@{
                File = $item.File
                Tier = $item.Tier
                Desc = $item.Desc
                Status = "已同步"
                Risk = $item.Risk
            }
        } else {
            $conflicts += [PSCustomObject]@{
                File = $item.File
                Tier = $item.Tier
                Desc = $item.Desc
                Status = "内容冲突"
                Risk = $item.Risk
            }
        }
    } elseif ($srcExists -and -not $dstExists) {
        $safeToAdd += [PSCustomObject]@{
            File = $item.File
            Tier = $item.Tier
            Desc = $item.Desc
            Status = "可安全添加"
            Risk = $item.Risk
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# agents/ 和 skills/ 目录检测
# ═══════════════════════════════════════════════════════════════
$hasAgentsDir = Test-Path (Join-Path $TargetPath "agents")
$hasSkillsDir = Test-Path (Join-Path $TargetPath "skills")
$hasHarnessDir = Test-Path (Join-Path $TargetPath "harness")
$hasOmxDir = Test-Path (Join-Path $TargetPath ".omx")

$dirResults = @()
$dirResults += [PSCustomObject]@{ Dir = "agents/"; Exists = $hasAgentsDir; Desc = "18个代理角色"; Files = if ($hasAgentsDir) { (Get-ChildItem (Join-Path $TargetPath "agents") -Filter "*.md").Count } else { 0 } }
$dirResults += [PSCustomObject]@{ Dir = "skills/"; Exists = $hasSkillsDir; Desc = "46个可复用技能"; Files = if ($hasSkillsDir) { (Get-ChildItem (Join-Path $TargetPath "skills") -Directory).Count } else { 0 } }
$dirResults += [PSCustomObject]@{ Dir = "harness/"; Exists = $hasHarnessDir; Desc = "状态管理中枢"; Files = if ($hasHarnessDir) { (Get-ChildItem (Join-Path $TargetPath "harness") -File).Count } else { 0 } }
$dirResults += [PSCustomObject]@{ Dir = ".omx/"; Exists = $hasOmxDir; Desc = "记忆与持久化"; Files = if ($hasOmxDir) { (Get-ChildItem (Join-Path $TargetPath ".omx") -File).Count } else { 0 } }

# ═══════════════════════════════════════════════════════════════
# 输出结果
# ═══════════════════════════════════════════════════════════════

Write-Host "--- 核心文件 ---" -ForegroundColor DarkGray
Write-Host ("{0,-24} {1,-10} {2,-12} {3,-30}" -f "文件", "层级", "状态", "说明")
Write-Host ("{0,-24} {1,-10} {2,-12} {3,-30}" -f "----", "----", "----", "----")

foreach ($c in $compatible) {
    Write-Host ("{0,-24} {1,-10} {2,-12} {3,-30}" -f $c.File, "T$($c.Tier)", $c.Status, $c.Desc) -ForegroundColor Green
}
foreach ($s in $safeToAdd) {
    Write-Host ("{0,-24} {1,-10} {2,-12} {3,-30}" -f $s.File, "T$($s.Tier)", $s.Status, $s.Desc) -ForegroundColor Cyan
}
foreach ($x in $conflicts) {
    Write-Host ("{0,-24} {1,-10} {2,-12} {3,-30}" -f $x.File, "T$($x.Tier), $($x.Risk)", $x.Status, $x.Desc) -ForegroundColor Yellow
}

Write-Host ""
Write-Host "--- 子系统目录 ---" -ForegroundColor DarkGray
Write-Host ("{0,-16} {1,-10} {2,-10} {3,-30}" -f "目录", "状态", "文件数", "说明")
Write-Host ("{0,-16} {1,-10} {2,-10} {3,-30}" -f "----", "----", "----", "----")

foreach ($d in $dirResults) {
    $color = if ($d.Exists) { "Green" } else { "Gray" }
    Write-Host ("{0,-16} {1,-10} {2,-10} {3,-30}" -f $d.Dir, $(if ($d.Exists) { "存在" } else { "缺失" }), $d.Files, $d.Desc) -ForegroundColor $color
}

# ═══════════════════════════════════════════════════════════════
# 兼容性评分和建议
# ═══════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "=== 3. 兼容性评估 ===" -ForegroundColor Yellow
Write-Host ""

$score = 0
$maxScore = $AWI_Files.Count + 4  # 9 核心文件 + 4 子系统目录

foreach ($c in $compatible) { $score++ }
foreach ($s in $safeToAdd) { $score++ }
foreach ($d in $dirResults) { if ($d.Exists) { $score++ } }

$pct = [Math]::Round(($score / $maxScore) * 100, 0)

Write-Host "  兼容性评分: $score / $maxScore ($pct%)" -ForegroundColor $(if ($pct -ge 80) { "Green" } elseif ($pct -ge 40) { "Yellow" } else { "Red" })

# ═══════════════════════════════════════════════════════════════
# 导入建议
# ═══════════════════════════════════════════════════════════════
Write-Host ""
Write-Host "=== 4. 导入建议 ===" -ForegroundColor Yellow
Write-Host ""

$safeCount = $safeToAdd.Count
$conflictCount = $conflicts.Count
$missingDirs = ($dirResults | Where-Object { -not $_.Exists }).Count

if ($pct -ge 80) {
    Write-Host "  [推荐] 项目已高度兼容，使用最小导入模式" -ForegroundColor Green
    Write-Host "    .\bootstrap.ps1 -Mode minimum -TargetPath `"$TargetPath`" -ProjectName `"$ProjectName`"" -ForegroundColor Cyan
    Write-Host "    仅添加缺失的 harness/ 状态管理系统，不修改任何现有文件。"
} elseif ($pct -ge 40) {
    Write-Host "  [推荐] 项目部分兼容，使用最小导入模式 + 审计报告" -ForegroundColor Yellow
    Write-Host "    .\bootstrap.ps1 -Mode minimum -TargetPath `"$TargetPath`" -ProjectName `"$ProjectName`"" -ForegroundColor Cyan
    if ($conflictCount -gt 0) {
        Write-Host "  [!] 检测到 $conflictCount 个潜在冲突文件（同名但内容不同）" -ForegroundColor Yellow
        Write-Host "      建议先备份现有文件，然后使用 -Mode full -Force 覆盖"
        Write-Host "      或手动调和后再运行 -Mode minimum"
    }
} else {
    Write-Host "  [推荐] 低兼容性，使用完整导入模式" -ForegroundColor Red
    Write-Host "    .\bootstrap.ps1 -Mode full -TargetPath `"$TargetPath`" -ProjectName `"$ProjectName`" -Force" -ForegroundColor Cyan
    if ($conflictCount -gt 0) {
        Write-Host "  [!] -Force 将覆盖 $conflictCount 个冲突文件" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "--- 三种导入模式说明 ---" -ForegroundColor DarkGray
Write-Host "  audit   : 只评估，不修改（本脚本）" -ForegroundColor White
Write-Host "  minimum : 只添加 AWI 状态管理（harness/ + .omx/），不覆盖现有文件" -ForegroundColor White
Write-Host "  full    : 复制所有文件（代理+技能+文档+规则），需要 -Force 覆盖冲突" -ForegroundColor White
Write-Host ""

Write-Host "审计完成。未修改任何文件。" -ForegroundColor Cyan
Write-Host ""
