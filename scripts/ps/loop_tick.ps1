# Loop Engineering tick wrapper (repo root)
param(
    [Parameter(Position = 0)]
    [ValidateSet("status", "prepare", "emit-prompt", "advance")]
    [string]$Command = "status",
    [string]$Note = "",
    [string]$Next = "",
    [string]$NextAfter = "",
    [string]$TickId = ""
)

$Root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Set-Location $Root

switch ($Command) {
    "advance" {
        if (-not $Next) { throw "advance requires -Next" }
        $args = @("harness/loop_tick.py", "advance", "--next", $Next)
        if ($Note) { $args += @("--note", $Note) }
        if ($NextAfter) { $args += @("--next-after", $NextAfter) }
        if ($TickId) { $args += @("--tick-id", $TickId) }
        python @args
    }
    default {
        python "harness/loop_tick.py" $Command
    }
}
