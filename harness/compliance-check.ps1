<#
.SYNOPSIS
    Raindeer-AWI 合规检查脚本
.DESCRIPTION
    只读检查工作区是否遵循当前已落地的 Raindeer-AWI 基线：
    - 关键协议文件是否存在
    - TASK_TREES 是否锁定当前主线
    - PROJECT_STATUS §5 台账是否有有效记录
    - workflow-state.json 是否可解析且有工作流标识
    - Git 脏工作区是否有当日台账记录
    - SESSION_BOOT / agent-registry / team manifest 等运行时文件是否到位

    退出码：
      0 = 无违规项
      1 = 存在违规项（报告型失败，不做阻断动作）
#>

param(
    [string]$TargetPath = (Get-Location).Path,
    [ValidateSet("baseline", "post-bootstrap")]
    [string]$Mode = "baseline",
    [ValidateSet("text", "json", "markdown")]
    [string]$Format = "text",
    [switch]$Quiet
)

$ErrorActionPreference = "Continue"
$ProjectRoot = (Resolve-Path $TargetPath).Path
$HarnessDir = Join-Path $ProjectRoot "harness"
$DocsDir = Join-Path $ProjectRoot "docs"

$Findings = New-Object System.Collections.Generic.List[object]
$Checks = New-Object System.Collections.Generic.List[object]

function Add-Finding {
    param(
        [string]$Severity,
        [string]$Code,
        [string]$Title,
        [string]$Detail,
        [string]$Recommendation
    )

    $Findings.Add([pscustomobject]@{
        severity = $Severity
        code = $Code
        title = $Title
        detail = $Detail
        recommendation = $Recommendation
    }) | Out-Null
}

function Add-Check {
    param(
        [string]$Name,
        [string]$Status,
        [string]$Detail
    )

    $Checks.Add([pscustomobject]@{
        name = $Name
        status = $Status
        detail = $Detail
    }) | Out-Null
}

function Test-FileRequired {
    param(
        [string]$Path,
        [string]$Code,
        [string]$Title,
        [string]$Recommendation
    )

    if (Test-Path $Path) {
        Add-Check -Name $Title -Status "PASS" -Detail $Path
        return $true
    }

    Add-Check -Name $Title -Status "FAIL" -Detail $Path
    Add-Finding -Severity "error" -Code $Code -Title $Title -Detail "缺少文件: $Path" -Recommendation $Recommendation
    return $false
}

function Get-FileText {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    return Get-Content $Path -Raw -Encoding UTF8
}

function Get-LatestLedgerDate {
    param([string]$ProjectStatusText)

    if ([string]::IsNullOrWhiteSpace($ProjectStatusText)) {
        return $null
    }

    $matches = [regex]::Matches($ProjectStatusText, '^\|\s*(20\d{2}-\d{2}-\d{2})\s*\|', [System.Text.RegularExpressions.RegexOptions]::Multiline)
    if ($matches.Count -eq 0) {
        return $null
    }

    return $matches[0].Groups[1].Value
}

function Get-TreeMainline {
    param([string]$TaskTreesText)

    if ([string]::IsNullOrWhiteSpace($TaskTreesText)) {
        return $null
    }

    $match = [regex]::Match($TaskTreesText, 'Current sole foreground mainline:\s*`([^`]+)`')
    if (-not $match.Success) {
        return $null
    }

    return $match.Groups[1].Value
}

function Get-AgentCount {
    param([string]$AgentsPath)
    if (-not (Test-Path $AgentsPath)) { return 0 }
    return @(Get-ChildItem -Path $AgentsPath -Filter "*.md" -File -ErrorAction SilentlyContinue).Count
}

