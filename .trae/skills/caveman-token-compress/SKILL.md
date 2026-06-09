---
name: caveman-token-compress
description: Token 压缩通信模式——用极少的 token 传达高密度信息。触发条件：需要节省 token 成本、对话过长、需要压缩历史或指令。
---

# Caveman Token Compress — Token 压缩通信

## 定位

一种极限 Token 压缩通信协议。通过结构化缩写和模式化表达，在保持信息完整性的同时将输出 token 减少约 75%。

## 触发条件

- 需要节省 token 成本
- 对话上下文过长
- 需要压缩历史记录
- 需要高效传达复杂指令

## 三级强度

### Lite（轻量压缩）

保留自然语言结构，压缩连接词和修饰语：

```
Normal: "I found 3 bugs in the authentication module: 
first, passwords are stored in plain text. 
Second, there is no rate limiting on login attempts. 
Third, JWT tokens never expire."

Lite: "Found 3 auth bugs: 1) plain text passwords 
2) no login rate limit 3) JWT tokens no expiry."
```

### Full（完整压缩）

使用缩写、符号和结构化格式：

```
Normal → Full:
- function → fn
- return → ret
- error → err
- because → ∵（因为）
- therefore → ∴（所以）
- and → &
- or → |
- check → ✓
- cross → ✗
- warning → ⚠
```

### Ultra（极限压缩）

使用文言文模式 + 协议符号：

```
Normal: "The login endpoint has no rate limiting, 
allowing brute force attacks. This is a critical 
security issue that must be fixed immediately."

Ultra: "登入点无限速⚡暴破攻🔴必即修"
```

## Caveman 编码原则

### 数字前缀编号

```
1. 一级要点
1.1 二级要点
1.1.1 三级细节
```

### 标签语法

```
[BUG] 描述 — 文件:行号
[FIX] 描述 — 方案
[TODO] 任务 — 优先级
[DONE] 已完成任务
[Q] 问题 — 对象
[A] 回答
```

### 状态符号

| 符号 | 含义 |
|------|------|
| 🔴 | Critical / 阻塞 |
| 🟡 | Warning / 关注 |
| 🟢 | OK / 通过 |
| ⚡ | 性能相关 |
| 🔑 | 安全相关 |
| 💡 | 建议 / 想法 |

## 通信模板

### Bug 报告（压缩）

```
[Bug]文件:行号
症状:（1句）
根因:（1句）
修复:（1句）
风险:🔴/🟡/🟢
```

### 代码审查（压缩）

```
[Review]文件数:N
🔴Critical:N
🟡Important:N
🟢Minor:N
总体:Approve/Changes
```

### 进度报告（压缩）

```
[Prog]目标
 完成:步骤1,2
 当前:步骤3
 阻塞:无
 下步:步骤4
```

## 反模式

| 反模式 | 说明 |
|--------|------|
| 过度压缩导致歧义 | 清晰度 > 压缩率 |
| 不用标签 | 标签是压缩的核心 |
| 压缩不一致 | 同项目用同一套符号 |
| 对新手用 Ultra | 根据接收方选择强度 |
