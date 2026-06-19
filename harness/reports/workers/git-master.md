# Worker 工作汇报 · git-master

更新时间：2026-06-19T08:15:00Z  
Tick：`loop25-git-prep`  
Git 根目录（有历史）：`apps/quant_assistant/`（HEAD `ae29501`）  
Raindeer 根（`E:\raindeer`）：`main` 尚无 commit — harness/governance 见 **Bundle R0**

---

## 快照摘要

| 指标 | 值 |
|------|-----|
| 脏文件合计 | **428**（M 86 · D 8 · ?? 334） |
| 本轮动作 | **仅准备** — 不执行 `git commit`（用户策略） |
| 闭环树 | PL-C-UI-A · PL-C-GEN · PL-C-WR · PL-C-KB · PL-C-MINE · PL-C-BENCH · TREE-2 · TREE-3 · TREE-5 · quant-trading · docs |
| 建议 commit 数 | **16**（quant_assistant）+ **1**（raindeer harness，可选） |

---

## 全局排除（任何 bundle 均勿提交）

| 路径 / 模式 | 原因 |
|-------------|------|
| `.streamlit/` | 本地 Streamlit 缓存 |
| `tmp/` | 运行态快照 |
| `data/` | 本地数据 |
| `.review_*.{txt,stderr,stdout}` | review 临时输出 |
| `debug-factor-evaluation-submit-fail.md` | 调试笔记 |
| `factor-eval-dev-success*.png` | 截图 |
| `web/node_modules/` · `web/dist/` · `web/*.tsbuildinfo` | 已在 `web/.gitignore` |
| `.env` · `.env.local` | 密钥（SECURITY） |
| `logs/` · `.qa/` | 运行日志 |

---

## 建议提交顺序（依赖安全 · 自下而上）

> 用户在本机按序执行；每 commit 后跑最小门禁。共享文件（`schema.sql` / `models.py` / `db/engine.py`）在 **C-foundation** 一次性纳入，后续树 commit 不再重复 stage 这些文件。

### C-foundation · 共享 DB / 模型 / 依赖

**树**：跨树基础  
**类型**：`feat(db)` + `chore(deps)`

```
git add pyproject.toml uv.lock .env.example
git add src/qa/db/schema.sql src/qa/models.py src/qa/db/engine.py
git commit -m "feat(db): extend schema for intent, corpus, mining and backfill

Add intent_session, corpus, mining_loop, and backtest table extensions.
Wire engine helpers and frozen models consumed by PL-C-GEN/KB/MINE trees."
```

**验证**：`uv run pytest -q -m db --maxfail=3`（可选）· `uv run ruff check`

---

### C1 · TREE-2 — A 股历史回填

**树**：`TREE-2`  
**Conventional**：`feat(backfill): a-share history continuous runner and status snapshots`

**Stage 路径**：
- `src/qa/a_share_history/**`
- `scripts/a_share_history/**`
- `src/qa/datasources/cn_{adj_factor,cyq,index_basic,index_daily,index_weight,moneyflow,stk_weekly_monthly}.py`
- `src/qa/datasources/cn_daily_suspend_event.py`
- `src/qa/jobs/job_{asset_history_backfill,ingest_daily_snapshot_incremental,ingest_tushare_backtest_extras,post_close_daily_catchup}.py`
- `tools/qa_{appendix_c_backfill_progress,appendix_c_backfill_watchdog,cyq_chips_range_backfill,cyq_perf_range_backfill,moneyflow_range_backfill,tushare_extras_range_backfill}.py`
- `scripts/ps/run_appendix_c_{backfill_watchdog,p1_backfill}.ps1`
- `docs/APPENDIX_C_BACKFILL_PROGRESS.md`
- `docs/superpowers/{specs,plans}/2026-06-0{3,4}-a-share-*`
- `tests/test_a_share_history_*` · `test_financial_tables_db.py` · `test_asset_history_backfill_*` · `test_daily_suspend_event_filters_unit.py` · `test_schema_backtest_tables_db.py`
- 删除：`import_all_history.py` · `run_daily_incremental.ps1`

**验证**：`uv run pytest -q tests/test_a_share_history_runner_unit.py -m "not external"`

---

### C2 · PL-C-GEN — 意图解析状态机 R0–R2

**树**：`PL-C-GEN`  
**Conventional**：`feat(brain): intent understanding state machine R0-R2`

