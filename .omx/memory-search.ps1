<#
.SYNOPSIS
    OMX Memory 语义搜索脚本

.DESCRIPTION
    实现 OMX Memory 系统的多策略语义检索功能：
    - 精确匹配（Token 完全命中）
    - 内容子串匹配
    - 模糊匹配（Levenshtein 距离）
    - 别名/标签匹配
    - 类别和作用域过滤
    - 相关性综合排序

    支持三种数据源：
    - .omx/memory-index.json   (主索引：结构化搜索索引)
    - .omx/project-memory.json (原始记忆：全量记忆数据)
    - .omx/notepad.md          (记事本：全文检索补充)

.PARAMETER Query
    搜索查询字符串。支持自然语言、关键词、类别限定（category:XXX）、
    标签限定（tag:XXX）、ID 查找（id:mem-XXX）。

.PARAMETER Action
    操作模式：
    - search (默认): 执行检索
    - rebuild: 从 project-memory.json 重建索引
    - stats: 显示索引统计信息

.PARAMETER Category
    按记忆类别过滤：TECH_STACK, BUILD, CONVENTION, STRUCTURE,
    DECISION, NOTE, DIRECTIVE。多个用逗号分隔。

.PARAMETER Tag
    按标签过滤。

.PARAMETER Scope
    按作用域过滤：PROJECT, SESSION, AGENT, TURN。

.PARAMETER TopK
    最大返回结果数，默认 10，范围 1-50。

.PARAMETER OutputJson
    以 JSON 格式输出结果（供程序消费）。

.PARAMETER MinScore
    最低相关性分数阈值，默认 0.1。低于此分数的结果不显示。

.EXAMPLE
    .\memory-search.ps1 -Query "TypeScript React"
    关键词搜索"TypeScript React"。

.EXAMPLE
    .\memory-search.ps1 -Query "构建命令" -Category "BUILD"
    在 BUILD 类别中搜索"构建命令"。

.EXAMPLE
    .\memory-search.ps1 -Query "部署" -Tag "deploy" -OutputJson
    按标签过滤并输出 JSON。

.EXAMPLE
    .\memory-search.ps1 -Action rebuild
    从 project-memory.json 重建搜索索引。

.EXAMPLE
    .\memory-search.ps1 -Action stats
    查看索引统计信息。

.LINK
    规范文档: .omx/memory-index.md
    OMX Memory: .omx/memory.md
#>

param(
    [string]$Query,
    [ValidateSet("search", "rebuild", "stats")]
    [string]$Action = "search",
    [string]$Category,
    [string]$Tag,
    [ValidateSet("PROJECT", "SESSION", "AGENT", "TURN")]
    [string]$Scope,
    [ValidateRange(1, 50)]
    [int]$TopK = 10,
    [switch]$OutputJson,
    [ValidateRange(0.0, 10.0)]
    [double]$MinScore = 0.1
)

# ═══════════════════════════════════════════════════════════════
# 常量与配置
# ═══════════════════════════════════════════════════════════════

$Script:OmxDir = $PSScriptRoot
$Script:ProjectRoot = Split-Path -Parent $PSScriptRoot
$Script:IndexFile = Join-Path $OmxDir "memory-index.json"
$Script:ProjectMemoryFile = Join-Path $OmxDir "project-memory.json"
$Script:NotepadFile = Join-Path $OmxDir "notepad.md"

$Script:ValidCategories = @("TECH_STACK", "BUILD", "CONVENTION", "STRUCTURE", "DECISION", "NOTE", "DIRECTIVE")

# 英文停用词
$Script:EnglishStopWords = @(
    "a", "an", "the", "is", "are", "was", "were", "be", "been", "being",
    "have", "has", "had", "do", "does", "did", "will", "would", "could",
    "should", "may", "might", "can", "shall", "to", "of", "in", "for",
    "on", "with", "at", "by", "from", "as", "into", "through", "during",
    "and", "but", "or", "nor", "not", "so", "yet", "both", "either",
    "neither", "each", "every", "this", "that", "these", "those", "it", "its"
)

# 中文停用词
$Script:ChineseStopWords = @(
    "的", "了", "在", "是", "我", "有", "和", "就", "不", "人", "都",
    "一", "一个", "上", "也", "很", "到", "说", "要", "去", "你",
    "会", "着", "没有", "看", "好", "自己", "这"
)

