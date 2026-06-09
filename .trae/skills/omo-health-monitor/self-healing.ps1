# self-healing.ps1 — OMO Health Monitor 自愈引擎
param(
    [ValidateSet("diagnose", "heal", "status")]
    [string]$Action = "diagnose",
    [switch]$Quiet,
    [switch]$AutoApply,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptDir "..\..\..")
$HarnessDir = Join-Path $ProjectRoot "harness"
$HealthLogPath = Join-Path $HarnessDir "health-log.json"
$DegradationStatePath = Join-Path $HarnessDir "degradation-state.json"
$HealLogPath = Join-Path $HarnessDir "heal-log.json"

function Write-Colored {
    param([string]$T, [string]$C="White")
    if (-not $Quiet) { Write-Host $T -ForegroundColor $C }
}

function Read-JsonSafe {
    param([string]$P, $D=$null)
    if (-not (Test-Path $P)) { return $D }
    try { $c=Get-Content $P -Raw -Encoding UTF8; if([string]::IsNullOrWhiteSpace($c)){return $D}; return $c|ConvertFrom-Json } catch { return $D }
}

function Save-JsonSafe {
    param($Data, [string]$P)
    $d=Split-Path $P -Parent
    if(-not(Test-Path $d)){New-Item -ItemType Directory -Path $d -Force|Out-Null}
    $j=$Data|ConvertTo-Json -Depth 10
    $e=New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($P, $j, $e)
}

<#
    读取最新健康快照
#>
function Get-LatestSnapshot {
    $l=Read-JsonSafe $HealthLogPath
    if(-not $l -or -not $l.entries -or $l.entries.Count -eq 0){return $null}
    return $l.entries[-1]
}

<#
    读取降级状态
#>
function Get-DegradationState {
    $ds=Read-JsonSafe $DegradationStatePath
    if(-not $ds){ $ds=@{current_level="HEALTHY"; level_history=@()} }
    return $ds
}

<#
    读取自愈日志，不存在则创建
#>
function Get-HealLog {
    $hl=Read-JsonSafe $HealLogPath
    if(-not $hl){ $hl=@{version="1.0.0"; entries=@()} }
    return $hl
}

# ═══════════════════════════════════════════════
# 自愈方案库
# ═══════════════════════════════════════════════

<#
    自愈方案：每个方案包含诊断条件、推荐操作、可自动修复标记
#>
$HealRecipes = @(
    @{
        id = "heal-token-high"
        dimension = "resource"
        condition = { param($d) $d.resource.score -lt 50 }
        diagnosis = "Token usage critically high. Context window may overflow."
        severity = "CRITICAL"
        auto_fixable = $true
        actions = @(
            @{ type="recommend"; skill="token-budget"; desc="Run token budget optimization" },
            @{ type="recommend"; skill="omc-conversation-continuity"; desc="Handoff to new session" },
            @{ type="inline"; desc="Generate handoff prompt now" }
        )
        auto_apply = { Write-Colored "  [HEAL] Token budget: Suggesting conversation continuinity handoff" "Green" }
    },
    @{
        id = "heal-error-repeat"
        dimension = "error"
        condition = { param($d) $d.error.score -lt 70 -and $d.error.data.unresolved_errors -gt 0 }
        diagnosis = "Unresolved errors detected. Pattern may be recurring."
        severity = "WARNING"
        auto_fixable = $false
        actions = @(
            @{ type="recommend"; skill="systematic-debugging"; desc="Run systematic debugging on failed tests" },
            @{ type="recommend"; skill="code-review"; desc="Code review to identify root cause" }
        )
        auto_apply = { Write-Colored "  [HEAL] Error: Cannot auto-fix, recommend systematic-debugging" "Yellow" }
    },
    @{
        id = "heal-agent-idle"
        dimension = "agent"
        condition = { param($d) $d.agent.score -lt 60 }
        diagnosis = "Agent appears idle or blocked. Check for hanging operations."
        severity = "WARNING"
        auto_fixable = $true
        actions = @(
            @{ type="inline"; desc="Check active feature in workflow-state.json" },
            @{ type="recommend"; skill="session-retro"; desc="Review session for blocking items" }
        )
        auto_apply = { Write-Colored "  [HEAL] Agent: Marking idle status, suggest session review" "Green" }
    },
    @{
        id = "heal-task-stall"
        dimension = "task"
        condition = { param($d) $d.task.score -lt 30 }
        diagnosis = "Task progress is stalled. Likely blocked or scope creep."
        severity = "DEGRADED"
        auto_fixable = $false
        actions = @(
            @{ type="recommend"; skill="planner"; desc="Re-plan remaining tasks" },
            @{ type="inline"; desc="Review feature_list.json for blocked items" },
            @{ type="recommend"; skill="writing-plans"; desc="Create incremental plan for stuck tasks" }
        )
        auto_apply = { Write-Colored "  [HEAL] Task: Cannot auto-fix, suggest re-planning" "Yellow" }
    },
    @{
        id = "heal-file-churn"
        dimension = "resource"
        condition = { param($d) $d.resource.data.recent_file_changes -gt 30 }
        diagnosis = "Excessive file changes detected. Scope may have expanded."
        severity = "WARNING"
        auto_fixable = $false
        actions = @(
            @{ type="recommend"; skill="code-review"; desc="Review scope of changes" },
            @{ type="inline"; desc="Check if changes match active feature scope" }
        )
        auto_apply = { Write-Colored "  [HEAL] File churn: Suggest scope review" "Yellow" }
    }
)

# ═══════════════════════════════════════════════
# 诊断引擎
# ═══════════════════════════════════════════════

<#
    诊断当前工作区健康问题，匹配自愈方案
    返回诊断结果列表