**Stage 路径**：
- `src/qa/brain/graph/**`
- `src/qa/brain/{url_extract,draft_revision_parse,orchestration_contract,orchestration_modes,pipeline_orchestrator}.py`
- `src/qa/brain/{router,runtime,taskplan,capabilities,executors}.py`（M）
- `src/qa/research/universe.py`
- `docs/ENGINEERING/2026-06-19-{intent-understanding-state-machine-final,quant-research-routing-generalization-plan}.md`
- `docs/ENGINEERING/BRAIN_RIGIDITY_ANALYSIS.md`
- `tests/test_{intake_decision_v2,intake_n1_enrichment,intent_conflict,intent_outcome,intent_session,intent_session_persist,intent_session_web_wire,interrupt_carryover,adversarial_intake,invalid_combo_reject,continuation_turn,secondary_queue_runtime,general_chat_routing,material_plan_resolver,meta_request,dispatch_queue,brain_graph_intake,brain_graph_runner,brain_routing_invariants,brain_llm_route,r1_m5_clarify_resume,url_extract}_unit.py`

**验证**：`uv run pytest -q tests/test_intake_decision_v2_unit.py tests/test_brain_routing_invariants.py`

---

### C3 · PL-C-WR — Web Research Agent Loop

**树**：`PL-C-WR`  
**Conventional**：`feat(brain): web research agent loop with bounded planner`

**Stage 路径**：
- `src/qa/brain/web_research*.py`
- `src/qa/external/{web_search,safe_http,vid2txt_client}.py`
- `docs/ENGINEERING/2026-06-1{7,8}-*web-research*.md`
- `docs/ENGINEERING/2026-06-17-web-research-test-matrix.md`
- `tests/test_web_research_*` · `test_web_search_*` · `test_safe_http_unit.py` · `test_video_transcription_quality_gate_unit.py`

**验证**：`uv run pytest -q tests/test_web_research_loop_unit.py -m "not external"`

---

### C4 · PL-C-KB — 量化语料库 KB-0 + KB-M2

**树**：`PL-C-KB`  
**Conventional**：`feat(corpus): quant knowledge corpus KB-0 and live SSE shortcut`

**Stage 路径**：
- `src/qa/corpus/**`
- `src/qa/brain/corpus_formula_{executors,flow}.py`
- `src/qa/factors/{gtja_public_transcript,mineru_latex_alpha}.py`
- `docs/ENGINEERING/2026-06-20-brain-orchestration-knowledge-corpus-master-plan.md`
- `tests/test_corpus_*` · `test_kb_m2_alpha191_acceptance.py`

**验证**：`uv run pytest -q -m db tests/test_corpus_store_db.py`

---

### C5 · PL-C-MINE — Quant R&D Loop MINE-1..6

**树**：`PL-C-MINE`  
**Conventional**：`feat(mining): quant R&D loop controller, DSL gate and Co-STEER trace`

**Stage 路径**：
- `src/qa/quant_mining/**` · `src/qa/quant_rd/**` · `src/qa/factor_dsl/**`
- `src/qa/brain/{mining_loop_flow,factor_mining_executors,batch_mining_flow}.py`
- `src/qa/factors/{expression_catalog,operator_registry,qlib_alpha158_catalog,qlib_alpha360_catalog,compute}.py`
- `src/qa/factors/compute.py`（M）
- `docs/ENGINEERING/2026-06-19-ai-quant-platform-{implementation-master-plan,landscape-redesign-research}.md`
- `docs/ENGINEERING/2026-06-18-haa-factor-mining-skill-parity.md`
- `docs/ENGINEERING/hypothesis-trial-v1.schema.yaml`
- `tools/qa_factor_mining_ready.py`
- `tests/test_{mining_loop_controller,mining_loop_dispatch,mining_runner,mining_valid_gate,mining_lab_snapshot,factor_dedup_gate,negative_kb,costeer_trace,factor_dsl,factor_dsl_f3_gate,hypothesis_contract,qa_factor_mining_ready,quant_mining_contracts,expression_catalog,signal_extraction,factor_draft_signal_filter}_unit.py`

**验证**：`uv run pytest -q tests/test_mining_loop_controller_unit.py tests/test_factor_dedup_gate_unit.py`

---

### C6 · PL-C-BENCH — 外部量化基准 stub

**树**：`PL-C-BENCH`  
**Conventional**：`feat(bench): qlib golden v0 adapter stub and WSL2 SOP`

**Stage 路径**：
- `src/qa/quant_rd/`（bench / qlib adapter 子集）
- `docs/SOP/04_wsl2_bench1_rd_agent_fin_factor.md`
- `tests/test_bench_qlib_adapter_unit.py`

