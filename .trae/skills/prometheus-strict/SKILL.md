---
name: prometheus-strict
description: "[OMX] Clean-room 访谈驱动规划器：Metis 澄清需求，Momus 挑战假设，Oracle 综合输出，然后交接给 $ultragoal/$team。"
argument-hint: "<目标或问题陈述>"
---

# Prometheus Strict

Clean-room OMX 规划工作流，仅受 OMO Prometheus 高层概念启发。本技能不复制 OMO 的实现、提示词、措辞、控制流或运行时代码。在此仓库的 MIT 许可技能约定下重新实现这一理念。

Credit: 受 OMO Prometheus (`code-yeongyu/oh-my-openagent`) 启发，从概念重新实现，遵循 MIT 许可。

<Purpose>
Prometheus Strict 在歧义仍有风险时创建严格的执行前计划。它分离三种规划声音：Metis 澄清需求，Momus 挑战假设和验证缺口，Oracle 综合输出可交接的 OMX 原生计划。

输出是面向 `$ultragoal` 的纯规划工件，当独立泳道合理时输出给 `$team`。当需要持久化工件时，将最终计划存储在 `.omx/plans/prometheus-strict/` 下。
</Purpose>

<Use_When>
- 任务足够重要，浅层计划可能产生错误工作。
- 需求部分已知但验收标准、边界、风险或验证不完整。
- 用户希望执行前进行严格访谈。
- 未来的 `$ultragoal` 故事需要持久化范围、测试和交接顺序。
- 可能需要团队拆分，但泳道尚未安全到可以分配。
</Use_When>

<Do_Not_Use_When>
- 用户要求立即实现一个清晰、低风险的变化；使用正常的 executor 路径。
- 任务仅是仓库查找或解释；酌情使用 `explore`/`analyze`。
- 用户需要代码变更后的对抗性执行 QA；使用 `$qa-testing`。
- 用户需要 hook 行为、Sisyphus 行为或 `start-work` 移植。这些是明确非目标。
- 用户只需要简单规划；使用 `$writing-plans` 或 `$ralplan`。
</Do_Not_Use_When>

<Why_This_Exists>
OMX 已有 `$writing-plans`、`$ralplan` 和 `$deep-interview`。Prometheus Strict 存在于一个更窄的场景：一个明确的 clean-room 严格规划通道，包含命名的澄清、批判和综合角色，外加持久的 `.omx/plans/prometheus-strict/` 交接契约。它不是执行工作流的替代品。
</Why_This_Exists>

<Execution_Policy>
- **保持纯规划**。不要在此技能期间编辑源代码，除非用户之后单独启动执行工作流。
- **保持 clean-room 边界**。不要复制或模仿 OMO 的措辞、源码、提示词、运行时行为或控制流。
- **保持非目标可见**：不实现 hook。不移植 Sisyphus/start-work。不执行自动外部生产操作。
- **批量提问**：当高杠杆问题可以独立回答时，将它们批量打包成一个 `questions[]` 数组调用问出。仅在下一个问题依赖前一个答案时才使用逐一提问。
- **安全假设优先**：如果存在安全假设，先声明它并继续，不要为此提问。
- **需要时读取仓库**：当需要使路径、测试和交接命令具体化时使用仓库读取。
- **规划阶段研究扇出**：在 Metis 访谈期间，对每个非平凡意图执行提问前研究扇出，除非任务是平凡的、引用的规格是自包含的、或缓存证据已覆盖相同范围；使用 `explore` 获取仓库事实，使用精确的廉价 `researcher` 通道获取外部文档/OSS 参考，然后再向用户提问。Prometheus Strict 每轮最多扇出 `2 explore + 4 researcher` 代理，因此广度来自更多引用聚焦的 researcher，而 Metis/Momus/Oracle 保持更强的判断角色。
- **仅在 Oracle 识别出独立、有界、可验证泳道时**推荐 `$team`。
</Execution_Policy>

### 结构化提问面 (Structured Question Surface)

每个 Metis/Momus/Oracle 向用户提出的问题必须通过适配其运行面的结构化提问路径。纯散文提问是最后的回退，不是默认方式。