$requiredFiles = @(
    @{ Path = (Join-Path $ProjectRoot "AGENTS-lite.md"); Code = "CFG-001"; Title = "AGENTS-lite"; Recommendation = "通过 bootstrap 或仓库同步补齐 AGENTS-lite.md" },
    @{ Path = (Join-Path $DocsDir "PROJECT_STATUS.md"); Code = "CFG-002"; Title = "PROJECT_STATUS"; Recommendation = "补齐 docs/PROJECT_STATUS.md 并建立 §5 台账" },
    @{ Path = (Join-Path $DocsDir "TASK_TREES.md"); Code = "CFG-003"; Title = "TASK_TREES"; Recommendation = "补齐 docs/TASK_TREES.md 并登记当前主线" },
    @{ Path = (Join-Path $DocsDir "FLOW-MODE.md"); Code = "CFG-004"; Title = "FLOW-MODE"; Recommendation = "补齐 docs/FLOW-MODE.md，确保心流协议存在" },
    @{ Path = (Join-Path $DocsDir "LOOP_ENGINEERING.md"); Code = "CFG-006"; Title = "LOOP_ENGINEERING"; Recommendation = "补齐 docs/LOOP_ENGINEERING.md 自治循环协议" },
    @{ Path = (Join-Path $HarnessDir "workflow-state.json"); Code = "CFG-005"; Title = "workflow-state"; Recommendation = "补齐 harness/workflow-state.json" },
    @{ Path = (Join-Path $HarnessDir "loop-state.json"); Code = "CFG-007"; Title = "loop-state"; Recommendation = "补齐 harness/loop-state.json Loop 机器态" },
    @{ Path = (Join-Path $ProjectRoot "apps/quant_assistant/docs/METHODOLOGY_MEMORY.md"); Code = "CFG-008"; Title = "METHODOLOGY_MEMORY"; Recommendation = "补齐方法论永久记忆真源" }
)

foreach ($item in $requiredFiles) {
    [void](Test-FileRequired -Path $item.Path -Code $item.Code -Title $item.Title -Recommendation $item.Recommendation)
}

$taskTreesPath = Join-Path $DocsDir "TASK_TREES.md"
$taskTreesText = Get-FileText -Path $taskTreesPath
$currentTree = Get-TreeMainline -TaskTreesText $taskTreesText
if ([string]::IsNullOrWhiteSpace($currentTree) -or $currentTree -eq "TREE-X") {
    Add-Check -Name "当前主线登记" -Status "FAIL" -Detail "未找到有效 foreground mainline"
    Add-Finding -Severity "error" -Code "TREE-001" -Title "当前主线未登记" -Detail "TASK_TREES.md 未解析到有效的当前主线。" -Recommendation "在 TASK_TREES.md 中设置 `Current sole foreground mainline`。"
}
else {
    Add-Check -Name "当前主线登记" -Status "PASS" -Detail $currentTree
}

$projectStatusPath = Join-Path $DocsDir "PROJECT_STATUS.md"
$projectStatusText = Get-FileText -Path $projectStatusPath
$latestLedgerDate = Get-LatestLedgerDate -ProjectStatusText $projectStatusText
if ($null -eq $latestLedgerDate) {
    Add-Check -Name "§5 台账条目" -Status "FAIL" -Detail "未找到有效日期行"
    Add-Finding -Severity "error" -Code "LEDGER-001" -Title "§5 台账为空" -Detail "PROJECT_STATUS.md §5 未找到任何活动台账记录。" -Recommendation "在实现、测试或关键决策后立即追加台账记录。"
}
else {
    Add-Check -Name "§5 台账条目" -Status "PASS" -Detail "latest=$latestLedgerDate"
}

$workflowStatePath = Join-Path $HarnessDir "workflow-state.json"
$workflowStateText = Get-FileText -Path $workflowStatePath
if (-not [string]::IsNullOrWhiteSpace($workflowStateText)) {
    try {
        $workflowState = $workflowStateText | ConvertFrom-Json
        $workflowName = $null
        if ($workflowState.PSObject.Properties.Name -contains "active_workflow") {
            $workflowName = $workflowState.active_workflow
        }
        elseif ($workflowState.PSObject.Properties.Name -contains "current_workflow") {
            $workflowName = $workflowState.current_workflow
        }

        if ([string]::IsNullOrWhiteSpace($workflowName)) {
            Add-Check -Name "workflow-state 当前工作流" -Status "WARN" -Detail "未设置 active/current_workflow"
            Add-Finding -Severity "warning" -Code "WF-001" -Title "workflow-state 未锁定工作流" -Detail "workflow-state.json 可解析，但没有有效的工作流标识。" -Recommendation "切换阶段时写入 active_workflow 或 current_workflow。"
        }
        else {
            Add-Check -Name "workflow-state 当前工作流" -Status "PASS" -Detail $workflowName
        }
    }
    catch {
        Add-Check -Name "workflow-state JSON" -Status "FAIL" -Detail $_.Exception.Message
        Add-Finding -Severity "error" -Code "WF-002" -Title "workflow-state 解析失败" -Detail $_.Exception.Message -Recommendation "修复 harness/workflow-state.json 的 JSON 格式。"
    }
}

