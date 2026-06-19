<#
.SYNOPSIS
    写入一条结构化 mailbox 消息（跨 Agent 文件总线）。
.EXAMPLE
    .\Send-MailboxMessage.ps1 -From orchestrator -To executor -Type dispatch_task -Payload @{ goal = "实现 X" } -TreeId TREE-RT
#>
param(
    [Parameter(Mandatory = $true)][string]$From,
    [Parameter(Mandatory = $true)][string]$To,
    [Parameter(Mandatory = $true)][ValidateSet("dispatch_task","report_changes","fix_request","acceptance_result","blocked")]
    [string]$Type,
    [object]$Payload = $null,
    [string]$PayloadJson = "",
    [string]$TreeId = "TREE-RT",
    [string]$CorrelationId = "",
    [ValidateSet("none","lite")][string]$Compress = "none",
    [string]$TargetPath = ""
)

$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if ([string]::IsNullOrWhiteSpace($TargetPath)) {
    $TargetPath = Split-Path -Parent (Split-Path -Parent $ScriptRoot)
}

$ProjectRoot = (Resolve-Path $TargetPath).Path

if (-not [string]::IsNullOrWhiteSpace($PayloadJson)) {
    $parsed = $PayloadJson | ConvertFrom-Json
    $Payload = @{}
    $parsed.PSObject.Properties | ForEach-Object { $Payload[$_.Name] = $_.Value }
}
elseif ($null -eq $Payload) {
    $Payload = @{}
}
elseif ($Payload -is [pscustomobject]) {
    $Payload = [hashtable]$Payload
}
$msgId = "MSG-{0}-{1}" -f (Get-Date -Format "yyyyMMdd-HHmmss"), ([guid]::NewGuid().ToString("N").Substring(0, 6))

if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
    $CorrelationId = $msgId
}

$message = [ordered]@{
    msg_id = $msgId
    correlation_id = $CorrelationId
    from = $From
    to = $To
    type = $Type
    tree_id = $TreeId
    payload = $Payload
    compress = $Compress
    created_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    requires_ack = $true
}

$inboxDir = Join-Path $ProjectRoot "harness/mailbox/$To/inbox"
if (-not (Test-Path $inboxDir)) {
    New-Item -ItemType Directory -Path $inboxDir -Force | Out-Null
}

$outPath = Join-Path $inboxDir "$msgId.json"
$message | ConvertTo-Json -Depth 8 | Set-Content -Path $outPath -Encoding UTF8

[pscustomobject]@{
    msg_id = $msgId
    path = $outPath
    to = $To
} | ConvertTo-Json
