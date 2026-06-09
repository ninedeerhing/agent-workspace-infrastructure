# heartbeat.ps1 — OMO Health Monitor 心跳采集器
# 版本: 1.0.0  |  平台: Windows PowerShell 5.1+

param(
    [ValidateSet("collect", "score", "report")]
    [string]$Action = "collect",
    [string]$OutputJson = "",
    [switch]$Quiet,
    [string]$HealthLogDir = ""
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillDir = $ScriptDir
$ProjectRoot = Resolve-Path (Join-Path $SkillDir "..\..\..")
$HarnessDir = Join-Path $ProjectRoot "harness"

if ($HealthLogDir) { $HealthLogPath = Join-Path $HealthLogDir "health-log.json" }
else { $HealthLogPath = Join-Path $HarnessDir "health-log.json" }

# ═══════════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════════

function Write-Colored {
    param([string]$Text, [string]$Color = "White")
    if (-not $Quiet) { Write-Host $Text -ForegroundColor $Color }
}

<#
    安全读取 JSON 文件，失败时返回默认值
#>
function Read-JsonSafe {
    param([string]$Path, $Default = $null)
    if (-not (Test-Path $Path)) { return $Default }
    try {
        $content = Get-Content $Path -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($content)) { return $Default }
        return $content | ConvertFrom-Json
    } catch { return $Default }
}

<#
    安全读取文本文件行
#>
function Read-LinesSafe {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return @() }
    try { return @(Get-Content $Path -Encoding UTF8) } catch { return @() }
}

<#
    根据分数返回健康等级：HEALTHY/WARNING/DEGRADED/CRITICAL
#>
function Get-HealthLevel {
    param([double]$Score)
    if ($Score -ge 90) { return "HEALTHY" }
    if ($Score -ge 70) { return "WARNING" }
    if ($Score -ge 50) { return "DEGRADED" }
    return "CRITICAL"
}

<#
    返回健康等级对应的图标
#>
function Get-HealthIcon {
    param([string]$Level)
    switch ($Level) {
        "HEALTHY"  { return "GREEN_CIRCLE" }
        "WARNING"  { return "YELLOW_CIRCLE" }
        "DEGRADED" { return "ORANGE_CIRCLE" }
        "CRITICAL" { return "RED_CIRCLE" }
        default    { return "WHITE_CIRCLE" }
    }
}

<#
    返回健康等级对应的终端颜色
#>
function Get-ColorForLevel {
    param([string]$Level)
    switch ($Level) {
        "HEALTHY"  { return "Green" }
        "WARNING"  { return "Yellow" }
        "DEGRADED" { return "Yellow" }
        "CRITICAL" { return "Red" }
        default    { return "White" }
    }
}

<#
    计算趋势方向：improving / declining / stable
#>
function Compute-TrendDirection {
    param([array]$Scores)
    if ($Scores.Count -lt 2) { return "stable" }
    $mid = [math]::Floor($Scores.Count / 2)
    $firstHalf = ($Scores[0..($mid - 1)] | Measure-Object -Average).Average
    $secondHalf = ($Scores[$mid..($Scores.Count - 1)] | Measure-Object -Average).Average
    $diff = $secondHalf - $firstHalf
    if ($diff -gt 3) { return "improving" }
    if ($diff -lt -3) { return "declining" }
    return "stable"
}

# ═══════════════════════════════════════════════
# AGENT 维度采集
# ═══════════════════════════════════════════════

function Collect-AgentDimension {
    $ws = Read-JsonSafe (Join-Path $HarnessDir "workflow-state.json")
    $status = "active"; $cnt = @{ active=0; total=0; blocked=0; idle=0 }
    $w = @(); $m = @()
    if ($ws -and $ws.current_context -and $ws.current_context.active_feature_id) {
        $cnt.active=1; $cnt.total=1
    } else { $cnt.idle=1; $cnt.total=1; $status="idle" }
    $pp = Join-Path $HarnessDir "progress.md"; $la=0
    if (Test-Path $pp) {
        $fi = Get-Item $pp; $la=[math]::Round(((Get-Date)-$fi.LastWriteTime).TotalMinutes,1)
    }
    if ($la -gt 30) { $status="idle"; $w+="idle_30m" }
    elseif ($la -gt 10) { $w+="idle_10m" }
    $hl = Read-LinesSafe (Join-Path $HarnessDir "session-handoff.md"); $bc=0
    foreach ($l in $hl) { if ($l -match "RED|BLOCKED|blocker|Blocked"){$bc++} }
    if ($bc -gt 0) { $status="blocked"; $cnt.blocked=1; $cnt.active=0; $m+="blockers:$bc" }
    return @{status=$status; delay_ms=0; count=$cnt; last_active_min=$la; warnings=$w; messages=$m}
}

