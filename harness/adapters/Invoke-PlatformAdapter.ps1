<#
.SYNOPSIS
    平台适配器调度：auto | generic | cursor | codex | claude-code | trae
#>
param(
    [string]$TargetPath = (Get-Location).Path,
    [ValidateSet("auto","generic","cursor","codex","claude-code","trae")]
    [string]$Platform = "auto",
    [string]$HubModel = "opus"
)

$ProjectRoot = (Resolve-Path $TargetPath).Path
$HarnessDir = Join-Path $ProjectRoot "harness"
$AdaptersRoot = Join-Path $HarnessDir "adapters"

function Detect-Platform {
    if ($env:CURSOR_TRACE_ID -or (Test-Path (Join-Path $ProjectRoot ".cursor"))) { return "cursor" }
    if ($env:TRAE_IDE -or (Test-Path (Join-Path $ProjectRoot ".trae"))) { return "trae" }
    if ($env:CODEX_HOME) { return "codex" }
    if ($env:CLAUDE_CODE) { return "claude-code" }
    return "generic"
}

if ($Platform -eq "auto") {
    $Platform = Detect-Platform
}

$installScript = Join-Path $AdaptersRoot "$Platform/Install.ps1"
if (-not (Test-Path $installScript)) {
    $Platform = "generic"
    $installScript = Join-Path $AdaptersRoot "generic/Install.ps1"
}

$result = & $installScript -TargetPath $ProjectRoot -HubModel $HubModel

$binding = [ordered]@{
    version = "0.1.0"
    generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    platform = $Platform
    adapter_path = "harness/adapters/$Platform"
    adapter_status = "installed"
    hub_model = $HubModel
    notes = @("generic mailbox baseline always available")
}

$binding | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $HarnessDir "platform-binding.json") -Encoding UTF8

[pscustomobject]@{
    platform = $Platform
    adapter_result = $result
    binding = "harness/platform-binding.json"
} | ConvertTo-Json -Depth 4
