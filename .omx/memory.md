# OMX Memory — 分层知识记忆系统

OMX Memory 是 `AWI` 的持久化知识存储层,解决 LLM 工作流的两个根本限制：上下文窗口溢出和会话间无持久化。

## 核心理念

**时间维度压缩**：不携带 10,000 tokens 的对话历史，只携带 100 tokens 的提炼记忆。

## 分层作用域 (Hierarchical Scoping)

```
PROJECT (最广)
 └── SESSION
      └── AGENT
           └── TURN (最窄)
```

| 作用域 | 持久化范围 | 典型用途 |
|--------|-----------|----------|
| **PROJECT** | 跨所有会话，永不过期 | 项目技术栈、构建命令、编码约定、架构决策 |
| **SESSION** | 当前会话期间 | 当前任务上下文、进行中目标 |
| **AGENT** | 当前代理在会话中的生命周期 | 代理专用上下文、工具偏好 |
| **TURN** | 单轮对话 | 临时工作记忆、中间推理结果 |

## 记忆类别 (Memory Categories)

| 类别 | 说明 | 示例 |
|------|------|------|
| `TECH_STACK` | 项目技术栈信息 | "使用 TypeScript + React + Vite" |
| `BUILD` | 构建和运行命令 | "`npm run build` 编译，`npm run dev` 启动" |
| `CONVENTION` | 编码约定和风格 | "使用 Prettier 默认配置，缩进 2 空格" |
| `STRUCTURE` | 项目目录结构约定 | "按功能组织，非按文件类型" |
| `DECISION` | 已做出的技术决策 | "选择 PostgreSQL 而非 MySQL" |
| `NOTE` | 带分类的通用笔记 | "部署需要先运行数据库迁移" |
| `DIRECTIVE` | 持久化指令 | "永远不要修改 `vendor/` 目录" |

## 存储架构

```
┌────────────────────────────────────────────────────────────┐
│                     OMX Memory Store                       │
│                                                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Project      │  │  Semantic     │  │  Full-Text    │     │
│  │  Memory       │  │  Search       │  │  Search       │     │
│  │  (JSON)       │  │  (Embedding)  │  │  (Keyword)    │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                 │                 │              │
│         └─────────────────┼─────────────────┘              │
│                           ▼                                │
│              .omx/project-memory.json                      │
│              .omx/notepad.md                               │
│              .omx/memory-index.db                           │
└────────────────────────────────────────────────────────────┘
```

### 存储文件

| 文件 | 用途 |
|------|------|
| `.omx/project-memory.json` | 结构化项目记忆（技术栈、构建、约定、结构、笔记、指令） |
| `.omx/notepad.md` | 会话记事本（优先级、进行中、手动记录分段） |
| `.omx/memory-index.db` | 语义搜索索引（可选，用于大规模记忆检索） |

## 核心操作 (CRUD)

### 读取记忆

```json
// project_memory_read - 读取全部或指定分区
{
  "section": "all" | "techStack" | "build" | "conventions" | "structure" | "notes" | "directives"
}
```

### 写入记忆

```json
// project_memory_write - 写入或合并记忆
{
  "memory": { "techStack": "...", "build": "...", ... },
  "merge": true  // true=合并现有，false=完全替换
}
```

### 添加笔记

```json
// project_memory_add_note - 添加分类笔记
{
  "category": "build" | "test" | "deploy" | "env" | "architecture",
  "content": "笔记内容..."
}
```

### 添加指令

```json
// project_memory_add_directive - 添加持久化指令
{
  "directive": "指令文本",
  "priority": "high" | "normal",
  "context": "触发此指令的上下文（可选）"
}
```

## 记忆生命周期

### 智能去重 (LLM-Mediated Dedup)

当写入新记忆时，系统行为：

1. **立即保存** — 零延迟写入
2. **相似性搜索** — 查找语义相似的已有记忆
3. **返回富提示** — 若发现重复，返回可合并的建议

```json
{
  "status": "saved",
  "memory_id": "abc123",
  "note": "发现相似记忆 (id: def456, 89% 匹配)：'数据库迁移工具是 alembic'。可调用 memory_update 合并。"
}
```

LLM 自行决定是否合并，不依赖外部模型。

### 时间版本控制 (Supersession)

当事实变更时，不是覆盖而是创建替代链：

```
原始事实: "项目使用 React 17"
    ↓ supersede
新事实: "项目已升级到 React 18"
```

- 查询当前状态：排除被替代的记忆
- 查询完整历史：包含所有版本及有效性时间戳
- 用途：审计追踪、调试、回滚分析

### 记忆冒泡 (Memory Bubbling)

高频访问的记忆自动提升优先级，确保关键信息始终在检索结果前列。

## 记事本 (Notepad)

位于 `.omx/notepad.md`，提供人类可读的会话工作区：

- `# PRIORITY` — 当前优先级最高的事项
- `# WORKING` — 当前正在处理的事项
- `# MANUAL` — 用户手动添加的笔记

支持自动清理：可配置 `prune_days_old` 参数（默认 30 天），超时的进行中项自动移除。

## 安全与隔离

### 用户隔离

记忆按 `user_id` 隔离。不同开发者在同一项目中拥有独立的记忆存储。

### 代理来源追踪

每条记忆记录创建或更新的代理来源：

```json
{
  "content": "项目使用 alembic 进行数据库迁移",
  "metadata": {
    "source_agent": "claude",
    "source_provider": "anthropic",
    "created_via": "tool_call",
    "created_at_utc": "2026-06-09T10:30:00Z"
  }
}
```

### 项目隔离

每个项目的记忆存储在项目本地的 `.omx/` 目录中，不同项目间完全隔离。

## 最佳实践

1. **使用一致的 `user_id`** — 同一用户跨会话保持连续性的关键
2. **善用笔记分类** — 不同类别的信息分开存储，便于检索
3. **利用指令功能** — 将团队级别的硬约束写为 `DIRECTIVE`
4. **监控记忆增长** — 定期审查 `project_memory_read` 的输出
5. **使用替代而非删除** — 当事实变更时使用 supersession 保留历史
6. **标注置信度** — 在笔记中标注信息来源和可信度

## 与工作流的集成

| 工作流 | 集成点 |
|--------|--------|
| `$brainstorming` | 读取现有技术栈和约定，避免与历史决策冲突 |
| `$writing-plans` | 加载项目 build/conventions 作为规划上下文 |
| `$deep-interview` | 将关键决策写入 `DECISION` 类别 |
| `$executor` | 读取 build 命令，写入实现笔记 |
| `$code-review` | 参考约定检查代码风格一致性 |
| `$finishing-dev-branch` | 写入部署和环境笔记 |
