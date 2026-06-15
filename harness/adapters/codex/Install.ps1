param([string]$TargetPath = (Get-Location).Path)

$ProjectRoot = (Resolve-Path $TargetPath).Path
& (Join-Path $PSScriptRoot "..\generic\Install.ps1") -TargetPath $ProjectRoot | Out-Null

$note = @"
# Codex Platform Notes

- 跨会话消息：优先使用 Codex 原生 ``send_message``；协议字段与 ``harness/mailbox/README.md`` 对齐。
- 角色注册：``harness/agent-registry.json``
- 用户只对话 orchestrator 会话。
"@

Set-Content -Path (Join-Path $ProjectRoot "docs/PLATFORM-CODEX.md") -Value $note -Encoding UTF8
@{ adapter = "codex"; doc = "docs/PLATFORM-CODEX.md" } | ConvertTo-Json
