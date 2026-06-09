# Token 预算综合管理指南

> 整合 caveman、RTK、Headroom、DeepSeek-Reasonix 四大项目的 Token 优化策略，提供从策略选择到实施监控的完整决策框架。

---

## 1. 四种策略对比总览

| 维度 | **caveman** | **RTK** | **Headroom** | **Reasonix** |
|------|-------------|---------|-------------|-------------|
| **优化层级** | LLM 响应层 | 工具输出层 | 上下文输入层 | 会话持续层 |
| **压缩方向** | 输出压缩 | 输入压缩 | 输入压缩 | 缓存复用 |
| **核心机制** | 提示风格控制 | 命令输出过滤 | 内容智能压缩 | Prefix-Cache 稳定 |
| **压缩对象** | LLM 生成的回复 | Bash 命令输出 | 所有工具输出/检索结果 | API 请求 Prefix |
| **实现方式** | System Prompt 指令 | CLI 代理 + Hook | Python 库/代理/MCP | 终端代理（TypeScript） |
| **典型节省** | 14-21%（编码）；60-75%（解释） | 60-95%（按命令类型） | 40-90%（按内容类型） | 63-80%（总成本） |
| **质量风险** | 低（仅改变风格） | 中（有损压缩） | 极低（CCR 可逆） | 无（保持原始内容） |
| **适用范围** | 所有 LLM | Bash 命令 (Unix-first) | 所有 LLM 提供商 | DeepSeek 专用 |
| **Windows 支持** | ✅ 原生 | ⚠️ 需 WSL2 | ✅ 原生 | ✅ 原生 |
| **复杂度** | 极低 | 低 | 中 | 中 |
| **部署模式** | 提示指令 | 单一 Rust 二进制 | Python SDK/代理 | npm 包/TUI |

---

## 2. 策略选择决策树

```
开始
│
├─ 你使用 DeepSeek API？
│  ├─ 是 → 优先使用 Reasonix（prefix-cache 省 5x）
│  │      └─ 叠加：caveman 输出压缩 / RTK 命令压缩
│  │
│  └─ 否 → 继续
│
├─ 什么在消耗你的 token？
│  │
│  ├─ 主要是 LLM 输出太长？
│  │  └─ 使用 caveman（Lite → Full → Ultra 渐进）
│  │     注意：微缩版（<100 tokens）才能保证净正收益
│  │
│  ├─ 主要是命令输出太长？
│  │  ├─ 使用 Bash 工具？
│  │  │  ├─ Unix/Linux/macOS → 安装 RTK
│  │  │  └─ Windows → WSL2 中的 RTK / PowerShell 脚本
│  │  └─ 使用 Read/Grep/Glob 内置工具？
│  │     └─ 改用 Bash 等价命令（cat/rg/find）+ RTK
│  │
│  ├─ 主要是工具输出/检索结果太冗长？
│  │  └─ 使用 Headroom（Proxy 模式零代码变更）
│  │     ├─ JSON 数据多 → SmartCrusher
│  │     ├─ 源代码多 → CodeCompressor
│  │     └─ 文本/日志多 → Kompress-base
│  │
│  └─ 主要是上下文窗口逐渐填满？
│     ├─ 短会话（<30min）→ caveman + RTK 足矣
│     └─ 长会话（>1h）→ Headroom + CacheAligner
│
└─ 多管齐下：组合策略效果最佳
   └─ 详见第 3 节"逐层 Token 节省链"
```

---

## 3. 逐层 Token 节省链

一条完整的 agent 交互链上有四个可以优化的层级。每一层的节省相互叠加。

### 3.1 四层架构