# ═══════════════════════════════════════════════
# TASK 维度采集
# ═══════════════════════════════════════════════

function Collect-TaskDimension {
    $fl = Read-JsonSafe (Join-Path $HarnessDir "feature_list.json")
    $t=0; $d=0; $ip=0; $bl=0; $p=0; $blk=@(); $m=@(); $w=@()
    if ($fl -and $fl.features) {
        $t=$fl.features.Count
        foreach ($f in $fl.features) {
            switch ($f.status) { "done"{$d++} "in_progress"{$ip++} "blocked"{$bl++; $blk+=$f.name} "pending"{$p++} }
        }
    }
    $cr = if($t -gt 0){[math]::Round($d/$t*100,1)}else{0}
    if($bl -gt 0){$w+="blocked_$bl"; $m+="$bl blocked: $($blk -join ',')"}
    if($p -gt $d){$w+="pending_majority"; $m+="Pending($p) > done($d)"}
    $m+="Completion: ${cr}% ($d/$t)"
    return @{total=$t; done=$d; in_progress=$ip; blocked=$bl; pending=$p;
        completion_rate=$cr; blockers=$blk; warnings=$w; messages=$m}
}

function Collect-ResourceDimension {
    $w=@(); $m=@(); $tp=0; $cu=0; $ct=200000
    $pp=Join-Path $HarnessDir "progress.md"
    if(Test-Path $pp){
        $fs=(Get-Item $pp).Length
        if($fs -gt 100000){
            $tp=[math]::Min(95,[math]::Round(($fs-80000)/120000*100,1))
            if($tp -gt 0){$cu=[math]::Round($ct*$tp/100)}
        }
    }
    $hp=Join-Path $HarnessDir "session-handoff.md"
    if(Test-Path $hp){
        $hs=(Get-Item $hp).Length
        if($hs -gt 20000){
            $tp=[math]::Max($tp,[math]::Min(90,[math]::Round(($hs-15000)/10000*100,1)))
        }
    }
    $rfc=0
    try{
        $sd=(Get-Date).AddDays(-7)
        $sf=Get-ChildItem (Join-Path $ProjectRoot ".trae\skills") -Recurse -File -EA SilentlyContinue
        $rfc=($sf|?{$_.LastWriteTime -gt $sd}).Count
    }catch{$rfc=0}
    $ec=[math]::Round($tp*$ct/1000000*2.0,2)
    if($tp -gt 80){$w+="token_high_${tp}pct"; $m+="Token HIGH: ${tp}%"}
    elseif($tp -gt 50){$w+="token_moderate"; $m+="Token moderate: ${tp}%"}
    if($rfc -gt 30){$w+="files_high_$rfc"; $m+="File changes HIGH: $rfc"}
    $m+="Token: ${tp}% ($cu/$ct)"
    return @{
        token_usage_pct=$tp; context_used=$cu; context_total=$ct
        recent_file_changes=$rfc; estimated_api_cost=$ec
        warnings=$w; messages=$m
    }
}

function Collect-ErrorDimension {
    $w=@(); $m=@(); $te=0; $ue=0; $ep=@{}; $rr=100.0
    $hl=Read-LinesSafe (Join-Path $HarnessDir "session-handoff.md"); $ir=$false
    foreach($l in $hl){
        if($l -match "Blockers|Risks"){$ir=$true;continue}
        if($ir -and $l -match "^##\s"){$ir=$false;continue}
        if($ir){
            if($l -match "RED|CRITICAL|crit"){$ue++;$te++;$ep["blocker"]=($ep["blocker"]-or 0)+1}
            elseif($l -match "YELLOW|WARN"){$te++;$ep["warning"]=($ep["warning"]-or 0)+1}
        }
    }
    $pl=Read-LinesSafe (Join-Path $HarnessDir "progress.md")
    foreach($l in $pl){
        if($l -match "FAIL|error|ERROR"){
            $te++
            if($l -match "lint|typecheck"){$ep["type_lint"]=($ep["type_lint"]-or 0)+1}
            elseif($l -match "Test|test"){$ep["test"]=($ep["test"]-or 0)+1}
            elseif($l -match "build|compile"){$ep["build"]=($ep["build"]-or 0)+1}
        }
    }
    if($te -gt 0 -and $ue -gt 0){$rr=[math]::Round(($te-$ue)/$te*100,1)}
    $dom=""; $mx=0
    foreach($k in $ep.Keys){if($ep[$k] -gt $mx){$mx=$ep[$k];$dom=$k}}
    if($ue -gt 0){$w+="unresolved_$ue"; $m+="$ue unresolved errors"}
    if($dom){$m+="Dominant: $dom ($mx x)"}
    $m+="Recovery: ${rr}%"
    return @{
        total_errors=$te; unresolved_errors=$ue
        error_patterns=$ep; dominant_pattern=$dom
        recovery_rate=$rr; warnings=$w; messages=$m
    }
}