# 权重配置
$Script:WeightExactMatch = 1.0
$Script:WeightContentSubstring = 0.8
$Script:WeightFuzzyMatch = 0.7
$Script:WeightAliasMatch = 0.6
$Script:WeightTagMatch = 0.4
$Script:CategoryBonus = 0.3
$Script:AccessWeight = 0.1
$Script:ConfidenceWeight = 0.2

# ═══════════════════════════════════════════════════════════════
# 工具函数
# ═══════════════════════════════════════════════════════════════

<#
.SYNOPSIS
    带颜色输出文本。

.PARAMETER Message
    要输出的消息。

.PARAMETER Color
    控制台前景色名称。
#>
function Write-Colored {
    param([string]$Message, [string]$Color = "White", [switch]$NoNewline)
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    }
    else {
        Write-Host $Message -ForegroundColor $Color
    }
}

<#
.SYNOPSIS
    输出步骤标题。
#>
function Write-StepHeader {
    param([string]$Title)
    Write-Colored ""
    Write-Colored ("=" * 60) "Cyan"
    Write-Colored "  $Title" "Cyan"
    Write-Colored ("=" * 60) "Cyan"
    Write-Colored ""
}

<#
.SYNOPSIS
    计算两个字符串之间的 Levenshtein 编辑距离。

.DESCRIPTION
    使用动态规划计算将字符串 A 转换为字符串 B 所需的最少
    单字符编辑次数（插入、删除、替换）。

.PARAMETER A
    源字符串。

.PARAMETER B
    目标字符串。
#>
function Get-LevenshteinDistance {
    param([string]$A, [string]$B)

    $lenA = $A.Length
    $lenB = $B.Length

    if ($lenA -eq 0) { return $lenB }
    if ($lenB -eq 0) { return $lenA }

    $prev = 0..$lenB
    $curr = New-Object int[] ($lenB + 1)

    for ($i = 1; $i -le $lenA; $i++) {
        $curr[0] = $i
        for ($j = 1; $j -le $lenB; $j++) {
            $cost = if ($A[$i - 1] -eq $B[$j - 1]) { 0 } else { 1 }
            $curr[$j] = [Math]::Min(
                [Math]::Min($curr[$j - 1] + 1, $prev[$j] + 1),
                $prev[$j - 1] + $cost
            )
        }
        $temp = $prev
        $prev = $curr
        $curr = $temp
    }

    return $prev[$lenB]
}

<#
.SYNOPSIS
    对文本进行分词处理。

.DESCRIPTION
    将输入文本拆分为搜索 Token：
    - 英文：按空格/标点分词，小写化，去除停用词
    - 中文：生成 1-4 字滑动窗口词组，去除停用词
    - 混合文本：先分离中英文再分别处理

.PARAMETER Text
    待分词的原始文本。

.PARAMETER RemoveStopWords
    是否移除停用词，默认 $true。
#>
function Tokenize-Text {
    param([string]$Text, [bool]$RemoveStopWords = $true)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return @()
    }

    $tokens = [System.Collections.Generic.List[string]]::new()

    # 分离中文和非中文字符块
    $chinesePattern = '[\u4e00-\u9fff]+'
    $nonChinesePattern = '[^\u4e00-\u9fff]+'

    # 处理非中文部分（英文/数字/标点）
    $nonChineseMatches = [regex]::Matches($Text, $nonChinesePattern)
    foreach ($match in $nonChineseMatches) {
        $part = $match.Value.Trim()
        if ($part.Length -eq 0) { continue }
        # 按标点和空格分词
        $words = $part -split '[^a-zA-Z0-9]+' | Where-Object { $_ -ne '' }
        foreach ($word in $words) {
            $lower = $word.ToLowerInvariant()
            if ($lower.Length -ge 2) {
                if (-not $RemoveStopWords -or $lower -notin $Script:EnglishStopWords) {
                    $tokens.Add($lower)
                }
            }
        }
    }

    # 处理中文部分：生成 1-4 字滑动窗口
    $chineseMatches = [regex]::Matches($Text, $chinesePattern)
    foreach ($match in $chineseMatches) {
        $part = $match.Value
        if ($part.Length -eq 0) { continue }

        # 单字
        for ($i = 0; $i -lt $part.Length; $i++) {
            $ch = $part[$i].ToString()
            if (-not $RemoveStopWords -or $ch -notin $Script:ChineseStopWords) {
                if ($ch -notin $tokens) {
                    $tokens.Add($ch)
                }
            }
        }

        # 双字到四字滑动窗口
        for ($winSize = 2; $winSize -le 4; $winSize++) {
            for ($i = 0; $i -le $part.Length - $winSize; $i++) {
                $ngram = $part.Substring($i, $winSize)
                if (-not $RemoveStopWords -or $ngram -notin $Script:ChineseStopWords) {
                    if ($ngram -notin $tokens) {
                        $tokens.Add($ngram)
                    }
                }
            }
        }
    }

    return $tokens.ToArray()
}

