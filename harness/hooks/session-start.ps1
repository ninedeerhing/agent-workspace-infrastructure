param([string]$InputObject = $null)

# Cursor sessionStart hook — 注入 Raindeer-AWI 启动契约
$inputText = if ($InputObject) { $InputObject } else { [Console]::In.ReadToEnd() }

$boot = @"
[Raindeer-AWI Session Boot]
1. 读取 docs/SESSION_BOOT.md
2. 读取 docs/PROJECT_STATUS.md §5-§6 与 docs/TASK_TREES.md 当前主线
3. 读取 harness/workflow-state.json
4. orchestrator 是唯一对用户说话的会话；其余 agents/*.md 均为 worker
5. worker 禁止直接对用户输出；阻塞只上报 orchestrator
6. 有变更必须写 docs/PROJECT_STATUS.md §5 台账
"@

$payload = @{
    additional_context = $boot
} | ConvertTo-Json -Compress

Write-Output $payload
exit 0
