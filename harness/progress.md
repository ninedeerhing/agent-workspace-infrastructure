# raindeer 项目进度日志

> 更新时间：2026-07-13 19:17（Asia/Shanghai）
> 更新批次：SYNC-962-loop942-controlled-comparison-backtest-closed
> 本文档是 `harness/progress.md`，记录 raindeer 项目的人类可读进度日志。

---

## Hot Path Summary（2026-07-13）

- **当前主线**：TREE-6 因子构造宇宙，LOOP942 controlled comparison backtest readiness 已关闭。
- **本轮结果**：显式用户确认绑定完整 LOOP941 快照指纹；快照先经过严格 schema、指标、scope、summary、provenance、action 和嵌套执行标记重验，随后只生成分离的单因子/多因子回测草案与 qa-pg-alt 运行前复核材料。
- **验证证据**：focused 17 passed，直接 LOOP940-942 矩阵 72 passed，Verifier confirmation→selector→940→941→942 链 148 passed，Ruff、compileall、diff-check 全部通过。
- **Worker 链**：永久 Executor -> Test -> Review -> Verifier -> Sync；Review correction_cycle=1 关闭 malformed ready-shaped snapshot P2。
- **停止状态**：用户明确要求本轮收口后停止；已设置 `user_explicit_stop`，不启动 LOOP943。

---

## SYNC-962 · LOOP942 controlled comparison backtest readiness closed（2026-07-13）

- [x] 缺少用户确认：保持 awaiting_user_confirmation，草案为空。
- [x] reject/hold、过期 refs、过期 fingerprint、畸形/不安全快照全部 fail-closed。
- [x] 显式 human confirm 只产生 single-factor drafts + 一个 multi-factor draft；`executable_request=null`、`execution_allowed=false`。
- [x] Review 发现并修复 LOOP941 快照浅校验问题；严格重验发生在 fingerprint 接受之前。
- [x] 仅声明 `qa-pg-alt` + injected runner review material；无 DB/Docker/runtime、queue、scorer、backtest 或 accepted 写入。
- [x] Test/Review/Verifier/Sync 链闭合，当前按用户明确停止。

## Current State（当前状态）

- **项目阶段**：TREE-6 因子构造宇宙真实可用主线
- **整体进度**：跨类别 provisional cohort、真实单/多因子比较与消费级 accepted snapshot proposal 已完成；下一阶段为显式确认后的受控比较回测
- **当前主线**：LOOP941 closed；等待永久 Planner 签发下一核心功能
- **活跃任务树**：TREE-6
- **后台专题**：AWI permanent Worker report chain 已关闭并保持运行
- **环境状态**：本地开发环境就绪；本轮未启动 DB/Docker/runtime
  - Python 3.13 + uv
  - PostgreSQL/TimescaleDB
  - 项目根 `e:\raindeer`
  - `apps\quant_assistant` 已有完整代码基线

---

## What's Done（已完成）

### 治理文件创建（2026-06-10）
- [x] 项目根治理文件创建
- [x] `harness/` 目录结构设计与创建
- [x] AWI 治理层设计决策文档
- [x] 融合架构采用 minimum 模式（不覆盖现有业务代码）

### quant_assistant 现有基础（继承）
- [x] 状态台账：`docs/PROJECT_STATUS.md`
- [x] 工程方法论：`docs/HARNESS_ENGINEERING.md`
- [x] 文档索引：`docs/README.md`
- [x] 质量门禁：`docs/QUALITY_GATES.md`
- [x] 测试策略：`docs/TEST_STRATEGY.md`
- [x] 安全边界：`docs/SECURITY.md`
- [x] 运维手册：`docs/OPERATIONS.md`
- [x] 安装指南：`docs/SETUP.md`
- [x] 架构文档：`docs/ARCHITECTURE.md`
- [x] 工作流约定：`docs/WORKFLOWS.md`
- [x] 代理入口：`AGENTS.md`
- [x] 续接提示：`docs/CONTINUATION_PROMPT.md`
- [x] 任务树：`docs/TASK_TREES.md`
- [x] SOP 文档：`docs/SOP/`
- [x] 因子库文档：`docs/FACTOR_LIBRARY/`
- [x] 设计/实施文档：`docs/superpowers/specs/` + `docs/superpowers/plans/`
- [x] 完整测试套件
- [x] CI/CD 流程 (GitHub Actions)
- [x] Docker 开发环境配置