$sessionBootPath = Join-Path $DocsDir "SESSION_BOOT.md"
if (Test-Path $sessionBootPath) {
    Add-Check -Name "SESSION_BOOT" -Status "PASS" -Detail $sessionBootPath
}
else {
    Add-Check -Name "SESSION_BOOT" -Status "WARN" -Detail "缺失"
    Add-Finding -Severity "warning" -Code "BOOT-001" -Title "统一启动契约缺失" -Detail "docs/SESSION_BOOT.md 尚未落地。" -Recommendation "补齐统一启动契约，作为所有 agent 的最小 boot 文档。"
}

$agentsPath = Join-Path $ProjectRoot "agents"
$agentCount = Get-AgentCount -AgentsPath $agentsPath
if ($agentCount -eq 0) {
    Add-Check -Name "agents roster" -Status "FAIL" -Detail "未发现任何 agents/*.md"
    Add-Finding -Severity "error" -Code "AGENT-001" -Title "agents roster 缺失" -Detail "未检测到可用于 team provisioning 的 agents/*.md 文件。" -Recommendation "确认 full 模式已部署 agents/ 目录。"
}
else {
    Add-Check -Name "agents roster" -Status "PASS" -Detail "$agentCount files"
}

$registryPath = Join-Path $HarnessDir "agent-registry.json"
$manifestPath = Join-Path $HarnessDir "team-manifest.default.json"

if ($Mode -eq "post-bootstrap") {
    if (-not (Test-Path $registryPath)) {
        Add-Check -Name "agent-registry" -Status "FAIL" -Detail "缺失"
        Add-Finding -Severity "error" -Code "TEAM-001" -Title "agent-registry 缺失" -Detail "post-bootstrap 模式下未找到 harness/agent-registry.json。" -Recommendation "运行 team provisioning，生成 registry。"
    }
    else {
        Add-Check -Name "agent-registry" -Status "PASS" -Detail $registryPath
    }

    if (-not (Test-Path $manifestPath)) {
        Add-Check -Name "team manifest" -Status "FAIL" -Detail "缺失"
        Add-Finding -Severity "error" -Code "TEAM-002" -Title "team manifest 缺失" -Detail "post-bootstrap 模式下未找到 harness/team-manifest.default.json。" -Recommendation "生成默认团队清单，确保与 agents/ roster 同步。"
    }
    else {
        Add-Check -Name "team manifest" -Status "PASS" -Detail $manifestPath
    }

    $sessionSetupPath = Join-Path $DocsDir "SESSION_SETUP.md"
    if (-not (Test-Path $sessionSetupPath)) {
        Add-Check -Name "SESSION_SETUP" -Status "FAIL" -Detail "缺失"
        Add-Finding -Severity "error" -Code "TEAM-003" -Title "SESSION_SETUP 缺失" -Detail "post-bootstrap 未生成 docs/SESSION_SETUP.md。" -Recommendation "运行 Invoke-PlatformAdapter.ps1 或 bootstrap -ProvisionTeam。"
    }
    else {
        Add-Check -Name "SESSION_SETUP" -Status "PASS" -Detail $sessionSetupPath
    }

    $mailboxReadme = Join-Path $HarnessDir "mailbox/README.md"
    if (-not (Test-Path $mailboxReadme)) {
        Add-Check -Name "mailbox README" -Status "FAIL" -Detail "缺失"
        Add-Finding -Severity "error" -Code "TEAM-004" -Title "mailbox 协议缺失" -Detail "harness/mailbox/README.md 不存在。" -Recommendation "补齐 mailbox 协议文档。"
    }
    else {
        Add-Check -Name "mailbox README" -Status "PASS" -Detail $mailboxReadme
    }

    $bindingPath = Join-Path $HarnessDir "platform-binding.json"
    if (-not (Test-Path $bindingPath)) {
        Add-Check -Name "platform-binding" -Status "FAIL" -Detail "缺失"
        Add-Finding -Severity "error" -Code "PAL-001" -Title "platform-binding 缺失" -Detail "未找到 harness/platform-binding.json。" -Recommendation "运行 Invoke-PlatformAdapter.ps1。"
    }
    else {
        try {
            $binding = Get-Content $bindingPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($binding.adapter_status -ne "installed") {
                Add-Check -Name "platform-binding" -Status "WARN" -Detail "adapter_status=$($binding.adapter_status)"
                Add-Finding -Severity "warning" -Code "PAL-002" -Title "平台适配器未完整安装" -Detail "platform-binding.adapter_status 不是 installed。" -Recommendation "重新运行 PAL Install。"
            }
            else {
                Add-Check -Name "platform-binding" -Status "PASS" -Detail "platform=$($binding.platform)"
            }
        }
        catch {
            Add-Check -Name "platform-binding" -Status "FAIL" -Detail $_.Exception.Message
            Add-Finding -Severity "error" -Code "PAL-003" -Title "platform-binding 解析失败" -Detail $_.Exception.Message -Recommendation "修复 JSON 格式。"
        }
    }

    $workerMissingBoundary = @()
    if (Test-Path $agentsPath) {
        Get-ChildItem -Path $agentsPath -Filter "*.md" -File | ForEach-Object {
            if ($_.BaseName -eq "orchestrator") { return }
            $text = Get-Content $_.FullName -Raw -Encoding UTF8
            if ($text -notmatch "会话边界（Worker 硬约束）") {
                $workerMissingBoundary += $_.BaseName
            }
        }
    }
    if ($workerMissingBoundary.Count -gt 0) {
        Add-Check -Name "worker 会话边界" -Status "FAIL" -Detail ($workerMissingBoundary -join ", ")
        Add-Finding -Severity "error" -Code "WORKER-001" -Title "worker 边界未注入" -Detail "以下 worker 缺少会话边界块: $($workerMissingBoundary -join ', ')" -Recommendation "运行 Apply-WorkerBoundaryToAgents.ps1。"
    }
    else {
        Add-Check -Name "worker 会话边界" -Status "PASS" -Detail "all workers"
    }
}
else {
    if (-not (Test-Path $registryPath)) {
        Add-Check -Name "agent-registry" -Status "WARN" -Detail "缺失"
        Add-Finding -Severity "warning" -Code "TEAM-003" -Title "agent-registry 尚未生成" -Detail "当前处于 baseline 检查，registry 未生成属于预期缺口。" -Recommendation "后续通过 Build-AgentRegistryFromAgentsDir.ps1 生成 registry。"
    }
    else {
        Add-Check -Name "agent-registry" -Status "PASS" -Detail $registryPath
    }
}

