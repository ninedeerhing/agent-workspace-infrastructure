param(
    [int]$ContextPercent = 0,
    [string]$TargetPath = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
)

$budgetPath = Join-Path $TargetPath "harness/token-budget.json"
if (-not (Test-Path $budgetPath)) { exit 0 }

$budget = Get-Content $budgetPath -Raw -Encoding UTF8 | ConvertFrom-Json
$warn = [int]$budget.thresholds.warn_percent
$handoff = [int]$budget.thresholds.handoff_percent

$message = $null
if ($ContextPercent -ge $handoff) {
    $skills = ($budget.skills.handoff -join ", ")
    $message = "[Raindeer-AWI Token] 上下文 >= ${handoff}%。自动触发: $skills。请执行 handoff 并更新 session-handoff.md。"
}
elseif ($ContextPercent -ge $warn) {
    $skills = ($budget.skills.warn -join ", ")
    $message = "[Raindeer-AWI Token] 上下文 >= ${warn}%。建议触发: $skills。"
}

if ($message) {
    @{ additional_context = $message } | ConvertTo-Json -Compress
}
