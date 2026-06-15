<#
.SYNOPSIS
    轻量工作流门禁检查器。验证阶段跳转是否合法、所需 gate 是否已记录。
.EXAMPLE
    .\gate-runner.ps1 -Workflow standard -FromPhase RESEARCH -ToPhase EXECUTE
#>
param(
    [ValidateSet("standard","complex","product","tdd")][string]$Workflow = "standard",
    [Parameter(Mandatory = $true)][string]$FromPhase,
    [Parameter(Mandatory = $true)][string]$ToPhase,
    [string]$TargetPath = "",
    [ValidateSet("text","json")][string]$Format = "text"
)

$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    $TargetPath = Split-Path -Parent $ScriptRoot
}

$ProjectRoot = (Resolve-Path $TargetPath).Path
$statePath = Join-Path $ProjectRoot "harness/workflow-state.json"

$phaseOrders = @{
    standard = @("INTAKE","RESEARCH","PLAN","EXECUTE","REVIEW","VERIFY","HANDOFF")
    complex = @("DEEP_INTERVIEW","CONSENSUS_PLAN","TEAM_EXECUTION","QA_SECURITY_REVIEW","RELEASE_HANDOFF")
    product = @("OFFICE_HOURS","CEO_REVIEW","ENG_REVIEW","DESIGN_REVIEW","BUILD","QA","SHIP","RETRO")
    tdd = @("BRAINSTORMING","WRITING_PLANS","RED","GREEN","REFACTOR","CODE_REVIEW","VERIFY","FINISH")
}

$gateMap = @{
    "INTAKE->RESEARCH" = "G-STD-01"
    "RESEARCH->PLAN" = "G-STD-02"
    "PLAN->EXECUTE" = "G-STD-03"
    "EXECUTE->REVIEW" = "G-STD-04"
    "REVIEW->VERIFY" = "G-STD-05"
    "VERIFY->HANDOFF" = "G-STD-06"
}

$phases = $phaseOrders[$Workflow]
$fromIdx = [array]::IndexOf($phases, $FromPhase.ToUpper())
$toIdx = [array]::IndexOf($phases, $ToPhase.ToUpper())

$findings = @()
$result = "PASS"

if ($fromIdx -lt 0 -or $toIdx -lt 0) {
    $result = "FAIL"
    $findings += "未知阶段: From=$FromPhase To=$ToPhase Workflow=$Workflow"
}
elseif ($toIdx -ne ($fromIdx + 1)) {
    $result = "FAIL"
    $findings += "非法阶段跳转: 不允许从 $FromPhase 直接到 $ToPhase（标准流必须顺序推进）"
}

$transitionKey = ($FromPhase.ToUpper() + '->' + $ToPhase.ToUpper())
$requiredGate = $gateMap[$transitionKey]

$passedGates = @()
if (Test-Path $statePath) {
    try {
        $state = Get-Content $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($state.phase_gate_status.gates) {
            $state.phase_gate_status.gates.PSObject.Properties | ForEach-Object {
                if ($_.Value.result -eq "PASS" -or $_.Value.result -eq "PASS_WITH_WARNING") {
                    $passedGates += $_.Name
                }
            }
        }
    }
    catch { }
}

if ($requiredGate -and ($passedGates -notcontains $requiredGate)) {
    $result = "FAIL"
    $findings += "退出门禁未通过: $requiredGate（需在 workflow-state.json phase_gate_status 中记录 PASS 证据）"
}

$report = [pscustomobject]@{
    workflow = $Workflow
    from = $FromPhase
    to = $ToPhase
    required_gate = $requiredGate
    result = $result
    findings = $findings
}

if ($Format -eq "json") {
    $report | ConvertTo-Json -Depth 4
}
else {
    Write-Host "Gate Runner: $($report.result)"
    Write-Host "Transition: $FromPhase -> $ToPhase"
    if ($requiredGate) { Write-Host "Required gate: $requiredGate" }
    foreach ($f in $findings) { Write-Host "  - $f" -ForegroundColor Yellow }
}

if ($result -eq "FAIL") { exit 1 }
exit 0