- 在 attached-tmux OMX 运行时中，使用 `omx question` 作为 OMX 拥有的结构化提问面。从 attached-tmux 的 Bash/工具路径，前缀命令 `OMX_QUESTION_RETURN_PANE=$TMUX_PANE`（或具体 `%pane` 值）以保持 leader-pane 返回目标。
- **将独立的高杠杆问题批量打包成一个 `questions[]` 数组调用**：范围、约束、非目标、交付物、安全边界和验收标准通常是独立的，必须批量打包成一个结构化表单，让用户在一个面板中回答。仅在下一个问题依赖前一个答案时才使用逐一提问。
- 在检查 checklist 清除规则、问下一轮或交接之前，等待 `omx question` 的 JSON 回答；优先使用 `answers[]` / `answers[i].answer`，仅在兼容回退时使用旧版顶级 `answer`。在每一批 `answers[]` 之后，**在再次提问或交接前至少运行两次 gap-fill 扫描**：Pass 1 将用户回答吸收进 checklist；Pass 2 重新扫描仓库上下文、前轮记录、研究扇出证据和保守默认值，以吸收非 CRITICAL 的残留缺口。
- **最少两轮提问**：当 Metis 发出任何面向用户的提问轮次后，不要在 Round 1 之后交接，除非 hostility/`<turn_aborted>` 或 round-5 上限强制退出；只有在 Round 2 已发出并处理后才允许交接。零问题完整 checklist 交接在没有发出问题的情况下仍然有效。
- **轮间规划必须主动使用证据**：在 Round 1 回答和两次 gap-fill 扫描之后，刷新或复用 `<research_fan_out>` explore/researcher 证据，重新运行 spec prefill，并仅从残留的 CRITICAL 缺口构建 Round 2。
- 在 tmux 外，使用本地结构化输入工具（如果有）。
- 当两种结构化面都无法渲染时（非 tmux 的 Codex CLI、管道运行、CI），将本轮独立问题列为编号散文块（`Q1: ... Q2: ... Q3: ...`），并等待一个用户轮次中的所有回答；不要拆分到多个往返。
- **多轮访谈是预期的**：当 checklist 尚未清除时预期多轮；每轮是一个批量表单（或其散文回退），绝不在多个表单之间拆分。

### Checklist 清除规则 (Checklist Clearance)

访谈由确定性 checklist 清除规则治理，而非主观的"感觉够了"判断。当 6 项 checklist 全部为 YES 时退出 Metis 访谈循环：目标 / 范围 IN+OUT / 验收 / 测试策略 / 交接目标 / 无未解决 CRITICAL。每项使用 `<Turn_Termination_Rules>` 中定义的三态评估。

访谈轮次上限为 **5** 以防止失控。如果到 round 5 仍未达到 checklist 清除，将剩余的 UNKNOWN 项目作为显式的 carry-forward `<unresolved_blocker>` 条目交给 Oracle。

**Hostility / 非回答退出**：如果用户对某一轮的响应包含拒绝信号（1-2 字符的非回答、`알아서` / "你决定" / "随便" 等 dismissive 模式、含脏话的响应、或前一轮的 `<turn_aborted>`），该轮使回答无效 — 它不会将任何 checklist 项目推进到 YES，立即退出访谈循环，并将未解决的缺口路由到 `<silent_absorption>`（对于 dismissive 委托）或通过 `hostility_exit` 返回给用户（对于愤怒/中止的轮次）。
</Execution_Policy>

<Turn_Termination_Rules>
每个 Prometheus Strict 轮次以恰好以下之一结束。禁止裸总结和"我觉得可以了"。

6 项 checklist 为：目标 / 范围 IN+OUT / 验收 / 测试策略 / 交接目标 / 无未解决 CRITICAL。checklist 项目为 YES 当且仅当它是 USER_ANSWERED ∪ ABSORBED_WITH_CITATION ∪ INFERRED_FROM_SPEC。仅 UNKNOWN（无回答、无引用、无规格推断）计为 NO。

- (a) `omx question` 批量：当至少一个 CRITICAL 问题在 `<gap_triage>` 和 `<self_review>` 后存留时使用。批量即轮次；轮次等待 `answers[]` 后继续。
- (b) 显式交接：当 6 项 checklist 全部为 YES 时使用。清除后 Metis → Momus 交接，批判后 Momus → Oracle 交接，Pass 2 综合后 Oracle → 用户或 `<unresolved_blocker>` carry-forward 交接。
- (c) stop-blocker：当通过 `<hostility_detection>` 检测到 hostility/`<turn_aborted>`（子类型 `hostility_exit`）时使用，或当下一步是破坏性、凭证保护、外部生产且无法安全默认时使用。

边缘情况：
1. 零问题但 checklist 完整 → 选项 (b) 显式交接。不要发出空的 `omx question` 表单。
2. Round-5 上限但 checklist 不完整 → 选项 (a) 发出最后一轮问题批量并标注存留的 UNKNOWN 项目，或选项 (b) 交接并将 UNKNOWN 项目 carry-forward 给 Oracle 作为 `<unresolved_blocker>` 条目。
3. Hostility/`<turn_aborted>` → 对于愤怒、脏话或中止轮次使用选项 (c) 通过 `hostility_exit`；对于 dismissive 委托（`알아서` / "你决定"）使用选项 (b) 并标注被吸收的缺口。
</Turn_Termination_Rules>