```
┌─────────────────────────────────────────────────────────┐
│                    第 4 层：会话持续层                       │
│  策略: Reasonix Prefix-Cache / Headroom CacheAligner       │
│  节省: 63-80% 总成本（DeepSeek）或 20-40% 额外缓存命中       │
│  机制: 前缀稳定 → KV Cache 命中 → 输入 token 仅付 1/10 价格  │
├─────────────────────────────────────────────────────────┤
│                    第 3 层：上下文输入层                       │
│  策略: Headroom (SmartCrusher / CodeCompressor / Kompress) │
│  节省: 40-90% 输入 token（按内容类型）                       │
│  机制: 智能压缩工具输出/RAG结果/文件读取                      │
├─────────────────────────────────────────────────────────┤
│                    第 2 层：工具输出层                         │
│  策略: RTK (filter / group / truncate / dedupe)            │
│  节省: 60-95% 命令输出 token（按命令类型）                    │
│  机制: PreToolUse Hook → 命令改写 → 输出压缩                │
├─────────────────────────────────────────────────────────┤
│                    第 1 层：LLM 响应层                        │
│  策略: caveman (Lite / Full / Ultra)                        │
│  节省: 14-21% 输出 token（编码），60-75%（解释）               │
│  机制: System Prompt → 压缩输出风格                          │
└─────────────────────────────────────────────────────────┘
```

### 3.2 叠加效果估算

以 30 分钟 Claude Code 会话为例：

| 阶段 | 原始 Token | 策略 | 压缩后 | 节省率 |
|------|-----------|------|--------|--------|
| **无优化** | 150,000 | — | 150,000 | 基准 |
| +caveman | 150,000 | 输出 -18% | ~140,000 | -7% 总量 |
| +RTK | 150,000 | 命令输出 -80% | ~70,000 | -53% 总量 |
| +Headroom | 150,000 | 上下文 -60% | ~60,000 | -60% 总量 |
| **全部三层叠加** | 150,000 | 全部 | ~35,000 | **-77% 总量** |

> 注：叠加效果非严格可加（各层覆盖不同 token 源）。实际效果取决于工作负载的 token 分布。

---

## 4. 典型会话 Token 预算分配

### 4.1 无优化的 30 分钟编码会话

```
总 token 消耗: ~150,000
├─ 输入 token: ~120,000 (80%)
│  ├─ Bash 命令输出: ~50,000 (42%) ← RTK 可压缩
│  ├─ 文件读取输出: ~30,000 (25%) ← Headroom 可压缩
│  ├─ 对话历史: ~25,000 (21%)
│  └─ System Prompt + 规则: ~15,000 (12%)
│
└─ 输出 token: ~30,000 (20%)
   ├─ 代码生成: ~15,000 (50%)
   ├─ 解释说明: ~10,000 (33%) ← caveman 可压缩
   └─ 工具调用: ~5,000 (17%)
```

### 4.2 优化后的预算分配

```
总 token 消耗: ~35,000 (-77%)
├─ 输入 token: ~25,000 (71%)
│  ├─ Bash 命令输出: ~10,000 (40%) ← RTK -80%
│  ├─ 文件读取输出: ~6,000 (24%) ← Headroom -80%
│  ├─ 对话历史: ~5,000 (20%)
│  └─ System Prompt + 规则: ~4,000 (16%)
│
└─ 输出 token: ~10,000 (29%)
   ├─ 代码生成: ~7,000 (70%)
   └─ 解释说明: ~3,000 (30%) ← caveman -70%
```

### 4.3 预算配置建议

```yaml
# .trae/token-budget.yaml
budget:
  per_session: 200000        # 单会话 token 预算上限
  warn_at: 0.75              # 75% 时触发警告
  compact_at: 0.85           # 85% 时触发上下文压缩

allocation:
  system_prompt: 5000        # 固定开销
  rules_context: 10000       # 项目规则
  tool_output_max: 80000     # 工具输出累计上限
  conversation_history: 80000 # 对话历史上限
  output_per_turn: 5000      # 单轮输出上限

strategies:
  caveman: "full"            # lite | full | ultra | off
  rtk: "normal"              # minimal | normal | aggressive | off
  headroom: "auto"           # auto | proxy | off（按内容类型自动路由）
  reasonix_cache: "on"       # on | off（仅 DeepSeek API）
```

---

## 5. 监控指标建议

### 5.1 核心 KPI

| 指标 | 计算方式 | 目标值 | 监控工具 |
|------|----------|--------|----------|
| **缓存命中率** | cache_hit_tokens / total_input_tokens | >90% (DeepSeek); >60% (其他) | Reasonix dashboard / API response headers |
| **压缩率** | tokens_saved / original_tokens | >50% 工具输出; >15% 输出 | RTK `gain` / Headroom telemetry |
| **成本节省** | (estimated_without - actual) / estimated_without | >50% 总成本 | 各工具内置 / 自定义聚合 |
| **平均延迟** | 压缩时间 + LLM 推理时间 | < 无优化 LLM 推理时间 | 各工具 telemetry |
| **质量保持率** | 正确答案数 / 总查询数 | 100% | 手动审查 / 自动化测试 |

