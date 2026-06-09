# Headroom 上下文压缩策略

> 基于 [Headroom](https://github.com/chopratejas/headroom) 项目（10.4K+ Stars, Apache-2.0 License）的实践经验，本文档提供 Headroom 上下文压缩系统的完整策略指南。

---

## 1. Headroom 是什么

Headroom 是一个**上下文优化层**（Context Optimization Layer），位于你的应用/代理与 LLM 提供商之间。每一个工具调用输出、数据库查询结果、文件读取和 RAG 检索结果中 70-95% 是冗余内容。Headroom 在内容到达 LLM 之前进行压缩。

**核心数据**：
- 平均 Token 减少 **87%**
- 答案准确率 **100%**（压缩不丢失关键信息）
- 生产环境 50,000+ 代理会话，250+ 实例
- 累计节省 **14 亿 tokens**（~$4,000 成本节省）

**运行模式**：

```
你的代理/应用
 │
 │ 工具输出、日志、数据库读取、RAG结果、文件读取、API响应
 ▼
 Headroom ← 透明代理 / Python SDK / 框架集成
 │
 ▼
 LLM 提供商 (OpenAI, Anthropic, Google, Bedrock, 100+ via LiteLLM)
```

---

## 2. 六种压缩算法概述

### 2.1 SmartCrusher（JSON 压缩器）

**目标**：结构化 JSON 数组的智能压缩

**策略**：
- 保留前 N 项（schema 推断）
- 保留后 N 项（recency）
- 保留所有异常项（errors, warnings, nulls）
- 保留统计分布（数值字段的 min/max/mean）
- 丢弃中间冗余项

**性能**：

| 场景 | 原始 Tokens | 压缩后 | 节省 | 延迟 |
|------|------------|--------|------|------|
| JSON 数组 (100 项) | 10.2K | 1.5K | **85.3%** | 189ms |
| JSON 数组 (500 项) | 50.2K | 1.5K | **97.0%** | 943ms |
| JSON 数组 (1K 项) | 100.5K | 1.5K | **98.5%** | 2,012ms |
| API 响应 (500 项) | 38.9K | 1.1K | **97.2%** | 743ms |
| 数据库行 (1K rows) | 43.7K | 605 | **98.6%** | 961ms |

### 2.2 CodeCompressor（AST 感知代码压缩器）

**目标**：源代码的结构化压缩

**支持语言**：Python, JavaScript, TypeScript, Go, Rust, Java, C++

**策略**：
- 提取函数/类签名（保留 API 表面）
- 压缩函数体（仅保留关键调用和异常路径）
- 删除注释（可配置保留文档注释）
- 删除 import 中未使用的符号
- 保留 docstring/类型注解

**安全设计**：代码压缩器**仅对超长文件激活**。短文件（<100 行）透传以保证完整性。当 LLM 需要完整代码时，通过 CCR 检索。

### 2.3 Kompress-base（文本压缩器）

**目标**：自然语言文本和日志的语义压缩

**实现**：基于 HuggingFace 训练的自有模型（ONNX 运行时），在 Agentic Traces 上微调

**策略**：
- 识别并删除冗余段落
- 保留关键信息密度高的句子
- 保留错误代码、数值、日期等结构化信息
- 对技术文档保留操作步骤

**适用内容**：RAG 检索结果、文档页面、日志输出、用户对话历史

### 2.4 CacheAligner（前缀缓存稳定化器）

**目标**：稳定化 prompt 前缀，最大化提供商 KV Cache 命中率

**机制**：
- 检测不同请求间的共享前缀
- 自动重排内容块以稳定前缀（如将 system prompt 固定在前）
- 消除动态变化的内容（时间戳、随机 ID、token 计数）
- 将动态内容移到 prompt 末尾

**性能**：亚毫秒级延迟（<1ms），不影响请求速率

**效果**：在 Anthropic 和 OpenAI 的 prompt caching 基础上额外提升 20-40% 缓存命中率

### 2.5 IntelligentContext（智能上下文填充器）

**目标**：在有限 token 预算内最大化上下文质量

**策略**：
- 基于学习的重要性评分对内容块排序
- 预算约束下的最佳子集选择（背包问题变体）
- 适应不同模型的 token 限制
- 内容块可以交叉引用（如果 A 被包含，B 的评分自动降低）

**应用场景**：长文档选择、多文件上下文、大量搜索结果筛选

### 2.6 CCR（Compress-Cache-Retrieve，可逆压缩）

**目标**：使压缩完全可逆——原始数据永不删除，LLM 可按需检索

**架构**：

```
工具输出 (1000 项)
 → SmartCrusher 压缩至 20 项
 → 原始数据缓存，hash=abc123
 → 检索工具注入上下文

LLM 处理
 方案 A: LLM 用 20 项完成任务 → 完成 (90% 节省)
 方案 B: LLM 调用 headroom_retrieve(hash=abc123)
 → Response Handler 自动返回完整数据
```

**四个阶段**：

1. **压缩存储**：原始数据存入 LRU 缓存，生成 hash key
2. **标记注入**：压缩输出末尾添加 `[1000 items compressed to 20. Retrieve more: hash=abc123]`
3. **工具注入**：向 LLM 注入 `headroom_retrieve` 工具定义
4. **响应处理**：拦截 `headroom_retrieve` 调用，从缓存返回完整数据（~1ms）

**根本性优势**：
- 激进压缩零风险——LLM 随时可检索原始数据
- "压缩"不再是有损操作
- 消除了传统压缩的安全-节省权衡

---

## 3. ContentRouter 内容路由机制

ContentRouter 是 Headroom 管道的智能调度器，负责检测内容类型并路由到正确的压缩器。

### 3.1 检测逻辑

```python
# ContentRouter 分类决策（简化）
def route(content):
    if is_json_array(content):
        if len(items) > 10:
            return SmartCrusher
        return passthrough  # 小数组不需要压缩

    if is_source_code(content):
        if line_count > 100:  # 仅对长文件压缩
            return CodeCompressor
        return passthrough

    if is_structured_log(content):
        return KompressBase

    if is_html(content):
        return HTMLCompressor

    # 默认：不压缩（已紧凑格式）
    return passthrough
```

### 3.2 时序性能

| 步骤 | 中位数 | P90 | 说明 |
|------|--------|-----|------|
| `pipeline_total` | 16.9ms | 289ms | 完整压缩管道 |
| `content_router` | 11.7ms | 259ms | 内容检测 + 路由 |
| `smart_crusher` | 50.1ms | 50ms | JSON 数组压缩 |
| `text_compressor` | 32.0ms | 576ms | 文本压缩 (Kompress ONNX) |
| `initial_token_count` | 2.9ms | 16ms | Token 计数 (tiktoken) |

ContentRouter 占管道成本的 91-98%。CacheAligner 和 RollingWindow 为亚毫秒级。

---

## 4. CacheAligner 前缀缓存稳定化策略

### 4.1 工作原理

CacheAligner 通过以下机制稳定前缀：

**规则 1：System Prompt 始终第一**

```
[System Prompt]        ← 从不变化，构建最长缓存前缀
[固定上下文]           ← 项目规则、架构文档
[会话特定上下文]       ← 当前任务相关的可变内容
[用户消息]             ← 每次变化的尾部
```

**规则 2：动态内容后移**

```python
# Bad: 动态内容在前
prompt = f"Session {session_id} at {timestamp}\n{system_prompt}\n{user_msg}"
# → 缓存命中率 0%

# Good: 动态内容在后
prompt = f"{system_prompt}\n{user_msg}\nSession: {session_id}"
# → 缓存命中率 >90%
```

**规则 3：固定顺序**

- 文件列表按字典序排列（而非相关性排序）
- JSON key 始终按字母序
- 不注入 token 计数字段

### 4.2 与 DeepSeek Prefix-Cache 的关系

CacheAligner 的策略与 DeepSeek-Reasonix 的 prefix-cache 设计理念一致但更通用：

| 维度 | Headroom CacheAligner | Reasonix Prefix-Cache |
|------|----------------------|----------------------|
| 目标提供商 | Anthropic / OpenAI / Google | DeepSeek 专用 |
| 机制 | Prompt 重排 | 循环架构 |
| 缓存类型 | KV Cache (服务端) | KV Cache (服务端) |
| 命中率提升 | 20-40% 额外 | 99.82% 总命中率 |
| 通用性 | 多提供商 | DeepSeek 专用 |

---

## 5. CCR 可逆压缩深度解析

### 5.1 为什么 CCR 是突破性的

传统压缩面临根本困境：
- **激进压缩** → 可能丢失 LLM 需要的数据
- **保守压缩** → 错过了大量 token 节省机会

CCR 消除了这个权衡：激进压缩，按需检索。

### 5.2 主动扩展

CCR 不仅仅是"按需检索"——它还会主动扩展：

```
Turn 1: 用户搜索文件 → 500 文件压缩为 15，缓存 (hash=abc123)
        → LLM 用 15 文件回答

Turn 5: 用户问 "auth middleware 呢？"
        → Context Tracker 检测到 "auth" 可能匹配缓存内容
        → 主动扩展压缩数据
        → LLM 在完整列表中发现 auth_middleware.py
```

### 5.3 检索工具定义

```json
{
  "name": "headroom_retrieve",
  "description": "Retrieve original uncompressed data from Headroom cache",
  "parameters": {
    "hash": "The hash key from the compression marker",
    "query": "Optional: search within the cached data for specific matches"
  }
}
```

LLM 将此工具与应用的常规工具并列使用。当压缩数据不充分时，LLM 自主决定调用它。

---

## 6. 跨代理记忆共享

### 6.1 SharedContext

Headroom 提供跨代理会话的持久记忆：

```python
from headroom import SharedContext

ctx = SharedContext(project="my-app")

# 代理 A 写入
ctx.store("auth_architecture", "JWT with refresh token rotation")

# 代理 B 读取（不同会话，甚至不同模型）
auth = ctx.get("auth_architecture")
```

### 6.2 记忆文件集成

Headroom 兼容 Claude Code 的 CLAUDE.md 和 Reasonix 的 memory.md：

```yaml
# headroom.config.yaml
memory:
  sources:
    - type: "claude_md"
      path: "./CLAUDE.md"
    - type: "reasonix_memory"
      path: ".reasonix/memory.md"
    - type: "custom"
      path: "./.headroom/project-context.md"
  update_strategy: "append"  # append | replace | merge
```

### 6.3 故障学习

Headroom 记录压缩后的 LLM 错误（当 LLM 因缺少信息而请求完整数据时），并自动调整未来压缩策略：

```
压缩日志：
  错误: LLM 调用 retrieve_compressed(hash=abc, query="error handling")
  分析: SmartCrusher 丢弃了 error handler 函数
  调整: 未来压缩保留 error/exception handler 模式
```

---

## 7. 何时使用哪种模式

### 7.1 Library 模式（Python SDK）

```python
from headroom import compress

result = compress(messages, model="claude-sonnet-4-5-20250929")
response = client.messages.create(
    model="claude-sonnet-4-5-20250929",
    messages=result.messages,
)
```

**适用**：自定义 Python 应用、LangChain/Agno 集成、需要精细控制

### 7.2 Proxy 模式（零代码变更）

```bash
pip install "headroom-ai[all]"
headroom proxy
# 指向代理
ANTHROPIC_BASE_URL=http://localhost:8787 claude
OPENAI_BASE_URL=http://localhost:8787/v1 your-app
```

**适用**：Claude Code、Cursor、Aider、GitHub Copilot 等现有工具

### 7.3 MCP 模式

```bash
headroom mcp
```

将 Headroom 作为 MCP 服务器运行，所有通过 MCP 的工具调用自动压缩。

**适用**：MCP 启用的代理、Cursor MCP 集成

### 7.4 Wrap 模式（一键集成）

```bash
headroom wrap claude       # Claude Code
headroom wrap codex        # OpenAI Codex CLI
headroom wrap aider        # Aider
headroom wrap cursor       # Cursor
headroom wrap openclaw     # OpenClaw
```

启动代理，指向 Headroom 代理，自动压缩一切。

**适用**：快速试用、不想修改配置

---

## 8. 适用场景决策树

```
你的场景是什么？
│
├─ 使用 Claude Code / Cursor / Aider 等现有工具
│  └─ 使用 Proxy 模式 或 Wrap 模式
│     └─ headroom wrap claude
│
├─ 构建自定义 Python LLM 应用
│  ├─ 使用 LangChain？
│  │  └─ 使用 Library 模式 + LangChain 集成
│  ├─ 使用 Agno？
│  │  └─ 使用 Library 模式 + Agno 集成
│  └─ 原生 Anthropic/OpenAI SDK？
│     └─ 使用 Library 模式
│
├─ 使用 MCP 启用的代理
│  └─ 使用 MCP 模式
│     └─ headroom mcp
│
├─ 需要跨代理持久记忆
│  └─ 使用 SharedContext API
│
├─ 仅需要 JSON 压缩
│  └─ 仅启用 SmartCrusher
│     └─ compress(messages, algorithms=["smart_crusher"])
│
└─ 需要完整管道
   └─ 启用全部（默认）
      └─ CacheAligner → ContentRouter → 智能压缩 → CCR
```

### 不需要 Headroom 的场景

| 场景 | 原因 |
|------|------|
| 短对话（<5 轮） | 压缩开销 > 节省 |
| 纯文本聊天 | 输出本身已紧凑 |
| 固定格式 API 调用 | 无重复冗余可压缩 |
| Output-heavy 工作流 | Headroom 只压缩输入，不压缩输出 |
| 需要逐字节精度的场景 | 使用 `passthrough` 标记排除 |

---

## 9. 生产部署数据

来自 50,000+ 代理会话的生产遥测（2026 年 3-4 月）：

### 代理开销

| 百分位 | 延迟 |
|--------|------|
| **P50（中位数）** | **52ms** |
| P90 | 309ms |
| P99 | 4,172ms |
| 均值 | 161ms |

中位数 52ms 的额外延迟可忽略不计（LLM 推理通常需 2-10 秒）。

### 压缩率分布

| 百分位 | 压缩率 |
|--------|--------|
| P25 | 4.8% |
| **P50（中位数）** | **4.8%** |
| P75 | 6.9% |
| 均值 | 11.3% |

中位数压缩率适中，因为许多请求是短对话轮次。重型工具使用会话（文件读取、shell 输出）达到 40-80% 压缩率。

### 成本效益分析

| 场景 | 压缩延迟 | LLM 节省延迟 | 净收益 | 每 1K 请求节省 |
|------|----------|-------------|--------|---------------|
| JSON 100 项 | 189ms | 261ms | **+72ms** | $26 |
| JSON 500 项 | 943ms | 1,461ms | **+518ms** | $146 |
| JSON 1K 项 | 2,012ms | 2,969ms | **+957ms** | $297 |
| API 响应 500 项 | 743ms | 1,134ms | **+391ms** | $113 |
| 数据库行 1K | 961ms | 1,292ms | **+331ms** | $129 |

在 12 个测试场景中的 11 个中，压缩延迟净收益为正。更慢更贵的模型（Opus）收益更大。