<Steps>
### 1. Intake and Safety Bounds（接收与安全边界）

重述目标结果、已知约束、交付物、验证期望和停止条件。识别本轮是纯规划还是用户也请求了下游执行。

如果提示包含破坏性、凭证保护、外部生产或实质性改变范围的决定，保留这些决定待用户显式确认。否则，继续规划循环。

### 2. Metis Interview — 迭代式 Checklist 清除

使用 `prometheus-strict-metis` 作为访谈声音。当本地子代理可用时调用专用代理；否则在上下文中运行同一角色而不编辑文件。

Metis 发现成功标准、非目标、证据与假设、所需工件、可能的执行泳道和缺失的决策。**在第一个面向用户的提问批量之前**，Metis 必须按意图主动扇出仓库/外部研究：`explore` 映射本地面，精确的 `researcher` 通道收集官方/上游或 OSS 参考证据。

**扇出默认开启**：对于所有非平凡意图，研究扇出是默认开启的，不是触发条件式的。跳过规则：仅平凡意图（trivial）可普遍跳过。按意图的强制最小派发量：
- **simple**：至少 1 explore 基线
- **refactor**：至少 1 explore（保留面映射）
- **build-from-scratch**：至少 1 explore + 2 researcher
- **architecture**：至少 1 explore + 2 researcher
- **test-infra**：至少 1 explore + 2 researcher
- **research**：至少 2 researcher
- **STRONGLY PREFER**：对 build-from-scratch 和 architecture 强烈推荐

最大预算：每轮 `2 explore + 4 researcher`。

**访谈循环**：
1. 识别每个当前 UNKNOWN 的 checklist 项目，以及每个回答会实质性改变范围、安全或验证的 CRITICAL 问题。
2. 运行 `<gap_triage>`：将缺口分类为 CRITICAL（发问）| MINOR（声明假设，吸收）| AMBIGUOUS（使用保守行业默认值并标注）。
3. 运行 `<self_review>`：对照 7 个问题质量门重新检查。
4. 发出批量提问（如有 CRITICAL 缺口）或交接（如 checklist 完整）。
5. 收到回答后运行至少两次 gap-fill 扫描。
6. 在多轮之间刷新研究扇出证据。
7. 不要在一次 gap-fill 扫描后交接。不要在仅发出 Round 1 后交接（除非零问题完整 checklist 或 hostility/上限强制退出）。

**意图分类**：在访谈前将任务分类为以下之一：trivial、simple、refactor、build-from-scratch、research、spec-driven、test-infra、architecture、collaboration。
- trivial：完全不访谈
- simple/spec-driven/refactor：最多 1-2 个针对性问题
- 简短/模糊动词（"改进"、"修复"、"develop"、"디벨롭"）→ 路由到 simple/trivial 或 explore-first
- build-from-scratch/architecture：仅在显式新功能/从零开始关键词时分类

**Spec Prefill**：在访谈前扫描 PRD、RFC、issue、package.json、Cargo.toml 等规格信号，从 `docs/specs` 和 `docs/rfcs` 预填 checklist。

**Gap Triage（缺口分类）**：
- CRITICAL：发问（安全、范围、验收有实质性差异）
- MINOR：声明假设并继续，不发问
- AMBIGUOUS：使用保守默认值并显式标注

**Silent Absorption（静默吸收）**：低杠杆缺口必须由 Metis 自行回答（从仓库上下文、前轮记录、行业默认推断），不作为用户问题发出。

**Plan-A vs Plan-B 吸收**：当 Plan-A 和 Plan-B 在 5 个 CRITICAL 轴（范围边界 / 验收标准 / 回滚契约 / 泳道分配 / 交接目标）上保持一致时，必须吸收进计划。仅在计划有结构性差异时才发问。默认吸收。

**单次测试策略决策**：对 build/refactor/test-infra 意图，将测试策略合并为单一打包决策（TDD / 实现后测试 / 仅代理 QA / 无自动测试），而非三个独立问题。

**Hostility / 非回答检测**：
- 1-2 字符的简短响应 → 标记为非回答
- dismissive 模式（"알아서" / "你决定" / "whatever"）→ 作为非回答退出
- 脏话响应 → hostility 信号
- 退出访谈循环，不继续提问
- 将未解决决策上报给用户或 carry-forward，不静默吞掉
- hostile 响应不推进 checklist 项目

### 3. Momus Critique（Momus 批判）

使用 `prometheus-strict-momus` 作为批判声音。