<#
.SYNOPSIS
    计算搜索词与候选索引条目的相关性分数。

.DESCRIPTION
    根据 memory-index.md 定义的评分公式，综合计算精确匹配、
    子串匹配、模糊匹配、别名匹配、标签匹配以及元数据加权分。

.PARAMETER QueryTokens
    查询分词后的 Token 数组。

.PARAMETER Candidate
    候选索引条目对象（包含 tokens, aliases, tags, content, metadata, category）。

.PARAMETER QueryCategory
    查询指定的类别（可为空）。
#>
function Score-Relevance {
    param(
        [string[]]$QueryTokens,
        [PSCustomObject]$Candidate,
        [string]$QueryCategory
    )

    $score = 0.0

    # 处理可能为 $null 的数组字段
    $entryTokens = if ($Candidate.tokens) { $Candidate.tokens } else { @() }
    $entryAliases = if ($Candidate.aliases) { $Candidate.aliases } else { @() }
    $entryTags = if ($Candidate.tags) { $Candidate.tags } else { @() }
    $content = if ($Candidate.content) { $Candidate.content.ToLowerInvariant() } else { "" }
    $queryLower = ($QueryTokens -join ' ').ToLowerInvariant()

    # 1. Token 精确匹配
    foreach ($qt in $QueryTokens) {
        foreach ($et in $entryTokens) {
            if ($qt -eq $et) {
                $score += $Script:WeightExactMatch
                break
            }
        }
    }

    # 2. 内容子串匹配
    foreach ($qt in $QueryTokens) {
        if ($content -like "*$qt*") {
            $score += $Script:WeightContentSubstring
        }
    }

    # 3. Token 模糊匹配（Levenshtein 距离 <= 2）
    foreach ($qt in $QueryTokens) {
        if ($qt.Length -lt 3) { continue }
        $bestDist = [int]::MaxValue
        foreach ($et in $entryTokens) {
            if ($et.Length -lt 3) { continue }
            $dist = Get-LevenshteinDistance -A $qt -B $et
            if ($dist -lt $bestDist) { $bestDist = $dist }
        }
        if ($bestDist -le 2) {
            $score += $Script:WeightFuzzyMatch * (1.0 - $bestDist / 3.0)
        }
    }

    # 4. 别名匹配
    foreach ($qt in $QueryTokens) {
        foreach ($alias in $entryAliases) {
            if ($qt -eq $alias.ToLowerInvariant()) {
                $score += $Script:WeightAliasMatch
                break
            }
        }
    }

    # 5. 标签匹配
    foreach ($qt in $QueryTokens) {
        foreach ($tag in $entryTags) {
            if ($qt -eq $tag.ToLowerInvariant()) {
                $score += $Script:WeightTagMatch
                break
            }
        }
    }

    # 6. 类别匹配加分
    if ($QueryCategory -and $Candidate.category -eq $QueryCategory) {
        $score += $Script:CategoryBonus
    }

    # 7. 访问频次加权
    if ($Candidate.metadata -and $Candidate.metadata.access_count) {
        $accessCount = [int]$Candidate.metadata.access_count
        $score += [Math]::Log($accessCount + 1) * $Script:AccessWeight
    }

    # 8. 置信度加权
    if ($Candidate.metadata -and $Candidate.metadata.confidence) {
        $confidence = [double]$Candidate.metadata.confidence
        $score += $confidence * $Script:ConfidenceWeight
    }

    # 9. 新鲜度加权
    if ($Candidate.metadata -and $Candidate.metadata.last_accessed_at) {
        try {
            $lastAccess = [DateTime]::Parse($Candidate.metadata.last_accessed_at)
            $daysSince = [Math]::Abs(($lastAccess - (Get-Date)).TotalDays)
            if ($daysSince -le 7) { $score += 0.1 }
            elseif ($daysSince -le 30) { $score += 0.05 }
        }
        catch { }
    }

    return [Math]::Round($score, 3)
}

<#
.SYNOPSIS
    安全读取 JSON 文件。

.PARAMETER Path
    JSON 文件路径。

.PARAMETER DefaultValue
    读取失败时的默认返回值。
