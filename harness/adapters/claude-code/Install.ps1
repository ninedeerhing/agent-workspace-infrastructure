param([string]$TargetPath = (Get-Location).Path)

$ProjectRoot = (Resolve-Path $TargetPath).Path
& (Join-Path $PSScriptRoot "..\generic\Install.ps1") -TargetPath $ProjectRoot | Out-Null

$claudePath = Join-Path $ProjectRoot "CLAUDE.md"
if (-not (Test-Path $claudePath)) {
    @"
# Claude Code — Raindeer-AWI

用户只与 **orchestrator** 对话。完整契约见根目录 ``AGENTS.md`` 与 ``docs/SESSION_BOOT.md``。
"@ | Set-Content -Path $claudePath -Encoding UTF8
}

@{ adapter = "claude-code"; doc = "CLAUDE.md" } | ConvertTo-Json
