<#
.SYNOPSIS
    上下文 Token 预算实时监控脚本

.DESCRIPTION
    实时监控代理会话的上下文 Token 消耗量，根据预设的预算上限
    和告警阈值，输出不同级别的告警信息：

    - 绿色 [OK]: Token 消耗在安全范围内
    - 黄色 [WARNING]: 超过警告阈值，建议启用工具输出漏斗
    - 红色 [CRITICAL]: 超过严重阈值，立即激活 RTK 压缩

.PARAMETER Budget
    上下文 Token 预算上限，默认 128000

.PARAMETER WarningThreshold
    警告阈值百分比，默认 70（即 70% 时触发警告）

.PARAMETER CriticalThreshold
    严重阈值百分比，默认 90（即 90% 时触发严重警告）

.EXAMPLE
    .\context-budget.ps1 -Budget 200000 -WarningThreshold 75 -CriticalThreshold 85

.LINK
    来源: cache/rtk-strategy.md — 4.2 上下文预算监控脚本
#>

param(
    [int]$Budget = 128000,
    [int]$WarningThreshold = 70,
    [int]$CriticalThreshold = 90
)

$currentTokens = 0
$warningLimit = [Math]::Floor($Budget * $WarningThreshold / 100)
$criticalLimit = [Math]::Floor($Budget * $CriticalThreshold / 100)

<#
.SYNOPSIS
    更新并显示当前 Token 预算使用情况

.DESCRIPTION
    将消耗的 Token 数累加到当前计数，并输出带颜色的状态信息。

.PARAMETER Consumed
    本次消耗的 Token 数量

.EXAMPLE
    Update-Budget -Consumed 50000
#>
function Update-Budget {
    param([int]$Consumed)
    $script:currentTokens += $Consumed
    $percent = [Math]::Round($script:currentTokens / $script:Budget * 100, 1)

    if ($script:currentTokens -gt $criticalLimit) {
        Write-Host "[CRITICAL] Token: $script:currentTokens / $Budget ($percent%) — 立即激活 RTK 压缩！" -ForegroundColor Red
    }
    elseif ($script:currentTokens -gt $warningLimit) {
        Write-Host "[WARNING] Token: $script:currentTokens / $Budget ($percent%) — 建议启用工具输出漏斗" -ForegroundColor Yellow
    }
    else {
        Write-Host "[OK] Token: $script:currentTokens / $Budget ($percent%)" -ForegroundColor Green
    }
}