#>
function Read-JsonFileSafe {
    param([string]$Path, $DefaultValue = $null)

    if (-not (Test-Path $Path)) {
        return $DefaultValue
    }
    try {
        $content = Get-Content $Path -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($content)) {
            return $DefaultValue
        }
        return $content | ConvertFrom-Json
    }
    catch {
        Write-Colored "  [!] 读取 JSON 文件失败: $Path — $($_.Exception.Message)" "Red"
        return $DefaultValue
    }
}

<#
.SYNOPSIS
    安全写入 JSON 文件（UTF-8 无 BOM）。

.PARAMETER Path
    目标文件路径。

.PARAMETER Data
    要序列化的数据对象。
#>
function Write-JsonFileSafe {
    param([string]$Path, $Data)

    try {
        $json = $Data | ConvertTo-Json -Depth 10
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($Path, $json, $utf8NoBom)
    }
    catch {
        Write-Colored "  [!] 写入 JSON 文件失败: $Path — $($_.Exception.Message)" "Red"
    }
}

# ═══════════════════════════════════════════════════════════════
# 核心检索函数
# ═══════════════════════════════════════════════════════════════

<#
.SYNOPSIS
    从搜索记事本中检索匹配的条目。

.DESCRIPTION
    解析 notepad.md 的内容（PRIORITY / WORKING / MANUAL 分区），
    对每个条目进行分词匹配，将匹配结果作为 NOTE 类别记忆返回。

.PARAMETER QueryTokens
    查询分词后的 Token 数组。
#>
function Search-Notepad {
    param([string[]]$QueryTokens)

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    if (-not (Test-Path $Script:NotepadFile)) {
        return $results
    }

    try {
        $content = Get-Content $Script:NotepadFile -Raw -Encoding UTF8
    }
    catch {
        return $results
    }

    # 解析 notepad 分区
    $sections = [regex]::Matches($content, '###\s*(PRIORITY|WORKING|MANUAL)\s*\n([\s\S]*?)(?=###\s*(?:PRIORITY|WORKING|MANUAL)\s*\n|\Z)')
    foreach ($sec in $sections) {
        $sectionName = $sec.Groups[1].Value
        $sectionContent = $sec.Groups[2].Value.Trim()

        if ([string]::IsNullOrWhiteSpace($sectionContent)) { continue }

        # 按行拆分
        $lines = $sectionContent -split '\r?\n' | Where-Object { $_.Trim() -ne '' }
        foreach ($line in $lines) {
            $trimmed = $line.Trim() -replace '^[-*]\s*', ''
            if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }

            # 对每行计算相关性
            $lineTokens = Tokenize-Text -Text $trimmed
            $matchCount = 0
            foreach ($qt in $QueryTokens) {
                if ($trimmed.ToLowerInvariant() -like "*$qt*") {
                    $matchCount++
                }
            }

            if ($matchCount -gt 0) {
                $score = ($matchCount / [Math]::Max($QueryTokens.Count, 1)) * 0.5
                $entry = [PSCustomObject]@{
                    id       = "notepad-$($sectionName.ToLower())"
                    category = "NOTE"
                    scope    = "SESSION"
                    content  = "[$sectionName] $trimmed"
                    score    = [Math]::Round($score, 3)
                    source   = "notepad"
                    metadata = [PSCustomObject]@{
                        source_agent = "manual"
                        confidence   = 0.8
                    }
                }
                $results.Add($entry)
            }
        }
    }

    return $results
}

<#
.SYNOPSIS
    从 project-memory.json 中搜索匹配的记忆条目。

.DESCRIPTION
    直接搜索原始记忆文件中的记忆内容，作为索引文件的补充。
    对每条记忆的原始内容进行子串匹配。

.PARAMETER QueryTokens
    查询分词后的 Token 数组。

.PARAMETER QueryCategory
    可选类别过滤。
