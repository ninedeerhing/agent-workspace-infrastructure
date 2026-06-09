# ADR — Architecture Decision Records（架构决策记录）

本目录存放 TRAE Workspace 的架构决策记录。ADR 用于记录重要的技术选型、架构变更和方法论决策，帮助未来的维护者理解决策的背景和理由。

## 使用方法

1. 复制 `TEMPLATE.md` 创建新的 ADR
2. 按 `ADR-NNN-简短描述.md` 格式命名（NNN 从当前最大编号 +1）
3. 填写所有章节后，将状态设为 `accepted`
4. 在本项目文件中引用 ADR 时使用格式：`docs/adr/ADR-NNN.md`

## ADR 状态

| 状态 | 含义 |
|------|------|
| `proposed` | 提案中，等待讨论 |
| `accepted` | 已接受，当前有效 |
| `deprecated` | 已废弃，但未替代 |
| `superseded` | 已被新的 ADR 替代 |

## 索引

| 编号 | 标题 | 状态 | 日期 |
|------|------|------|------|
| ADR-001 | Harness Engineering 方法论选型 | accepted | 2026-06-09 |
| ADR-002 | Markdown 格式存储 ADR | accepted | 2026-06-09 |
| ADR-003 | 工作区根目录结构 | accepted | 2026-06-09 |
| ADR-004 | 集成来源优先级体系 | accepted | 2026-06-09 |
