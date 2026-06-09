# Prometheus Strict

`$prometheus-strict` 是一个 clean-room OMX 规划技能，用于执行前进行严格的访谈驱动规划。

仅受 OMO Prometheus 高层概念启发。不复制 OMO 源码文本、提示词、运行时代码或工作流实现。

Credit: 受 OMO Prometheus (`code-yeongyu/oh-my-openagent`) 启发，从概念重新实现，遵循 MIT 许可。

## 角色 (Roles)

- **Metis** 澄清需求、约束、非目标和验收标准。
- **Momus** 挑战假设、范围、交接风险和缺失的验证。
- **Oracle** 综合已批准计划并推荐 OMX 原生交接。

## OMX 交接 (OMX Handoff)

Prometheus Strict 默认为纯规划。应交接给：

1. `$ultragoal` 用于持久化目标执行。
2. `$team` 仅在 Oracle 计划识别出独立并行泳道时使用。

## 非目标 (Non-Goals)

- 不实现 hook。
- 不移植 Sisyphus 或 `start-work`。
- 不直接实现，除非显式调用下游执行工作流。
- 不从灵感项目逐字复制源码。

## 工作流概览 (Workflow Overview)

```
接收任务 → Metis 访谈 (迭代式 Checklist 清除)
               ↓
          Momus 批判 (有界重试，最多 3 周期)
               ↓
          Oracle 综合 (两遍: 综合 + 自我验证)
               ↓
          Post-Plan Metis 缺口检查
               ↓
          交接给 $ultragoal / $team
```

## 预期输出 (Expected Output)

本技能返回一份 Prometheus Strict Plan，包含：

- 澄清后的需求和验收标准
- 已解决的批判和 carry-forward 的未解决阻塞项
- Oracle 执行计划（有序步骤或独立泳道）
- 验证矩阵（每项声明 → 证据来源 → 所有者/泳道）
- 停止、回滚和上报条件
- 推荐的 OMX 交接工作流
- 可选持久化工件路径（`.omx/plans/prometheus-strict/<slug>.md`）
- Clean-room credit

## 持久化计划工件 (Durable Plan Artifacts)

当计划需要在交接或审查后存留时，将最终 Oracle 综合写入 `.omx/plans/prometheus-strict/<slug>.md`，并在调用 `$ultragoal` 或 `$team` 前将该路径包含在计划中。仅内联计划可将工件路径设置为 `N/A — 仅内联计划`。

## 角色代理提示词 (Role Agent Prompts)

三个专用提示词文件支持 Metis、Momus 和 Oracle 角色：

| 角色 | 提示词文件 | 职责 |
|------|-----------|------|
| Metis | `prompts/prometheus-strict-metis.md` | 澄清访谈、意图分类、研究扇出、spec prefill |
| Momus | `prompts/prometheus-strict-momus.md` | 对抗性批判、缺口感测、有界重试 |
| Oracle | `prompts/prometheus-strict-oracle.md` | 计划综合、两遍自我验证、验收契约 |

每个提示词是独立的 clean-room 实现，包含 `<identity>`、`<goal>`、`<constraints>`、`<scope_guard>`、`<ask_gate>`、`<execution_loop>`、`<success_criteria>`、`<tools>`、`<style>` 和 `<output_contract>` 部分。

## 调用方式

在任意工作流中显式调用：

```text
$prometheus-strict 实现用户认证系统，支持 OAuth2 和 JWT
```
