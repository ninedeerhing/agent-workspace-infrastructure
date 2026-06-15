param([string]$InputObject = $null)

# postToolUse / afterFileEdit 提醒 — 脏工作区时提示更新 §5 台账
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$git = Get-Command git -ErrorAction SilentlyContinue

if (-not $git) {
    exit 0
}

Push-Location $ProjectRoot
try {
    $dirty = git status --porcelain 2>$null
    if (-not $dirty) { exit 0 }

    $payload = @{
        additional_context = "[Raindeer-AWI Compliance] 检测到未提交变更。若本回合有实现/测试/决策，请同步 docs/PROJECT_STATUS.md §5 台账。"
    } | ConvertTo-Json -Compress

    Write-Output $payload
}
finally {
    Pop-Location
}
exit 0
