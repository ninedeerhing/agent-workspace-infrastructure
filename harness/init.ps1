<#
.SYNOPSIS
    AWI Harness — 启动验证脚本
.DESCRIPTION
    检查开发环境、安装依赖、运行类型检查、lint 和测试。
    用于每次会话开始时的环境验证，确保工作区处于干净可用状态。
    所有检查失败不会阻塞启动，但会在摘要中标记警告或失败。
.NOTES
    版本: 1.0.0
    平台: Windows PowerShell 5.1+
    语言: 中文（输出）、英文（标识符和命令）
#>

param(
    [switch]$SkipTests,
    [switch]$SkipLint,
    [switch]$SkipTypeCheck,
    [switch]$SkipInstall,
    [switch]$Quiet
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir

# 统计变量
$TotalChecks = 0
$PassedChecks = 0
$FailedChecks = 0
$WarningChecks = 0
$StartTime = Get-Date

# ═══════════════════════════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════════════════════════

function Write-Header {
    param([string]$Text)
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "  $Text" -ForegroundColor Cyan
        Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
    }
}

function Write-Step {
    param([string]$Text)
    if (-not $Quiet) {
        Write-Host "  >> $Text" -ForegroundColor DarkCyan
    }
}

function Write-Pass {
    param([string]$Text)
    $script:TotalChecks++
    $script:PassedChecks++
    if (-not $Quiet) {
        Write-Host "  [$( '✓' )] $Text" -ForegroundColor Green
    }
}

function Write-Fail {
    param([string]$Text, [string]$Detail)
    $script:TotalChecks++
    $script:FailedChecks++
    if (-not $Quiet) {
        Write-Host "  [$( '✗' )] $Text" -ForegroundColor Red
        if ($Detail) {
            Write-Host "      原因: $Detail" -ForegroundColor DarkRed
        }
    }
}

function Write-Warn {
    param([string]$Text)
    $script:TotalChecks++
    $script:WarningChecks++
    if (-not $Quiet) {
        Write-Host "  [$( '!' )] $Text" -ForegroundColor Yellow
    }
}

function Write-Info {
    param([string]$Text)
    if (-not $Quiet) {
        Write-Host "       $Text" -ForegroundColor Gray
    }
}

function Write-Summary {
    param([string]$Text)
    Write-Host ""
    Write-Host "  $Text" -ForegroundColor White
}

<#
    检查指定命令是否在 PATH 中可用
    @param $CommandName 命令名称（如 node, git, npm）
    @returns bool 命令是否可用
#>
function Test-CommandExists {
    param([string]$CommandName)
    $result = Get-Command $CommandName -ErrorAction SilentlyContinue
    return $null -ne $result
}

<#
    尝试读取项目根目录下的 package.json
    @returns 解析后的 package.json 对象，不存在则返回 $null
#>
function Get-ProjectPackageJson {
    param([string]$RootPath)
    $packageJsonPath = Join-Path $RootPath "package.json"
    if (Test-Path $packageJsonPath) {
        try {
            $content = Get-Content $packageJsonPath -Raw -Encoding UTF8
            return $content | ConvertFrom-Json
        }
        catch {
            return $null
        }
    }
    return $null
}

<#
    检查 package.json 中是否存在指定的 npm script
    @param $PackageJson package.json 解析对象
    @param $ScriptName 脚本名称（如 test, lint, typecheck）
    @returns bool 脚本是否存在
#>
function Test-NpmScriptExists {
    param($PackageJson, [string]$ScriptName)
    if ($null -eq $PackageJson -or $null -eq $PackageJson.scripts) {
        return $false
    }
    $scripts = $PackageJson.scripts | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
    return $ScriptName -in $scripts
}

# ═══════════════════════════════════════════════════════════════
# 1. 欢迎信息
# ═══════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
Write-Host "  ║          AWI Harness — 启动验证              ║" -ForegroundColor Magenta
Write-Host "  ║          基于 learn-harness-engineering 五子系统         ║" -ForegroundColor Magenta
Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
Write-Host ""
Write-Info "项目路径: $ProjectRoot"
Write-Info "Harness 路径: $ScriptDir"
Write-Info "启动时间: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Info "平台: Windows $($env:OS)"
Write-Host ""

