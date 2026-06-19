# CONTEXT-PRELOAD — 新会话上下文自动预加载规范

> 补齐 everos 审计中发现的"持久化运行时缺口"和 personal_AI_infrastructure 审计中发现的"上下文自动预加载"缺口。

## 定位

定义新会话启动时的上下文自动加载序列。目标：代理在新会话中无需用户手动引导即可恢复工作状态。

## 预加载序列

```
会话启动 → 自动执行（按顺序）

0. docs/SESSION_BOOT.md    # Raindeer-AWI 统一启动契约（orchestrator-Only + worker 边界）
1. CONSTITUTION.md       # 宪法级规则（最高优先级）
2. AGENTS-lite.md        # 精简操作契约（< 500 tokens）
3. AGENTS.md             # 完整操作契约（§3 §5 §6 §7）
4. harness/agent-registry.json  # 团队 roster（若已 ProvisionTeam）
5. .omx/memory.md        # 持久记忆（项目架构 + 编码规范 + 关键决策）
6. workflow-state.json   # 当前工作流阶段
6b. harness/loop-state.json  # Loop 下一原子动作（机器态真源）
7. session-handoff.md    # 上次会话的完成状态和下一步
8. progress.md           # 完整进度日志（最后 200 行）
```

## Token 预算

预加载的总 token 消耗控制在总上下文的 5% 以内：

| 文件 | 预算 | 读取策略 |
|------|------|----------|
| CONSTITUTION.md | ~200 tokens | 全文 |
| SESSION_BOOT.md | ~300 tokens | 全文 |
| AGENTS-lite.md | ~300 tokens | 全文 |
| AGENTS.md | ~500 tokens | §3 §5 §6 §7 摘取 |
| .omx/memory.md | ~800 tokens | 全文 |
| workflow-state.json | ~200 tokens | active_workflow + current_phase |
| session-handoff.md | ~500 tokens | Current Objective + Next Step |
| progress.md | ~600 tokens | 最后 200 行 |

**总预算**: ~3100 tokens

## 恢复检查清单

加载完成后，代理自动回答 4 个问题：

1. 当前处于哪个工作流？哪个阶段？
2. 上次会话完成了什么？
3. 当前 tasks 是什么？
4. 有哪些阻塞项或风险？

## 信号检测

如果以下信号出现，表明恢复成功：
- `workflow-state.json` 的 active_workflow 非空
- `session-handoff.md` 的 Next Step 非空
- `progress.md` 的 What's Done 最新条目在 24 小时内

如果缺少 ≥2 个信号，代理应主动询问用户确认任务方向。

## 与 omc-conversation-continuity 的关系

| 场景 | 使用的机制 |
|------|-----------|
| 上下文窗口近满（>85%） | $omc-conversation-continuity → handoff prompt |
| 新旧会话切换 | context-preload → 自动加载序列 |
| 会话崩溃恢复 | archive/store.ps1 restore → context-preload |