# ═══════════════════════════════════════════════
# 评分引擎
# ═══════════════════════════════════════════════

function Score-AgentDimension {
    param($data)
    $s=100; $r=@()
    if($data.status -eq "blocked"){$s-=40; $r+="Blocked:-40"}
    elseif($data.status -eq "idle"){$s-=20; $r+="Idle:-20"}
    if($data.last_active_min -gt 30){$s-=25; $r+="Inactive>30m:-25"}
    elseif($data.last_active_min -gt 10){$s-=10; $r+="Inactive>10m:-10"}
    if($data.count.blocked -gt 0){$s-=15*$data.count.blocked; $r+="$($data.count.blocked)blocked:-$($data.count.blocked*15)"}
    $s=[math]::Max(0,$s)
    return @{score=$s; level=(Get-HealthLevel $s); reasons=$r}
}

function Score-TaskDimension {
    param($data)
    $s=[math]::Max(0,[math]::Min(100,[math]::Round($data.completion_rate)))
    $r=@("Completion:${s}pts")
    if($data.blocked -gt 0){$p=[math]::Min(30,$data.blocked*10); $s-=$p; $r+="$($data.blocked)blocked:-$p"}
    if($data.pending -gt $data.done){$s-=15; $r+="Pending>done:-15"}
    $s=[math]::Max(0,$s)
    return @{score=$s; level=(Get-HealthLevel $s); reasons=$r}
}

function Score-ResourceDimension {
    param($data)
    $s=100; $r=@()
    if($data.token_usage_pct -gt 95){$s-=40; $r+="Token>95%:-40"}
    elseif($data.token_usage_pct -gt 80){$s-=25; $r+="Token>80%:-25"}
    elseif($data.token_usage_pct -gt 50){$s-=10; $r+="Token>50%:-10"}
    if($data.recent_file_changes -gt 40){$s-=20; $r+="Files>40:-20"}
    elseif($data.recent_file_changes -gt 20){$s-=10; $r+="Files>20:-10"}
    $s=[math]::Max(0,$s)
    return @{score=$s; level=(Get-HealthLevel $s); reasons=$r}
}

function Score-ErrorDimension {
    param($data)
    $s=[math]::Max(0,[math]::Round($data.recovery_rate))
    $r=@("Recovery:${s}pts")
    if($data.unresolved_errors -ge 3){$s-=30; $r+=">=3unresolved:-30"}
    elseif($data.unresolved_errors -ge 1){$s-=15; $r+="$($data.unresolved_errors)unresolved:-15"}
    $s=[math]::Max(0,$s)
    return @{score=$s; level=(Get-HealthLevel $s); reasons=$r}
}

# ═══════════════════════════════════════════════
# 健康日志 I/O
# ═══════════════════════════════════════════════

function Read-HealthLog {
    $default = @{version="1.0.0"; entries=@(); trends=@{last_7_scores=@(); trend_direction="stable"}}
    if(-not (Test-Path $HealthLogPath)){return $default}
    $log = Read-JsonSafe $HealthLogPath
    if(-not $log){return $default}
    if(-not $log.entries){$log|Add-Member -Name entries -Value @() -MemberType NoteProperty -Force}
    if(-not $log.trends){$log|Add-Member -Name trends -Value @{last_7_scores=@(); trend_direction="stable"} -MemberType NoteProperty -Force}
    return $log
}

function Save-HealthLog {
    param($Log)
    $ld = Split-Path $HealthLogPath -Parent
    if(-not (Test-Path $ld)){New-Item -ItemType Directory -Path $ld -Force|Out-Null}
    $json = $Log | ConvertTo-Json -Depth 10
    $enc = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($HealthLogPath, $json, $enc)
}

# ═══════════════════════════════════════════════
# Action: collect — 全量采集
# ═══════════════════════════════════════════════

