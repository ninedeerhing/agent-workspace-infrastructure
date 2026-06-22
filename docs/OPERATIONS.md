# Operations — Raindeer-AWI

> **效力**：AWI 根仓库运行与 Git 运维真源。quant_assistant 产品运行见 `apps/quant_assistant/docs/SETUP.md` · `OPERATIONS.md`（若存在）。

---

## 1. Git · main-only 开发策略（用户权威 · 2026-06-21）

**硬约束**：日常开发与 Automation push **必须在本地 `main` 分支**上进行。禁止将 `cursor/*`、feature、task 等命名分支作为默认工作区。

| 仓库 | 路径 | GitHub | 本地分支 | Upstream（跟踪分支） |
|------|------|--------|----------|----------------------|
| **Raindeer-AWI** | 仓库根 | `agent-workspace-infrastructure` | **`main`** | **`origin/raindeer-AWI`**（合法；**不是** feature 分支） |
| **Quant Assistant** | `apps/quant_assistant` | `raindeer-quant-assistant` | **`main`** | **`origin/main`** |

### 1.1 允许 vs 禁止

- **允许**：AWI 根本地 `main` 跟踪 `origin/raindeer-AWI`（upstream 名与本地分支名不同是预期配置）
- **允许**：quant 本地 `main` 跟踪 `origin/main`
- **禁止**：在任一仓库用 `cursor/*`、`feat/*`、`task*` 等分支做日常 commit / push
- **禁止**：代理或脚本**自动删除**用户遗留分支（仅文档 + `daily-git-push` **blocked**）
- **Clean-worktree gate（用户权威 2026-06-22）**：loop 每轮结束前，AWI 根与 `apps/quant_assistant` 的 `git status --porcelain` 必须为空。真实源码/测试/真源改动提交到本地 `main`；本地缓存、构建产物、截图、临时 review 输出写入 `.gitignore` 后保留不入库。若存在冲突、secret 风险或破坏性清理需求，必须标记真实阻塞并短报，禁止把 dirty_count 当作长期正常状态。

### 1.2 从非 main 分支恢复（人工）

```powershell
# Quant Assistant（独立仓库）
cd E:\raindeer\apps\quant_assistant
git status -sb
# 若有未提交工作：stash 或 commit 到 main 后再整理
git checkout main
git pull origin main
# 可选：合并后删除本地 feature 分支（用户手动）
# git branch -d cursor/git-e8c5

# AWI 根
cd E:\raindeer
git checkout main
git pull origin raindeer-AWI
```

### 1.3 日末 push 脚本

- 脚本：`.\harness\scripts\daily-git-push.ps1`
- 本地分支 ≠ `main` → **blocked** · exit **1** · 消息：`policy: main-only development; merge/delete branch X and checkout main`
- 在 `main` 上仍按 upstream 感知 ahead 计数；禁止 `--force`

详见 `docs/LOOP_ENGINEERING.md` §9.3 · `harness/templates/daily-git-push-prompt.md` · **GP-08**。

---

## 2. 双仓库 push 模型（摘要）

- AWI 根：只 publish Harness / 治理 / 架构；**不**把 quant_assistant 业务一并推到 AWI 远程
- quant：独立产品仓库；push 目标为自身 upstream
- ahead：`git rev-list --count '@{u}..HEAD'`；push：`git push <remote> HEAD:<upstream-branch>`

---

## 3. 相关 Automation

| 任务 id | Cron | 脚本 / 模板 |
|---------|------|-------------|
| `daily-compliance` | `0 20 * * *` | `harness/scripts/daily-compliance.ps1` |
| `daily-git-push` | `30 20 * * *` | `harness/scripts/daily-git-push.ps1` · `harness/templates/daily-git-push-prompt.md` |

`harness/schedule.json` 为 manifest；须在 Cursor Automations UI 手动创建任务。
