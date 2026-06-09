# SECURITY-ZONES — 运行时安全区定义

> 与 CONSTITUTION.md §VI 配合，定义 TRAE Workspace 的文件系统级安全边界。

## 区域定义

### 🟢 自由区（Free Zone）
**路径**: skills/*.md, agents/*.md, cache/*, rules/common/*, .trae/skills/*
**规则**:
- 读取：无限制
- 写入：任务匹配时允许
- 删除：任务匹配时允许
- 风险等级：LOW

### 🟡 保护区（Protected Zone）
**路径**: harness/*, .omx/*, docs/*
**规则**:
- 读取：无限制
- 写入：需在 progress.md 中记录原因
- 删除：需用户显式确认
- 风险等级：MEDIUM

### 🔴 禁区（Restricted Zone）
**路径**: AGENTS.md, SOUL.md, RULES.md, SECURITY.md, CONSTITUTION.md
**规则**:
- 读取：无限制
- 写入：需用户显式许可（AskUserQuestion）
- 删除：禁止（FATAL）
- 风险等级：HIGH

## PreWrite 安全检查流程

代理在写入任何文件前必须执行此检查：

1. 确定目标文件所属区域
2. 如果是 🔴 禁区 → ❌ 立即中止，询问用户
3. 如果是 🟡 保护区 → ⚠️ 继续，但必须在 progress.md 记录
4. 如果是 🟢 自由区 → ✅ 继续，无需额外步骤

## 跨区通信规则

| 方向 | 规则 |
|------|------|
| 🟢 → 🟡 | 仅限状态文件（progress.md、session-handoff.md），写入后记录 |
| 🟢 → 🔴 | 禁止直接写入，只能通过 orchestrator 代理提交变更请求 |
| 🟡 → 🟢 | 允许（状态文件 → 技能/代理文件） |
| 🔴 → 🟡 | 仅限 orchestrator 代理写入状态文件 |

## 例外规则

以下操作不受区域限制：
- harness/init.ps1 运行（只读检查）
- harness/archive/store.ps1 归档操作
- .trae/skills/ 与 skills/ 的同步操作
- omo-health-monitor 的健康检查操作

## 违规处理协议

违反安全区规则的代理：
1. 第一次违规 → WARNING + 记录到 harness/health-log.json
2. 第二次违规 → 停止当前任务 + 手交
3. 第三次违规 → 标记为 unhealthy + 要求人工介入
