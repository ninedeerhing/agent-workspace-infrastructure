<#
.SYNOPSIS
    AWI Schedule Engine — recurring task dispatcher (Loop Engineering: Automations)
.DESCRIPTION
    Reads harness/schedule.json and outputs which tasks are due to run.
    Designed to be called by a cron job, GitHub Actions, or an agent's
    automations trigger.

    Output format: JSON array of due task objects, each containing:
      - id, name, description, skill_to_invoke, prompt, last_run, next_due

    Does not execute tasks directly — it returns what should run.
    Execution is the agent's responsibility (the agent reads the output
    and invokes the skill or executes the prompt).

.PARAMETER ScheduleFile
    Path to schedule.json (default: harness/schedule.json)
.PARAMETER MarkRun
    If provided, marks the specified task ID as run (updates last_run)
.EXAMPLE
    .\harness\schedule.ps1
    Returns JSON array of due tasks

.EXAMPLE
    .\harness\schedule.ps1 -MarkRun "daily-health-check"
    Marks the task as run and returns nothing
#>

param(
    [string]$ScheduleFile = "$PSScriptRoot\schedule.json",
    [string]$MarkRun
)

$ErrorActionPreference = "Stop"

# ═══════════════════════════════════════════════════════════════
# Default schedule if file does not exist
# ═══════════════════════════════════════════════════════════════
$DefaultSchedule = @"
{
  "version": "1.0.0",
  "tasks": [
    {
      "id": "daily-health-check",
      "name": "Daily Health Check",
      "description": "Run omo-health-monitor heartbeat, check for degraded agents, log status",
      "skill_to_invoke": "omo-health-monitor",
      "prompt": "Run health check: scan harness/progress.md for stalled tasks, check harness/feature_list.json for stuck features, report any anomalies.",
      "cron": "0 9 * * 1-5",
      "max_duration_minutes": 5,
      "retry_on_failure": false,
      "enabled": true,
      "last_run": null
    },
    {
      "id": "weekly-curator-cycle",
      "name": "Weekly Capability Curation",
      "description": "Run capability-accumulation curator cycle: review, grade, merge, prune skills",
      "skill_to_invoke": "capability-accumulation",
      "prompt": "Run the curator cycle: review all capability cards, grade their current value, merge overlapping ones, prune low-value ones.",
      "cron": "0 10 * * 1",
      "max_duration_minutes": 15,
      "retry_on_failure": false,
      "enabled": true,
      "last_run": null
    },
    {
      "id": "session-retro-trigger",
      "name": "Post-Session Retrospective",
      "description": "After each development session, extract patterns and update learning records",
      "skill_to_invoke": "session-retro",
      "prompt": "Review the latest entries in harness/progress.md, extract reusable patterns, update skills if patterns have appeared 3+ times.",
      "cron": "0 18 * * 1-5",
      "max_duration_minutes": 10,
      "retry_on_failure": true,
      "enabled": false,
      "last_run": null
    },
    {
      "id": "weekly-progress-summary",
      "name": "Weekly Progress Summary",
      "description": "Summarize the week's progress: features completed, blockers, next priorities",
      "prompt": "Read harness/progress.md and harness/feature_list.json. Summarize: what was completed this week, what is blocked, what should be the top 3 priorities next week. Write to harness/progress.md.",
      "cron": "0 16 * * 5",
      "max_duration_minutes": 10,
      "retry_on_failure": false,
      "enabled": true,
      "last_run": null
    }
  ]
}
"@

# ═══════════════════════════════════════════════════════════════
# Load schedule
# ═══════════════════════════════════════════════════════════════
if (-not (Test-Path $ScheduleFile)) {
    $dir = Split-Path $ScheduleFile -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Set-Content -Path $ScheduleFile -Value $DefaultSchedule -Encoding UTF8
    Write-Host "[INFO] Created default schedule.json with 4 tasks" -ForegroundColor Cyan
}

try {
    $schedule = Get-Content $ScheduleFile -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    Write-Host "[ERROR] Failed to parse schedule.json: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# ═══════════════════════════════════════════════════════════════
# MarkRun mode — update last_run timestamp
# ═══════════════════════════════════════════════════════════════
if ($MarkRun) {
    $found = $false
    foreach ($task in $schedule.tasks) {
        if ($task.id -eq $MarkRun) {
            $task.last_run = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
            $found = $true
            break
        }
    }
    if (-not $found) {
        Write-Host "[ERROR] Task not found: $MarkRun" -ForegroundColor Red
        exit 1
    }
    $schedule | ConvertTo-Json -Depth 5 | Set-Content -Path $ScheduleFile -Encoding UTF8
    Write-Host "[OK] Marked task '$MarkRun' as run at $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Green
    exit 0
}

# ═══════════════════════════════════════════════════════════════
# Check which tasks are due
# ═══════════════════════════════════════════════════════════════
function Test-CronMatch {
    param([string]$CronExpression, [DateTime]$Now)

    $parts = $CronExpression -split '\s+'
    if ($parts.Count -ne 5) { return $false }

    $minute = $parts[0]
    $hour   = $parts[1]
    $dom    = $parts[2]
    $month  = $parts[3]
    $dow    = $parts[4]

    $minMatch = ($minute -eq "*" -or [int]$minute -eq $Now.Minute)
    $hourMatch = ($hour -eq "*" -or [int]$hour -eq $Now.Hour)
    $domMatch = ($dom -eq "*" -or [int]$dom -eq $Now.Day)

    $dowMatch = $true
    if ($dow -ne "*") {
        $dowNums = $dow -split ',' | ForEach-Object { [int]$_.Trim() }
        $todayDow = [int]$Now.DayOfWeek
        $dowMatch = $todayDow -in $dowNums
    }

    return $minMatch -and $hourMatch -and $domMatch -and $dowMatch
}

function Test-DueForRun {
    param($LastRun, [DateTime]$Now)

    if (-not $LastRun) { return $true }

    try {
        $lastDt = [DateTime]::Parse($LastRun)
        $diff = $Now - $lastDt
        # Don't re-run within 30 minutes of last run
        return $diff.TotalMinutes -gt 30
    } catch {
        return $true
    }
}

$now = Get-Date
$due = @()

foreach ($task in $schedule.tasks) {
    if (-not $task.enabled) { continue }

    $cronMatch = Test-CronMatch -CronExpression $task.cron -Now $now
    $dueForRun = Test-DueForRun -LastRun $task.last_run -Now $now

    if ($cronMatch -and $dueForRun) {
        $due += [PSCustomObject]@{
            id               = $task.id
            name             = $task.name
            description      = $task.description
            skill_to_invoke  = if ($task.skill_to_invoke) { $task.skill_to_invoke } else { $null }
            prompt           = $task.prompt
            max_duration_min = $task.max_duration_minutes
            retry_on_failure = $task.retry_on_failure
            last_run         = $task.last_run
            cron             = $task.cron
        }
    }
}

# Output
if ($due.Count -eq 0) {
    Write-Host "[INFO] No scheduled tasks due at $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Gray
    exit 0
}

$due | ConvertTo-Json -Depth 3
Write-Host ""
Write-Host "$($due.Count) task(s) due. Run harness/schedule.ps1 -MarkRun '<task-id>' after execution." -ForegroundColor Cyan
Write-Host "  Tasks: $($due.ForEach({ $_.id }) -join ', ')" -ForegroundColor White