---

## In Progress（进行中）

### AWI 状态管理层 Bootstrap
- [ ] `harness/feature_list.json` - 功能状态追踪器
- [ ] `harness/progress.md` - 本文档
- [ ] `harness/session-handoff.md` - 会话交接模板
- [ ] `harness/workflow-state.json` - 工作流状态追踪器
- [ ] `harness/workflow-gates.md` - 工作流质量门禁
- [ ] `harness/grader-types.md` - 评分器类型定义
- [ ] `harness/clean-state-checklist.md` - 状态检查清单
- [ ] `harness/init.ps1` - 启动验证脚本
- [ ] `harness/sandbox.ps1` - uv 沙箱适配脚本
- [ ] `harness/schedule.json` + `harness/schedule.ps1` - 定时任务系统
- [ ] `harness/audit.ps1` - 兼容性审计脚本
- [ ] `harness/archive/store.ps1` + `harness/archive/index.json` - 归档引擎

---

## Next（待开始）

### 优先级排序
1. **P0**：raindeer 业务功能开发
   - 未定义具体功能（待规划）
2. **P1**：基础设施验证
   - Docker 真实环境首跑验证（如果当前阻塞已解决）
   - GitHub Actions 真实环境触发验证
3. **P2**：可观测性增强
   - 补充 metrics/health 面板
   - 收紧共享环境密码/会话策略
4. **P3**：测试资产整理
   - 整理 fixtures/mocks/fakes 目录结构

### 候选功能方向
- 基本面分析研报模块（TREE-1 相关）
- 因子评估独立推进（TREE-3 相关）
- 回测引擎增强
- 市场数据看板

---

## Blockers（阻塞项/风险）

### 当前阻塞
- **无**：当前 AWI 治理层文件创建无阻塞

### 已知风险（从 quant_assistant 继承）
| 风险 | 等级 | 描述 | 缓解措施 |
|------|------|------|----------|
| Docker 首跑验证 | P0 | 曾受宿主机 127.0.0.1:5432 端口占用阻塞 | 使用 qa-pg-alt 容器 + 非标准端口 |
| 共享环境认证 | P0 | 仍为最小实现，缺严格会话/审计 | 已默认 fail-closed |
| 可观测性 | P1 | 仍以日志为主，缺 metrics/health 面板 | 列入 P2 待办 |
| 文档分散 | P1 | 部分文档散布于多处 | 按簇治理持续收敛 |
| 消费端 action/primary 映射漂移 | P1 | 后端 queued job 已可显式 run，但前端 Jobs 页可能因 read-model action 缺失或 terminal 历史任务排在前面显示 idle | 对关键手动动作增加消费端 fallback contract，用混乱顺序 selector fixture 锁定 active primary，并用 smoke 证明 page-load no POST |

---

## Decisions Made（决策记录）

### 2026-06-10

| # | 决策 | 理由 | 影响 |
|---|------|------|------|
| D-001 | 融合架构采用 minimum 模式 | 不覆盖现有 quant_assistant 业务代码，只在 raindeer 项目根创建治理层 | `harness/` 目录独立于 `apps/quant_assistant/docs/`，形成双层治理 |
| D-002 | harness 目录独立于 apps | raindeer 是总体项目，未来可能有多个 app；治理层应在项目根 | 文档分层：raindeer 级治理 → app 级治理 |
| D-003 | 继承 quant_assistant 治理规范 | quant_assistant 已有成熟治理体系，不重复造轮子 | harness 文档引用现有工程方法论、质量门禁和测试策略 |
| D-004 | 所有 harness 文档使用中文（简体） | 项目主要协作语言为中文 | 与现有 quant_assistant 文档保持一致 |

