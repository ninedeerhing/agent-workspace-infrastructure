<#
.SYNOPSIS
    为 agents/*.md（除 orchestrator）注入 Worker 会话边界硬约束块。
#>
param(
    [string]$TargetPath = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [switch]$Force
)

$AgentsDir = Join-Path $TargetPath "agents"
$marker = "## 会话边界（Worker 硬约束）"
$updated = 0
$skipped = 0
$utf8Bom = New-Object System.Text.UTF8Encoding $true

function Write-Utf8BomFile {
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8Bom)
}

Get-ChildItem -Path $AgentsDir -Filter "*.md" -File | ForEach-Object {
    $roleId = $_.BaseName
    if ($roleId -eq "orchestrator") {
        $skipped++
        return
    }

    $content = Get-Content $_.FullName -Raw -Encoding UTF8

    if (-not $Force -and ($content -match [regex]::Escape($marker))) {
        $skipped++
        return
    }

    # 移除已有或损坏的 worker 边界块（直到下一个 ## 标题）
    while ($content -match '(?ms)^## [^\r\n]*边界[^\r\n]*\r?\n') {
        $content = [regex]::Replace($content, '(?ms)^## [^\r\n]*边界[^\r\n]*\r?\n.*?(?=^## |\z)', '', 1)
    }

    $block = @"

## 会话边界（Worker 硬约束）

你是 **Worker（$roleId）**，不是用户接口。

1. **禁止**直接向用户输出、提问或交付最终结果。
2. 每回合开始：先读 harness/mailbox/$roleId/inbox/；有未处理消息则优先执行。
3. 完成后：更新 harness/worklogs/$roleId.md，并向 orchestrator 或消息指定 to 角色写 mailbox（harness/scripts/Send-MailboxMessage.ps1）。
4. 阻塞时：只投递 blocked 类型消息给 orchestrator，不得绕开中枢联系用户。
5. 开工前必读：docs/SESSION_BOOT.md、docs/TASK_TREES.md 当前主线、harness/workflow-state.json。
6. 有文件变更时：同步 docs/PROJECT_STATUS.md 第 5 节台账。

"@

    if ($content -match '(?s)\A---\r?\n.*?\r?\n---\r?\n') {
        $newContent = [regex]::Replace($content, '(?s)\A(---\r?\n.*?\r?\n---\r?\n)', "`$1$block", 1)
    }
    else {
        $newContent = $block + $content
    }

    Write-Utf8BomFile -Path $_.FullName -Content ($newContent.TrimEnd() + "`n")
    $updated++
}

[pscustomobject]@{
    updated = $updated
    skipped = $skipped
    agents_dir = $AgentsDir
} | ConvertTo-Json