**验证**：`uv run pytest -q tests/test_bench_qlib_adapter_unit.py`

---

### C7 · API — FastAPI SSE 薄层

**树**：跨树（支撑 PL-C-UI-A / PL-D）  
**Conventional**：`feat(api): FastAPI SSE thin layer for React shell`

**Stage 路径**：
- `src/qa/api/**`
- `tests/test_api_app_unit.py`

**验证**：`uv run pytest -q tests/test_api_app_unit.py`

---

### C8 · PL-C-UI-A — Claude 浅色 UI UI-A-1/2

**树**：`PL-C-UI-A`  
**Conventional**：`feat(ui): Claude light tokens, motion QA and UI-A-2 responsive shell`

**Stage 路径**（`web/` 源码 only — 不含 node_modules/dist）：
- `web/src/**` · `web/public/**`（如有）
- `web/{package.json,package-lock.json,vite.config.ts,tailwind.config.ts,tailwind.config.js,tsconfig*.json,index.html,eslint.config.js,postcss.config.js}`
- `docs/ENGINEERING/{UI-A-improvement-guide,UI-A-claude-react-foundation,design-tokens-rd}.md`
- `docs/UI-STYLE-FOR-AI.md`

**验证**：`cd web && npm run lint && npm run build`

---

### C9 · quant-trading — 六环节导航

**树**：TREE-6 / quant-trading  
**Conventional**：`feat(quant-trading): six-stage navigation pages and recent activity`

**Stage 路径**：
- `pages/Quant_*.py`
- `src/qa/quant_trading/**`
- `src/qa/ui/pages/quant_*` · `src/qa/ui/quant_trading_recent.py`（如有）
- `tests/test_quant_trading_*` · `test_quant_trading_recent_unit.py`

**验证**：`uv run pytest -q tests/test_quant_trading_unit.py`

---

### C10 · TREE-5 — Brain 平台入口 + Chat SSE

**树**：`TREE-5`  
**Conventional**：`feat(brain): unified chat entry, brain flows and run persistence`

**Stage 路径**：
- `pages/Chat.py` · `streamlit_app.py`
- `src/qa/brain/{article_factor_extract,article_insight_flow,broker_research_flow,canonical_literature_flow,factor_library_compare_flow,insight_extraction_flow,prefab_feature_flow,volume_profile_flow,video_transcription_quality}.py`
- `src/qa/brain/{insight_extraction_executors,quant_trading_executors}.py`
- `src/qa/ui/{brain_entry,chat_brain,chat_brain_jobs,chat_brain_keys,chat_history_store,chat_model_settings,chat_session_store,chat_thread_context,chat_thread_list,brain_run_resume,brain_run_store,draft_confirmation}.py`
- `src/qa/ui/chat.py` · `src/qa/ui/router.py` · `src/qa/ui/state.py` · `src/qa/ui/auth.py`（M）
- `src/qa/llm/{router,deepseek,ollama}.py`
- `src/qa/ai/tools/research_tools.py` · `src/qa/paths.py`
- `tests/test_brain_*` · `test_chat_*` · `test_research_tools_*` · `test_ui_*brain*` · `test_llm_*`

**验证**：`uv run pytest -q -m "not db and not external" tests/test_brain_router_unit.py`

---

### C11 · TREE-3 — 因子评估 / Promoted Asset

**树**：`TREE-3`  
**Conventional**：`feat(factor-eval): evaluation orchestrator, detail pages and smoke seeds`

**Stage 路径**：
- `src/qa/ui/{factor_evaluation,factor_evaluation_display,factor_library_insights,factor_version_summary,promoted_asset_detail,history,backtest,backtest_display,backtest_strategy_detail,exporting}.py`
- `src/qa/ui/pages/{factor_evaluation_page,backtest_workbench_page,research_home}.py`
- `src/qa/backtest/engine.py`
- `scripts/{detail_history_browser_smoke_seed,factor_evaluation_richer_smoke_sample}.py`
- `docs/ENGINEERING/DETAIL_HISTORY_BROWSER_SMOKE.md` · `STOCK_RESEARCH_HISTORY_BROWSER_SMOKE.md`
- 删除：`pages/{Factor_Evaluation,Board_Research,Backtest_Workbench}.py` · `src/qa/ui/pages/board_research_page.py` · `src/qa/ui/report.py`
- `tests/test_factor_evaluation_*` · `test_promoted_asset_detail_*` · `test_history_*` · `test_backtest_*` · `test_detail_history_*`

**验证**：`uv run pytest -q tests/test_factor_evaluation_orchestrator_unit.py`