### 继承的决策（来自 quant_assistant）
| # | 决策 | 来源 |
|---|------|------|
| D-INH-001 | 证据优先于聊天记忆 | `docs/HARNESS_ENGINEERING.md` |
| D-INH-002 | 入口先于细节，按簇治理 | `docs/HARNESS_ENGINEERING.md` |
| D-INH-003 | 裸 uv 与 qa_uv.ps1 双入口 | `docs/QUALITY_GATES.md` |
| D-INH-004 | db/external 测试默认排除 | `docs/TEST_STRATEGY.md` |
| D-INH-005 | 默认 fail-closed 安全策略 | `docs/SECURITY.md` |

---

## Files Modified（文件修改记录）

### 2026-06-10 创建
| 文件 | 操作 | 说明 |
|------|------|------|
| `harness/feature_list.json` | 创建 | 功能状态追踪器 |
| `harness/progress.md` | 创建 | 本文档 |
| `harness/session-handoff.md` | 创建 | 会话交接模板 |
| `harness/workflow-state.json` | 创建 | 工作流状态追踪器 |
| `harness/workflow-gates.md` | 创建 | 工作流质量门禁 |
| `harness/grader-types.md` | 创建 | 评分器类型定义 |
| `harness/clean-state-checklist.md` | 创建 | 状态检查清单 |
| `harness/init.ps1` | 创建 | 启动验证脚本 |
| `harness/sandbox.ps1` | 创建 | uv 沙箱适配脚本 |
| `harness/schedule.json` | 创建 | 定时任务定义 |
| `harness/schedule.ps1` | 创建 | Cron 调度引擎 |
| `harness/audit.ps1` | 创建 | 兼容性审计脚本 |
| `harness/archive/store.ps1` | 创建 | 归档引擎 |
| `harness/archive/index.json` | 创建 | 归档索引 |

---

## Evidence（证据）

### 当前环境验证
- [ ] `uv` 可用性验证（待运行 `harness/init.ps1`）
- [ ] 所有治理文件存在性验证（待运行 `harness/init.ps1`）
- [ ] Git 仓库状态检查（待运行 `harness/init.ps1`）

### 继承的验证证据（来自 quant_assistant）
- quant_assistant 测试套件已覆盖 unit/smoke/db/external 分层
- CI 流水线已定义（`.github/workflows/ci.yml`）
- Docker 开发环境已配置（`docker-compose.yml`）

---

## Notes（备注）

1. 本文件遵循 `docs/HARNESS_ENGINEERING.md` 定义的事实源优先级原则
2. 与 `docs/PROJECT_STATUS.md` 的关系：`PROJECT_STATUS.md` 是 quant_assistant 的状态事实源，`harness/progress.md` 是 raindeer 项目级进度日志
3. 当两处存在冲突时，以本项目级 `harness/progress.md` 为准（但应同步对齐）
4. 所有"已完成"声明必须有对应验证证据
5. 每轮状态更新必须同步更新本文件的 Current State 和时间戳

## 2026-07-14 · SYNC-963 · TREE-6 controlled comparison vertical slice

- Closed the user-visible LOOP941/942 comparison path: explicit Jobs action only, official injected runner only, `qa-pg-alt` contract only, with separate single-factor and multi-factor request lineage.
- Jobs and Factor Library now carry comparison run IDs, progress/report state and feedback-memory state. Strict bridge validation rejects malformed runtime/progress/report/feedback evidence without regressing legacy controlled-backtest observability.
- Verification: backend `183 passed`; bridge/surface `36 passed`; Ruff, compileall, diff check, web current-task contract and production build passed. No services, DB, Docker, queue, scorer or real backtest were started for verification.
- Status: user-requested pause after this loop; no next business action is scheduled.