Momus 挑战：假设、范围风险、缺失的验证门、泳道冲突、交接风险和测试覆盖缺口。

**有界重试**：Momus → Oracle 重新综合最多 3 个周期。在第 3 周期后将未解决的批判 carry-forward。批判必须指向列表中可验证的缺口，而非主观判断。

**默认吸收优先**：不要发问，除非 Plan-A 和 Plan-B 在 5 个 CRITICAL 轴上有分歧。有疑问时作为 `<unresolved_blocker>` 条目 carry-forward。

### 4. Oracle Synthesis（Oracle 综合 — 两遍）

使用 `prometheus-strict-oracle` 作为综合声音。

**Pass 1 — 综合**：
1. 重述最终目标。
2. 将 Metis 发现转化为需求和验收标准。
3. 解决或 carry-forward Momus 反对意见。
4. 将执行拆分为有序步骤或独立泳道。
5. 将每个交付物映射到验证证据。
6. 声明停止、回滚和上报条件。
7. 提供推荐的 OMX 交接。

**Pass 2 — 自我验证（机器可检查的验收契约）**：
8. 验证矩阵中的每个声明都有显式证据来源（test/build/lint/e2e/doc）。
9. 每个步骤列出其所有者/泳道/执行者；并行泳道之间无共享文件冲突。
10. 停止、回滚和验收标准相互一致（没有验收标准被同时触发回滚的状态满足）。
11. 没有破坏性、凭证保护或外部生产步骤在未授权情况下执行。
12. 交接命令具体（可直接调用）并指向现有工作流（`$ultragoal`、`$team` 或 `none`）。
13. 保留 clean-room credit。
14. 如果任何 Pass 2 检查失败，循环回 Pass 1 步骤 1 以修复后再发出计划。Pass 1 ↔ Pass 2 周期上限为 3；在周期 3 失败时，发出计划并标注失败的 gate 为 carry-forward，并上报用户。

### 5. Post-Plan Metis Gap Check（规划后 Metis 缺口检查）

在 Oracle 综合后，Metis 重新评估最终计划以确保没有在合成过程中引入新的缺口。如发现缺口，路由回 Oracle 进行修复。
</Steps>

<Tool_Usage>
- 使用只读仓库检查：当计划正确性依赖实际路径或命令时。
- 使用 `explore` 进行仓库面映射和符号定位。
- 使用 `researcher` 进行外部文档和 OSS 参考查找。
- 使用 `task(subagent_type=...)` 进行后台研究扇出派发。
- 使用 `omx question` 进行结构化提问（在 attached-tmux OMX 运行时）。
- 不在此技能期间编辑文件；在 `Steps` 中声明的持久化计划工件路径是推荐的，需要用户或下游工作流执行写入。
</Tool_Usage>

<Final_Checklist>
在交接前，验证：
- [ ] 6 项 checklist 全部 YES（目标 / 范围 IN+OUT / 验收 / 测试策略 / 交接目标 / 无未解决 CRITICAL）
- [ ] Metis checklist 清除已完成
- [ ] Momus 有界重试已完成（最多 3 周期）
- [ ] Oracle Pass 2 自我验证已完成
- [ ] Post-plan Metis 缺口检查已完成
- [ ] Clean-room credit 已保留
- [ ] 交接命令具体且可调用
- [ ] 持久化计划工件路径已文档化（或标注为 N/A — 仅内联计划）
</Final_Checklist>

<Advanced>
### 持久化计划工件 (Durable Plan Artifacts)

当计划需要在交接或审查后存留时，将最终 Oracle 综合写入 `.omx/plans/prometheus-strict/<slug>.md`，并在调用 `$ultragoal` 或 `$team` 前将该路径包含在计划中。仅内联计划可将工件路径设置为 `N/A — 仅内联计划`。

### 与 OMX 工作流的集成

```text
$prometheus-strict (本技能)
    ↓ (checklist 清除，Momus 批判，Oracle 综合)
    ↓
$ultragoal (持久化目标执行) 或 $team (独立并行泳道)
    ↓
$executor | $ralph-loop (实现)
    ↓
$qa-testing (验证)
    ↓
$code-review (审查)
```

### 角色代理提示词

三个角色由专用提示词文件支持：
- `prompts/prometheus-strict-metis.md` — Metis 澄清访谈
- `prompts/prometheus-strict-momus.md` — Momus 对抗性批判
- `prompts/prometheus-strict-oracle.md` — Oracle 计划综合

每个提示词是独立的 clean-room 实现，包含 identity、goal、constraints、scope_guard、ask_gate、execution_loop、success_criteria、tools、style 和 output_contract 部分。
</Advanced>

---

原始任务: {{PROMPT}}