#>
function Search-ProjectMemoryRaw {
    param([string[]]$QueryTokens, [string]$QueryCategory)

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()
    $data = Read-JsonFileSafe -Path $Script:ProjectMemoryFile

    if (-not $data) { return $results }

    # 支持顶层数组和对象格式
    $entries = @()
    if ($data -is [Array]) { $entries = $data }
    elseif ($data.PSObject.Properties.Name -contains "memories") { $entries = $data.memories }

    foreach ($entry in $entries) {
        if (-not $entry.content) { continue }
        if ($QueryCategory -and $entry.category -ne $QueryCategory) { continue }

        $entryContent = $entry.content.ToLowerInvariant()
        $matchCount = 0
        foreach ($qt in $QueryTokens) {
            if ($entryContent -like "*$qt*") {
                $matchCount++
            }
        }

        if ($matchCount -gt 0) {
            $score = ($matchCount / [Math]::Max($QueryTokens.Count, 1)) * 0.6
            $result = [PSCustomObject]@{
                id       = if ($entry.id) { $entry.id } else { "pm-" + [Guid]::NewGuid().ToString().Substring(0, 8) }
                category = if ($entry.category) { $entry.category } else { "NOTE" }
                scope    = if ($entry.scope) { $entry.scope } else { "PROJECT" }
                content  = $entry.content
                score    = [Math]::Round($score, 3)
                source   = "project-memory"
                metadata = $entry.metadata
            }
            $results.Add($result)
        }
    }

    return $results
}

<#
.SYNOPSIS
    执行三阶段语义搜索。

.DESCRIPTION
    Stage 1: 查询标准化（小写、分词、去停用词）
    Stage 2: 候选检索（索引搜索 + 原始记忆搜索 + 记事本搜索）
    Stage 3: 相关性排序并返回 Top-K 结果

.PARAMETER Query
    原始查询字符串。

.PARAMETER Category
    类别过滤，多个用逗号分隔。

.PARAMETER Tag
    标签过滤。

.PARAMETER Scope
    作用域过滤。

.PARAMETER TopK
    最大返回条数。

.PARAMETER MinScore
    最低分数阈值。
#>
function Search-Memory {
    param(
        [string]$Query,
        [string]$Category,
        [string]$Tag,
        [string]$Scope,
        [int]$TopK = 10,
        [double]$MinScore = 0.1
    )

    # 输入验证
    if ([string]::IsNullOrWhiteSpace($Query)) {
        Write-Colored "  [!] 查询不能为空" "Red"
        return @()
    }
    if ($Query.Length -gt 500) {
        Write-Colored "  [!] 查询长度不能超过 500 字符" "Red"
        return @()
    }

    # 解析类别列表
    $categories = if ($Category) { $Category -split ',' | ForEach-Object { $_.Trim().ToUpper() } } else { @() }

    # Stage 1: 查询标准化
    $normalizedQuery = $Query.ToLowerInvariant()
    $queryTokens = Tokenize-Text -Text $Query

    if ($queryTokens.Count -eq 0) {
        Write-Colored "  [!] 查询在分词后无有效关键词" "Yellow"
        return @()
    }

    # 检查特殊模式：id: 前缀
    if ($Query -match '^id:(mem-[\w-]+)$') {
        $targetId = $Matches[1]
        $index = Read-JsonFileSafe -Path $Script:IndexFile
        if ($index -and $index.indexes) {
            foreach ($entry in $index.indexes) {
                if ($entry.id -eq $targetId) {
                    $entry | Add-Member -NotePropertyName "score" -NotePropertyValue 10.0 -Force
                    $entry | Add-Member -NotePropertyName "source" -NotePropertyValue "index" -Force
                    return @($entry)
                }
            }
        }
        Write-Colored "  [!] 未找到 ID: $targetId" "Yellow"
        return @()
    }

    # Stage 2: 候选检索
    $allCandidates = [System.Collections.Generic.List[PSCustomObject]]::new()

    # 2a. 从 memory-index.json 检索
    $index = Read-JsonFileSafe -Path $Script:IndexFile
    if ($index -and $index.indexes) {
        foreach ($entry in $index.indexes) {
            # 排除被替代的记忆
            if ($entry.metadata -and $entry.metadata.superseded_by) {
                continue
            }

            # 类别过滤
            if ($categories.Count -gt 0) {
                if ($entry.category -notin $categories) { continue }
            }

            # 作用域过滤
            if ($Scope -and $entry.scope -ne $Scope) { continue }

            # 标签过滤
            if ($Tag) {
                if (-not $entry.tags -or $Tag -notin $entry.tags) { continue }
            }

            # 计算相关性分数
            $queryCat = if ($categories.Count -eq 1) { $categories[0] } else { "" }
            $score = Score-Relevance -QueryTokens $queryTokens -Candidate $entry -QueryCategory $queryCat

            if ($score -ge $MinScore) {
                $entry | Add-Member -NotePropertyName "score" -NotePropertyValue $score -Force
                $entry | Add-Member -NotePropertyName "source" -NotePropertyValue "index" -Force
                $allCandidates.Add($entry)
            }
        }
    }

    # 2b. 从 project-memory.json 原始数据补充检索
    if (-not $index -or $index.indexes.Count -eq 0) {
        $queryCat = if ($categories.Count -eq 1) { $categories[0] } else { "" }
        $pmResults = Search-ProjectMemoryRaw -QueryTokens $queryTokens -QueryCategory $queryCat
        foreach ($r in $pmResults) {
            if ($r.score -ge $MinScore) {
                $allCandidates.Add($r)
            }
        }
    }

    # 2c. 从 notepad.md 补充检索
    $notepadResults = Search-Notepad -QueryTokens $queryTokens
    foreach ($r in $notepadResults) {
        if ($r.score -ge $MinScore) {
            $allCandidates.Add($r)
        }
    }

    # Stage 3: 相关性排序
    $sorted = $allCandidates | Sort-Object -Property score -Descending

    # 返回 Top-K
    return $sorted | Select-Object -First $TopK
}