#>
function Invoke-Diagnose {
    $s=Get-LatestSnapshot
    if(-not $s){Write-Colored "[!] No health snapshot" "Yellow"; return @()}
    
    Write-Colored ""; Write-Colored "=== Self-Healing Diagnosis ===" "Cyan"
    Write-Colored "  Health: $($s.health_score)/100 [$($s.level)]" "White"
    
    $dims=$s.dimensions
    $matched=@()
    $results=@()
    
    foreach($recipe in $HealRecipes){
        $cond=$recipe.condition
        $triggered=&$cond $dims
        if($triggered){
            $matched+=$recipe
            Write-Colored ""; Write-Colored "  [ISSUE] $($recipe.diagnosis)" $(if($recipe.severity -eq "CRITICAL"){"Red"}else{"Yellow"})
            Write-Colored "    Severity: $($recipe.severity) | Auto-fix: $($recipe.auto_fixable)" "Gray"
            Write-Colored "    Actions:" "White"
            
            $actList=@()
            foreach($a in $recipe.actions){
                $prefix=if($a.type -eq "recommend"){"[SKILL]"}else{"[INLINE]"}
                Write-Colored "      $prefix $($a.desc)" "Gray"
                $actList+=@{type=$a.type; skill=$a.skill; desc=$a.desc}
            }
            
            $results+=@{
                recipe_id=$recipe.id
                dimension=$recipe.dimension
                diagnosis=$recipe.diagnosis
                severity=$recipe.severity
                auto_fixable=$recipe.auto_fixable
                actions=$actList
                triggered=(Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
            }
        }
    }
    
    if($matched.Count -eq 0){Write-Colored "  [OK] No issues requiring healing" "Green"}
    
    # 记录诊断结果
    if($results.Count -gt 0){
        $healLog=Get-HealLog
        $healLog.entries+=@{
            timestamp=(Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
            type="diagnosis"
            health_score=$s.health_score
            findings=$results
        }
        Save-JsonSafe $healLog $HealLogPath
        Write-Colored ""; Write-Colored "  Diagnosis saved to: $HealLogPath" "Gray"
    }
    
    return $results
}

<#
    执行自愈：对诊断结果中可自动修复的问题执行修复
#>
function Invoke-Heal {
    $results=Invoke-Diagnose
    if($results.Count -eq 0){return}
    
    Write-Colored ""; Write-Colored "=== Applying Self-Healing ===" "Cyan"
    
    $autoFixed=0
    $needHuman=0
    $healActions=@()
    
    foreach($r in $results){
        $recipe=$HealRecipes|Where-Object{$_.id -eq $r.recipe_id}|Select-Object -First 1
        if(-not $recipe){continue}
        
        if($recipe.auto_fixable -and ($AutoApply -or $Force)){
            Write-Colored "  [HEAL] Auto-fixing: $($r.recipe_id)" "Green"
            try{
                &$recipe.auto_apply
                $autoFixed++
                $healActions+=@{
                    recipe_id=$r.recipe_id
                    action="auto_fix"
                    success=$true
                    timestamp=(Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
                }
            }catch{
                Write-Colored "  [FAIL] Auto-fix failed: $($_.Exception.Message)" "Red"
                $healActions+=@{
                    recipe_id=$r.recipe_id
                    action="auto_fix"
                    success=$false
                    error=$_.Exception.Message
                    timestamp=(Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
                }
            }
        }elseif(-not $recipe.auto_fixable){
            $needHuman++
            $skillRecs=$r.actions|Where-Object{$_.type -eq "recommend"}|ForEach-Object{"`$"+$_.skill}
            if($skillRecs){
                Write-Colored "  [RECOMMEND] $($r.recipe_id): Try $($skillRecs -join ', ')" "Yellow"
            }
            $healActions+=@{
                recipe_id=$r.recipe_id
                action="recommend_human"
                success=$null
                recommended_skills=@($skillRecs)
                timestamp=(Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
            }
        }else{
            Write-Colored "  [SKIP] $($r.recipe_id): Auto-fix available but requires --AutoApply" "Gray"
            $needHuman++
        }
    }
    
    # 记录自愈操作
    $healLog=Get-HealLog
    $healLog.entries+=@{
        timestamp=(Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        type="heal"
        actions=$healActions
        summary=@{auto_fixed=$autoFixed; need_human=$needHuman; total=$results.Count}
    }
    Save-JsonSafe $healLog $HealLogPath
    
    Write-Colored ""; Write-Colored "=== Heal Summary ===" "Cyan"
    Write-Colored "  Auto-fixed: $autoFixed | Need human: $needHuman | Total: $($results.Count)" "White"
    Write-Colored "  Log: $HealLogPath" "Gray"
}

<#
    查看历史自愈状态
#>
function Invoke-HealStatus {
    $hl=Get-HealLog
    Write-Colored ""; Write-Colored "=== Self-Healing History ===" "Cyan"
    if($hl.entries.Count -eq 0){Write-Colored "  No heal records" "Gray"; return}
    
    $recent=$hl.entries|Select-Object -Last 10
    foreach($e in $recent){
        Write-Colored "  [$($e.timestamp)] $($e.type)" "White"
        if($e.findings){
            foreach($f in $e.findings){Write-Colored "    - $($f.diagnosis)" "Gray"}
        }
        if($e.summary){
            Write-Colored "    Auto:$($e.summary.auto_fixed) Human:$($e.summary.need_human)" "Gray"
        }
    }
    Write-Colored "  Total: $($hl.entries.Count) records" "Gray"
}

function Main {
    switch($Action){
        "diagnose" { Invoke-Diagnose|Out-Null }
        "heal" { Invoke-Heal }
        "status" { Invoke-HealStatus }
    }
}

Main
