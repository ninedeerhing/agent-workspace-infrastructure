param([string]$TargetPath = (Get-Location).Path)

$ProjectRoot = (Resolve-Path $TargetPath).Path
& (Join-Path $PSScriptRoot "..\generic\Install.ps1") -TargetPath $ProjectRoot | Out-Null

$traeRulesDir = Join-Path $ProjectRoot ".trae/rules"
New-Item -ItemType Directory -Path $traeRulesDir -Force | Out-Null

$rulePath = Join-Path $traeRulesDir "raindeer-awi.md"
if (-not (Test-Path $rulePath)) {
    @"
# Raindeer-AWI（Trae）

- orchestrator 是唯一对用户会话
- worker = agents/ 下除 orchestrator 外全部角色
- 启动读 docs/SESSION_BOOT.md
- 协作 harness/mailbox/
"@ | Set-Content -Path $rulePath -Encoding UTF8
}

@{ adapter = "trae"; rules = ".trae/rules/raindeer-awi.md" } | ConvertTo-Json