---

### C12 · TREE-1 残余 — 基本面 / 报告

**树**：`TREE-1` 归档外溢  
**Conventional**：`feat(research): filing-driven report and resolver utilities`

**Stage 路径**：
- `src/qa/{external/eastmoney,reports/stock_report,resolve/security_resolver,resolve/trade_calendar}.py`
- `tests/test_{external_eastmoney,security_resolver,stock_report_smoke,trade_calendar}_*`

---

### C13 · docs/governance — 状态真源与 master-plan

**树**：`TREE-4` + harness 文档同步  
**Conventional**：`docs: sync PROJECT_STATUS, TASK_TREES and master-plan corpus`

**Stage 路径**：
- `docs/{PROJECT_STATUS,CONTINUATION_PROMPT,TASK_TREES,WORKFLOWS,ARCHITECTURE,README,SETUP,TEST_STRATEGY}.md`
- `docs/METHODOLOGY_MEMORY.md`
- `docs/ENGINEERING/README.md` · `docs/SOP/README.md`
- `docs/ENGINEERING/2026-06-16-brain-p0-p2-and-claude-ui-plan.md`
- `docs/ACCEPTANCE/**`
- `docs/superpowers/{specs,plans,research}/**`（批量 ?? — 可拆为 second docs commit 若过大）
- `AGENTS.md` · `README.md`

**验证**：人工 diff — 无密钥 · 无 `.env` 路径明文密码

---

### C14 · tests/conftest 与杂项工具

**树**：跨树测试基建  
**Conventional**：`test: shared fixtures and acceptance harness`

**Stage 路径**：
- `tests/conftest.py` · `tests/test_ai_tool_contracts_unit.py`
- `tests/test_acceptance_t4_e2e_unit.py` · `tests/test_{closure_gate_lifecycle,continuation_turn,methodology_memory_lifecycle,sync_coherence_lifecycle,verification_snapshot_lifecycle}_unit.py`
- `tools/{purge_promoted_quant_assets,web_t5_t6_poll}.py`

---

### Bundle R0 · raindeer harness/governance（可选 · 独立 repo init）

**树**：harness/governance（`E:\raindeer` 根 · 尚无 commit）  
**Conventional**：`chore(harness): AWI loop engineering and governance lifecycles`

**Stage 路径**（raindeer 根）：
- `harness/**`（含 loop-state · lifecycles · reports）
- `AGENTS.md` · `CONSTITUTION.md` · `SOUL.md` · `RULES.md` · `SECURITY*.md`
- `agents/` · `skills/` · `.cursor/rules/`
- **排除**：`.omx/` · `.trae/` · `cache/` · `_worktree_backups/` · `NINEDEER-WiKi/`

> 与 `apps/quant_assistant` 分仓提交；用户若采用 monorepo 单根策略，可先 `git init` raindeer 根再 R0。

---

## 共享文件冲突备忘

| 文件 | 归属策略 |
|------|----------|
| `schema.sql` | **C-foundation** 唯一 stage |
| `models.py` | **C-foundation** 唯一 stage |
| `db/engineering.py` | **C-foundation** 唯一 stage |
| `pyproject.toml` / `uv.lock` | **C-foundation** |
| `streamlit_app.py` | **C10**（Brain 入口为主） |
| `tests/conftest.py` | **C14**（最后或随各树 partial — 推荐 C14） |

---

## 用户执行清单（本轮回合仅准备）

```powershell
# 1. 进入 quant_assistant 仓
cd E:\raindeer\apps\quant_assistant

# 2. 确认排除项未误 stage
git status --short | Select-String -Pattern '\.env\.local|tmp/|data/|\.streamlit'

# 3. 按 C-foundation → C14 顺序逐 commit（见上各节 git add / commit -m）

# 4. 每 commit 后最小门禁
uv run ruff check .
uv run pytest -q -m "not db and not external"
```

---

## Tick loop25-git-prep

- **任务 ID**：loop25-git-prep
- **任务树**：跨树 · git-master
- **动作**：428 脏文件按 TASK_TREES 分组 · 16+1 commit bundle · **未执行 commit**
- **涉及文件**：`harness/reports/workers/git-master.md` · `docs/PROJECT_STATUS.md` §5.323 · `loop-state.json`
- **验证**：`git status` 428 行 · bundle 文档就绪 · 五 lifecycle 待跑
- **状态**：**done（prep only）**
- **更新时间**：2026-06-19T08:15:00Z

> 同步：TASK_TREES + §5.323 + CONTINUATION + loop-state + 本报告。
