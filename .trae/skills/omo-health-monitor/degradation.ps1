# degradation.ps1 — OMO Health Monitor 降级检测与响应
param(
    [ValidateSet("check", "watch")]
    [string]$Action = "check",
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptDir "..\..\..")
$HarnessDir = Join-Path $ProjectRoot "harness"
$HealthLogPath = Join-Path $HarnessDir "health-log.json"
$DegradationStatePath = Join-Path $HarnessDir "degradation-state.json"

function Write-Colored {
    param([string]$T, [string]$C="White")
    if (-not $Quiet) { Write-Host $T -ForegroundColor $C }
}

function Read-JsonSafe {
    param([string]$P, $D=$null)
    if (-not (Test-Path $P)) { return $D }
    try { $c=Get-Content $P -Raw -Encoding UTF8; if([string]::IsNullOrWhiteSpace($c)){return $D}; return $c|ConvertFrom-Json } catch { return $D }
}

function Get-LatestSnapshot {
    $l=Read-JsonSafe $HealthLogPath
    if(-not $l -or -not $l.entries -or $l.entries.Count -eq 0){return $null}
    return $l.entries[-1]
}

function Get-DegradationState {
    $ds=Read-JsonSafe $DegradationStatePath
    if(-not $ds){ $ds=@{version="1.0.0"; current_level="HEALTHY"; level_history=@(); degraded_since=$null; recovery_count=0; last_check=$null} }
    return $ds
}

function Save-DegradationState {
    param($S)
    $d=Split-Path $DegradationStatePath -Parent
    if(-not(Test-Path $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}
    $j=$S|ConvertTo-Json -Depth 10
    $e=New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($DegradationStatePath, $j, $e)
}

function Get-LevelColor {
    param([string]$L)
    switch($L){
        "HEALTHY" { return "Green" }
        "WARNING" { return "Yellow" }
        "DEGRADED" { return "Yellow" }
        "CRITICAL" { return "Red" }
        default { return "White" }
    }
}

function Invoke-DegradationCheck {
    $s=Get-LatestSnapshot
    if(-not $s){Write-Colored "[!] No health snapshot. Run heartbeat.ps1 first." "Yellow"; return $null}
    
    $st=Get-DegradationState
    $cl=$s.level; $pl=$st.current_level; $now=Get-Date
    
    Write-Colored ""; Write-Colored "=== Degradation Check ===" "Cyan"
    Write-Colored "  Score: $($s.health_score)/100  Level: $cl" $(Get-LevelColor $cl)
    
    $lo=@{"HEALTHY"=1;"WARNING"=2;"DEGRADED"=3;"CRITICAL"=4}
    $lchg=$cl -ne $pl
    $dg=$false; $rc=$false
    
    if($lchg){
        if($lo[$cl] -gt $lo[$pl]){$dg=$true; Write-Colored "  [DEGRADE] $pl -> $cl" "Red"}
        else{$rc=$true; Write-Colored "  [RECOVER] $pl -> $cl" "Green"}
    }else{Write-Colored "  Level stable: $cl" "Gray"}
    
    $actions=@()
    $blockNew=$false; $summary=""
    switch($cl){
        "HEALTHY"{$actions=@("continue_normal"); $blockNew=$false; $summary="Normal"}
        "WARNING"{$actions=@("log_warning","suggest_token_opt","flag_slow_dims"); $blockNew=$false; $summary="Caution"}
        "DEGRADED"{$actions=@("log_degraded","recommend_handoff","check_errors","reduce_parallel"); $blockNew=$false; $summary="Degraded"}
        "CRITICAL"{$actions=@("log_critical","pause_new_tasks","force_handoff","escalate","trigger_self_heal"); $blockNew=$true; $summary="CRITICAL"}
        default{$actions=@("unknown"); $blockNew=$false; $summary="Unknown"}
    }
    
    $ev=@{
        timestamp=$now.ToString("yyyy-MM-ddTHH:mm:sszzz")
        previous_level=$pl; current_level=$cl
        health_score=$s.health_score
        is_degrading=$dg; is_recovering=$rc
        strategy_applied=$actions; block_new_tasks=$blockNew
        dimension_scores=@{
            agent=$s.dimensions.agent.score
            task=$s.dimensions.task.score
            resource=$s.dimensions.resource.score
            error=$s.dimensions.error.score
        }
    }
    
    $st.current_level=$cl; $st.last_check=$now.ToString("yyyy-MM-ddTHH:mm:sszzz")
    $st.level_history+=$ev
    if($dg){$st.degraded_since=$now.ToString("yyyy-MM-ddTHH:mm:sszzz")}
    elseif($rc -and $cl -eq "HEALTHY"){$st.degraded_since=$null; $st.recovery_count++}
    if($st.level_history.Count -gt 20){$st.level_history=$st.level_history[-20..-1]}
    Save-DegradationState $st
    
    Write-Colored ""; Write-Colored "  Strategy: $summary" "White"
    Write-Colored "  Actions: $($actions -join ', ')" "Gray"
    if($blockNew){Write-Colored "  [BLOCKED] New tasks blocked at CRITICAL!" "Red"}
    
    Write-Colored ""; Write-Colored "  Dims: A=$($s.dimensions.agent.score) T=$($s.dimensions.task.score) R=$($s.dimensions.resource.score) E=$($s.dimensions.error.score)" "Gray"
    
    return @{snapshot=$s; event=$ev; state=$st}
}

function Main {
    switch($Action){
        "check"{Invoke-DegradationCheck}
        "watch"{Write-Colored "Watch mode not in single-run" "Yellow"; Invoke-DegradationCheck}
    }
}

Main
