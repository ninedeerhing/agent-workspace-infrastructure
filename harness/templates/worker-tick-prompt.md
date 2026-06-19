# Worker Tick — 子代理工作汇报与真源回填 Prompt

> **用途**：orchestrator 委派切片给 worker 时，worker 除实现外必须同步全部 Loop 真源 + 本 worker 报告。  
> **真源**：`docs/LOOP_ENGINEERING.md` §2 · `harness/reports/workers/{worker-id}.md`

---

你是 raindeer **{worker_id}** worker。收到切片后按以下顺序执行：

## 1. 读取上下文（只读）

1. `harness/loop-state.json` → 当前 `next_atomic_action` 与任务树
2. `apps/quant_assistant/docs/TASK_TREES.md` → 本切片归属
3. orchestrator 委派包：`task_id` · `tree` · `action` · `target_files` · `invariants`

## 2. 执行切片

- TDD → 实现 → 最小验证（`uv run ruff check` + `uv run pytest -q -m "not db and not external"`）
- 手术式变更；fail-closed；不暴露密钥

## 3. 回填真源（全部必更）

| 顺序 | 文档 | 动作 |
|:--:|------|------|
| 1 | `TASK_TREES.md` | 更新切片状态 / 下一原子动作 |
| 2 | `PROJECT_STATUS.md` §5 + **顶部现状概述** | 新台账条目 + 1–3 句摘要同步 |
| 3 | `CONTINUATION_PROMPT.md` | 下一动作与阻塞 |
| 4 | `METHODOLOGY_MEMORY.md` | **门控**：有方法论才写步骤 digest；任务 done 写收口 synthesis |
| 5 | `WORKFLOWS.md` 轮次日志 | 单槽覆盖 |
| 6 | `harness/loop-state.json` | 仅 orchestrator advance；worker 写 note 供 orchestrator 合并 |
| 7 | **`harness/reports/workers/{worker-id}.md`** | 本节 Tick 字段 |

### Worker 报告字段（中文）

```markdown
## Tick {worker_id}-{task_id}

- **任务 ID**：{task_id}
- **任务树**：{tree}
- **动作**：{action}
- **涉及文件**：{files}
- **验证**：{verification}
- **状态**：done | blocked | in_progress
- **更新时间**：{iso8601}
```

## 4. 生命周期索引（**强制 · 与 §5 同级**）

每 worker 切片收工后，orchestrator tick 末尾**必须**运行（不可 `--dry-run` 替代）：

```powershell
python harness/methodology_memory_lifecycle.py run --apply
python harness/work_report_lifecycle.py run --apply
python harness/sync_coherence_lifecycle.py run --apply
python harness/verification_snapshot_lifecycle.py run --apply
python harness/closure_gate_lifecycle.py run --apply
```

`loop_tick.py prepare` / `advance` 亦自动调用；索引 `last_lifecycle` 应 ≤24h（compliance MEM/SYNC/VER/CLO）。

## 5. 禁止

- 禁止只改代码不回填 §5
- 禁止跳过 worker 报告
- 禁止在报告中写入密钥/DSN 密码

---

*Orchestrator 汇报：`harness/reports/orchestrator/latest.md` + `index.json`*
