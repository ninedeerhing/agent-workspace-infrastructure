# monitor.ps1 — OMO Health Monitor 主入口编排器
param(
    [ValidateSet("check", "full", "report", "watch")]
    [string]$Action = "check",
    [switch]$Quiet,
    [switch]$AutoHeal,
    [string]$OutputReport = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptDir "..\..\..")
$HarnessDir = Join-Path $ProjectRoot "harness"
$HealthLogPath = Join-Path $HarnessDir "health-log.json"
$DegradationStatePath = Join-Path $HarnessDir "degradation-state.json"

function wc { param($t,$c="White") if(-not$Quiet){Write-Host $t -ForegroundColor $c} }

function rjs { param($p,$d=$null) if(-not(Test-Path $p)){return $d}; try{$c=Get-Content $p -Raw -Enc UTF8; if([string]::IsNullOrWhiteSpace($c)){return $d}; return $c|ConvertFrom-Json}catch{return $d} }

function snap {
    $l=rjs $HealthLogPath
    if(-not$l -or -not$l.entries -or $l.entries.Count -eq 0){return $null}
    return $l.entries[-1]
}

function lc {
    param($l)
    switch($l){
        "HEALTHY" { "Green" }
        "WARNING" { "Yellow" }
        "DEGRADED" { "Yellow" }
        "CRITICAL" { "Red" }
        default { "White" }
    }
}

function run-hb {
    wc ""; wc "--- Heartbeat ---" "Cyan"
    $s=Join-Path $ScriptDir "heartbeat.ps1"
    if(Test-Path $s){& powershell -EP Bypass -File $s -Action collect -Quiet 2>&1|Out-Null}
    else{wc "heartbeat.ps1 not found" "Red"}
}

function run-dg {
    wc ""; wc "--- Degradation ---" "Cyan"
    $s=Join-Path $ScriptDir "degradation.ps1"
    if(Test-Path $s){& powershell -EP Bypass -File $s -Action check -Quiet 2>&1|Out-Null}
    else{wc "degradation.ps1 not found" "Red"}
}

function run-sh {
    wc ""; wc "--- Self-Healing ---" "Cyan"
    $s=Join-Path $ScriptDir "self-healing.ps1"
    if(Test-Path $s){
        if($AutoHeal){& powershell -EP Bypass -File $s -Action heal -AutoApply -Quiet 2>&1|Out-Null}
        else{& powershell -EP Bypass -File $s -Action diagnose -Quiet 2>&1|Out-Null}
    }else{wc "self-healing.ps1 not found" "Red"}
}

function report {
    $s=snap
    if(-not$s){wc "No snapshot" "Yellow"; run-hb; $s=snap; if(-not$s){wc "Still none" "Red"; return}}

    wc ""; wc "=== Health Report ===" "Cyan"
    $lbl = "Overall: $($s.health_score)/100 [$($s.level)]"
    wc $lbl (lc $s.level)
    wc "Time: $($s.timestamp)" "Gray"

    wc ""; wc "-- Dimensions --" "White"
    $dims=$s.dimensions
    foreach($k in @("agent","task","resource","error")){
        $d=$dims.$k; $wp=[math]::Round($s.weights.$k*100)
        $lbl=("  {0} ({1}pct): {2}/100 [{3}]" -f $k,$wp,$d.score,$d.status)
        wc $lbl (lc $d.status)
    }

    if($s.warnings -and $s.warnings.Count -gt 0){
        wc ""; wc "-- Warnings --" "Yellow"
        foreach($w in $s.warnings){wc "  - $w" "Yellow"}
    }
    if($s.blockers -and $s.blockers.Count -gt 0){
        wc ""; wc "-- Blockers --" "Red"
        foreach($b in $s.blockers){wc "  - $b" "Red"}
    }

    $ds=rjs $DegradationStatePath
    if($ds){
        wc ""; wc "-- Degradation --" "White"
        wc "  Level: $($ds.current_level)" "Gray"
        if($ds.degraded_since){wc "  Since: $($ds.degraded_since)" "Yellow"}
    }

    $log=rjs $HealthLogPath
    if($log -and $log.trends){
        wc ""; wc "-- Trends --" "White"
        wc "  Direction: $($log.trends.trend_direction)" "Gray"
        if($log.trends.last_7_scores -and $log.trends.last_7_scores.Count -gt 0){
            $scores=$log.trends.last_7_scores -join ' -> '
            wc "  Last 7: $scores" "Gray"
        }
    }

    if($OutputReport){
        $r="# OMO Health Monitor Report`n"
        $r+="Time: $($s.timestamp)`n`n"
        $r+="## Overall: $($s.health_score)/100 [$($s.level)]`n`n"
        $r+="### Dimensions`n"
        foreach($k in @("agent","task","resource","error")){
            $d=$dims.$k; $wp=[math]::Round($s.weights.$k*100)
            $r+=('- **{0}** ({1}pct): {2}/100 [{3}]`n' -f $k,$wp,$d.score,$d.status)
        }
        $enc=New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($OutputReport,$r,$enc)
        wc ""; wc "Report saved: $OutputReport" "Green"
    }
}

function main {
    wc "OMO Health Monitor v1.0.0" "Cyan"

    switch($Action){
        "check"  { run-hb; run-dg }
        "full"   { run-hb; run-dg; run-sh; report }
        "report" { report }
        "watch"  { wc "Watch mode: run check/full periodically" "Yellow" }
    }
}

main
