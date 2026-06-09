<#
.SYNOPSIS
    AWI Harness — 历史交接归档引擎
.DESCRIPTION
    对 harness/ 目录下的状态文件进行时间点快照归档。
    支持创建归档、列出归档、还原归档、删除归档和比较归档。
    归档目录结构：harness/archive/YYYY-MM-DD-HH-MM-SS-<reason>/
    每个归档包含：feature_list.json, progress.md, session-handoff.md,
                  workflow-state.json, workflow-gates.md, archive-meta.json
.NOTES
    版本: 1.0.0
    平台: Windows PowerShell 5.1+
    语言: 中文（输出）、英文（标识符和命令）
#>

param(
    [ValidateSet("new", "list", "info", "restore", "remove", "compare", "verify", "cleanup")]
    [string]$Action = "list",

    [string]$Reason = "",

    [string[]]$FeatureIds = @(),

    [switch]$Force,

    [string]$ArchiveId = "",

    [switch]$DryRun,

    [switch]$BackupFirst,

    [string]$ArchiveIdA = "",

    [string]$ArchiveIdB = "",

    [switch]$ConfirmRemove,

    [int]$KeepRecent = 20,

    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ArchiveDir = $ScriptDir
$HarnessDir = Split-Path -Parent $ScriptDir
$ProjectRoot = Split-Path -Parent $HarnessDir
$IndexFile = Join-Path $ArchiveDir "index.json"

<#
    快照文件列表 — 每次归档时需要捕获的 Harness 状态文件
    这些文件构成完整的会话交接上下文
#>
$SnapshotFiles = @(
    "feature_list.json",
    "progress.md",
    "session-handoff.md",
    "workflow-state.json",
    "workflow-gates.md",
    "clean-state-checklist.md"
)

# ═══════════════════════════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════════════════════════

function Write-Colored {
    param([string]$Text, [string]$Color = "White")
    if (-not $Quiet) { Write-Host $Text -ForegroundColor $Color }
}

function Write-StepHeader {
    param([string]$Text)
    if (-not $Quiet) {
        Write-Host ""
        Write-Host "═══ $Text ═══" -ForegroundColor Cyan
    }
}

<#
    读取归档索引文件，不存在则创建默认索引
    @returns 归档索引对象
#>
function Get-ArchiveIndex {
    if (Test-Path $IndexFile) {
        try {
            $content = Get-Content $IndexFile -Raw -Encoding UTF8
            return $content | ConvertFrom-Json
        }
        catch {
            Write-Colored "  [!] 索引文件损坏，重建默认索引" "Yellow"
        }
    }
    return @{
        version  = "1.0.0"
        archives = @()
    }
}

<#
    将归档索引对象写回 index.json
    @param $Index 归档索引对象
#>
function Save-ArchiveIndex {
    param($Index)
    $json = $Index | ConvertTo-Json -Depth 10
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($IndexFile, $json, $utf8NoBom)
}

<#
    生成归档 ID，格式为 arc-序号（从 index 中推导下一个序号）
    @param $Index 归档索引对象
    @returns 新归档 ID 字符串
#>
function New-ArchiveId {
    param($Index)
    $maxId = 0
    foreach ($arc in $Index.archives) {
        if ($arc.id -match 'arc-(\d+)') {
            $num = [int]$Matches[1]
            if ($num -gt $maxId) { $maxId = $num }
        }
    }
    return "arc-" + ($maxId + 1).ToString("D3")
}

<#
    生成归档目录名
    @param $Timestamp 时间戳字符串（ISO 8601 格式）
    @param $ArchiveId 归档 ID
    @param $Reason 归档原因（可选）
    @returns 目录名字符串
#>
function New-ArchiveDirName {
    param([string]$Timestamp, [string]$ArchiveId, [string]$Reason)
    $dt = [DateTime]::Parse($Timestamp)
    $ts = $dt.ToString("yyyy-MM-dd-HH-mm-ss")
    if ($Reason) {
        $safeReason = $Reason -replace '[<>:"/\\|?*\s]', '-' -replace '-{2,}', '-' -replace '-$', ''
        if ($safeReason.Length -gt 40) { $safeReason = $safeReason.Substring(0, 40) }
        return "$ts-$ArchiveId-$safeReason"
    }
    return "$ts-$ArchiveId"
}

<#
    获取指定归档的元数据
    @param $ArchiveId 归档 ID
    @returns 归档条目对象，未找到则返回 $null
#>
function Get-ArchiveEntry {
    param([string]$ArchiveId)
    $index = Get-ArchiveIndex
    foreach ($arc in $index.archives) {
        if ($arc.id -eq $ArchiveId) { return $arc }
    }
    return $null
}

<#
    验证归档目录中的所有文件是否存在且非空
    @param $ArchiveDirPath 归档目录的完整路径
    @returns 包含验证结果的哈希表
#>
function Test-ArchiveIntegrity {
    param([string]$ArchiveDirPath)
    $result = @{
        Valid    = $true
        Missing  = @()
        Empty    = @()
        Present  = @()
    }
    foreach ($file in $SnapshotFiles) {
        $filePath = Join-Path $ArchiveDirPath $file
        if (-not (Test-Path $filePath)) {
            $result.Valid = $false
            $result.Missing += $file
        }
        else {
            $content = Get-Content $filePath -Raw -ErrorAction SilentlyContinue
            if ([string]::IsNullOrWhiteSpace($content)) {
                $result.Empty += $file
            }
            else {
                $result.Present += $file
            }
        }
    }
    $metaPath = Join-Path $ArchiveDirPath "archive-meta.json"
    if (-not (Test-Path $metaPath)) {
        $result.Missing += "archive-meta.json"
    }
    else {
        $result.Present += "archive-meta.json"
    }
    return $result
}

# ═══════════════════════════════════════════════════════════════
# Action: new — 创建新归档
# ═══════════════════════════════════════════════════════════════

function Invoke-NewArchive {
    Write-StepHeader "创建新归档"

    $index = Get-ArchiveIndex
    $archiveId = New-ArchiveId -Index $index
    $timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
    $dirName = New-ArchiveDirName -Timestamp $timestamp -ArchiveId $archiveId -Reason $Reason
    $archivePath = Join-Path $ArchiveDir $dirName

    if (Test-Path $archivePath) {
        if (-not $Force) {
            Write-Colored "  [!] 归档目录已存在: $dirName，使用 --Force 覆盖" "Yellow"
            return
        }
        Write-Colored "  [i] 覆盖已有归档目录: $dirName" "Yellow"
    }

    New-Item -ItemType Directory -Path $archivePath -Force | Out-Null
    Write-Colored "  [+] 创建归档目录: $dirName" "Green"

    $copiedFiles = @()
    foreach ($file in $SnapshotFiles) {
        $srcPath = Join-Path $HarnessDir $file
        $dstPath = Join-Path $archivePath $file
        if (Test-Path $srcPath) {
            Copy-Item -Path $srcPath -Destination $dstPath -Force
            $copiedFiles += $file
            Write-Colored "  [+] 已快照: $file" "Green"
        }
        else {
            Write-Colored "  [!] 源文件缺失，跳过: $file" "Yellow"
        }
    }

    $activeFeatureId = $null
    $workflowState = Get-Content (Join-Path $HarnessDir "workflow-state.json") -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($workflowState) {
        try {
            $ws = $workflowState | ConvertFrom-Json
            $activeFeatureId = $ws.current_context.active_feature_id
        }
        catch { }
    }

    $meta = @{
        archive_id            = $archiveId
        timestamp             = $timestamp
        directory             = $dirName
        reason                = if ($Reason) { $Reason } else { "会话交接归档" }
        feature_ids           = if ($FeatureIds.Count -gt 0) { $FeatureIds } else { @($activeFeatureId | Where-Object { $_ }) }
        active_feature_id     = $activeFeatureId
        files_snapshot        = $copiedFiles
        harness_dir           = $HarnessDir
        project_root          = $ProjectRoot
        verification_status   = "not_verified"
        operator              = "$env:USERNAME@$env:COMPUTERNAME"
    }

    $metaPath = Join-Path $archivePath "archive-meta.json"
    $metaJson = $meta | ConvertTo-Json -Depth 5
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($metaPath, $metaJson, $utf8NoBom)
    Write-Colored "  [+] 已写入元数据: archive-meta.json" "Green"

    $archiveEntry = @{
        id                  = $archiveId
        timestamp           = $timestamp
        directory           = $dirName
        reason              = $meta.reason
        feature_ids         = $meta.feature_ids
        files_snapshot      = $copiedFiles
        file_count          = $copiedFiles.Count
    }

    $index.archives = @($archiveEntry) + @($index.archives)
    Save-ArchiveIndex -Index $index
    Write-Colored "  [+] 已更新归档索引: index.json ($($index.archives.Count) 个归档)" "Green"

    Write-Colored ""
    Write-Colored "  === 归档创建完成 ===" "White"
    Write-Colored "  ID:       $archiveId" "White"
    Write-Colored "  目录:     $dirName" "White"
    Write-Colored "  文件数:   $($copiedFiles.Count)" "White"
    Write-Colored "  时间戳:   $timestamp" "White"
    if ($Reason) { Write-Colored "  原因:     $Reason" "White" }
}

# ═══════════════════════════════════════════════════════════════
# Action: list — 列出所有归档
# ═══════════════════════════════════════════════════════════════

function Invoke-ListArchives {
    Write-StepHeader "归档列表"

    $index = Get-ArchiveIndex
    if ($index.archives.Count -eq 0) {
        Write-Colored "  暂无归档记录" "Yellow"
        return
    }

    Write-Colored "  共 $($index.archives.Count) 个归档（按时间倒序）" "White"
    Write-Colored ""

    $header = "{0,-10} {1,-22} {2,-20} {3,-30}" -f "ID", "时间", "文件数", "原因"
    Write-Colored "  $header" "Cyan"
    Write-Colored ("  " + ("-" * 85)) "DarkGray"

    foreach ($arc in $index.archives) {
        $dt = [DateTime]::Parse($arc.timestamp)
        $timeStr = $dt.ToString("yyyy-MM-dd HH:mm:ss")
        $reason = if ($arc.reason.Length -gt 28) { $arc.reason.Substring(0, 28) + ".." } else { $arc.reason }
        $line = "{0,-10} {1,-22} {2,-20} {3,-30}" -f $arc.id, $timeStr, $arc.file_count, $reason
        Write-Colored "  $line" "White"
    }
}

# ═══════════════════════════════════════════════════════════════
# Action: info — 查看归档详情
# ═══════════════════════════════════════════════════════════════

function Invoke-ArchiveInfo {
    param([string]$Id)
    Write-StepHeader "归档详情"

    $entry = Get-ArchiveEntry -ArchiveId $Id
    if (-not $entry) {
        Write-Colored "  [!] 未找到归档: $Id" "Red"
        Write-Colored "  使用 'list' 操作查看所有归档" "Yellow"
        return
    }

    $archivePath = Join-Path $ArchiveDir $entry.directory
    $metaPath = Join-Path $archivePath "archive-meta.json"

    Write-Colored "  ID:           $($entry.id)" "White"
    Write-Colored "  目录:         $($entry.directory)" "White"
    Write-Colored "  时间戳:       $($entry.timestamp)" "White"
    Write-Colored "  原因:         $($entry.reason)" "White"
    Write-Colored "  关联功能:     $($entry.feature_ids -join ', ')" "White"
    Write-Colored "  快照文件数:   $($entry.file_count)" "White"
    Write-Colored ""

    if (Test-Path $metaPath) {
        try {
            $meta = Get-Content $metaPath -Raw -Encoding UTF8 | ConvertFrom-Json
            Write-Colored "  --- 扩展元数据 ---" "DarkGray"
            if ($meta.operator) { Write-Colored "  操作者:       $($meta.operator)" "White" }
            if ($meta.verification_status) { Write-Colored "  验证状态:     $($meta.verification_status)" "White" }
            if ($meta.active_feature_id) { Write-Colored "  活跃功能:     $($meta.active_feature_id)" "White" }
        }
        catch { }
    }

    Write-Colored ""
    Write-Colored "  --- 文件清单 ---" "DarkGray"
    foreach ($f in $entry.files_snapshot) {
        $fp = Join-Path $archivePath $f
        if (Test-Path $fp) {
            $size = (Get-Item $fp).Length
            $sizeStr = if ($size -gt 1024) { "{0:N1} KB" -f ($size / 1024) } else { "$size B" }
            Write-Colored "  [✓] $f ($sizeStr)" "Green"
        }
        else {
            Write-Colored "  [✗] $f (缺失)" "Red"
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# Action: restore — 从归档还原状态文件
# ═══════════════════════════════════════════════════════════════

function Invoke-RestoreArchive {
    param([string]$Id, [switch]$DryRunMode, [switch]$DoBackupFirst)

    Write-StepHeader "还原归档"

    $entry = Get-ArchiveEntry -ArchiveId $Id
    if (-not $entry) {
        Write-Colored "  [!] 未找到归档: $Id" "Red"
        return
    }

    $archivePath = Join-Path $ArchiveDir $entry.directory
    if (-not (Test-Path $archivePath)) {
        Write-Colored "  [!] 归档目录不存在: $archivePath" "Red"
        Write-Colored "  索引记录存在但目录缺失，请使用 'verify' 检查完整性" "Yellow"
        return
    }

    $integrity = Test-ArchiveIntegrity -ArchiveDirPath $archivePath
    if (-not $integrity.Valid) {
        Write-Colored "  [!] 归档完整性检查失败" "Red"
        if ($integrity.Missing.Count -gt 0) {
            Write-Colored "  缺失文件: $($integrity.Missing -join ', ')" "Red"
        }
        return
    }

    Write-Colored "  归档 ID:   $Id" "White"
    Write-Colored "  归档时间:  $($entry.timestamp)" "White"
    Write-Colored "  归档原因:  $($entry.reason)" "White"
    Write-Colored "  文件数:    $($entry.file_count)" "White"
    Write-Colored ""

    if ($DryRunMode) {
        Write-Colored "  === 试运行模式（不会实际修改文件）===" "Cyan"
        Write-Colored ""
        Write-Colored "  将还原以下文件:" "White"
        foreach ($file in $entry.files_snapshot) {
            $src = Join-Path $archivePath $file
            $dst = Join-Path $HarnessDir $file
            Write-Colored "    $src" "Gray"
            Write-Colored "    -> $dst" "Green"
        }
        return
    }

    if ($DoBackupFirst) {
        Write-Colored "  [i] 先创建当前状态的安全备份..." "Cyan"
        $backupReason = "还原前自动备份（还原 $Id）"
        $backupArchiveId = New-ArchiveId -Index (Get-ArchiveIndex)
        $backupTimestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        $backupDirName = New-ArchiveDirName -Timestamp $backupTimestamp -ArchiveId $backupArchiveId -Reason $backupReason
        $backupPath = Join-Path $ArchiveDir $backupDirName
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        $backupCopied = @()
        foreach ($file in $SnapshotFiles) {
            $src = Join-Path $HarnessDir $file
            if (Test-Path $src) {
                Copy-Item -Path $src -Destination (Join-Path $backupPath $file) -Force
                $backupCopied += $file
            }
        }
        $backupMeta = @{
            archive_id          = $backupArchiveId
            timestamp           = $backupTimestamp
            directory           = $backupDirName
            reason              = $backupReason
            feature_ids         = @()
            active_feature_id   = $null
            files_snapshot      = $backupCopied
            harness_dir         = $HarnessDir
            project_root        = $ProjectRoot
            verification_status = "auto_backup_before_restore"
            operator            = "$env:USERNAME@$env:COMPUTERNAME"
        }
        $backupMetaJson = $backupMeta | ConvertTo-Json -Depth 5
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText((Join-Path $backupPath "archive-meta.json"), $backupMetaJson, $utf8NoBom)
        $backupEntry = @{
            id             = $backupArchiveId
            timestamp      = $backupTimestamp
            directory      = $backupDirName
            reason         = $backupReason
            feature_ids    = @()
            files_snapshot = $backupCopied
            file_count     = $backupCopied.Count
        }
        $idx = Get-ArchiveIndex
        $idx.archives = @($backupEntry) + @($idx.archives)
        Save-ArchiveIndex -Index $idx
        Write-Colored "  [+] 安全备份已创建: $backupArchiveId" "Green"
    }

    Write-Colored ""
    Write-Colored "  [i] 正在还原文件..." "Cyan"
    foreach ($file in $entry.files_snapshot) {
        $src = Join-Path $archivePath $file
        $dst = Join-Path $HarnessDir $file
        if (Test-Path $src) {
            Copy-Item -Path $src -Destination $dst -Force
            Write-Colored "  [+] 已还原: $file" "Green"
        }
    }

    Write-Colored ""
    Write-Colored "  === 还原完成 ===" "White"
    Write-Colored "  已从 $Id 还原 $($entry.file_count) 个文件到 harness/" "White"
    if ($DoBackupFirst) {
        Write-Colored "  还原前的状态已备份为 $backupArchiveId" "White"
    }
    Write-Colored "  建议运行 init.ps1 验证当前状态" "Yellow"
}

# ═══════════════════════════════════════════════════════════════
# Action: remove — 删除归档
# ═══════════════════════════════════════════════════════════════

function Invoke-RemoveArchive {
    param([string]$Id, [switch]$Confirmed)

    Write-StepHeader "删除归档"

    if (-not $Confirmed) {
        Write-Colored "  [!] 此操作将永久删除归档及其文件" "Red"
        Write-Colored "  请使用 -ConfirmRemove 参数确认删除操作" "Yellow"
        Write-Colored "  示例: .\store.ps1 -Action remove -ArchiveId $Id -ConfirmRemove" "Yellow"
        return
    }

    $entry = Get-ArchiveEntry -ArchiveId $Id
    if (-not $entry) {
        Write-Colored "  [!] 未找到归档: $Id" "Red"
        return
    }

    $archivePath = Join-Path $ArchiveDir $entry.directory
    Write-Colored "  归档 ID:   $Id" "White"
    Write-Colored "  归档目录:  $($entry.directory)" "White"
    Write-Colored "  归档时间:  $($entry.timestamp)" "White"
    Write-Colored ""

    if (Test-Path $archivePath) {
        Remove-Item -Path $archivePath -Recurse -Force
        Write-Colored "  [+] 已删除归档目录" "Green"
    }
    else {
        Write-Colored "  [!] 归档目录已不存在，仅清理索引" "Yellow"
    }

    $index = Get-ArchiveIndex
    $newArchives = @()
    foreach ($arc in $index.archives) {
        if ($arc.id -ne $Id) {
            $newArchives += $arc
        }
    }
    $index.archives = $newArchives
    Save-ArchiveIndex -Index $index
    Write-Colored "  [+] 已更新归档索引（剩余 $($index.archives.Count) 个归档）" "Green"
    Write-Colored ""
    Write-Colored "  === 删除完成 ===" "White"
}

# ═══════════════════════════════════════════════════════════════
# Action: compare — 比较两个归档
# ═══════════════════════════════════════════════════════════════

function Invoke-CompareArchives {
    param([string]$IdA, [string]$IdB)

    Write-StepHeader "比较归档"

    $entryA = Get-ArchiveEntry -ArchiveId $IdA
    $entryB = Get-ArchiveEntry -ArchiveId $IdB

    if (-not $entryA) { Write-Colored "  [!] 未找到归档: $IdA" "Red"; return }
    if (-not $entryB) { Write-Colored "  [!] 未找到归档: $IdB" "Red"; return }

    $pathA = Join-Path $ArchiveDir $entryA.directory
    $pathB = Join-Path $ArchiveDir $entryB.directory

    Write-Colored "  A: $IdA ($($entryA.timestamp))" "Cyan"
    Write-Colored "  B: $IdB ($($entryB.timestamp))" "Cyan"
    Write-Colored ""

    $allFiles = @{}
    foreach ($f in $entryA.files_snapshot) { $allFiles[$f] = $true }
    foreach ($f in $entryB.files_snapshot) { $allFiles[$f] = $true }

    foreach ($file in $allFiles.Keys | Sort-Object) {
        $fpA = Join-Path $pathA $file
        $fpB = Join-Path $pathB $file
        $existsA = Test-Path $fpA
        $existsB = Test-Path $fpB

        if (-not $existsA -and -not $existsB) {
            Write-Colored "  [?] $file — 两边均缺失" "DarkGray"
        }
        elseif (-not $existsA) {
            Write-Colored "  [+] $file — 仅在 B 中存在" "Green"
        }
        elseif (-not $existsB) {
            Write-Colored "  [-] $file — 仅在 A 中存在" "Red"
        }
        else {
            $hashA = (Get-FileHash $fpA -Algorithm MD5).Hash
            $hashB = (Get-FileHash $fpB -Algorithm MD5).Hash
            if ($hashA -eq $hashB) {
                Write-Colored "  [=] $file — 内容相同" "Gray"
            }
            else {
                $sizeA = (Get-Item $fpA).Length
                $sizeB = (Get-Item $fpB).Length
                Write-Colored "  [≠] $file — 内容不同 (A: $sizeA B, B: $sizeB B)" "Yellow"
            }
        }
    }
    Write-Colored ""
    Write-Colored "  === 比较完成 ===" "White"
}

# ═══════════════════════════════════════════════════════════════
# Action: verify — 验证归档完整性
# ═══════════════════════════════════════════════════════════════

function Invoke-VerifyArchives {
    param([string]$SpecificId)

    Write-StepHeader "归档完整性验证"

    if ($SpecificId) {
        $entry = Get-ArchiveEntry -ArchiveId $SpecificId
        if (-not $entry) {
            Write-Colored "  [!] 未找到归档: $SpecificId" "Red"
            return
        }
        $archivePath = Join-Path $ArchiveDir $entry.directory
        $result = Test-ArchiveIntegrity -ArchiveDirPath $archivePath
        Write-Colored "  归档: $SpecificId ($($entry.timestamp))" "White"
        if ($result.Valid) {
            Write-Colored "  [✓] 完整 — $($result.Present.Count) 个文件均存在且非空" "Green"
        }
        else {
            Write-Colored "  [✗] 不完整" "Red"
            if ($result.Missing.Count -gt 0) { Write-Colored "    缺失: $($result.Missing -join ', ')" "Red" }
            if ($result.Empty.Count -gt 0) { Write-Colored "    为空: $($result.Empty -join ', ')" "Yellow" }
        }
        return
    }

    $index = Get-ArchiveIndex
    if ($index.archives.Count -eq 0) {
        Write-Colored "  暂无归档记录" "Yellow"
        return
    }

    $total = $index.archives.Count
    $valid = 0
    $invalid = 0

    foreach ($arc in $index.archives) {
        $archivePath = Join-Path $ArchiveDir $arc.directory
        Write-Colored "  检查: $($arc.id)..." "Gray" -NoNewline
        if (-not (Test-Path $archivePath)) {
            Write-Colored " [✗] 目录缺失" "Red"
            $invalid++
            continue
        }
        $result = Test-ArchiveIntegrity -ArchiveDirPath $archivePath
        if ($result.Valid) {
            Write-Colored " [✓] 完整" "Green"
            $valid++
        }
        else {
            $issues = @()
            if ($result.Missing.Count -gt 0) { $issues += "缺失:$($result.Missing.Count)" }
            if ($result.Empty.Count -gt 0) { $issues += "为空:$($result.Empty.Count)" }
            Write-Colored " [✗] $($issues -join ', ')" "Red"
            $invalid++
        }
    }

    Write-Colored ""
    Write-Colored "  === 验证结果: $valid 完整 / $invalid 异常 / $total 总计 ===" $(if ($invalid -gt 0) { "Yellow" } else { "Green" })
}

# ═══════════════════════════════════════════════════════════════
# Action: cleanup — 清理过期归档（保留最近 N 个）
# ═══════════════════════════════════════════════════════════════

function Invoke-CleanupArchives {
    param([int]$KeepCount)

    Write-StepHeader "清理过期归档"

    $index = Get-ArchiveIndex
    if ($index.archives.Count -le $KeepCount) {
        Write-Colored "  当前归档数 $($index.archives.Count) ≤ 保留数 $KeepCount，无需清理" "Green"
        return
    }

    $toRemove = $index.archives | Select-Object -Skip $KeepCount
    Write-Colored "  将删除 $($toRemove.Count) 个过期归档（保留最近 $KeepCount 个）:" "Yellow"
    Write-Colored ""

    foreach ($arc in $toRemove) {
        Write-Colored "    - $($arc.id) ($($arc.timestamp)) — $($arc.reason)" "Yellow"
    }

    Write-Colored ""
    Write-Colored "  如需确认删除，请使用 -Action remove -ArchiveId <id> -ConfirmRemove" "Cyan"
    Write-Colored "  或者单独删除每个归档" "Cyan"
}

# ═══════════════════════════════════════════════════════════════
# 主调度
# ═══════════════════════════════════════════════════════════════

function Main {
    # 确保归档目录存在
    if (-not (Test-Path $ArchiveDir)) {
        New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null
    }

    # 确保索引文件存在
    if (-not (Test-Path $IndexFile)) {
        $initIndex = @{ version = "1.0.0"; archives = @() }
        Save-ArchiveIndex -Index $initIndex
    }

    switch ($Action) {
        "new"     { Invoke-NewArchive }
        "list"    { Invoke-ListArchives }
        "info"    { Invoke-ArchiveInfo -Id $ArchiveId }
        "restore" { Invoke-RestoreArchive -Id $ArchiveId -DryRunMode:$DryRun -DoBackupFirst:$BackupFirst }
        "remove"  { Invoke-RemoveArchive -Id $ArchiveId -Confirmed:$ConfirmRemove }
        "compare" { Invoke-CompareArchives -IdA $ArchiveIdA -IdB $ArchiveIdB }
        "verify"  { Invoke-VerifyArchives -SpecificId $ArchiveId }
        "cleanup" { Invoke-CleanupArchives -KeepCount $KeepRecent }
        default   { Write-Colored "  [!] 未知操作: $Action" "Red" }
    }
}

Main
