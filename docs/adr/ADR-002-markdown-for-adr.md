# ADR-002：采用 Markdown 格式存储架构决策记录

**状态**：已采纳

**日期**：2026-06-09

**决策者**：TRAE Workspace 架构团队

---

## 背景

TRAE Workspace 作为一个 AI 工程工作区，需要在开发过程中持续记录架构决策。这些决策记录需要满足以下需求：

- **可被 AI 代理直接读取**：无需额外工具或渲染步骤，AI 代理能直接解析和理解
- **版本控制友好**：差异可读、合并友好、适合 Git 管理
- **人类可读**：开发者能直接用任何文本编辑器阅读和编辑
- **结构化但灵活**：有标准模板确保一致性，但允许部分自定义
- **与项目技术栈一致**：项目已经是 Markdown 驱动的（AGENTS.md、SOUL.md、RULES.md 等）

考虑的备选格式：

- **纯文本（.txt）** — 最简单，但缺乏结构化和链接能力
- **Markdown（.md）** — 结构化文本，支持标题层级、列表、表格和链接
- **AsciiDoc（.adoc）** — 更丰富的语义标记，但工具链更重
- **YAML/JSON** — 严格结构化，但可读性差，不适合长篇说明
- **Wiki 页面** — 需要额外的服务端基础设施

---

## 决策

**我们将使用 Markdown（.md）格式存储所有架构决策记录（ADR）**，遵循 Michael Nygard 的 ADR 模板结构，并适配项目的中文文档约定。

具体实施：

1. 所有 ADR 存放在 `docs/adr/` 目录
2. 文件命名规范：`ADR-NNN-简短描述.md`，如 `ADR-001-harness-engineering-methodology.md`
3. ADR 编号从 001 开始，顺序递增
4. 使用 [TEMPLATE.md](file:///e:/trae_workspace/docs/adr/TEMPLATE.md) 作为标准模板
5. 模板包含以下章节：背景、决策、理由、后果、备选方案、参考资料

---

## 理由

Markdown 是唯一同时满足所有需求的方案：

1. **AI 代理原生可读**：所有主流 AI 编码工具（Trae、Claude Code、Codex CLI、Cursor 等）都原生支持 Markdown 渲染和解析，无需额外处理

2. **版本控制友好**：纯文本格式，`git diff` 可精确显示每次决策的变更内容。相比之下，二进制格式或 Wiki 无法做到这一点

3. **零工具链依赖**：不需要 AsciiDoc 处理器、YAML 验证器或 Wiki 服务器。开发者用任何编辑器即可创建和修改 ADR

4. **与技术栈一致**：TRAE Workspace 的所有核心协议文件（AGENTS.md、SOUL.md、RULES.md、SECURITY.md、agents/*.md、skills/*/SKILL.md）均为 Markdown 格式。选择 Markdown 保持了整个工作区的技术一致性，降低了认知负担

5. **结构化能力充足**：标题层级支持章节组织，表格支持备选方案对比，链接支持跨 ADR 引用

**备选方案不足**：

- **YAML/JSON**：严格结构化适合机器处理，但对于需要长篇叙述的"背景"和"后果"章节，自由文本表达能力远优于结构化格式
- **AsciiDoc**：功能更丰富但工具链更重，在 AI 编码工具中的原生支持不及 Markdown
- **Wiki**：无法做到与代码同分支版本控制，"代码变更但文档未同步"的问题在 Wiki 中更为突出

---

## 后果

### 正面影响

- **零门槛**：任何开发者或 AI 代理都可以直接创建和修改 ADR
- **Git 原生**：ADR 与代码在同一仓库、同一分支，差异跟踪和代码审查天然支持
- **工具兼容**：GitHub/GitLab 等平台自动渲染 Markdown，方便在线查阅
- **跨平台可移植**：纯文本格式，不绑定任何特定平台或工具

### 负面影响

- **无强制约束**：Markdown 无法像 JSON Schema 那样对文档结构进行自动校验。模板合规性依赖人工审查
- **无内置图表**：复杂架构图需要借助 Mermaid（需渲染器支持）或外部图片。决定在需要时使用 Mermaid 代码块
- **无自动索引**：ADR 之间的引用关系需要手动维护，无法像数据库那样自动关联

### 中性影响

- ADR 文件与代码共享同一 Git 历史，需要遵循相同的提交规范（Conventional Commits）
- 新增 ADR 时应在对应代码变更的同一 PR 中提交，确保决策记录与实现同步

---

## 备选方案

| 方案 | 简述 | 未采纳原因 |
|------|------|------------|
| YAML/JSON | 严格结构化格式，可自动校验 | 长篇叙述可读性差；不适合"背景"和"后果"等自由文本章节 |
| AsciiDoc | 丰富语义标记，适合技术文档 | 工具链依赖；AI 编码工具中原生支持不及 Markdown |
| Wiki 页面 | 在线协作编辑，支持丰富的多媒体 | 无法与代码同分支版本控制；文档与代码容易不同步 |
| 纯文本 | 最简单，零依赖 | 缺乏结构化能力；无法使用表格和链接 |

---

## 参考资料

- Michael Nygard, [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) — ADR 概念的原始提出
- [TEMPLATE.md](file:///e:/trae_workspace/docs/adr/TEMPLATE.md) — 本项目的 ADR 标准模板
- [ADR-001](file:///e:/trae_workspace/docs/adr/ADR-001-harness-engineering-methodology.md) — 首个 ADR，定义了工作区核心框架
- [AGENTS.md](file:///e:/trae_workspace/AGENTS.md) — 项目文档均为 Markdown 格式的例证