# ═══════════════════════════════════════════════════════════════
# 索引维护函数
# ═══════════════════════════════════════════════════════════════

<#
.SYNOPSIS
    从 project-memory.json 重建 memory-index.json。

.DESCRIPTION
    读取原始记忆文件，对每条记忆执行分词、别名提取，
    生成结构化的搜索索引文件。

    重建流程：
    1. 读取 project-memory.json 全量数据
    2. 对每条记忆执行分词
    3. 提取别名和标签
    4. 生成 memory-index.json
    5. 输出变更摘要
#>
function Rebuild-MemoryIndex {
    Write-StepHeader "Memory Index 重建"

    $data = Read-JsonFileSafe -Path $Script:ProjectMemoryFile
    if (-not $data) {
        Write-Colored "  [!] project-memory.json 不存在或为空，创建空索引" "Yellow"
        $emptyIndex = @{
            version    = "1.0.0"
            updated_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
            indexes    = @()
        }
        Write-JsonFileSafe -Path $Script:IndexFile -Data $emptyIndex
        Write-Colored "  [+] 已创建空索引文件" "Green"
        return
    }

    # 解析条目
    $entries = @()
    if ($data -is [Array]) { $entries = $data }
    elseif ($data.PSObject.Properties.Name -contains "memories") { $entries = $data.memories }

    $newIndexes = [System.Collections.Generic.List[PSCustomObject]]::new()
    $newCount = 0
    $skipCount = 0

    foreach ($entry in $entries) {
        if (-not $entry.content) {
            $skipCount++
            continue
        }

        # 分词
        $tokens = Tokenize-Text -Text $entry.content

        # 生成 ID
        $entryId = if ($entry.id) { $entry.id } else { "mem-" + [Guid]::NewGuid().ToString().Substring(0, 8) }

        # 提取别名（从已有 aliases 或自动生成）
        $aliases = if ($entry.aliases) {
            @($entry.aliases)
        }
        else {
            @()
        }

        # 构建元数据
        $meta = $entry.metadata
        $metadata = [PSCustomObject]@{
            source_agent     = $(if ($meta -and $meta.source_agent) { $meta.source_agent } else { "unknown" })
            source_provider  = $(if ($meta -and $meta.source_provider) { $meta.source_provider } else { "unknown" })
            created_at_utc   = $(if ($meta -and $meta.created_at_utc) { $meta.created_at_utc } else { (Get-Date).ToString("o") })
            access_count     = $(if ($meta -and $null -ne $meta.access_count) { [int]$meta.access_count } else { 0 })
            last_accessed_at = $(if ($meta -and $meta.last_accessed_at) { $meta.last_accessed_at } else { $null })
            confidence       = $(if ($meta -and $null -ne $meta.confidence) { [double]$meta.confidence } else { 1.0 })
            supersedes       = $(if ($meta -and $meta.supersedes) { $meta.supersedes } else { $null })
            superseded_by    = $(if ($meta -and $meta.superseded_by) { $meta.superseded_by } else { $null })
        }

        # 构建索引条目
        $indexEntry = [PSCustomObject]@{
            id        = $entryId
            category  = $(if ($entry.category -and $entry.category -in $Script:ValidCategories) { $entry.category } else { "NOTE" })
            scope     = $(if ($entry.scope) { $entry.scope } else { "PROJECT" })
            content   = $entry.content
            tokens    = $tokens
            embedding = $null
            aliases   = $aliases
            tags      = $(if ($entry.tags) { @($entry.tags) } else { @() })
            metadata  = $metadata
        }

        $newIndexes.Add($indexEntry)
        $newCount++
    }

    # 构建索引文件
    $index = [PSCustomObject]@{
        version    = "1.0.0"
        updated_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:sszzz")
        indexes    = $newIndexes.ToArray()
    }

    Write-JsonFileSafe -Path $Script:IndexFile -Data $index

    Write-Colored "  [+] 索引重建完成" "Green"
    Write-Colored "  新建条目: $newCount" "White"
    if ($skipCount -gt 0) {
        Write-Colored "  跳过条目: $skipCount (无内容)" "Yellow"
    }

    # 输出类别分布
    Write-Colored ""
    Write-Colored "  --- 类别分布 ---" "DarkGray"
    $categoryCounts = $newIndexes | Group-Object -Property category | Sort-Object Count -Descending
    foreach ($grp in $categoryCounts) {
        Write-Colored "  $($grp.Name): $($grp.Count) 条" "White"
    }

    # 输出文件大小
    if (Test-Path $Script:IndexFile) {
        $size = (Get-Item $Script:IndexFile).Length
        $sizeStr = if ($size -gt 1MB) { "{0:N2} MB" -f ($size / 1MB) } elseif ($size -gt 1KB) { "{0:N1} KB" -f ($size / 1KB) } else { "$size B" }
        Write-Colored ""
        Write-Colored "  索引文件大小: $sizeStr" "Gray"
    }
}