$gitAvailable = $null -ne (Get-Command git -ErrorAction SilentlyContinue)
if ($gitAvailable) {
    Push-Location $ProjectRoot
    try {
        $insideRepo = (git rev-parse --is-inside-work-tree 2>$null)
        if ($insideRepo -eq "true") {
            $statusLines = @(git status --porcelain 2>$null)
            if ($statusLines.Count -gt 0) {
                Add-Check -Name "Git 工作区" -Status "WARN" -Detail "$($statusLines.Count) dirty entries"

                $today = Get-Date -Format "yyyy-MM-dd"
                if ($latestLedgerDate -ne $today) {
                    Add-Finding -Severity "warning" -Code "LEDGER-002" -Title "脏工作区缺少当日台账" -Detail "检测到 Git 未提交变更，但最新台账日期不是今天。" -Recommendation "在 §5 追加今日条目，记录本轮实现/测试/决策。"
                }
            }
            else {
                Add-Check -Name "Git 工作区" -Status "PASS" -Detail "clean"
            }
        }
        else {
            Add-Check -Name "Git 工作区" -Status "WARN" -Detail "not a git repo"
        }
    }
    finally {
        Pop-Location
    }
}
else {
    Add-Check -Name "Git 工具" -Status "WARN" -Detail "git unavailable"
}

$qaProjectStatusPath = Join-Path $ProjectRoot "apps/quant_assistant/docs/PROJECT_STATUS.md"
$qaProjectStatusText = Get-FileText -Path $qaProjectStatusPath
if ($null -eq $qaProjectStatusText) {
    Add-Check -Name "QA PROJECT_STATUS §5" -Status "WARN" -Detail "apps/quant_assistant/docs/PROJECT_STATUS.md missing"
    Add-Finding -Severity "warning" -Code "LEDGER-003" -Title "业务台账缺失" -Detail "quant_assistant PROJECT_STATUS 未找到。" -Recommendation "同步 apps/quant_assistant/docs/PROJECT_STATUS.md §5。"
}
elseif ($qaProjectStatusText -notmatch '### 5\.\d+') {
    Add-Check -Name "QA PROJECT_STATUS §5" -Status "WARN" -Detail "no §5 entries"
    Add-Finding -Severity "warning" -Code "LEDGER-004" -Title "业务 §5 无条目" -Detail "未找到 ### 5.x 台账节。" -Recommendation "每轮 Loop 追加 §5 条目。"
}
else {
    Add-Check -Name "QA PROJECT_STATUS §5" -Status "PASS" -Detail $qaProjectStatusPath
}

