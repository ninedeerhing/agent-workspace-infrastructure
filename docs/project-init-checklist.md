# 大型项目启动检查清单

> **准入标准**：启动大型项目前，以下所有项必须全部通过。任何一项未通过即阻塞开工。

---

## 1. 项目骨架搭建

- [ ] 目录结构已按功能/领域组织（非按文件类型堆叠）
- [ ] `AGENTS.md` 已编写，明确代理指令和委派规则
- [ ] `SOUL.md` / `RULES.md` / `SECURITY.md` 已就位
- [ ] `.trae/rules/project_rules.md` 已配置 IDE 级规则
- [ ] `harness/` 目录已初始化（feature_list.json、progress.md）
- [ ] `skills/` 目录已创建，通用技能已导入
- [ ] `.gitignore` 已覆盖：`node_modules/`、`.env`、`dist/`、`coverage/`、`*.log`

## 2. 数据库设计评审

- [ ] ER 图已完成并通过架构师审查
- [ ] 迁移策略已选定（up/down 文件 or 声明式）
- [ ] 主键统一使用 `id`（UUID or 自增），外键命名 `<表名>_id`
- [ ] 所有表包含 `created_at` 和 `updated_at` 时间戳
- [ ] 索引设计已评审：覆盖索引 > 复合索引 > 单列索引
- [ ] 无过度索引（写密集型表控制 5 个以内）
- [ ] 备份策略已制定（全量周期 + 增量频率）
- [ ] 回滚计划已演练至少一次

## 3. API 设计评审

- [ ] URL 设计遵循 RESTful 规范（名词复数、层级清晰）
- [ ] 版本控制策略已确定（URL 前缀 or Header 方式）
- [ ] 统一响应格式已定义：`{ status, data, error, meta }`
- [ ] 分页规范已统一（page/size 或 cursor-based）
- [ ] 错误码体系完整（业务码 + HTTP 状态码映射表）
- [ ] 速率限制策略已制定（含 429 + Retry-After 头）
- [ ] OpenAPI 3.0 文档生成流程已纳入 CI

## 4. 依赖审计

- [ ] 所有第三方依赖的 License 已检查（禁止 GPL/AGPL 传染性协议）
- [ ] `pnpm audit` / `npm audit` 无 HIGH 或 CRITICAL 级别漏洞
- [ ] 依赖版本已固定（lockfile 提交到仓库）
- [ ] 直接依赖数量合理（每个领域 ≤ 5 个核心依赖）
- [ ] 无废弃或停止维护的依赖包

## 5. 分支策略

- [ ] 分支模型已选定并文档化（Git Flow / trunk-based / GitHub Flow）
- [ ] 分支保护规则已配置（main 分支禁止直接推送）
- [ ] PR 模板已创建（含检查清单、截图区域、测试说明）
- [ ] `using-git-worktrees` 流程已就绪，支持并行开发
- [ ] 提交规范已确定（Conventional Commits 格式）
- [ ] 合并策略已设定（squash merge or rebase merge）

## 6. 环境配置

- [ ] `.env.example` 模板已创建（含所有必需变量及说明）
- [ ] 密钥管理方案已选定（Vault / Infisical / 云厂商密钥服务）
- [ ] 多环境策略已定义：`development` → `staging` → `production`
- [ ] CI/CD 流水线变量已在对应平台配置
- [ ] `.env` 已加入 `.gitignore`，绝无硬编码密钥
- [ ] 本地开发环境一键启动脚本已就绪

## 7. 质量门禁

- [ ] 代码检查工具已配置（ESLint / Biome / Ruff）
- [ ] 类型检查已纳入 CI（TypeScript strict mode / mypy）
- [ ] 测试框架已选定，目标覆盖率 ≥ 80%
- [ ] Pre-commit hook 已配置（lint-staged + husky / lefthook）
- [ ] CI/CD 流水线模板 `harness/ci-cd-template.yml` 已适配到项目

---

**检查日期**：________　　　**检查人**：________　　　**批准人**：________
