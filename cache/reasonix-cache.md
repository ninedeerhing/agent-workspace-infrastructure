# DeepSeek-Reasonix Prefix-Cache 稳定性策略

> 基于 [DeepSeek-Reasonix](https://github.com/esengine/DeepSeek-Reasonix) 项目（1.4K+ Stars, MIT License）及其实践数据，本文档提供 Prefix-Cache 稳定性策略的完整指南。

---

## 1. 三大支柱

Reasonix 的架构建立在三个核心支柱之上：

### 支柱 1：Cache-First Loop（缓存优先循环）

**核心**：字节稳定的 append-only 循环

DeepSeek 的 prefix cache 从字节 0 开始对 prompt 做指纹匹配。Reasonix 的消息循环设计为 append-only——不重排，不基于标记压缩——因此缓存前缀在每次 tool call 后都存活。

四个关键机制：

1. **append-only**：消息和工具结果始终追加；历史从不修改
2. **no marker**：不依赖 `cache_control` 标记等触发器
3. **stable order**：工具调用顺序和时间戳完全确定性
4. **prefix-survive**：即使大量工具调遣，前缀仍然命中

### 支柱 2：Tool-Call Repair（工具调用修复）

当 DeepSeek 模型产生格式不正确的 tool call 时，Reasonix 自动修复而非报错重试。这避免了因格式问题浪费 token 和破坏缓存前缀。

**修复策略**：
- 缺失参数的默认值填充
- JSON 格式错误的自动纠正
- 截断 tool call 的参数补全

### 支柱 3：Cost Control（成本控制）

内置 cost tracking 和预算管理，实时显示会话开销：

```
Tokens: 245K in (99.8% cached) / 3.2K out | Cost: $0.003 | Session: $0.047
```

---

## 2. Prefix-Cache 稳定性核心机制

### 2.1 DeepSeek Prefix Cache 工作原理

```
请求 N:
[System Prompt] [Memory] [Project Context] [Turn 1] [Turn 2] ... [Turn N-1] [New Message]
 ↑_________________________ 缓存命中（相同前缀）___________________________↑  ↑___ 新 token ___↑
                                                                            仅这部分收费
```

**关键约束**：前缀从字节 0 开始匹配。任何变化都会使该点之后的所有缓存失效。

**经济模型**（DeepSeek V4 Flash）：

| Token 类型 | 价格 (/1M tokens) | 比例 |
|------------|-------------------|------|
| 输入（缓存未命中） | $0.07 | 基准 |
| 输入（缓存命中） | ~$0.007 | **1/10 ~ 1/12** |
| 输出 | $0.28 | — |

### 2.2 Reasonix 的三层缓存稳定策略

**层级 1：固定前缀顺序**

```
每条请求的刚性前缀顺序：
[System Prompt] [Memory] [Project Context] [Conversation History] [New Message]
      ↑                ↑            ↑                   ↑                ↑
   从不变化        会话启动时     固定顺序，          append-only      仅此处不同
                   加载一次      从不重排
```

- System Prompt 在整个会话中从不改变
- Memory 在会话启动时加载一次，仅追加不重写
- 项目上下文文件以固定顺序添加，从不重排

**层级 2：Append-Only 上下文增长**

关键对比：

```
// 传统方法（破坏缓存）
Turn 1: [System] [FileA] [FileB] [Message1]
Turn 2: [System] [FileA] [FileC] [FileB] [Message1] [Response1] [Message2]
                  ↑ 在此插入，之后的缓存全部失效

// Reasonix 方法（缓存稳定）
Turn 1: [System] [FileA] [FileB] [Message1]
Turn 2: [System] [FileA] [FileB] [Message1] [Response1] [FileC] [Message2]
                                           ↑ 在末尾追加，前缀全部缓存命中
```

**层级 3：确定性格式化**

- 每个工具调用用字节相同的模板格式化
- 头部无时间戳
- 无变量空白
- 无 JSON key 重排
- 同一文件读取两次产生完全相同的 token 序列

---

## 3. 缓存命中率优化策略（99.82% 案例）

### 3.1 那 99.82% 是怎么来的

真实用户，单日（2026-05-01）：**435M 输入 tokens，99.82% 缓存命中，~$12** 而非相同工作在 V4-Flash 上无缓存时的 **~$61**。

### 3.2 七条提升缓存命中的规则

**规则 1：System Prompt 必须静态**

```python
# Bad: 动态 system prompt
system_prompt = f"You are a coding assistant. Current time: {datetime.now()}"
# → 每次请求都不同，缓存命中率 0%

# Good: 静态 system prompt
system_prompt = "You are a coding assistant."  # 从不变化
user_message = f"Help me with X. (Current time: {datetime.now()})"  # 动态内容在末尾
```

**规则 2：始终追加，从不插入**

当添加新上下文到对话时：
- ✅ 追加到现有内容之后
- ❌ 插入到现有消息或上下文块之间

**规则 3：使用一致的格式化**

```python
# Bad: 不固定的 key 顺序
def format_tool_result(tool_call):
    return json.dumps({
        "output": result.output,
        "tool": tool_call.name,
    })

# Good: 字母序固定的 key 顺序
def format_tool_result(tool_call):
    return json.dumps({
        "output": result.output,
        "tool": tool_call.name,
    }, sort_keys=True)
```

**规则 4：保持长会话**

缓存命中率随会话增长而提升。10 轮对话的缓存比远高于 10 次单独的 1 轮对话。

```
会话长度 → 缓存命中率
1-3 轮:   80-95%
5-10 轮:  95-99%
10+ 轮:   99%+
```

**规则 5：稳定内容前置**

```
[最稳定] System Prompt
         Memory file (.reasonix/memory.md)
         Project conventions, architecture docs
         File list (alphabetical, not by relevance)
         Current conversation turns
[最易变] New user message, just-read files
```

**规则 6：避免不必要的上下文清除**

每次 `/clear` 都会丢失热缓存。仅在以下情况清除：
- 切换到完全不相关的任务
- 达到上下文窗口限制

**规则 7：使用 Memory 文件**

```markdown
# .reasonix/memory.md
## 项目架构
- 前端: React 18 + TypeScript
- 后端: FastAPI + PostgreSQL
- 部署: Docker + AWS ECS

## 编码规范
- 使用 Prettier 格式化
- 函数命名: camelCase
- 测试框架: Vitest
```

Memory 文件在前缀中的固定位置加载，为跨会话提供稳定的共享前缀。

---

## 4. 字节稳定前缀设计原则

### 4.1 原理

DeepSeek 的 prefix cache 在 **token 边界**上匹配，而非字符边界。这意味着 tokenization 的一致性至关重要。

### 4.2 实践检查清单

| 检查项 | 说明 |
|--------|------|
| □ System prompt 在会话期间不变 | 无时间戳、无动态计数 |
| □ 消息数组始终 append | 不插入、不重排、不从中间删除 |
| □ JSON 输出始终 `sort_keys=True` | 保证 key 顺序确定性 |
| □ 文件路径使用相对路径且一致 | 不同工具调用的同文件路径相同 |
| □ 不注入 token 计数字段到消息体 | 计数变化破坏缓存 |
| □ tool_call 的 ID 可预测 | 不使用随机 UUID，使用递增序号 |
| □ 不格式化差异（如避免缩进变化） | 相同内容 = 相同字节 = 相同 tokens |

### 4.3 错误模式识别

```python
# 模式 1: 随机 ID 破坏缓存
# Bad
message_id = str(uuid.uuid4())
# Good
message_id = f"msg_{session_turn_counter}"  # 确定性的

# 模式 2: Timestamp 破坏缓存
# Bad
system_prompt = f"Session started at {time.time()}"
# Good
system_prompt = "Coding assistant session"  # 静态

# 模式 3: 相关性排序破坏缓存
# Bad
files = sorted(relevant_files, key=lambda f: f.score, reverse=True)
# Good
files = sorted(relevant_files, key=lambda f: f.path)  # 固定排序
```

---

## 5. Token 预算管理

### 5.1 Reasonix 的预算层次

| 模型 | 角色 | 价格 (/1M tokens) | 适用场景 |
|------|------|-------------------|----------|
| **deepseek-flash** | 默认执行器 | $0.07 in / $0.28 out | 日常编码、文件操作 |
| **deepseek-pro** | 按需升级 | $0.435 in / $1.10 out | 复杂推理、架构决策 |

### 5.2 预算控制配置

```toml
# reasonix.toml
[agent]
default_model = "deepseek-flash"
planner_model = "mimo-pro"        # 可选低频规划器
subagent_model = "deepseek-pro"   # 可选的子代理默认模型
max_steps = 0                      # 0 = 无限制
planner_max_steps = 12             # 规划器只读工具调用轮数

[cost]
budget_limit = 5.0                 # 会话预算上限 ($)
warn_threshold = 0.8              # 80% 时警告
```

### 5.3 模型切换策略

```
/deepseek-flash   → 默认，日常编码
/pro               → 单轮升级到 Pro
/preset max        → 整个会话使用 Pro
```

---

## 6. 适用条件

### 6.1 必要条件

| 条件 | 说明 |
|------|------|
| DeepSeek API Key | 从 [platform.deepseek.com](https://platform.deepseek.com/) 获取 |
| Node.js >= 22 | 运行 Reasonix CLI 的要求 |

### 6.2 支持平台

| 平台 | 状态 |
|------|------|
| macOS | ✅ 完全支持 |
| Linux | ✅ 完全支持 |
| Windows | ✅ PowerShell / Git Bash / Windows Terminal |
| Desktop (Tauri) | ✅ 预览版 |

### 6.3 安装

```bash
# npx（推荐，无需全局安装）
npx reasonix code

# npm 全局
npm install -g reasonix

# 桌面版
# 从 https://esengine.github.io/DeepSeek-Reasonix/download.html 下载
```

---

## 7. 成本对比分析

### 7.1 真实成本案例（V4 Flash）

**30 分钟编码会话**：

| 项目 | 无缓存 | Reasonix | 节省 |
|------|--------|----------|------|
| 输入 tokens | 500K ($0.035) | 499.1K cached ($0.0035) + 0.9K miss ($0.00006) | — |
| 输出 tokens | 50K ($0.014) | 50K ($0.014) | — |
| **总计** | **$0.049** | **$0.018** | **63%** |

**2 小时重构会话**：

| 项目 | 无缓存 | Reasonix | 节省 |
|------|--------|----------|------|
| 输入 tokens | 3M ($0.21) | 2.99M cached ($0.021) + 5.4K miss ($0.0004) | — |
| 输出 tokens | 300K ($0.084) | 300K ($0.084) | — |
| **总计** | **$0.294** | **$0.105** | **64%** |

**全天编码（435M 案例）**：

| 项目 | 无缓存 | Reasonix |
|------|--------|----------|
| Flash 输入 (370M) | $25.90 | $2.59 |
| Pro 输入 (65M) | $28.28 | $2.34 |
| 输出 (Flash + Pro) | ~$7.00 | ~$7.00 |
| **总计** | **~$61** | **~$12** |

### 7.2 与其他工具的缓存对比

| 工具 | 缓存策略 | 典型命中率 | 成本影响 |
|------|----------|-----------|----------|
| **Reasonix** | 前缀稳定架构 | 99.82% | **5x 节省** |
| **Claude Code** | Anthropic 自动缓存 | ~60-80% | 1.5-2x 节省 |
| **Aider** | 无显式优化 | ~30-50% | 微小节省 |
| **Cursor** | 服务端，不透明 | 未知 | 未知 |
| **OpenCode** | 无缓存优化 | ~30-50% | 微小节省 |

---

## 8. 监控与诊断

### 8.1 实时指标

Reasonix 在会话页脚实时显示：

```
Tokens: 245K in (99.8% cached) / 3.2K out | Cost: $0.003 | Session: $0.047
```

### 8.2 会话回放与分析

```bash
# 查看最近会话的统计
reasonix replay --last --stats

# 显示每轮缓存命中率、token 计数、累积成本
```

### 8.3 DeepSeek API 响应验证

每个 API 响应包含：

```json
{
  "usage": {
    "prompt_tokens": 500000,
    "prompt_cache_hit_tokens": 499100,
    "prompt_cache_miss_tokens": 900,
    "completion_tokens": 3200
  }
}
```

### 8.4 缓存健康检查

```bash
# 检查会话缓存效率
reasonix stats --cache

# 输出示例:
# Session cache efficiency: 99.8%
# Avg cache hit per turn: 98.2%
# Cache break events: 0
# Estimated savings: $48.73
```

---

## 9. 常见问题

### Q: 缓存能存活多久？

DeepSeek 没有公布精确的 TTL。经验数据：同一会话中，数分钟不活动后缓存仍然温热。5-10 分钟离开通常没问题。30 分钟以上的长时间离开可能导致缓存驱逐。

### Q: 能跨会话共享缓存吗？

部分可以。如果多个会话使用相同的 system prompt，DeepSeek 的前缀树可能共享该前缀。但会话特定的对话历史不会共享。Reasonix 的 memory 文件在此有帮助——它创建了跨会话的更长共享前缀。

### Q: 99.82% 的缓存命中率是否现实？

对于 5-10 轮以上的交互式编码会话，是的。命中率随会话增长而提升。短会话（1-3 轮）将看到较低命中率（80-95%），因为新内容占总 tokens 比例更大。

### Q: 缓存优化与上下文窗口限制冲突吗？

不冲突。缓存优化关乎排序和稳定性，而非使用更多或更少 tokens。你仍需要管理上下文窗口限制，但通过从末尾截断（而非从中间摘要）来处理，这样保留缓存前缀。

### Q: 上下文窗口满了怎么办？

Reasonix 从对话历史中间截断最旧的轮次（不是稳定前缀部分）。System prompt、memory 和项目上下文在开头保持完整，保护缓存前缀。仅对话历史被修剪。
