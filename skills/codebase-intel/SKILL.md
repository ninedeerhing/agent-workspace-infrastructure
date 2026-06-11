---
name: codebase-intel
description: 代码库理解 Provider 技能。以 GitNexus/Understand-Anything 为参考，定义 AWI 代理消费代码库深度分析的标准化接口。遵循 Provider Plugin 模式：AWI 保持协议级纯粹，通过标准化接口消费外部工具的输出，而非内嵌解析引擎。
version: "1.0.0"
triggers:
  - "代码库理解"
  - "依赖追踪"
  - "影响分析"
  - "架构探索"
  - "codebase intel"
  - "explore codebase"
design_references:
  - "GitNexus MCP tools (query, context, impact, detect_changes, route_map, api_impact)"
  - "Understand-Anything knowledge-graph.json schema"
  - "GitNexus communities 阶段 — Leiden 社区检测算法"
---

# Codebase Intel — 代码库理解 Provider 技能

## 概述

本技能定义了 AWI 代理获取代码库深度理解的标准化接口。不内嵌任何解析引擎（不引入 Tree-sitter、不引入图数据库），而是通过 Provider Plugin 模式消费外部工具的输出。

**核心理念**：AWI 是代理执行环境，不是代码分析工具。代码分析能力通过外部 Provider 提供，AWI 只定义消费接口。

## Provider 架构

```
AWI 技能层（本技能）
    ↓ 标准化查询接口
Provider 适配层
    ├── GitNexus Adapter    → MCP 协议连接 GitNexus CLI
    ├── UA Adapter           → 读取 .understand-anything/knowledge-graph.json
    ├── Native Adapter       → 使用内置 Grep/Glob/Read 工具（无外部依赖）
    └── Future Adapters      → 其他代码分析工具的适配器
```

## Provider 查询接口

以下为标准化查询原语。所有 Provider 适配器必须实现此接口（Native Adapter 提供降级实现）。

### query_symbol — 符号查询

```
输入: {
  name: string,          // 符号名称（支持模糊匹配）
  repo_path: string,     // 仓库根路径
  kind?: enum(            // 符号类型过滤
    function|class|interface|type|variable|module|route|tool|all
  ),
  language?: string,      // 语言过滤
  limit?: number          // 返回数量上限，默认 10
}

输出: {
  matches: [{
    id: string,           // 符号唯一标识
    name: string,         // 符号名称
    kind: string,         // 符号类型
    file: string,         // 所在文件路径
    line: number,         // 定义行号
    summary?: string,     // 人类可读摘要（来自 GitNexus context 或 UA summary）
    tags?: string[]       // 语义标签
  }],
  total_count: number
}
```

### trace_dependency — 依赖追踪

```
输入: {
  symbol_id: string,      // 起始符号 ID
  direction: enum(        // 追踪方向
    upstream|downstream|both
  ),
  depth?: number,         // 追踪深度，默认 2
  relation_types?: enum(  // 关系类型过滤
    imports|calls|extends|implements|references|all
  )[],
  repo_path: string
}

输出: {
  root: SymbolNode,
  edges: [{
    from: string,         // 源符号 ID
    to: string,           // 目标符号 ID
    relation: string,     // 关系类型
    confidence: enum(high|medium|low),
    file: string          // 关系所在文件
  }],
  graph_summary: string,  // 人类可读的依赖链摘要
  depth_reached: number
}
```

### impact_analysis — 影响分析

```
输入: {
  changed_files: string[],  // 变更的文件列表
  repo_path: string
}

输出: {
  affected_symbols: [{
    symbol_id: string,
    name: string,
    impact_type: enum(direct|indirect|transitive),
    reason: string
  }],
  risk_summary: string,
  risk_level: enum(low|medium|high|critical)
}
```

### code_structure — 代码结构

```
输入: {
  repo_path: string,
  scope?: string[],         // 范围路径，默认项目根目录
  layer_analysis?: boolean  // 是否进行架构分层分析
}

输出: {
  file_tree: TreeNode[],
  architecture_layers?: {
    API: string[],       // API 层文件
    Service: string[],   // 服务层文件
    Data: string[],      // 数据层文件
    UI: string[],        // UI 层文件
    Utility: string[]    // 工具层文件
  },
  dependency_graph?: {
    nodes: SymbolNode[],
    edges: DepEdge[]
  },
  communities?: {        // 来自 GitNexus communities 阶段或 UA domain view
    id: string,
    name: string,
    members: string[],
    description: string
  }[],
  entry_points: string[]  // 入口文件列表（main、index、路由文件）
}
```

### api_surface — API 接口面