### 5.2 监控设置

**RTK 监控**：

```bash
# 查看累积统计
rtk gain

# 按项目查看
rtk gain --project my-project

# 导出 JSON 用于仪表盘
rtk gain --json > rtk-stats.json
```

**Headroom 监控**：

```python
from headroom import get_metrics

metrics = get_metrics()
print(f"Total tokens saved: {metrics.total_saved:,}")
print(f"Avg compression ratio: {metrics.avg_compression_ratio:.1%}")
print(f"Avg latency overhead: {metrics.avg_latency_ms}ms")
```

**Reasonix 监控**：

```bash
# 会话统计
reasonix replay --last --stats

# 导出会话数据
reasonix events export --format json > session-data.json
```

### 5.3 告警阈值

```yaml
alerts:
  cache_hit_drop:
    threshold: "drop > 10% in 10 turns"
    action: "检查是否有缓存破坏操作（动态内容注入、重排等）"

  compression_regression:
    threshold: "avg < 30% over 20 commands"
    action: "检查是否有未被覆盖的高频命令，运行 rtk discover"

  cost_spike:
    threshold: "per-turn cost > 3x baseline"
    action: "检查是否在无缓存情况下使用 Pro 模型"

  latency_degradation:
    threshold: "p95 > 5s added"
    action: "检查 Headroom pipeline 是否超时，考虑降级为纯规则模式"
```

---

## 6. 实施优先级建议

### 6.1 快速见效（第 1 天）

**优先级 1：caveman Lite**

```markdown
# 在 CLAUDE.md 或每条提示开头添加
Caveman Lite. Be concise, skip pleasantries, keep technical substance.
Code/URLs/paths preserved verbatim.
```

- **投入**：1 行文本
- **产出**：10-20% 输出 token 节省
- **风险**：零
- **适用**：所有场景

**优先级 2：RTK（Unix/Linux/macOS）**

```bash
brew install rtk        # macOS
rtk init -g             # 激活 hook
# 重启 Claude Code
```

- **投入**：5 分钟
- **产出**：60-90% 命令输出 token 节省
- **风险**：低（小输出可能膨胀）
- **适用**：频繁运行 shell 命令的会话

**优先级 3：Reasonix（如果你使用 DeepSeek）**

```bash
npx reasonix code
```

- **投入**：首次启动配置 API key（2 分钟）
- **产出**：63-80% 总成本节省
- **风险**：零（仅改变架构，不改变内容）
- **适用**：DeepSeek API 用户

### 6.2 中期优化（第 1 周）

**优先级 4：Caveman Full**

```markdown
Caveman mode ON. No filler, no grammar if not needed.
Use symbols (→, =, vs). Output = shortest correct answer.
Code/URLs/paths preserved byte-exact.
```

- **投入**：更新 CLAUDE.md
- **产出**：额外 5-15% 输出 token 节省（vs Lite）
- **风险**：低-中（回复可能过于简洁）
- **适用**：确认质量无损失后

**优先级 5：Headroom Proxy**

```bash
pip install "headroom-ai[all]"
headroom proxy
# 另一终端
ANTHROPIC_BASE_URL=http://localhost:8787 claude
```

- **投入**：30 分钟设置
- **产出**：40-90% 上下文 token 节省
- **风险**：中（管道延迟 P50 52ms，需验证压缩质量）
- **适用**：工具调用密集、搜索重度的会话

### 6.3 深度优化（第 2-4 周）

**优先级 6：RTK 命令扩展**

```bash
rtk discover          # 发现未覆盖的频繁命令
# 添加自定义规则
```

**优先级 7：Headroom 自定义规则**

```python
from headroom import compress, Rule

rules = [
    Rule(match="jest output", algorithms=["smart_crusher"]),
    Rule(match="*.md", algorithms=["kompress_base"]),
]
compress(messages, custom_rules=rules)
```

**优先级 8：跨策略协调**