$methodologyPath = Join-Path $ProjectRoot "apps/quant_assistant/docs/METHODOLOGY_MEMORY.md"
$methodologyText = Get-FileText -Path $methodologyPath
if ($null -eq $methodologyText) {
    Add-Check -Name "METHODOLOGY_MEMORY" -Status "FAIL" -Detail "missing"
    Add-Finding -Severity "error" -Code "MEM-001" -Title "方法论真源缺失" -Detail "METHODOLOGY_MEMORY.md 不存在。" -Recommendation "创建并每轮复盘。"
}
elseif ($methodologyText -notmatch '## 轮次-') {
    Add-Check -Name "METHODOLOGY 轮次复盘" -Status "WARN" -Detail "no round sections"
    Add-Finding -Severity "warning" -Code "MEM-002" -Title "无轮次复盘节" -Detail "METHODOLOGY_MEMORY 缺少 ## 轮次- 节。" -Recommendation "每轮 Loop 追加复盘。"
}
else {
    Add-Check -Name "METHODOLOGY 轮次复盘" -Status "PASS" -Detail "rounds present"
}

$loopStatePath = Join-Path $HarnessDir "loop-state.json"
$loopStateText = Get-FileText -Path $loopStatePath
if ($null -eq $loopStateText) {
    Add-Check -Name "loop-state" -Status "WARN" -Detail "missing"
    Add-Finding -Severity "warning" -Code "LOOP-001" -Title "Loop 机器态缺失" -Detail "harness/loop-state.json 不存在。" -Recommendation "创建并维护 next_atomic_action。"
}
else {
    try {
        $loopState = $loopStateText | ConvertFrom-Json
        $nextAction = [string]$loopState.next_atomic_action
        if ([string]::IsNullOrWhiteSpace($nextAction)) {
            Add-Check -Name "loop-state next action" -Status "WARN" -Detail "empty next_atomic_action"
            Add-Finding -Severity "warning" -Code "LOOP-002" -Title "Loop 无下一动作" -Detail "loop-state.json 未设置 next_atomic_action。" -Recommendation "每轮 tick 后更新。"
        }
        else {
            Add-Check -Name "loop-state next action" -Status "PASS" -Detail $nextAction.Substring(0, [Math]::Min(80, $nextAction.Length))
        }
    }
    catch {
        Add-Check -Name "loop-state JSON" -Status "FAIL" -Detail $_.Exception.Message
        Add-Finding -Severity "error" -Code "LOOP-003" -Title "loop-state 解析失败" -Detail $_.Exception.Message -Recommendation "修复 JSON。"
    }
}

$memIndexPath = Join-Path $HarnessDir "methodology-memory-index.json"
if (-not (Test-Path $memIndexPath)) {
    Add-Check -Name "methodology-memory-index" -Status "WARN" -Detail "missing"
    Add-Finding -Severity "warning" -Code "MEM-003" -Title "方法论索引未生成" -Detail "运行 methodology_memory_lifecycle.py --apply。" -Recommendation "python harness/methodology_memory_lifecycle.py run --apply"
}
else {
    Add-Check -Name "methodology-memory-index" -Status "PASS" -Detail $memIndexPath
}

$memIndexText = Get-FileText -Path $memIndexPath
$lastLifecycleAt = $null
if (-not [string]::IsNullOrWhiteSpace($memIndexText)) {
    try {
        $memIndex = $memIndexText | ConvertFrom-Json
        if ($memIndex.PSObject.Properties.Name -contains "last_lifecycle") {
            $lastLifecycleAt = [string]$memIndex.last_lifecycle.at
        }
    }
    catch {
        Add-Check -Name "methodology-memory-index JSON" -Status "WARN" -Detail $_.Exception.Message
    }
}

