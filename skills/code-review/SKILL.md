---
name: code-review
description: 员工工程师视角的 PR 代码审查。触发条件：有代码需要从工程质量和架构角度审查。
---

# Code Review — 员工工程师 PR 审查

## 定位

以资深员工工程师（Staff Engineer）视角执行 PR 审查。使用 Review Army 并行专家系统——分别从不同工程维度并行审查，确保全面覆盖。

## 触发条件

- PR 提交审查
- 代码需要从工程质量和架构角度审查
- 需要多维度专业审查

## Review Army 并行专家系统

同时从以下维度审查代码：

### 1. 架构审查（Architecture）

- 解决方案是否符合系统架构？
- 模块边界是否清晰？
- 依赖方向是否正确？
- 是否引入了不必要的耦合？

### 2. 可维护性审查（Maintainability）

- 代码是否易于理解？
- 命名是否清晰一致？
- 是否有不必要的复杂性？
- 新人能否快速上手？

### 3. 性能审查（Performance）

- 是否有 N+1 查询？
- 是否有不必要的内存分配？
- 关键路径是否高效？
- 资源是否正确释放？

### 4. 可靠性审查（Reliability）

- 错误处理是否完善？
- 边界条件是否覆盖？
- 是否有竞态条件？
- 是否考虑重试和幂等性？

### 5. 测试质量审查（Test Quality）

- 测试覆盖是否充分？
- 测试是否测试行为而非实现？
- 是否有集成测试？
- 测试是否稳定可靠？

### 6. 一致性审查（Consistency）

- 是否符合项目代码规范？
- 是否使用项目约定的库和模式？
- 是否与相邻代码风格一致？

## 审查输出

```markdown
## Code Review Report

### Architecture
- [问题/建议]

### Maintainability
- [问题/建议]

### Performance
- [问题/建议]

### Reliability
- [问题/建议]

### Test Quality
- [问题/建议]

### Consistency
- [问题/建议]

### Overall Verdict
[Approve / Approve with Comments / Request Changes]
```

## 反模式 / 红牌

| 反模式 | 说明 |
|--------|------|
| 只审查代码风格 | 黄牌。风格用 linter 解决 |
| 不做架构审查 | 红牌。架构问题是长期隐患 |
| 不审查错误处理 | 红牌。错误处理是可靠性基础 |
| 过度审查 | 黄牌。不要吹毛求疵 |
