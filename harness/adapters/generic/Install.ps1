param(
    [string]$TargetPath = (Get-Location).Path,
    [string]$HubModel = "opus"
)

$ProjectRoot = (Resolve-Path $TargetPath).Path
$HarnessDir = Join-Path $ProjectRoot "harness"
$registryPath = Join-Path $HarnessDir "agent-registry.json"

if (-not (Test-Path $registryPath)) {
    & (Join-Path $HarnessDir "scripts/Build-AgentRegistryFromAgentsDir.ps1") -TargetPath $ProjectRoot -HubModel $HubModel -WriteFiles -EnsureScaffold | Out-Null
}

$registry = Get-Content $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$setupPath = Join-Path $ProjectRoot "docs/SESSION_SETUP.md"

$lines = @(
    "# Session Setup Checklist (Generic Platform)",
    "",
    "导入后请在本 IDE 中创建以下会话（名称与模型见 registry）：",
    "",
    "| 会话名 | role_id | kind | model | 源文件 |",
    "|--------|---------|------|-------|--------|"
)

foreach ($role in $registry.roles) {
    $userNote = if ($role.user_facing) { " ← **唯一对用户**" } else { "" }
    $lines += "| $($role.session_name) | $($role.role_id) | $($role.kind) | $($role.model) | $($role.source_file)$userNote |"
}

$lines += @(
    "",
    "## 使用方式",
    "",
    "1. 日常只打开 **orchestrator** 会话。",
    '2. 将 harness/templates/orchestrator-init-prompt.md 粘贴到 orchestrator 首条消息。',
    '3. 各 worker 会话粘贴 harness/templates/worker-init-prompt.md（替换 ROLE_ID）。',
    '4. Agent 协作通过 harness/mailbox/ 文件总线。',
    "",
    "## 验证",
    "",
    '```powershell',
    '.\harness\compliance-check.ps1 -Mode post-bootstrap',
    '```'
)

$lines -join "`n" | Out-File -FilePath $setupPath -Encoding utf8

[pscustomobject]@{
    adapter = "generic"
    session_setup = "docs/SESSION_SETUP.md"
    role_count = $registry.role_count
} | ConvertTo-Json