```yaml
# .trae/stack.yaml
layers:
  - name: caveman_full
    enabled: true
    config:
      mode: full
      exclude_contexts: ["documentation", "user_facing"]

  - name: rtk_normal
    enabled: true
    config:
      level: normal
      exclude_commands: ["curl", "playwright"]

  - name: headroom_auto
    enabled: true
    config:
      mode: proxy
      algorithms: ["smart_crusher", "code_compressor"]

  - name: reasonix_cache
    enabled: true
    condition: "provider == 'deepseek'"
```

---

## 7. 成本估算对照表

### 7.1 不同策略组合的月度成本

假设：每天 4 小时编码，相当于 8 个 30 分钟会话。使用 Claude Sonnet 级别定价（$3/MTok 输入，$15/MTok 输出）。

| 策略组合 | 日均 Token | 日均成本 | 月度成本 | vs 基准 |
|----------|-----------|----------|----------|---------|
| 无优化 | 1.2M in + 0.24M out | $7.20 | $144.00 | 基准 |
| caveman only | 1.2M in + 0.19M out | $6.45 | $129.00 | -10% |
| RTK only | 0.48M in + 0.24M out | $5.04 | $100.80 | -30% |
| Headroom only | 0.48M in + 0.24M out | $5.04 | $100.80 | -30% |
| caveman + RTK | 0.48M in + 0.19M out | $4.29 | $85.80 | -40% |
| caveman + RTK + Headroom | 0.20M in + 0.19M out | $3.45 | $69.00 | **-52%** |

### 7.2 DeepSeek V4 Flash 特例

相同工作负载，使用 Reasonix（99.82% 缓存命中）：

| 策略 | 日均 Token | 日均成本 | 月度成本 |
|------|-----------|----------|----------|
| 无优化 + Flash | 1.2M in + 0.24M out | $0.15 | $3.05 |
| Reasonix cache | 1.2M in (99.8% cached) + 0.24M out | $0.08 | **$1.52** |
| Reasonix + caveman + RTK | ~0.48M in (99.8% cached) + 0.19M out | ~$0.06 | **~$1.15** |

---

## 8. 质量保障

### 8.1 验证清单

在启用任何压缩策略后，验证以下项目：

| 验证项 | 方法 | 通过标准 |
|--------|------|----------|
| 代码生成质量 | 运行测试套件 | 100% 通过率 |
| 错误诊断准确度 | 注入已知 Bug，检查诊断 | 根因正确且完整 |
| 上下文保持 | 多轮对话后检查记忆 | 不丢失关键决策信息 |
| 输出完整性 | 检查代码块、路径、URL | 逐字节正确 |
| 延迟可接受性 | 测量 P95 响应时间 | 不超过基线的 2x |

### 8.2 回退策略

```bash
# 每个策略都有独立的关闭开关
# RTK
rtk off                  # 禁用自动改写

# Headroom
HEADROOM_ENABLED=0 claude

# caveman
# 从 CLAUDE.md 中移除或追加
Caveman mode OFF. Resume normal communication style.

# Reasonix
# 切换回你之前使用的工具即可
```

### 8.3 渐进采用路径

```
Week 1: caveman Lite → 无风险，立即生效
Week 2: RTK normal  → 验证测试输出无回退问题
Week 3: Headroom proxy → 验证压缩质量，关注边缘案例
Week 4: caveman Full → 在已验证质量的前提下
Week 5+: 微调规则、添加自定义命令、启用 CCR
```

---

## 9. 综合建议

1. **从 caveman 开始**：零依赖、零配置、立即可用。这是每个开发者都应该启用的基线优化。

2. **DevOps 优先 RTK**：如果你频繁运行 `git`、`pytest`、`npm test`、`docker`，RTK 的投入产出比最高。

3. **数据密集型用 Headroom**：如果你的代理大量使用搜索、数据库查询、RAG 结果，Headroom 的 SmartCrusher 和 CCR 机制是无价的。

4. **DeepSeek 用户用 Reasonix**：如果你已经用 DeepSeek API，没有理由不用 Reasonix——5x 成本节省是自动的。

5. **组合使用**：这四个工具优化不同的 token 源——它们互相正交，可以同时使用而不会冲突。

6. **始终验证**：压缩是优化，不是魔术。每次启用新策略后，运行一遍测试确保质量无回退。
