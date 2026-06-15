<#
.SYNOPSIS
    从 agents/ 目录生成 Raindeer-AWI agent registry 与默认团队清单
.DESCRIPTION
    扫描项目根目录下的 agents/*.md：
    - orchestrator 作为唯一 user-facing 角色
    - 其余 .md 文件作为 worker
    - 输出 harness/agent-registry.json
    - 输出 harness/team-manifest.default.json
    - 可选创建 mailbox 与 worklog 脚手架
#>

param(
    [string]$TargetPath = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [string]$HubModel = "opus",
    [hashtable]$WorkerModels = @{},
    [switch]$WriteFiles,
    [switch]$EnsureScaffold,
    [switch]$PassThru
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path $TargetPath).Path
$AgentsDir = Join-Path $ProjectRoot "agents"
$HarnessDir = Join-Path $ProjectRoot "harness"

if (-not (Test-Path $AgentsDir)) {
    throw "agents/ 目录不存在: $AgentsDir"
}

function Get-FrontmatterValue {
    param(
        [string[]]$Lines,
        [string]$Key
    )

    foreach ($line in $Lines) {
        if ($line -match "^\s*$Key\s*:\s*(.+?)\s*$") {
            return $matches[1].Trim().Trim('"')
        }
    }

    return $null
}

function Get-DescriptionFallback {
    param([string[]]$Lines)

    $afterFrontmatter = $false
    foreach ($line in $Lines) {
        if (-not $afterFrontmatter) {
            if ($line -eq "---") {
                $afterFrontmatter = $true
            }
            continue
        }

        if ($line -eq "---") {
            continue
        }

        $trimmed = $line.Trim()
        if ($trimmed -and -not $trimmed.StartsWith("#") -and -not $trimmed.StartsWith("tools:") -and -not $trimmed.StartsWith("model:")) {
            return $trimmed
        }
    }

    return $null
}

function New-RoleRecord {
    param(
        [System.IO.FileInfo]$File
    )

    $roleId = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
    $content = Get-Content $File.FullName -Encoding UTF8
    $frontmatterLines = @()

    if ($content.Count -gt 2 -and $content[0] -eq "---") {
        for ($i = 1; $i -lt $content.Count; $i++) {
            if ($content[$i] -eq "---") { break }
            $frontmatterLines += $content[$i]
        }
    }

    $modelFromFile = Get-FrontmatterValue -Lines $frontmatterLines -Key "model"
    $description = Get-FrontmatterValue -Lines $frontmatterLines -Key "description"
    if ([string]::IsNullOrWhiteSpace($description) -or $description -eq ">") {
        $description = Get-DescriptionFallback -Lines $content
    }
    $isUserFacing = $roleId -eq "orchestrator"
    $kind = if ($isUserFacing) { "orchestrator" } else { "worker" }
    $model = if ($isUserFacing) {
        $HubModel
    }
    elseif ($WorkerModels.ContainsKey($roleId)) {
        [string]$WorkerModels[$roleId]
    }
    else {
        $modelFromFile
    }

    return [pscustomobject]@{
        role_id = $roleId
        kind = $kind
        user_facing = $isUserFacing
        enabled = $true
        source_file = "agents/$($File.Name)"
        session_name = "AWI / $roleId"
        model = $model
        description = $description
        mailbox = [pscustomobject]@{
            inbox = "harness/mailbox/$roleId/inbox"
            processed = "harness/mailbox/$roleId/processed"
        }
        worklog = "harness/worklogs/$roleId.md"
        platform_binding = [pscustomobject]@{
            platform = $null
            session_id = $null
            adapter = $null
        }
    }
}

$agentFiles = @(Get-ChildItem -Path $AgentsDir -Filter "*.md" -File | Sort-Object @{ Expression = { if ($_.BaseName -eq "orchestrator") { 0 } else { 1 } } }, Name)
if ($agentFiles.Count -eq 0) {
    throw "agents/ 目录下没有 .md 角色文件。"
}

$roles = foreach ($file in $agentFiles) {
    New-RoleRecord -File $file
}

$orchestrator = $roles | Where-Object { $_.role_id -eq "orchestrator" } | Select-Object -First 1
if ($null -eq $orchestrator) {
    throw "未找到 orchestrator.md，无法生成团队清单。"
}

$workers = @($roles | Where-Object { $_.role_id -ne "orchestrator" })

$registry = [pscustomobject]@{
    version = "0.1.0"
    generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    source = "harness/scripts/Build-AgentRegistryFromAgentsDir.ps1"
    project_root = $ProjectRoot
    orchestrator_role = "orchestrator"
    user_facing_role = "orchestrator"
    role_count = $roles.Count
    worker_count = $workers.Count
    roles = $roles
}

$manifest = [pscustomobject]@{
    version = "0.1.0"
    template_id = "default-full-roster"
    generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    orchestrator_role = "orchestrator"
    user_facing_role = "orchestrator"
    roles = @(
        $roles | ForEach-Object {
            [pscustomobject]@{
                role_id = $_.role_id
                kind = $_.kind
                enabled = $_.enabled
                session_name = $_.session_name
                model = $_.model
                source_file = $_.source_file
            }
        }
    )
    defaults = [pscustomobject]@{
        register_skills = $true
        ensure_mailbox = $true
        ensure_worklogs = $true
        platform = "auto"
    }
}

if ($WriteFiles) {
    if (-not (Test-Path $HarnessDir)) {
        New-Item -ItemType Directory -Path $HarnessDir -Force | Out-Null
    }

    $registry | ConvertTo-Json -Depth 8 | Set-Content -Path (Join-Path $HarnessDir "agent-registry.json") -Encoding UTF8
    $manifest | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $HarnessDir "team-manifest.default.json") -Encoding UTF8
}

if ($EnsureScaffold) {
    $mailboxRoot = Join-Path $HarnessDir "mailbox"
    $worklogRoot = Join-Path $HarnessDir "worklogs"

    foreach ($role in $roles) {
        $inbox = Join-Path $ProjectRoot $role.mailbox.inbox
        $processed = Join-Path $ProjectRoot $role.mailbox.processed
        $worklog = Join-Path $ProjectRoot $role.worklog

        New-Item -ItemType Directory -Path $inbox -Force | Out-Null
        New-Item -ItemType Directory -Path $processed -Force | Out-Null
        New-Item -ItemType Directory -Path (Split-Path $worklog -Parent) -Force | Out-Null

        if (-not (Test-Path $worklog)) {
            @(
                "# $($role.role_id) Worklog",
                "",
                "- Role: $($role.kind)",
                "- User-facing: $($role.user_facing)",
                "- Source: $($role.source_file)",
                "- Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            ) | Set-Content -Path $worklog -Encoding UTF8
        }
    }
}

if ($PassThru) {
    $registry
}
else {
    [pscustomobject]@{
        project_root = $ProjectRoot
        orchestrator_role = "orchestrator"
        role_count = $roles.Count
        worker_count = $workers.Count
        generated_files = @(
            "harness/agent-registry.json",
            "harness/team-manifest.default.json"
        )
    } | ConvertTo-Json -Depth 4
}