<#
.SYNOPSIS
    获取并显示索引统计信息。
#>
function Get-MemoryIndexStats {
    Write-StepHeader "Memory Index 统计"

    $indexFileExists = Test-Path $Script:IndexFile
    $pmFileExists = Test-Path $Script:ProjectMemoryFile
    $notepadFileExists = Test-Path $Script:NotepadFile

    Write-Colored "  索引文件:     $(if ($indexFileExists) { '存在' } else { '不存在' })" $(if ($indexFileExists) { "Green" } else { "Red" })
    Write-Colored "  原始记忆文件: $(if ($pmFileExists) { '存在' } else { '不存在' })" $(if ($pmFileExists) { "Green" } else { "Yellow" })
    Write-Colored "  记事本文件:   $(if ($notepadFileExists) { '存在' } else { '不存在' })" $(if ($notepadFileExists) { "Green" } else { "Yellow" })
    Write-Colored ""

    if (-not $indexFileExists) {
        Write-Colored "  索引文件不存在。运行 '-Action rebuild' 从 project-memory.json 创建索引。" "Yellow"
        return
    }

    $index = Read-JsonFileSafe -Path $Script:IndexFile
    if (-not $index) {
        Write-Colored "  [!] 无法读取索引文件" "Red"
        return
    }

    $totalEntries = if ($index.indexes) { $index.indexes.Count } else { 0 }
    $activeEntries = 0
    $supersededEntries = 0
    $totalAccessCount = 0
    $categoryStats = @{}

    if ($index.indexes) {
        foreach ($entry in $index.indexes) {
            if ($entry.metadata -and $entry.metadata.superseded_by) {
                $supersededEntries++
            }
            else {
                $activeEntries++
            }

            if ($entry.metadata -and $entry.metadata.access_count) {
                $totalAccessCount += [int]$entry.metadata.access_count
            }

            $cat = if ($entry.category) { $entry.category } else { "UNKNOWN" }
            if (-not $categoryStats.ContainsKey($cat)) {
                $categoryStats[$cat] = 0
            }
            $categoryStats[$cat]++
        }
    }

    Write-Colored "  索引版本:    $($index.version)" "White"
    Write-Colored "  更新时间:    $($index.updated_at)" "White"
    Write-Colored "  总条目数:    $totalEntries" "White"
    Write-Colored "  活跃条目:    $activeEntries" "Green"
    if ($supersededEntries -gt 0) {
        Write-Colored "  已替代条目:  $supersededEntries" "Yellow"
    }
    Write-Colored "  总访问次数:  $totalAccessCount" "White"

    Write-Colored ""
    Write-Colored "  --- 类别分布 ---" "DarkGray"
    foreach ($key in ($categoryStats.Keys | Sort-Object)) {
        Write-Colored "  $key`: $($categoryStats[$key]) 条" "White"
    }

    # 文件大小
    if ($indexFileExists) {
        $size = (Get-Item $Script:IndexFile).Length
        $sizeStr = if ($size -gt 1MB) { "{0:N2} MB" -f ($size / 1MB) } elseif ($size -gt 1KB) { "{0:N1} KB" -f ($size / 1KB) } else { "$size B" }
        Write-Colored ""
        Write-Colored "  索引文件大小: $sizeStr" "Gray"
    }

    # 指标检查
    Write-Colored ""
    if ($totalEntries -gt 10000) {
        Write-Colored "  [!] 条目数 $totalEntries 超过建议上限 10,000，建议归档旧记忆" "Yellow"
    }
    if ($indexFileExists) {
        $size = (Get-Item $Script:IndexFile).Length
        if ($size -gt 5MB) {
            Write-Colored "  [!] 索引文件大小超过 5MB，建议归档部分条目" "Yellow"
        }
    }
}

