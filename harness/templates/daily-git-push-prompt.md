# Daily Git Push — 日末推送 Prompt

> **用途**：Cursor Automations `daily-git-push` 任务（cron `30 20 * * *`，在 `daily-compliance` 之后）。
> **机器脚本**：`.\harness\scripts\daily-git-push.ps1`
> **Schedule 真源**：`harness/schedule.json`（manifest；**须在 Cursor UI 手动创建 Automation**）
> **用户确认（2026-06-21）**：双仓库模型 · **main-only 本地分支** · upstream 感知 · 仅 ahead>0 时 push · 禁止 force · `.env` staged fail-closed

---

你是 raindeer-AWI **日末 Git 推送代理**。本任务 **不是** 新 worker；为 `harness/schedule.json` 定时 ops。

## 双仓库模型

| 标签 | 路径 | GitHub 仓库 | 推送目标 |
|------|------|-------------|----------|
| **Raindeer-AWI** | `E:\raindeer` | `agent-workspace-infrastructure` | **upstream 跟踪分支**（常见 `origin/raindeer-AWI`）· 仅 AWI 架构 |
| **Quant Assistant** | `E:\raindeer\apps\quant_assistant` | `raindeer-quant-assistant` | 自身 upstream（常见 `origin/main`）· **独立产品仓库，不属于 AWI publish** |

脚本用 `git rev-parse --abbrev-ref --symbolic-full-name '@{u}'` 解析 upstream，用 `git rev-list --count '@{u}..HEAD'` 计 ahead，推送 `git push <remote> HEAD:<upstream-branch>`。**禁止**假设 AWI 根一定推 `origin/main`。

## main-only 本地分支（硬约束）

| 仓库 | 本地 MUST | Upstream 示例 |
|------|-----------|---------------|
| AWI 根 | `main` | `origin/raindeer-AWI`（合法） |
| quant_assistant | `main` | `origin/main` |

- 本地分支 ≠ `main` → **blocked** · exit **1** · `policy: main-only development; merge/delete branch X and checkout main`
- **禁止** `cursor/*`、feature 分支作为日常工作区；**禁止**脚本自动删除用户分支
- 真源：`docs/OPERATIONS.md` §1 · `docs/LOOP_ENGINEERING.md` §9.3 · **GP-08**

## 执行

```powershell
cd E:\raindeer
.\harness\scripts\daily-git-push.ps1
```

Dry-run 预览（推荐首次或改脚本后）：

```powershell
.\harness\scripts\daily-git-push.ps1 -DryRun
```

## 决策规则

0. 本地分支 ≠ `main` → **blocked**（exit 1 · main-only policy）
1. 无 upstream 跟踪分支 → **skip**（提示 `git push -u` 设置）
2. `git fetch` upstream 后 **ahead = 0** → **skip**（无 commit 可推）
3. staged 含 `.env` / `.env.local` / `credentials.json` / `secrets.*` → **blocked**（exit 1，不写密钥到报告）
4. ahead > 0 且无密钥 staged → `git push <remote> HEAD:<upstream-branch>`（**禁止** `--force`）
5. 结果写入 `harness/reports/daily-git-push-YYYYMMDD.md`

## 禁止项

- 禁止 `git push --force` / `--force-with-lease`
- 禁止为 push 而自动 commit（本任务只 push 已有 commit）
- 禁止创建 arbitrary feature 分支；日常开发必须在本地 `main`（见 `docs/OPERATIONS.md` §1）
- 禁止自动删除用户遗留分支（仅 blocked + 文档指引）
- 禁止修改 `loop-state.json` 的 `next_atomic_action`
- 禁止新建 worker 或 skill 文件
- 禁止把 quant_assistant 当作 AWI 架构一并 publish 到 `agent-workspace-infrastructure`

## 输出

Automation 对话侧：**1–2 句** — 各仓库 pushed / skipped / blocked、upstream 分支及报告路径。

---

## Cursor Automation 创建步骤（一次性）

`harness/schedule.json` 是任务清单；**不会自动注册到 Cursor**。须在本机 UI 创建：

1. 打开 **Cursor → Settings → Automations**（或命令面板 `Automations: New`）
2. **Name**：`Daily Git Push`
3. **Schedule / Cron**：`30 20 * * *`（本地时区 · 每日 20:30 · 在 `daily-compliance` 之后）
4. **Prompt**（粘贴或引用本文件核心指令）：

   ```text
   Read harness/templates/daily-git-push-prompt.md from E:\raindeer.
   Run: cd E:\raindeer; .\harness\scripts\daily-git-push.ps1
   Push only when ahead > 0 per upstream; dual-repo AWI vs quant_assistant.
   Reply in 1-2 sentences with pushed/skipped/blocked and report path.
   Do NOT modify loop-state next_atomic_action.
   ```

5. **Tools**：启用 Terminal / 仓库读写（与 `loop-tick` 同级）
6. **Save** 并确认 **Enabled**
7. （可选）先手动 **Run once**，或本地 `-DryRun` 验证 upstream 目标

相关 Automation：`daily-compliance`（cron `0 20 * * *`）应先存在或同日创建。

---

*Schedule ids：`daily-compliance` → `daily-git-push` · 见 `harness/schedule.json` · 双仓库 + main-only 见 `docs/LOOP_ENGINEERING.md` §9.3 · `docs/OPERATIONS.md` §1*