# ═══════════════════════════════════════════════════════════════
# 2. 环境检查 — 必要工具
# ═══════════════════════════════════════════════════════════════

Write-Header "1. 环境检查 — 必要工具"

# 检查 Node.js
if (Test-CommandExists "node") {
    $nodeVersion = (node --version 2>$null) -replace 'v', ''
    Write-Pass "Node.js 已安装 (v$nodeVersion)"
}
else {
    Write-Warn "Node.js 未安装 — 跳过 JavaScript/TypeScript 相关检查"
}

# 检查 npm
if (Test-CommandExists "npm") {
    $npmVersion = (npm --version 2>$null)
    Write-Pass "npm 已安装 (v$npmVersion)"
}
else {
    Write-Warn "npm 未安装 — 跳过依赖安装"
}

# 检查 Git
if (Test-CommandExists "git") {
    $gitVersion = (git --version 2>$null) -replace 'git version ', ''
    Write-Pass "Git 已安装 ($gitVersion)"
}
else {
    Write-Warn "Git 未安装 — 跳过版本控制检查"
}

# 检查 PowerShell 版本
$psVersion = $PSVersionTable.PSVersion
if ($psVersion.Major -ge 5) {
    Write-Pass "PowerShell 版本满足要求 ($($psVersion))"
}
else {
    Write-Fail "PowerShell 版本过低 ($($psVersion))" "需要 PowerShell 5.1 或更高版本"
}

# 检查 Harness 目录结构
Write-Header "2. 环境检查 — Harness 目录结构"

$requiredHarnessFiles = @(
    "feature_list.json",
    "progress.md",
    "session-handoff.md",
    "init.ps1",
    "clean-state-checklist.md",
    "archive\store.ps1",
    "archive\index.json"
)

foreach ($file in $requiredHarnessFiles) {
    $filePath = Join-Path $ScriptDir $file
    if (Test-Path $filePath) {
        Write-Pass "harness/$file 存在"
    }
    else {
        Write-Fail "harness/$file 缺失" "文件未找到，请检查 harness 目录完整性"
    }
}

# 检查顶层协议文件
$requiredRootFiles = @(
    "AGENTS.md",
    "SOUL.md",
    "RULES.md",
    "SECURITY.md"
)

foreach ($file in $requiredRootFiles) {
    $filePath = Join-Path $ProjectRoot $file
    if (Test-Path $filePath) {
        Write-Pass "$file 存在"
    }
    else {
        Write-Fail "$file 缺失" "顶层协议文件未找到，请检查项目根目录完整性"
    }
}

# ═══════════════════════════════════════════════════════════════
# 3. 依赖安装
# ═══════════════════════════════════════════════════════════════

Write-Header "3. 依赖安装"

$packageJson = Get-ProjectPackageJson -RootPath $ProjectRoot

if ($null -ne $packageJson) {
    Write-Info "项目名称: $($packageJson.name)"
    Write-Info "版本: $($packageJson.version)"

    if (-not $SkipInstall) {
        $nodeModulesPath = Join-Path $ProjectRoot "node_modules"
        if (Test-Path $nodeModulesPath) {
            Write-Pass "node_modules 已存在，跳过 npm install"
        }
        else {
            Write-Step "运行 npm install..."
            $installResult = npm --prefix "$ProjectRoot" install 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Pass "npm install 成功"
            }
            else {
                Write-Fail "npm install 失败" "检查网络连接和 package.json 依赖"
            }
        }
    }
    else {
        Write-Warn "跳过依赖安装 (--SkipInstall)"
    }
}
else {
    Write-Warn "未找到 package.json — 跳过依赖安装"
}

# ═══════════════════════════════════════════════════════════════
# 4. 类型检查
# ═══════════════════════════════════════════════════════════════

Write-Header "4. 类型检查 (TypeCheck)"

