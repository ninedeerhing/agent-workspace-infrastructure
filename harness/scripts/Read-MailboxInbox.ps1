<#
.SYNOPSIS
    读取指定角色的 mailbox inbox 未处理消息。
#>
param(
    [Parameter(Mandatory = $true)][string]$RoleId,
    [string]$TargetPath = "",
    [switch]$AsJson
)

$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    $TargetPath = Split-Path -Parent (Split-Path -Parent $ScriptRoot)
}

$ProjectRoot = (Resolve-Path $TargetPath).Path
$inboxDir = Join-Path $ProjectRoot "harness/mailbox/$RoleId/inbox"
$messages = @()

if (Test-Path $inboxDir) {
    Get-ChildItem -Path $inboxDir -Filter "*.json" -File | Sort-Object Name | ForEach-Object {
        try {
            $messages += Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        }
        catch { }
    }
}

if ($AsJson) {
    $messages | ConvertTo-Json -Depth 8
}
else {
    if ($messages.Count -eq 0) {
        Write-Host "inbox empty for role: $RoleId"
    }
    else {
        foreach ($m in $messages) {
            Write-Host ("[{0}] {1} -> {2} type={3}" -f $m.msg_id, $m.from, $m.to, $m.type)
        }
    }
}
