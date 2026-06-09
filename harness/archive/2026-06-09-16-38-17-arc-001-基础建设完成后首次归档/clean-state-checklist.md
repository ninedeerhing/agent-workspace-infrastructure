# Clean State Checklist — agent-workspace-infrastructure 干净状态检查清单

> 本文件定义 agent-workspace-infrastructure 工作区的"干净状态"标准。在会话开始、会话结束和功能完成时使用，确保工作区始终处于可信任的状态。
>
> 基于 learn-harness-engineering 的 Verification（验证）子系统设计。

---

## 一、会话开始检查清单（Session Start）

每次新会话开始时，逐项检查以下 8 项。全部通过后方可开始工作。

| 编号 | 检查项 | 验证方法 | 期望结果 |
|------|--------|----------|----------|
| S01 | AGENTS.md 已读取并理解 | 在 IDE 中打开 `AGENTS.md`，确认已理解当前操作契约、委派规则和验证协议 | 能复述核心操作原则和当前有效的工作流 |
| S02 | init.ps1 验证通过 | 运行 `powershell -ExecutionPolicy Bypass -File .\harness\init.ps1` | 退出码 0，无失败项 |
| S03 | progress.md 已读取 | 打开 `harness/progress.md`，阅读 Current State、What's Done、What's In Progress、Blockers/Risks | 了解项目当前进度和阻塞项 |
| S04 | feature_list.json 已读取 | 打开 `harness/feature_list.json`，确认所有功能的状态 | 知道哪些功能已完成、哪些在进行中、哪些待开始 |
| S05 | session-handoff.md 已读取 | 打开 `harness/session-handoff.md`，阅读上次会话的交接内容 | 了解上次会话的目标、完成内容、决策和下一步建议 |
| S06 | Git 状态已确认 | 运行 `git status` 查看当前分支和未提交变更 | 知道当前分支、是否有未提交变更、最近提交是什么 |
| S07 | 环境工具可用 | 确认 node、git 等必要工具在 PATH 中 | 所有必要工具可用 |
| S08 | 安全基线已确认 | 确认 SECURITY.md 中的 Prompt Defense Baseline（6 条规则）已理解 | 能复述三不原则和凭证防护规则 |

**检查结论：**
- [ ] 全部 8 项通过 → 可以开始工作
- [ ] 存在未通过项 → 先解决未通过项，再开始工作

---

## 二、会话结束检查清单（Session End）

每次会话结束前，逐项检查以下 8 项。全部通过后方可结束会话。

| 编号 | 检查项 | 验证方法 | 期望结果 |
|------|--------|----------|----------|
| E01 | 所有测试通过 | 运行 `npm run test`（如果存在） | 退出码 0，0 个失败 |
| E02 | 类型检查通过 | 运行 `npm run typecheck`（如果存在） | 退出码 0，0 个错误 |
| E03 | Lint 检查通过 | 运行 `npm run lint`（如果存在） | 退出码 0，0 个警告或错误 |
| E04 | 无硬编码密钥 | 运行 `Select-String -Path "." -Pattern '(TOKEN\|SECRET\|KEY\|PASSWORD)\s*[:=]\s*["''][A-Za-z0-9_\-]{16,}["'']' -Recurse` | 0 个匹配 |
| E05 | progress.md 已更新 | 检查 `harness/progress.md` 的 What's Done、What's In Progress、Blockers/Risks 是否反映当前状态 | 所有内容是最新的 |
| E06 | session-handoff.md 已更新 | 检查 `harness/session-handoff.md` 的 Current Objective、Completed、Evidence、Next Step 是否反映当前状态 | 下次会话可无缝恢复 |
| E07 | feature_list.json 已同步 | 检查 `harness/feature_list.json` 中相关功能的状态和证据是否已更新 | 状态与实际情况一致 |
| E08 | Git 提交已完成 | 运行 `git status` 确认无遗漏的未提交变更；如有提交，确认 Commit Message 符合 Conventional Commits 规范 | 工作区干净或变更已妥善提交 |

**检查结论：**
- [ ] 全部 8 项通过 → 可以结束会话
- [ ] 存在未通过项 → 解决未通过项后再结束，或在 session-handoff.md 中记录原因