# ═══════════════════════════════════════════════════════════════
# 结果格式化函数
# ═══════════════════════════════════════════════════════════════

<#
.SYNOPSIS
    以人类可读格式输出搜索结果。
#>
function Format-ResultsHuman {
    param($Results)

    if ($Results.Count -eq 0) {
        Write-Colored "  未找到匹配的记忆条目。" "Yellow"
        Write-Colored "  建议：尝试更通用的关键词，或运行 '-Action rebuild' 重建索引。" "Gray"
        return
    }

    Write-Colored "  找到 $($Results.Count) 条结果：" "White"
    Write-Colored ""

    $rank = 1
    foreach ($r in $Results) {
        # 分数着色
        $scoreColor = if ($r.score -ge 2.0) { "Green" } elseif ($r.score -ge 1.0) { "Yellow" } else { "Gray" }

        Write-Colored "  #$rank " -NoNewline -Color "Cyan"
        Write-Colored "[$($r.score)] " -NoNewline -Color $scoreColor
        Write-Colored "[$($r.category)] " -NoNewline -Color "Magenta"
        Write-Colored $r.content -Color "White"

        # 元数据行
        $metaParts = @()
        $metaParts += "id=$($r.id)"
        $metaParts += "scope=$($r.scope)"
        $metaParts += "source=$($r.source)"

        if ($r.metadata -and $r.metadata.confidence) {
            $confPct = [Math]::Round([double]$r.metadata.confidence * 100)
            $metaParts += "confidence=$confPct%"
        }
        if ($r.metadata -and $r.metadata.access_count) {
            $metaParts += "accessed=$($r.metadata.access_count)x"
        }
        if ($r.tags -and $r.tags.Count -gt 0) {
            $metaParts += "tags=[$($r.tags -join ', ')]"
        }

        Write-Colored ("        " + ($metaParts -join ' | ')) "DarkGray"

        $rank++
    }
}

<#
.SYNOPSIS
    以 JSON 格式输出搜索结果（供程序消费）。
#>
function Format-ResultsJson {
    param($Results)

    $output = $Results | ForEach-Object {
        [PSCustomObject]@{
            rank     = [Array]::IndexOf($Results, $_) + 1
            id       = $_.id
            category = $_.category
            scope    = $_.scope
            content  = $_.content
            score    = $_.score
            source   = $_.source
            metadata = $_.metadata
            tags     = if ($_.tags) { $_.tags } else { @() }
            aliases  = if ($_.aliases) { $_.aliases } else { @() }
        }
    }

    $output | ConvertTo-Json -Depth 5
}

# ═══════════════════════════════════════════════════════════════
# 主调度
# ═══════════════════════════════════════════════════════════════

function Main {
    # 确保 .omx 目录存在
    if (-not (Test-Path $Script:OmxDir)) {
        New-Item -ItemType Directory -Path $Script:OmxDir -Force | Out-Null
    }

    switch ($Action) {
        "search" {
            if (-not $Query) {
                Write-Colored "  用法: .\memory-search.ps1 -Query ""搜索关键词"" [-Category ""TECH_STACK""] [-Tag ""tag""] [-TopK 10] [-OutputJson]" "Yellow"
                Write-Colored "  其他操作: -Action rebuild | stats" "Gray"
                return
            }

            Write-StepHeader "Memory Search: ""$Query"""
            $results = Search-Memory -Query $Query -Category $Category -Tag $Tag -Scope $Scope -TopK $TopK -MinScore $MinScore

            if ($OutputJson) {
                Format-ResultsJson -Results $results
            }
            else {
                Format-ResultsHuman -Results $results
            }
        }
        "rebuild" {
            Rebuild-MemoryIndex
        }
        "stats" {
            Get-MemoryIndexStats
        }
    }
}

Main
