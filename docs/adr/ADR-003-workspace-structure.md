# ADR-003: 工作区根目录结构

**状态:** accepted  
**日期:** 2026-06-09  
**决策者:** TRAE Workspace Harness 系统

---

## 背景

TRAE Workspace 需要定义项目的顶层目录布局。核心问题是：协议文件（AGENTS.md、SOUL.md、RULES.md、SECURITY.md）应该放在何处？状态管理文件应该独立还是分散？

候选方案之一是创建 `docs/` 子目录存放所有 `.md` 文档，但这种方法违背了 Claude Code / Codex CLI 的 AGENTS.md 根目录约定。

## 决策内容

**将 AGENTS.md、SOUL.md、RULES.md、SECURITY.md 直接放在工作区根目录，harness/ 作为独立的状态管理子目录。**

具体文件布局：

```
E:\trae_workspace\
├── AGENTS.md              — 代理指令主入口
├── SOUL.md                — 核心身份声明
├── RULES.md               — 规则契约
├── SECURITY.md            — 安全策略
├── harness/               — 状态管理（独立目录）
│   ├── feature_list.json
│   ├── progress.md
│   ├── session-handoff.md
│   ├── init.ps1
│   └── clean-state-checklist.md
├── skills/                — 技能库
├── agents/                — 代理角色
├── rules/common/          — 通用规则
├── cache/                 — 缓存策略
└── docs/                  — 调研文档和 ADR
```

## 理由

1. **遵循行业约定** — Claude Code、Codex CLI 和大多数 AI 代理工具默认从根目录读取 `AGENTS.md`，根目录放置确保零配置可用
2. **协议文件一目了然** — 开发者打开项目即可在文件树顶部看到核心契约，无需深入子目录
3. **harness/ 保持聚焦** — 状态管理目录只包含与运行时状态直接相关的文件，不混装文档或规则
4. **跨工具可移植性** — 核心协议文件路径独立于特定平台的适配目录（如 `.trae/`、`.claude/`）

## 后果

- **正面**：当用户首次打开工作区时，核心协议文件立即可见且可读
- **正面**：迁移到其他 AI 编码工具时，只需复制根目录的 4 个 `.md` 文件
- **正面**：`harness/` 目录职责单一，不会变成"杂项堆放处"
- **负面**：根目录文件较多（4 个 `.md` + 多个子目录），需要对根目录保持纪律

## 备选方案

### 方案 A：全部放入 docs/
```
docs/AGENTS.md
docs/SOUL.md
docs/harness/
```
**不采纳原因**：违反 Claude Code 的 `AGENTS.md` 根目录约定，导致工具无法自动读取。

### 方案 B：使用 .github/ 目录
```
.github/AGENTS.md
.github/SOUL.md
```
**不采纳原因**：`.github/` 是 GitHub 专用目录，语义不匹配，且不是所有工具都支持。

## 相关记录

- [ADR-001](ADR-001-harness-engineering-methodology.md) — 方法论选型
- AGENTS.md §13 — 项目结构定义
- PROGRECT-STRUCTURE.md — 目录结构详细说明
