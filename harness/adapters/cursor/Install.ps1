param(
    [string]$TargetPath = (Get-Location).Path
)

$ProjectRoot = (Resolve-Path $TargetPath).Path
$cursorDir = Join-Path $ProjectRoot ".cursor"
$rulesDir = Join-Path $cursorDir "rules"

New-Item -ItemType Directory -Path $rulesDir -Force | Out-Null

# hooks.json 已由仓库提供；确保 harness hooks 存在
$hooksJson = Join-Path $cursorDir "hooks.json"
if (-not (Test-Path $hooksJson)) {
    Copy-Item -Path (Join-Path $ProjectRoot "harness/adapters/cursor/hooks.json.template") -Destination $hooksJson -ErrorAction SilentlyContinue
}

# 复制 orchestrator/worker 规则（若 bootstrap 未复制）
$srcRules = @("raindeer-awi-orchestrator.mdc", "raindeer-awi-worker.mdc")
foreach ($r in $srcRules) {
    $src = Join-Path $ProjectRoot ".cursor/rules/$r"
    if (Test-Path $src) { continue }
}

& (Join-Path $PSScriptRoot "..\generic\Install.ps1") -TargetPath $ProjectRoot | Out-Null

[pscustomobject]@{
    adapter = "cursor"
    hooks = ".cursor/hooks.json"
    rules = ".cursor/rules/raindeer-awi-*.mdc"
} | ConvertTo-Json
