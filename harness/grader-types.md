# Grader Types — 评分器类型定义

> 本文件定义 TRAE Workspace 的 5 种评分器类型，用于 Verification Loops 质量评估。每条完成声明都应至少通过一种评分器的检查。

---

## 评分器矩阵

| 评分器 | 检查维度 | 触发阶段 | 检查项数 | 通过标准 |
|--------|----------|----------|----------|----------|
| **G-CORRECT** | 正确性 | EXECUTE → REVIEW | 5 | 5/5 pass |
| **G-COMPLETE** | 完整性 | REVIEW → VERIFY | 6 | 6/6 pass |
| **G-STYLE** | 代码风格 | EXECUTE | 5 | 无 CRITICAL 项失败 |
| **G-SECURE** | 安全性 | REVIEW → VERIFY | 5 | 5/5 pass, 0 CRITICAL |
| **G-PERF** | 性能 | VERIFY | 4 | 无回归 |

---

## G-CORRECT：正确性评分器

**触发**：每次 EXECUTE 完成后

| 编号 | 检查项 | 验证方法 | 严重性 |
|------|--------|----------|--------|
| C1 | 逻辑正确性 | 单元测试通过（目标覆盖率 80%+） | CRITICAL |
| C2 | 边界条件覆盖 | 边界值测试（空、最大、最小、null） | HIGH |
| C3 | 错误路径覆盖 | 异常输入产生合理错误（不崩溃） | HIGH |
| C4 | 幂等性 | 重复执行产生相同结果 | MEDIUM |
| C5 | 并发安全 | 并发场景下无竞态条件 | HIGH |

**通过标准**：C1 必须通过；C2-C3 至少 2/3 通过；C4-C5 至少 1/2 通过。

**失败处理**：
- C1 失败 → ❌ RED，退回 EXECUTE
- C2-C3 失败 → 🟡 记录为已知风险，可在 VERIFY 前修复

---

## G-COMPLETE：完整性评分器

**触发**：REVIEW 阶段，声明"功能完成"前

| 编号 | 检查项 | 验证方法 | 严重性 |
|------|--------|----------|--------|
| CP1 | 需求覆盖 | 对照验收标准逐项核对 | CRITICAL |
| CP2 | 文件变更完整 | 所有计划修改的文件已完成变更 | CRITICAL |
| CP3 | 测试覆盖 | 新增代码有对应测试 | CRITICAL |
| CP4 | 文档同步 | API/接口文档与代码一致 | HIGH |
| CP5 | 依赖声明 | package.json/requirements 已更新 | MEDIUM |
| CP6 | 无遗漏 TODO/FIXME | git grep "TODO\|FIXME" 0 结果 | HIGH |

**通过标准**：全部 6 项通过。任何 CRITICAL 失败 → ❌ RED。

---

## G-STYLE：代码风格评分器

**触发**：每次 EXECUTE 完成后（lint 自动运行）

| 编号 | 检查项 | 验证方法 | 严重性 |
|------|--------|----------|--------|
| S1 | 命名规范 | 函数 camelCase、文件 kebab-case、类 PascalCase | HIGH |
| S2 | 函数体长度 | ≤ 50 行 | MEDIUM |
| S3 | 文件长度 | ≤ 800 行 | MEDIUM |
| S4 | 嵌套深度 | ≤ 4 层 | HIGH |
| S5 | 无死代码 | 无被注释掉的代码块、无 console.log/debugger | HIGH |

**通过标准**：S1 和 S4 必须通过；其余至少 2/3 通过。无 CRITICAL 失败。

**工具化**：S1-S5 应通过 ESLint/Prettier/Ruff 自动检查。

---

## G-SECURE：安全性评分器

**触发**：REVIEW 阶段，`$security-review` 技能加载时

| 编号 | 检查项 | 验证方法 | 严重性 |
|------|--------|----------|--------|
| SE1 | 无硬编码密钥 | 模式匹配 KEY/SECRET/PASSWORD/TOKEN | CRITICAL |
| SE2 | 输入验证 | 所有外部输入有 schema 验证 | CRITICAL |
| SE3 | 注入防护 | SQL 使用参数化查询；HTML 输出转义 | CRITICAL |
| SE4 | 认证/授权 | 每个端点检查权限 | HIGH |
| SE5 | 错误不泄露 | 生产错误信息不含堆栈/密钥/内部路径 | HIGH |

**通过标准**：全部 5 项通过。任何 CRITICAL 失败 → ❌ RED，禁止合入。

**工具化**：SE1 已集成到 `init.ps1` 密钥审计步骤。

---

## G-PERF：性能评分器

**触发**：VERIFY 阶段，性能敏感功能

| 编号 | 检查项 | 验证方法 | 严重性 |
|------|--------|----------|--------|
| P1 | 无 N+1 查询 | ORM 查询使用 eager loading | HIGH |
| P2 | 无同步阻塞 | IO 操作使用 async/await | HIGH |
| P3 | 内存无泄漏 | 事件监听器正确 removeListener | MEDIUM |
| P4 | 包大小无膨胀 | bundle size 无显著增长（>5%） | MEDIUM |

**通过标准**：P1-P2 必须通过；P3-P4 至少 1/2 通过。无回归（与基线对比）。

---

## pass@k 质量指标

定义：连续 k 次功能完成中，评分器通过的比例。

| 指标 | 目标值 | 监控频率 |
|------|--------|----------|
| pass@1 (G-CORRECT) | ≥ 95% | 每个功能 |
| pass@1 (G-COMPLETE) | ≥ 90% | 每个功能 |
| pass@1 (G-SECURE) | ≥ 100% | 每个功能（不允许失败） |
| pass@5 (全评分器) | ≥ 85% | 每 5 个功能 |
| pass@10 (G-STYLE) | ≥ 95% | 每 10 个功能 |

**如果 pass@k 连续 2 次低于目标**：触发流程审查（$prometheus-strict 模式）。

---

## 评分器与工作流阶段对应

```
INTAKE   → 无需评分器（仅定义验收标准）
RESEARCH → G-COMPLETE（研究覆盖度检查）
PLAN     → G-COMPLETE（计划完整性检查）
EXECUTE  → G-CORRECT + G-STYLE
REVIEW   → G-CORRECT + G-SECURE + G-COMPLETE（全部）
VERIFY   → G-CORRECT + G-PERF
HANDOFF  → G-COMPLETE（交接完整性检查）
```

---

## 版本

**当前版本:** 1.0.0
**创建日期:** 2026-06-09
