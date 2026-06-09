<#
.SYNOPSIS
    Token 计数工具函数——使用 tiktoken 进行精确的 Token 计数统计

.DESCRIPTION
    本脚本提供两个核心函数：
    - Get-TokenCount: 对单段文本进行精确 Token 计数
    - Get-ProjectTokens: 批量统计目录下所有代码文件的 Token 数

.PREREQUISITES
    pip install tiktoken

.LINK
    来源: cache/rtk-strategy.md — 策略一（推理链分段）
#>

<#
.SYNOPSIS
    对指定文本进行精确 Token 计数（使用 cl100k_base 编码器）

.DESCRIPTION
    调用 Python tiktoken 库计算文本的 Token 数量。
    自动对文本中的双引号进行转义处理。

.PARAMETER Text
    要计数的文本内容

.EXAMPLE
    Get-TokenCount -Text "Hello, world!"
    # 输出: 4
#>
function Get-TokenCount {
    param([string]$Text)
    $escaped = $Text -replace '"', '`"'
    python -c "import tiktoken; enc=tiktoken.get_encoding('cl100k_base'); print(len(enc.encode(`"$escaped`")))"
}

<#
.SYNOPSIS
    批量统计目录下所有代码文件的 Token 数量

.DESCRIPTION
    递归搜索指定目录，对所有 .md、.py、.ts、.js 文件进行 Token 计数，
    按 Token 数降序排列输出。

.PARAMETER Path
    要统计的根目录路径，默认为当前目录 "."

.EXAMPLE
    Get-ProjectTokens -Path "e:\trae_workspace"
    # 输出: 按 Token 数降序排列的文件列表
#>
function Get-ProjectTokens {
    param([string]$Path = ".")
    Get-ChildItem -Path $Path -Recurse -Include *.md,*.py,*.ts,*.js |
        ForEach-Object {
            $content = Get-Content $_.FullName -Raw
            $tokens = Get-TokenCount -Text $content
            [PSCustomObject]@{File=$_.Name; Tokens=$tokens; Path=$_.FullName}
        } | Sort-Object Tokens -Descending
}
