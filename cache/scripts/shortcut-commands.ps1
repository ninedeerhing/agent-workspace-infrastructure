<#
.SYNOPSIS
    Windows 终端下的 Token 管理快捷命令集合

.DESCRIPTION
    提供三个全局快捷函数，用于 Windows PowerShell 终端中
    快速进行 Token 统计、内容压缩和报告生成：

    - tk:            快速统计单个文件的 Token 数
    - compress:      压缩 Markdown 文件（去空行、去注释）
    - token-report:  生成目录下所有文件的 Token 报告

.PREREQUISITES
    pip install tiktoken（tk 和 token-report 需要）

.NOTES
    这些函数可添加到 PowerShell 配置文件中以便全局使用：
    . $PROFILE 或在其中 dot-source 本脚本

.LINK
    来源: cache/rtk-strategy.md — 4.3 Windows 终端下的快捷命令
#>

<#
.SYNOPSIS
    快速统计单个文件的 Token 数量

.DESCRIPTION
    使用 Python tiktoken 对指定文件进行 Token 计数并直接输出结果。

.PARAMETER args
    要统计的文件路径

.EXAMPLE
    tk .\src\main.py
    # 输出: Tokens: 1234
#>
function global:tk {
    python -c "import tiktoken; enc=tiktoken.get_encoding('cl100k_base'); print(f'Tokens: {len(enc.encode(open(\"$args\", encoding=\"utf-8\").read()))}')"
}

<#
.SYNOPSIS
    压缩 Markdown 文件内容（去空行、去注释行）

.DESCRIPTION
    移除 Markdown 文件中的空行和纯注释行（以 # 开头），
    将压缩结果写入同目录下的 <原文件名>.compressed 文件。

.PARAMETER File
    要压缩的 Markdown 文件路径

.EXAMPLE
    compress .\docs\readme.md
    # 生成: .\docs\readme.md.compressed
#>
function global:compress {
    param([string]$File)
    (Get-Content $File | Where-Object { $_ -notmatch '^\s*$' -and $_ -notmatch '^\s*#' }) -join "`n" | Set-Content "$File.compressed"
}

<#
.SYNOPSIS
    生成目录下所有文件的 Token 统计报告

.DESCRIPTION
    递归搜索当前目录下所有代码文件（.md、.py、.ts、.js），
    按 Token 数降序排列并以格式化的表格形式输出。
    依赖同目录下 get-token-count.ps1 中的 Get-ProjectTokens 函数。

.EXAMPLE
    token-report
    # 输出: 格式化的 Token 统计表格
#>
function global:token-report {
    Get-ProjectTokens | Format-Table -AutoSize
}