---

## 三、功能完成检查清单（Feature Completion）

当声明一个功能模块"已完成"时，必须逐项检查以下 10 项。全部通过后方可标记为 `done`。

| 编号 | 检查项 | 详细说明 | 是否通过 |
|------|--------|----------|----------|
| FC01 | 需求已完整实现 | 对照功能描述和验收标准，所有需求点均已实现 | [ ] |
| FC02 | 测试已编写且通过 | 新功能有对应的单元测试或集成测试；现有测试无回归；目标覆盖率 80%+ | [ ] |
| FC03 | 类型检查通过 | TypeScript/Python 等类型系统无错误 | [ ] |
| FC04 | Lint 检查通过 | 代码风格符合项目规范，无警告或错误 | [ ] |
| FC05 | 安全审查通过 | 已使用 security-reviewer 检查；无硬编码密钥；输入已验证；无注入漏洞 | [ ] |
| FC06 | 代码审查通过 | 已使用 code-reviewer 检查；逻辑正确；无死代码；命名清晰；遵循现有模式 | [ ] |
| FC07 | 文档已更新 | 相关 docs/ 已更新；API 文档与代码同步；变更日志已记录 | [ ] |
| FC08 | feature_list.json 已更新 | 状态已改为 `done`；evidence 字段已填入具体验证证据；dependencies 已验证 | [ ] |
| FC09 | 完成声明已发出 | 包含：改了什么文件、跑了什么检查及原始结果、什么风险未验证、下一步建议 | [ ] |
| FC10 | 无遗留阻塞项 | 无已知 Bug、无半完成代码、无 TODO/FIXME 标记（除非已记录为已知问题） | [ ] |

**功能 ID：** `___________`
**功能名称：** `___________`
**完成日期：** `___________`
**验证人：** `___________`

**检查结论：**
- [ ] 全部 10 项通过 → **功能已完成，标记为 `done`**
- [ ] 存在未通过项 → **功能未完成，继续工作或记录阻塞原因**

---

## 四、验证证据要求

### 4.1 证据的充分性

每条已验证通过的项目必须附带：

1. **检查名称：** 清楚说明做了什么检查。
2. **执行结果：** 原始输出或摘要（退出码、通过数/失败数、关键指标）。
3. **时间戳：** 检查执行的时间（至少精确到日期）。
4. **环境信息：** 执行检查的环境（操作系统版本、工具版本）。

### 4.2 证据的优先级

当多种验证方式均可用时，按以下优先级采纳：

```text
自动化测试输出 > 类型检查/Lint 输出 > 构建日志 > 手动验证截图 > 逻辑推理
```

高优先级证据不可用时，必须使用次优证据并说明原因。

### 4.3 证据记录格式

在 `feature_list.json` 的 `evidence` 字段中记录：

```json
{
  "id": "feat-xxx",
  "evidence": "TC: 15/15 pass | Lint: 0 warnings | TypeCheck: 0 errors | Build: success | Date: 2026-06-09"
}
```

在 `progress.md` 中记录详细的 Evidence of Completion 章节。

### 4.4 证据不可用时的处理

如果某项验证无法执行（例如项目无 package.json 因此无 npm scripts），必须：

1. 在检查清单中标记为"跳过"而非"通过"。
2. 记录跳过原因。
3. 使用可用的次优验证方式。
4. 在 session-handoff.md 中标记为风险/注意事项。

---

## 五、快速检查命令参考

```powershell
# 运行完整验证（Windows PowerShell）
powershell -ExecutionPolicy Bypass -File .\harness\init.ps1

# 仅运行测试
npm run test

# 仅运行类型检查
npm run typecheck

# 仅运行 lint
npm run lint

# 检查 Git 状态
git status

# 检查最近提交
git log --oneline -5

# 审计硬编码密钥
Select-String -Path "." -Pattern '(TOKEN|SECRET|KEY|PASSWORD)\s*[:=]\s*["''][A-Za-z0-9_\-]{16,}["'']' -Recurse
```

---

## 版本

**当前版本:** 1.0.0
**最后更新:** 2026-06-09
**维护者:** agent-workspace-infrastructure Harness