if ([string]::IsNullOrWhiteSpace($lastLifecycleAt)) {
    Add-Check -Name "MEM-004 last_lifecycle" -Status "WARN" -Detail "last_lifecycle.at missing"
    Add-Finding -Severity "warning" -Code "MEM-004" -Title "方法论 lifecycle 未记录" -Detail "methodology-memory-index.json 缺少 last_lifecycle.at。" -Recommendation "python harness/methodology_memory_lifecycle.py run --apply"
}
else {
    try {
        $lifecycleTime = [datetime]::Parse($lastLifecycleAt.Replace("Z", "+00:00"))
        $ageHours = ((Get-Date).ToUniversalTime() - $lifecycleTime.ToUniversalTime()).TotalHours
        $gitDirty = $false
        if ($gitAvailable) {
            Push-Location $ProjectRoot
            try {
                $insideRepo = (git rev-parse --is-inside-work-tree 2>$null)
                if ($insideRepo -eq "true") {
                    $statusLines = @(git status --porcelain 2>$null)
                    $gitDirty = $statusLines.Count -gt 0
                }
            }
            finally {
                Pop-Location
            }
        }
        if ($ageHours -gt 24) {
            $checkStatus = "WARN"
            Add-Check -Name "MEM-004 last_lifecycle freshness" -Status $checkStatus -Detail "age=${ageHours}h dirty=$gitDirty at=$lastLifecycleAt"
            $detail = "last_lifecycle.at=$lastLifecycleAt exceeds 24h threshold."
            if ($gitDirty) {
                $detail += " Git working tree has uncommitted changes."
            }
            Add-Finding -Severity "warning" -Code "MEM-004" -Title "methodology lifecycle index stale" -Detail $detail -Recommendation "Run python harness/methodology_memory_lifecycle.py run --apply each loop tick (loop_tick prepare/advance wired)."
        }
        else {
            Add-Check -Name "MEM-004 last_lifecycle freshness" -Status "PASS" -Detail "at=$lastLifecycleAt age=${ageHours}h"
        }
    }
    catch {
        Add-Check -Name "MEM-004 last_lifecycle parse" -Status "WARN" -Detail $_.Exception.Message
        Add-Finding -Severity "warning" -Code "MEM-004" -Title "last_lifecycle 时间不可解析" -Detail $_.Exception.Message -Recommendation "重新运行 methodology_memory_lifecycle.py run --apply"
    }
}

$workReportsIndexPath = Join-Path $HarnessDir "work-reports-index.json"
$orchestratorReportPath = Join-Path $HarnessDir "reports/orchestrator/latest.md"
$workersReportDir = Join-Path $HarnessDir "reports/workers"
if (-not (Test-Path $orchestratorReportPath)) {
    Add-Check -Name "orchestrator-work-report" -Status "WARN" -Detail "missing latest.md"
    Add-Finding -Severity "warning" -Code "LOOP-005" -Title "Orchestrator 工作汇报缺失" -Detail "harness/reports/orchestrator/latest.md 不存在。" -Recommendation "python harness/work_report_lifecycle.py run --apply"
}
else {
    Add-Check -Name "orchestrator-work-report" -Status "PASS" -Detail $orchestratorReportPath
}
if (-not (Test-Path $workersReportDir)) {
    Add-Check -Name "worker-work-reports" -Status "WARN" -Detail "missing workers dir"
    Add-Finding -Severity "warning" -Code "LOOP-005" -Title "Worker 工作汇报目录缺失" -Detail "harness/reports/workers 不存在。" -Recommendation "python harness/work_report_lifecycle.py run --apply"
}
else {
    $workerFiles = @(Get-ChildItem -Path $workersReportDir -Filter "*.md" -File -ErrorAction SilentlyContinue)
    if ($workerFiles.Count -lt 21) {
        Add-Check -Name "worker-work-reports" -Status "WARN" -Detail "count=$($workerFiles.Count)/21"
        Add-Finding -Severity "warning" -Code "LOOP-005" -Title "Worker 汇报不完整" -Detail "期望 21 个 worker 报告，当前 $($workerFiles.Count) 个。" -Recommendation "python harness/work_report_lifecycle.py run --apply"
    }
    else {
        Add-Check -Name "worker-work-reports" -Status "PASS" -Detail "count=$($workerFiles.Count)"
    }
}
if (-not (Test-Path $workReportsIndexPath)) {
    Add-Check -Name "work-reports-index" -Status "WARN" -Detail "missing"
    Add-Finding -Severity "warning" -Code "LOOP-005" -Title "工作汇报索引未生成" -Detail "运行 work_report_lifecycle.py --apply。" -Recommendation "python harness/work_report_lifecycle.py run --apply"
}
else {
    Add-Check -Name "work-reports-index" -Status "PASS" -Detail $workReportsIndexPath
}

