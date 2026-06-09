---
name: reasonix-cache
description: DeepSeek-Reasonix Prefix-Cache 稳定性策略——通过缓存优先架构实现 90%+ 的 token 缓存命中率，节省 5x+ API 成本。触发条件：使用 DeepSeek API、需要优化缓存命中率、降低 LLM 调用成本。
---

# Reasonix Cache — Prefix-Cache 稳定性策略

## 定位

DeepSeek-Reasonix 的 Prefix-Cache 稳定性最佳实践。通过在 Agent 会话中保持字节级前缀稳定性，使 DeepSeek 的 KV Cache 持续命中，将输入 token 成本降至 1/10 ~ 1/12。

## 触发条件

- 使用 DeepSeek API（V4 Flash / Pro）
- 需要降低 API token 成本
- 缓存命中率低于 90%
- 长会话中 token 消耗持续增长
- 新接入 DeepSeek 需要指导配置

## 核心原理

DeepSeek 的 prefix cache 从 **字节 0** 开始对 prompt 做指纹匹配。任何前缀变化都会导致该位置之后的所有缓存失效。

```
请求 N:
[System] [Memory] [Context] [Turn 1] ... [Turn N-1] [New Message]
 ↑__________________ 缓存命中（相同前缀）____________________↑  ↑___ 新 token ___↑
                                                            仅这部分收费
```

## 三大支柱

### 支柱 1：Cache-First Loop（缓存优先循环）

字节稳定的 append-only 循环，不重排、不插入、不基于标记压缩。

| 机制 | 说明 |
|------|------|
| **append-only** | 消息和工具结果始终追加；历史从不修改 |
| **no marker** | 不依赖 `cache_control` 标记等触发器 |
| **stable order** | 工具调用顺序和时间戳完全确定性 |
| **prefix-survive** | 即使大量工具调用，前缀仍然命中 |

### 支柱 2：Tool-Call Repair（工具调用修复）

当模型产生格式不正确的 tool call 时，自动修复而非报错重试：
- 缺失参数的默认值填充
- JSON 格式错误的自动纠正
- 截断 tool call 的参数补全

### 支柱 3：Cost Control（成本控制）

内置实时成本追踪和预算管理。

## 七条提升缓存命中的规则

### 规则 1：System Prompt 必须静态

```python
# ❌ Bad：动态 system prompt
system_prompt = f"You are a coding assistant. Current time: {datetime.now()}"

# ✅ Good：静态 system prompt，动态内容放末尾
system_prompt = "You are a coding assistant."
user_message = f"Help me with X. (Current time: {datetime.now()})"
```

### 规则 2：始终追加，从不插入

当添加新上下文到对话时：
- ✅ 追加到现有内容之后
- ❌ 插入到现有消息或上下文块之间

```
// ❌ 传统方法（破坏缓存）
Turn 1: [System] [FileA] [FileB] [Message1]
Turn 2: [System] [FileA] [FileC] [FileB] [Message1] [Response1] [Message2]
                  ↑ 在此插入，之后的缓存全部失效

// ✅ Reasonix 方法（缓存稳定）
Turn 1: [System] [FileA] [FileB] [Message1]
Turn 2: [System] [FileA] [FileB] [Message1] [Response1] [FileC] [Message2]
                                           ↑ 在末尾追加，前缀全部缓存命中
```

### 规则 3：使用一致的格式化

```python
# ❌ Bad：不固定的 key 顺序
json.dumps({"output": r.output, "tool": t.name})

# ✅ Good：字母序固定的 key 顺序
json.dumps({"output": r.output, "tool": t.name}, sort_keys=True)
```

### 规则 4：保持长会话

会话长度与缓存命中率正相关：

| 会话长度 | 缓存命中率 |
|----------|-----------|
| 1-3 轮 | 80-95% |
| 5-10 轮 | 95-99% |
| 10+ 轮 | 99%+ |

### 规则 5：稳定内容前置

```
[最稳定] System Prompt
         Memory file
         项目约定、架构文档
         文件列表（按字母序，非相关性序）
         当前对话轮次
[最易变] 新用户消息、刚读取的文件
```

### 规则 6：避免不必要的上下文清除

每次 `/clear` 都会丢失热缓存。仅在以下情况清除：
- 切换到完全不相关的任务
- 达到上下文窗口限制

### 规则 7：使用 Memory 文件

在固定位置加载 memory 文件，为跨会话提供稳定的共享前缀：

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

## 固定前缀顺序（三层架构）

```
每条请求的刚性前缀顺序：
[System Prompt] [Memory] [Project Context] [Conversation History] [New Message]
     ↑                ↑            ↑                   ↑                ↑
  从不变化        会话启动时     固定顺序，           append-only      仅此处不同
                  加载一次      从不重排
```

## 错误模式识别

| 反模式 | 问题 | 正确做法 |
|--------|------|----------|
| `message_id = str(uuid.uuid4())` | 随机 UUID 破坏缓存 | 使用递增序号：`f"msg_{turn_counter}"` |
| `system_prompt = f"Session at {time.time()}"` | 时间戳破坏缓存 | 静态 system prompt |
| `files = sorted(files, key=score)` | 相关性排序破坏缓存 | 按路径字母序固定排序 |
| 动态 token 计数注入消息体 | 计数变化破坏缓存 | 不在消息体内放变化字段 |

## 成本对比

**30 分钟编码会话（DeepSeek V4 Flash）**：

| 项目 | 无缓存 | Reasonix | 节省 |
|------|--------|----------|------|
| 输入 tokens | 500K ($0.035) | 499K cached ($0.0035) | — |
| 输出 tokens | 50K ($0.014) | 50K ($0.014) | — |
| **总计** | **$0.049** | **$0.018** | **63%** |

**全天编码（435M tokens 案例）**：99.82% 缓存命中，$12 vs 无缓存的 $61。

## 安装与使用

```bash
# npx（推荐，无需全局安装）
npx reasonix code

# npm 全局
npm install -g reasonix
```

## 缓存健康监控

```bash
# 会话统计
reasonix replay --last --stats

# 缓存效率检查
reasonix stats --cache
```

实时页脚显示：
```
Tokens: 245K in (99.8% cached) / 3.2K out | Cost: $0.003 | Session: $0.047
```

## 上下文窗口管理

当上下文窗口满了：
- 从对话历史**中间**截断最旧的轮次（非稳定前缀部分）
- System prompt、memory 和项目上下文在开头保持完整
- 保护缓存前缀不被破坏

## 回退策略

```bash
# 切换回之前使用的工具即可，无锁定效应
# 直接使用原生 API 或其它客户端
```