```
输入: {
  repo_path: string,
  framework?: string       // 框架提示（express|next|fastapi|spring|...）
}

输出: {
  routes: [{
    method: string,       // HTTP 方法
    path: string,         // 路由路径
    handler: string,      // 处理器文件#符号
    middleware: string[], // 中间件链
    consumers: string[]   // 消费者文件列表
  }],
  tools: [{               // MCP/RPC 工具（来自 GitNexus tool_map）
    name: string,
    file: string,
    description: string
  }]
}
```

## Provider Adapter 切换规则

执行时按优先级选择 Provider：

```
1. GitNexus MCP — 如果 MCP 服务器可用（npx gitnexus mcp 已运行）
   → 使用 MCP 工具获得最深度分析

2. Understand-Anything — 如果 .understand-anything/knowledge-graph.json 存在
   → 从 JSON 文件提取查询结果（无运行时依赖）

3. Native Fallback — 以上均不可用
   → 使用 Grep/Glob/Read 工具进行基本代码探索
```

## Native Fallback 降级实现

当无外部 Provider 可用时，使用 AWI 内置工具降级实现每个查询：

| 查询原语 | 降级实现方法 |
|----------|-------------|
| `query_symbol` | `Grep` 搜索符号定义模式（`function\|class\|const` + 名称）；`Read` 打开匹配文件定位定义 |
| `trace_dependency` | `Grep` 搜索 `import.*from\|require(` 语句；限制深度为 2 |
| `impact_analysis` | `Grep` 搜索变更文件中导出的符号，再搜索引用这些符号的位置 |
| `code_structure` | `Glob` + `LS` 构建文件树；`Grep` 搜索路由定义推断 API 层 |
| `api_surface` | `Grep` 搜索路由注册模式（`app.get\|router.get\|@Get` 等） |

降级实现的置信度为 `low`，且不保证完整性——在输出中必须显式标注。

## 使用示例

### 场景 1：执行代理在执行前理解代码依赖

```
代理: executor
任务: 修改 src/auth/login.ts 的认证逻辑

1. 加载 codebase-intel 技能
2. 调用 impact_analysis({ changed_files: ["src/auth/login.ts"], repo_path })
3. 获得影响分析结果：auth 中间件、session 管理、user 模型
4. 根据影响范围规划修改

→ 收益：执行代理在修改前知道 "改 login.ts 会影响哪些文件"
```

### 场景 2：探索代理分析项目架构

```
代理: explore
任务: 分析一个 200,000 行代码的陌生项目

1. 加载 codebase-intel 技能
2. 调用 code_structure({ repo_path, layer_analysis: true })
3. 获得：文件结构树 + 架构分层 + 入口点列表
4. 将结果传递给 planner → 制定调研路线

→ 收益：explore 代理从 "逐个文件 grep" 变为 "结构化知识消费"
```

### 场景 3：合并多个 Provider 的结果

```
当 GitNexus 和 UA 同时存在时：

1. GitNexus 提供：完整的调用链（crossFile 阶段）、社区检测（communities 阶段）、类型解析（scope-resolution pipeline）
2. UA 提供：人类可读摘要（LLM 生成）、引导式学习路径（tour-builder）、业务域映射（domain-analyzer）

→ 合并策略：
  - 结构事实（调用关系、类型关系）以 GitNexus（确定性 Tree-sitter）为准
  - 语义解释（摘要、标签、业务域）以 UA（LLM 生成）为准
  - 冲突时记录差异，以 GitNexus 的结构解析为基准
```

## 技能交互协议

本技能与以下 AWI 代理配合使用：

| 代理 | 使用场景 |
|------|---------|
| `explore` | 加载本技能获取结构化代码库上下文 |
| `executor` | 执行前调用 `impact_analysis` 评估变更风险 |
| `architect` | 使用 `code_structure` + `communities` 进行架构分析 |
| `planner` | 使用 `api_surface` 理解项目接口面以制定实施计划 |
| `debugger` | 使用 `trace_dependency` 追踪 bug 的调用链 |
| `code-reviewer` | 使用 `impact_analysis` 验证 PR 的波及范围 |

## 注意事项

1. **不引入依赖**：本技能文件为纯协议定义。Provider 适配器的实际实现（如启动 GitNexus MCP）由代理在运行时按需执行。
2. **隐私优先**：所有查询在本地执行（GitNexus CLI、文件读取）。不向外部服务发送代码。
3. **降级透明**：使用降级实现时必须向用户报告 "使用了 Native Fallback，结果精度有限（置信度 low）"。
4. **不替代现有工具**：本技能补充而非替代 AWI 的 `Grep`/`Glob`/`Read` 工具。简单搜索仍优先使用直接工具调用。