function Test-LifecycleIndexFreshness {
    param(
        [string]$IndexPath,
        [string]$CheckName,
        [string]$Code,
        [string]$Recommendation
    )

    if (-not (Test-Path $IndexPath)) {
        Add-Check -Name $CheckName -Status "WARN" -Detail "missing"
        Add-Finding -Severity "warning" -Code $Code -Title "$CheckName 索引未生成" -Detail "缺少 $IndexPath" -Recommendation $Recommendation
        return
    }

    Add-Check -Name $CheckName -Status "PASS" -Detail $IndexPath
    $text = Get-FileText -Path $IndexPath
    if ([string]::IsNullOrWhiteSpace($text)) { return }

    try {
        $index = $text | ConvertFrom-Json
        $lastAt = $null
        if ($index.PSObject.Properties.Name -contains "last_lifecycle") {
            $lastAt = [string]$index.last_lifecycle.at
        }
        if ([string]::IsNullOrWhiteSpace($lastAt)) {
            Add-Check -Name "$Code last_lifecycle" -Status "WARN" -Detail "missing at"
            Add-Finding -Severity "warning" -Code $Code -Title "$CheckName 未记录 last_lifecycle" -Detail "$IndexPath 缺少 last_lifecycle.at" -Recommendation $Recommendation
            return
        }
        $lifecycleTime = [datetime]::Parse($lastAt.Replace("Z", "+00:00"))
        $ageHours = ((Get-Date).ToUniversalTime() - $lifecycleTime.ToUniversalTime()).TotalHours
        $gitDirty = $false
        if ($gitAvailable) {
            Push-Location $ProjectRoot
            try {
                if ((git rev-parse --is-inside-work-tree 2>$null) -eq "true") {
                    $gitDirty = @(git status --porcelain 2>$null).Count -gt 0
                }
            }
            finally { Pop-Location }
        }
        if ($ageHours -gt 24) {
            Add-Check -Name "$Code freshness" -Status "WARN" -Detail "age=${ageHours}h dirty=$gitDirty"
            $detail = "last_lifecycle.at=$lastAt exceeds 24h."
            if ($gitDirty) { $detail += " Git dirty." }
            Add-Finding -Severity "warning" -Code $Code -Title "$CheckName stale" -Detail $detail -Recommendation $Recommendation
        }
        else {
            Add-Check -Name "$Code freshness" -Status "PASS" -Detail "at=$lastAt age=${ageHours}h"
        }
    }
    catch {
        Add-Check -Name "$Code parse" -Status "WARN" -Detail $_.Exception.Message
        Add-Finding -Severity "warning" -Code $Code -Title "$CheckName 解析失败" -Detail $_.Exception.Message -Recommendation $Recommendation
    }
}

$syncIndexPath = Join-Path $HarnessDir "sync-coherence-index.json"
Test-LifecycleIndexFreshness -IndexPath $syncIndexPath -CheckName "sync-coherence-index" -Code "SYNC-001" -Recommendation "python harness/sync_coherence_lifecycle.py run --apply"

$verIndexPath = Join-Path $HarnessDir "verification-snapshot-index.json"
Test-LifecycleIndexFreshness -IndexPath $verIndexPath -CheckName "verification-snapshot-index" -Code "VER-001" -Recommendation "python harness/verification_snapshot_lifecycle.py run --apply"

$cloIndexPath = Join-Path $HarnessDir "closure-gate-index.json"
Test-LifecycleIndexFreshness -IndexPath $cloIndexPath -CheckName "closure-gate-index" -Code "CLO-001" -Recommendation "python harness/closure_gate_lifecycle.py run --apply"