function Invoke-Collect {
    $now = Get-Date
    Write-Colored ""; Write-Colored "=== Heartbeat: $($now.ToString('yyyy-MM-dd HH:mm:ss')) ===" "Cyan"

    $ad = Collect-AgentDimension
    $td = Collect-TaskDimension
    $rd = Collect-ResourceDimension
    $ed = Collect-ErrorDimension

    $as = Score-AgentDimension $ad
    $ts = Score-TaskDimension $td
    $rs = Score-ResourceDimension $rd
    $es = Score-ErrorDimension $ed

    $overall = [math]::Round($as.score*0.25 + $ts.score*0.30 + $rs.score*0.20 + $es.score*0.25, 1)
    $level = Get-HealthLevel $overall

    Write-Colored ""; Write-Colored "  Total: ${overall}/100  [$level]" $(Get-ColorForLevel $level)
    Write-Colored "  AGENT:$($as.score) TASK:$($ts.score) RESOURCE:$($rs.score) ERROR:$($es.score)" "Gray"

    $allW = @()
    $allW += ($ad.warnings|%{"agent:$_"}); $allW += ($td.warnings|%{"task:$_"})
    $allW += ($rd.warnings|%{"resource:$_"}); $allW += ($ed.warnings|%{"error:$_"})

    $allM = @()
    $allM += ($ad.messages|%{"[AGENT]$_"}); $allM += ($td.messages|%{"[TASK]$_"})
    $allM += ($rd.messages|%{"[RESOURCE]$_"}); $allM += ($ed.messages|%{"[ERROR]$_"})

    $entry = @{
        timestamp = $now.ToString("yyyy-MM-ddTHH:mm:sszzz")
        health_score = $overall; level = $level
        dimensions = @{
            agent = @{score=$as.score; status=$as.level; data=$ad}
            task = @{score=$ts.score; status=$ts.level; data=$td}
            resource = @{score=$rs.score; status=$rs.level; data=$rd}
            error = @{score=$es.score; status=$es.level; data=$ed}
        }
        blockers = $td.blockers; warnings = $allW; messages = $allM
        weights = @{agent=0.25; task=0.30; resource=0.20; error=0.25}
    }

    $log = Read-HealthLog
    $log.entries += $entry
    $recentScores = @($log.entries|Select -Last 7|%{$_.health_score})
    $log.trends.last_7_scores = $recentScores
    $log.trends.trend_direction = Compute-TrendDirection $recentScores
    Save-HealthLog $log

    Write-Colored "  [OK] Snapshot saved: $HealthLogPath" "Green"
    Write-Colored "  [$($log.entries.Count) entries] trend: $($log.trends.trend_direction) | last: $($recentScores -join ',')" "Gray"

    if($OutputJson){$entry|ConvertTo-Json -Depth 10|Out-File $OutputJson -Encoding UTF8}
    return $entry
}

function Invoke-ReScore {
    $log = Read-HealthLog
    if($log.entries.Count -eq 0){Write-Colored "[!] No records yet" "Yellow"; return}
    $e = $log.entries[-1]
    Write-Colored "Last: $($e.timestamp) | Score: $($e.health_score)/100 [$($e.level)]" "White"
    if($OutputJson){$e|ConvertTo-Json -Depth 10|Out-File $OutputJson -Encoding UTF8}
    return $e
}

function Invoke-Report {
    $log = Read-HealthLog
    if($log.entries.Count -eq 0){Write-Colored "[!] No records" "Yellow"; return}
    $e = $log.entries[-1]
    Write-Colored ""; Write-Colored "=== Health Report ===" "Cyan"
    Write-Colored "  Time: $($e.timestamp)" "White"
    Write-Colored "  Score: $($e.health_score)/100 [$($e.level)]" $(Get-ColorForLevel $e.level)
    Write-Colored "  Dims: A=$($e.dimensions.agent.score) T=$($e.dimensions.task.score) R=$($e.dimensions.resource.score) E=$($e.dimensions.error.score)" "Gray"
    Write-Colored "  Trend: $($log.trends.trend_direction) ($(($log.trends.last_7_scores -join ', ')))" "Gray"
    if($e.warnings.Count -gt 0){Write-Colored "  Warnings: $($e.warnings -join ', ')" "Yellow"}
    if($e.blockers.Count -gt 0){Write-Colored "  Blockers: $($e.blockers -join ', ')" "Red"}
}

function Main {
    switch ($Action) {
        "collect" { Invoke-Collect }
        "score"   { Invoke-ReScore }
        "report"  { Invoke-Report }
        default   { Write-Colored "[!] Unknown: $Action" "Red" }
    }
}

Main