if ($SkipTypeCheck) {
    Write-Warn "跳过类型检查 (--SkipTypeCheck)"
}
elseif ($null -eq $packageJson) {
    Write-Warn "未找到 package.json — 跳过类型检查"
}
elseif (-not (Test-NpmScriptExists -PackageJson $packageJson -ScriptName "typecheck")) {
    Write-Warn "package.json 中未定义 typecheck 脚本 — 跳过类型检查"
}
else {
    Write-Step "运行 npm run typecheck..."
    $typecheckResult = npm --prefix "$ProjectRoot" run typecheck 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Pass "类型检查通过"
    }
    else {
        Write-Fail "类型检查失败" "请检查 TypeScript 类型错误"
        if (-not $Quiet) {
            $typecheckResult | ForEach-Object { Write-Info $_ }
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# 5. Lint 检查
# ═══════════════════════════════════════════════════════════════

Write-Header "5. Lint 检查"

if ($SkipLint) {
    Write-Warn "跳过 Lint 检查 (--SkipLint)"
}
elseif ($null -eq $packageJson) {
    Write-Warn "未找到 package.json — 跳过 Lint 检查"
}
elseif (-not (Test-NpmScriptExists -PackageJson $packageJson -ScriptName "lint")) {
    Write-Warn "package.json 中未定义 lint 脚本 — 跳过 Lint 检查"
}
else {
    Write-Step "运行 npm run lint..."
    $lintResult = npm --prefix "$ProjectRoot" run lint 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Pass "Lint 检查通过"
    }
    else {
        Write-Fail "Lint 检查失败" "请检查代码风格问题"
        if (-not $Quiet) {
            $lintResult | ForEach-Object { Write-Info $_ }
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# 6. 测试运行
# ═══════════════════════════════════════════════════════════════

Write-Header "6. 测试运行"

if ($SkipTests) {
    Write-Warn "跳过测试运行 (--SkipTests)"
}
elseif ($null -eq $packageJson) {
    Write-Warn "未找到 package.json — 跳过测试"
}
elseif (-not (Test-NpmScriptExists -PackageJson $packageJson -ScriptName "test")) {
    Write-Warn "package.json 中未定义 test 脚本 — 跳过测试"
}
else {
    Write-Step "运行 npm run test..."
    $testResult = npm --prefix "$ProjectRoot" run test 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Pass "所有测试通过"
    }
    else {
        Write-Fail "测试失败" "部分测试未通过，请检查测试输出"
        if (-not $Quiet) {
            $testResult | ForEach-Object { Write-Info $_ }
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# 7. Git 状态检查
# ═══════════════════════════════════════════════════════════════

Write-Header "7. Git 状态检查"

if (Test-CommandExists "git") {
    Push-Location $ProjectRoot
    try {
        # 检查是否在 Git 仓库中
        $gitStatus = git rev-parse --is-inside-work-tree 2>$null
        if ($gitStatus -eq "true") {
            Write-Pass "当前目录是 Git 仓库"

            # 检查当前分支
            $branch = git branch --show-current 2>$null
            if ($branch) {
                Write-Info "当前分支: $branch"
            }

            # 检查未提交的变更
            $statusOutput = git status --porcelain 2>$null
            if ($statusOutput) {
                $changeCount = ($statusOutput -split "`n").Count
                Write-Warn "存在 $changeCount 个未提交的变更"
                if (-not $Quiet) {
                    $statusOutput | ForEach-Object { Write-Info "    $_" }
                }
            }
            else {
                Write-Pass "工作区干净，无未提交变更"
            }

            # 检查最近的提交
            $lastCommit = git log -1 --format="%h — %s (%ar)" 2>$null
            if ($lastCommit) {
                Write-Info "最近提交: $lastCommit"
            }
        }
        else {
            Write-Warn "当前目录不是 Git 仓库"
        }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Warn "Git 未安装 — 跳过 Git 状态检查"
}

# ═══════════════════════════════════════════════════════════════
# 8. 特征列表状态摘要
# ═══════════════════════════════════════════════════════════════

Write-Header "8. 功能列表摘要"

$featureListPath = Join-Path $ScriptDir "feature_list.json"
if (Test-Path $featureListPath) {
    try {
        $featureList = Get-Content $featureListPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $features = $featureList.features
        if ($features) {
            Write-Info "共 $($features.Count) 个功能模块"
            foreach ($feat in $features) {
                $statusIcon = switch ($feat.status) {
                    "done"       { "[✓]" }
                    "in_progress" { "[▶]" }
                    "pending"    { "[ ]" }
                    "blocked"    { "[✗]" }
                    default      { "[?]" }
                }
                Write-Info "$statusIcon $($feat.id) — $($feat.name) ($($feat.status))"
            }
        }
    }
    catch {
        Write-Warn "feature_list.json 解析失败: $_"
    }
}
else {
    Write-Warn "feature_list.json 不存在"
}

# ═══════════════════════════════════════════════════════════════
# 9. Harness 系统自检
# ═══════════════════════════════════════════════════════════════

Write-Header "9. Harness 系统自检"

<#
    检查 agents/ 目录 — 代理角色文件数量和关键代理完整性
#>
Write-Step "检查 agents/ 代理角色目录..."

$agentsDir = Join-Path $ProjectRoot "agents"
if (Test-Path $agentsDir) {
    $agentFiles = Get-ChildItem -Path $agentsDir -Filter "*.md" -ErrorAction SilentlyContinue
    if ($agentFiles) {
        $agentCount = $agentFiles.Count
        Write-Pass "agents/ 目录存在，包含 $agentCount 个代理角色文件"

        $criticalAgents = @(
            "orchestrator", "planner", "architect", "critic",
            "executor", "debugger", "explore",
            "test-engineer", "code-reviewer", "security-reviewer", "verifier",
            "designer", "qa-tester", "writer"
        )
        $missingAgents = @()
        $emptyAgents = @()
        foreach ($agent in $criticalAgents) {
            $agentPath = Join-Path $agentsDir "$agent.md"
            if (Test-Path $agentPath) {
                $content = Get-Content $agentPath -Raw -ErrorAction SilentlyContinue
                if ([string]::IsNullOrWhiteSpace($content)) {
                    $emptyAgents += $agent
                }
            }
            else {
                $missingAgents += $agent
            }
        }
        if ($missingAgents.Count -gt 0) {
            Write-Warn "缺失关键代理文件: $($missingAgents -join ', ')"
        }
        else {
            Write-Pass "所有关键代理文件完整 ($($criticalAgents.Count) 个)"
        }
        if ($emptyAgents.Count -gt 0) {
            Write-Warn "以下代理文件内容为空: $($emptyAgents -join ', ')"
        }
    }
    else {
        Write-Warn "agents/ 目录为空，无 .md 文件"
    }
}
else {
    Write-Warn "agents/ 目录不存在"
}

<#
    检查 skills/ 目录 — 技能模块数量和每个技能的 SKILL.md 完整性
#>
Write-Step "检查 skills/ 技能目录..."

$skillsDir = Join-Path $ProjectRoot "skills"
if (Test-Path $skillsDir) {
    $skillSubdirs = Get-ChildItem -Path $skillsDir -Directory -ErrorAction SilentlyContinue
    if ($skillSubdirs) {
        $skillCount = $skillSubdirs.Count
        Write-Pass "skills/ 目录存在，包含 $skillCount 个技能模块"

        $missingSkillMd = @()
        $emptySkillMd = @()
        foreach ($subdir in $skillSubdirs) {
            $skillMdPath = Join-Path $subdir.FullName "SKILL.md"
            if (Test-Path $skillMdPath) {
                $content = Get-Content $skillMdPath -Raw -ErrorAction SilentlyContinue
                if ([string]::IsNullOrWhiteSpace($content)) {
                    $emptySkillMd += $subdir.Name
                }
            }
            else {
                $missingSkillMd += $subdir.Name
            }
        }
        if ($missingSkillMd.Count -gt 0) {
            Write-Warn "以下技能缺少 SKILL.md: $($missingSkillMd -join ', ')"
        }
        else {
            Write-Pass "所有技能 SKILL.md 文件完整 ($skillCount 个)"
        }
        if ($emptySkillMd.Count -gt 0) {
            Write-Warn "以下技能 SKILL.md 内容为空: $($emptySkillMd -join ', ')"
        }
    }
    else {
        Write-Warn "skills/ 目录为空，无子目录"
    }
}
else {
    Write-Warn "skills/ 目录不存在"
}

<#
    检查 docs/ 目录 — 文档文件数量和关键文档存在性
#>
Write-Step "检查 docs/ 文档目录..."

$docsDir = Join-Path $ProjectRoot "docs"
if (Test-Path $docsDir) {
    $docFiles = Get-ChildItem -Path $docsDir -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
    if ($docFiles) {
        $docCount = $docFiles.Count
        Write-Pass "docs/ 目录存在，包含 $docCount 个文档文件"
    }
    else {
        Write-Warn "docs/ 目录为空，无 .md 文档"
    }

    $projectStructure = Join-Path $docsDir "PROJECT-STRUCTURE.md"
    if (Test-Path $projectStructure) {
        Write-Pass "PROJECT-STRUCTURE.md 存在"
    }
    else {
        Write-Warn "PROJECT-STRUCTURE.md 缺失"
    }

    $adrTemplate = Join-Path $docsDir "adr\TEMPLATE.md"
    if (Test-Path $adrTemplate) {
        Write-Pass "adr/TEMPLATE.md 存在"
    }
    else {
        Write-Warn "adr/TEMPLATE.md 缺失"
    }
}
else {
    Write-Warn "docs/ 目录不存在"
}

<#
    检查 Harness 状态文件内容完整性
    验证 feature_list.json 格式、progress.md / session-handoff.md 非空、
    workflow-state.json 格式、workflow-gates.md / clean-state-checklist.md 非空
#>
Write-Step "检查 Harness 状态文件内容完整性..."

$featureListPath = Join-Path $ScriptDir "feature_list.json"
if (Test-Path $featureListPath) {
    try {
        $fl = Get-Content $featureListPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($fl.features -and $fl.features.Count -gt 0) {
            $validFeatures = 0
            $invalidFeatures = 0
            foreach ($feat in $fl.features) {
                if ($feat.id -and $feat.name -and $feat.status -and $feat.evidence) {
                    $validFeatures++
                }
                else {
                    $invalidFeatures++
                }
            }
            if ($invalidFeatures -gt 0) {
                Write-Warn "feature_list.json: $invalidFeatures 个功能条目字段不完整（缺少 id/name/status/evidence）"
            }
            else {
                Write-Pass "feature_list.json 格式有效，$validFeatures 个功能条目完整"
            }
        }
        else {
            Write-Warn "feature_list.json: features 数组为空"
        }
    }
    catch {
        Write-Fail "feature_list.json 解析失败" $_.Exception.Message
    }
}

$progressPath = Join-Path $ScriptDir "progress.md"
if (Test-Path $progressPath) {
    $progressContent = Get-Content $progressPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($progressContent)) {
        Write-Warn "progress.md 内容为空"
    }
    else {
        Write-Pass "progress.md 内容非空 ($($progressContent.Length) 字符)"
    }
}

$handoffPath = Join-Path $ScriptDir "session-handoff.md"
if (Test-Path $handoffPath) {
    $handoffContent = Get-Content $handoffPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($handoffContent)) {
        Write-Warn "session-handoff.md 内容为空"
    }
    else {
        Write-Pass "session-handoff.md 内容非空 ($($handoffContent.Length) 字符)"
    }
}

$workflowStatePath = Join-Path $ScriptDir "workflow-state.json"
if (Test-Path $workflowStatePath) {
    try {
        $ws = Get-Content $workflowStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
        Write-Pass "workflow-state.json 格式有效"
    }
    catch {
        Write-Fail "workflow-state.json 解析失败" $_.Exception.Message
    }
}

$gatesPath = Join-Path $ScriptDir "workflow-gates.md"
if (Test-Path $gatesPath) {
    $gatesContent = Get-Content $gatesPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($gatesContent)) {
        Write-Warn "workflow-gates.md 内容为空"
    }
    else {
        Write-Pass "workflow-gates.md 内容非空 ($($gatesContent.Length) 字符)"
    }
}

$checklistPath = Join-Path $ScriptDir "clean-state-checklist.md"
if (Test-Path $checklistPath) {
    $checklistContent = Get-Content $checklistPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ([string]::IsNullOrWhiteSpace($checklistContent)) {
        Write-Warn "clean-state-checklist.md 内容为空"
    }
    else {
        Write-Pass "clean-state-checklist.md 内容非空 ($($checklistContent.Length) 字符)"
    }
}

<#
    输出 Harness 系统统计摘要
    汇总代理、技能、文档、功能模块的数量
#>
Write-Host ""
Write-Info "--- Harness 系统统计 ---"

$statAgentCount = 0
if (Test-Path (Join-Path $ProjectRoot "agents")) {
    $statAgentCount = @(Get-ChildItem -Path (Join-Path $ProjectRoot "agents") -Filter "*.md" -ErrorAction SilentlyContinue).Count
}

$statSkillCount = 0
if (Test-Path (Join-Path $ProjectRoot "skills")) {
    $statSkillCount = @(Get-ChildItem -Path (Join-Path $ProjectRoot "skills") -Directory -ErrorAction SilentlyContinue).Count
}

$statDocCount = 0
if (Test-Path (Join-Path $ProjectRoot "docs")) {
    $statDocCount = @(Get-ChildItem -Path (Join-Path $ProjectRoot "docs") -Filter "*.md" -Recurse -ErrorAction SilentlyContinue).Count
}

$statFeatureCount = 0
$featureListPath2 = Join-Path $ScriptDir "feature_list.json"
if (Test-Path $featureListPath2) {
    try {
        $fl2 = Get-Content $featureListPath2 -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($fl2.features) {
            $statFeatureCount = $fl2.features.Count
        }
    }
    catch { }
}

Write-Info "代理角色:     $statAgentCount 个"
Write-Info "技能模块:     $statSkillCount 个"
Write-Info "文档文件:     $statDocCount 个"
Write-Info "功能模块:     $statFeatureCount 个"
Write-Info "Harness 文件: 7 个 (feature_list.json, progress.md, session-handoff.md, init.ps1, clean-state-checklist.md, workflow-state.json, workflow-gates.md)"

# ═══════════════════════════════════════════════════════════════
# 10. 最终摘要
# ═══════════════════════════════════════════════════════════════

$EndTime = Get-Date
$Elapsed = $EndTime - $StartTime

Write-Host ""
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  验证摘要" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Summary "总检查数:     $TotalChecks"
Write-Summary "通过:         $PassedChecks $( if ($PassedChecks -gt 0) { '( ✓ )' } )" -ForegroundColor $(if ($PassedChecks -gt 0) { 'Green' } else { 'White' })
Write-Summary "警告:         $WarningChecks $( if ($WarningChecks -gt 0) { '( ! )' } )" -ForegroundColor $(if ($WarningChecks -gt 0) { 'Yellow' } else { 'White' })
Write-Summary "失败:         $FailedChecks $( if ($FailedChecks -gt 0) { '( ✗ )' } )" -ForegroundColor $(if ($FailedChecks -gt 0) { 'Red' } else { 'White' })

Write-Host ""

if ($FailedChecks -gt 0) {
    Write-Host "  状态: 失败 — 存在 $FailedChecks 个失败项，请修复后重试" -ForegroundColor Red
    Write-Host ""
    exit 1
}
elseif ($WarningChecks -gt 0) {
    Write-Host "  状态: 通过（有警告）— 存在 $WarningChecks 个警告，建议排查" -ForegroundColor Yellow
    Write-Host ""
    exit 0
}
else {
    Write-Host "  状态: 全部通过 — 工作区处于干净可用状态" -ForegroundColor Green
    Write-Host ""
    exit 0
}