$syncIndexText = Get-FileText -Path $syncIndexPath
if (-not [string]::IsNullOrWhiteSpace($syncIndexText)) {
    try {
        $syncIndex = $syncIndexText | ConvertFrom-Json
        $warnCount = 0
        if ($syncIndex.PSObject.Properties.Name -contains "findings") {
            foreach ($f in @($syncIndex.findings)) {
                if ($f.severity -eq "warning") { $warnCount++ }
            }
        }
        if ($warnCount -gt 0) {
            Add-Check -Name "SYNC coherence drift" -Status "WARN" -Detail "warnings=$warnCount"
            Add-Finding -Severity "warning" -Code "SYNC-002" -Title "五真源漂移" -Detail "sync-coherence-index 含 $warnCount 条 warning" -Recommendation "更新 PROJECT_STATUS 顶部现状概述并与 loop-state/CONTINUATION 对齐"
        }
        else {
            Add-Check -Name "SYNC coherence drift" -Status "PASS" -Detail "no warnings"
        }
    }
    catch { }
}

$cloIndexText = Get-FileText -Path $cloIndexPath
if (-not [string]::IsNullOrWhiteSpace($cloIndexText)) {
    try {
        $cloIndex = $cloIndexText | ConvertFrom-Json
        $openCount = 0
        if ($cloIndex.PSObject.Properties.Name -contains "open_count") {
            $openCount = [int]$cloIndex.open_count
        }
        if ($openCount -gt 0) {
            Add-Check -Name "CLO closure candidates" -Status "WARN" -Detail "open=$openCount"
            Add-Finding -Severity "warning" -Code "CLO-002" -Title "收口候选未闭合" -Detail "closure-gate-index open_count=$openCount" -Recommendation "补 synthesis-* 或显式 没有"
        }
        else {
            Add-Check -Name "CLO closure candidates" -Status "PASS" -Detail "open=0"
        }
    }
    catch { }
}

$report = [pscustomobject]@{
    mode = $Mode
    projectRoot = $ProjectRoot
    checkedAt = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    summary = [pscustomobject]@{
        checks = $Checks.Count
        findings = $Findings.Count
        pass = @($Checks | Where-Object { $_.status -eq "PASS" }).Count
        warn = @($Checks | Where-Object { $_.status -eq "WARN" }).Count
        fail = @($Checks | Where-Object { $_.status -eq "FAIL" }).Count
    }
    checks = $Checks
    findings = $Findings
}

switch ($Format) {
    "json" {
        $report | ConvertTo-Json -Depth 6
    }
    "markdown" {
        "# Compliance Report"
        ""
        "- Mode: $($report.mode)"
        "- Project: $($report.projectRoot)"
        "- Checked At: $($report.checkedAt)"
        "- Checks: $($report.summary.checks) / Findings: $($report.summary.findings)"
        ""
        "## Checks"
        ""
        "| Name | Status | Detail |"
        "|------|--------|--------|"
        foreach ($check in $Checks) {
            "| $($check.name) | $($check.status) | $($check.detail) |"
        }
        ""
        "## Findings"
        ""
        "| Severity | Code | Title | Detail | Recommendation |"
        "|----------|------|-------|--------|----------------|"
        foreach ($finding in $Findings) {
            "| $($finding.severity) | $($finding.code) | $($finding.title) | $($finding.detail) | $($finding.recommendation) |"
        }
    }
    default {
        if (-not $Quiet) {
            Write-Host ""
            Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host "  Raindeer-AWI Compliance Check" -ForegroundColor Cyan
            Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "模式: $Mode" -ForegroundColor White
            Write-Host "项目: $ProjectRoot" -ForegroundColor Gray
            Write-Host "时间: $($report.checkedAt)" -ForegroundColor Gray
            Write-Host ""

            foreach ($check in $Checks) {
                $color = switch ($check.status) {
                    "PASS" { "Green" }
                    "WARN" { "Yellow" }
                    "FAIL" { "Red" }
                    default { "White" }
                }
                Write-Host ("[{0}] {1} — {2}" -f $check.status, $check.name, $check.detail) -ForegroundColor $color
            }

            if ($Findings.Count -gt 0) {
                Write-Host ""
                Write-Host "Findings:" -ForegroundColor Yellow
                foreach ($finding in $Findings) {
                    Write-Host ("- [{0}] {1}: {2}" -f $finding.code, $finding.title, $finding.detail) -ForegroundColor Yellow
                    Write-Host ("  → {0}" -f $finding.recommendation) -ForegroundColor DarkYellow
                }
            }

            Write-Host ""
            Write-Host ("Summary: pass={0} warn={1} fail={2} findings={3}" -f $report.summary.pass, $report.summary.warn, $report.summary.fail, $report.summary.findings) -ForegroundColor White
            Write-Host ""
        }
    }
}

if ($Findings.Count -gt 0) {
    exit 1
}

exit 0
