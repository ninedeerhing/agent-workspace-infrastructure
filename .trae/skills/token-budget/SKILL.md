---
name: token-budget
description: Token 预算综合管理——整合 caveman、RTK、Headroom、Reasonix 四大 Token 优化策略，提供从策略选择到实施监控的完整决策框架。触发条件：需要优化 token 成本、对话过长、工具输出冗余、API 费用过高。
---

# Token Budget — Token 预算综合管理

## 定位

一套四层 Token 优化决策框架。覆盖 LLM 响应层 → 工具输出层 → 上下文输入层 → 会话持续层，提供从快速见效到深度优化的渐进路径，组合使用可节省 77%+ 的 token 消耗。

## 触发条件

- 单会话 token 消耗超过 150K
- API 月度费用超过预算
- 对话上下文频繁因 token 限制而截断
- 工具输出（bash 命令、文件读取）过于冗长
- 新项目需要配置 token 优化策略

## 四层优化架构

```
┌─────────────────────────────────────────────────────────┐
│              第 4 层：会话持续层                            │
│  策略: Reasonix Prefix-Cache / Headroom CacheAligner       │
│  节省: 63-80% 总成本（DeepSeek）或 20-40% 额外缓存命中       │
│  机制: 前缀稳定 → KV Cache 命中 → 输入仅 1/10 价格          │
├─────────────────────────────────────────────────────────┤
│              第 3 层：上下文输入层                            │
│  策略: Headroom (SmartCrusher / CodeCompressor / Kompress) │
│  节省: 40-90% 输入 token（按内容类型）                       │
│  机制: 智能压缩工具输出 / RAG 结果 / 文件读取                 │
├─────────────────────────────────────────────────────────┤
│              第 2 层：工具输出层                              │
│  策略: RTK (filter / group / truncate / dedupe)            │
│  节省: 60-95% 命令输出 token（按命令类型）                    │
│  机制: PreToolUse Hook → 命令改写 → 输出压缩                │
├─────────────────────────────────────────────────────────┤
│              第 1 层：LLM 响应层                             │
│  策略: caveman (Lite / Full / Ultra)                        │
│  节省: 14-21% 输出 token（编码），60-75%（解释）               │
│  机制: System Prompt → 压缩输出风格                          │
└─────────────────────────────────────────────────────────┘
```

## 策略选择决策树

```
开始
│
├─ 使用 DeepSeek API？
│  ├─ 是 → 优先使用 Reasonix（prefix-cache 省 5x）
│  │      └─ 叠加：caveman 输出压缩 / RTK 命令压缩
│  │
│  └─ 否 → 继续
│
├─ 什么在消耗 token？
│  │
│  ├─ 主要是 LLM 输出太长？
│  │  └─ 使用 caveman（Lite → Full → Ultra 渐进）
│  │
│  ├─ 主要是命令输出太长？
│  │  ├─ Unix/Linux/macOS → 安装 RTK
│  │  └─ Windows → WSL2 中的 RTK / PowerShell 脚本
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
```

## 四种策略对比

| 维度 | **caveman** | **RTK** | **Headroom** | **Reasonix** |
|------|-------------|---------|-------------|-------------|
| **优化层级** | LLM 响应层 | 工具输出层 | 上下文输入层 | 会话持续层 |
| **压缩方向** | 输出压缩 | 输入压缩 | 输入压缩 | 缓存复用 |
| **核心机制** | 提示风格控制 | 命令输出过滤 | 内容智能压缩 | Prefix-Cache 稳定 |
| **典型节省** | 14-21%（编码）；60-75%（解释） | 60-95%（按命令类型） | 40-90%（按内容类型） | 63-80%（总成本） |
| **质量风险** | 低（仅改变风格） | 中（有损压缩） | 极低（CCR 可逆） | 无（保持原始内容） |
| **Windows 支持** | ✅ 原生 | ⚠️ 需 WSL2 | ✅ 原生 | ✅ 原生 |
| **复杂度** | 极低 | 低 | 中 | 中 |

## 叠加效果估算

以 30 分钟编码会话（~150K tokens）为例：

| 阶段 | 原始 Token | 策略 | 压缩后 | 节省率 |
|------|-----------|------|--------|--------|
| **无优化** | 150,000 | — | 150,000 | 基准 |
| +caveman | 150,000 | 输出 -18% | ~140,000 | -7% 总量 |
| +RTK | 150,000 | 命令输出 -80% | ~70,000 | -53% 总量 |
| +Headroom | 150,000 | 上下文 -60% | ~60,000 | -60% 总量 |
| **三层叠加** | 150,000 | 全部 | **~35,000** | **-77% 总量** |

> 叠加效果非严格可加（各层覆盖不同 token 源）。

## 实施优先级

### 快速见效（第 1 天）

**优先级 1：caveman Lite** — 零依赖、零配置

```markdown
# 在 CLAUDE.md 或 System Prompt 中添加
Caveman Lite. Be concise, skip pleasantries, keep technical substance.
Code/URLs/paths preserved verbatim.
```

- **投入**：1 行文本
- **产出**：10-20% 输出 token 节省
- **适用**：所有场景

**优先级 2：RTK（Unix/Linux/macOS）**

```bash
brew install rtk
rtk init -g
```

- **投入**：5 分钟
- **产出**：60-90% 命令输出 token 节省
- **适用**：频繁运行 shell 命令的会话

**优先级 3：Reasonix（使用 DeepSeek 时）**

```bash
npx reasonix code
```

- **投入**：2 分钟
- **产出**：63-80% 总成本节省
- **适用**：DeepSeek API 用户

### 中期优化（第 1 周）

**优先级 4：caveman Full**

```markdown
Caveman mode ON. No filler, no grammar if not needed.
Use symbols (→, =, vs). Output = shortest correct answer.
Code/URLs/paths preserved byte-exact.
```

**优先级 5：Headroom Proxy**

```bash
pip install "headroom-ai[all]"
headroom proxy
ANTHROPIC_BASE_URL=http://localhost:8787 claude
```

- **投入**：30 分钟
- **产出**：40-90% 上下文 token 节省

### 深度优化（第 2-4 周）

- RTK 命令扩展：`rtk discover` 发现未覆盖命令
- Headroom 自定义压缩规则
- 跨策略协调配置

## 预算配置模板

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
  headroom: "auto"           # auto | proxy | off
  reasonix_cache: "on"       # on | off（仅 DeepSeek API）
```

## 跨策略协调

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

## 月度成本估算

基于：每天 4 小时编码（8 个 30 分钟会话），Claude Sonnet 级定价。

| 策略组合 | 日均成本 | 月度成本 | vs 基准 |
|----------|----------|----------|---------|
| 无优化 | $7.20 | $144.00 | 基准 |
| caveman only | $6.45 | $129.00 | -10% |
| RTK only | $5.04 | $100.80 | -30% |
| Headroom only | $5.04 | $100.80 | -30% |
| caveman + RTK | $4.29 | $85.80 | -40% |
| caveman + RTK + Headroom | $3.45 | **$69.00** | **-52%** |

DeepSeek V4 Flash + Reasonix（99.82% 缓存命中）：

| 策略 | 月度成本 |
|------|----------|
| 无优化 + Flash | $3.05 |
| Reasonix cache | **$1.52** |
| Reasonix + caveman + RTK | **~$1.15** |

## 监控指标

| 指标 | 目标值 | 工具 |
|------|--------|------|
| **缓存命中率** | >90% (DeepSeek); >60% (其他) | Reasonix dashboard / API headers |
| **压缩率** | >50% 工具输出; >15% LLM 输出 | RTK `gain` / Headroom telemetry |
| **成本节省** | >50% 总成本 | 各工具内置 / 自定义聚合 |
| **P95 延迟** | < 基线的 2x | 各工具 telemetry |
| **质量保持率** | 100% | 手动审查 / 自动化测试 |

### 监控命令

```bash
# RTK
rtk gain
rtk gain --project my-project

# Reasonix
reasonix replay --last --stats
reasonix stats --cache
```

### 告警阈值

```yaml
alerts:
  cache_hit_drop:
    threshold: "drop > 10% in 10 turns"
    action: "检查是否有缓存破坏操作（动态内容注入、重排等）"
  compression_regression:
    threshold: "avg < 30% over 20 commands"
    action: "检查未被覆盖的高频命令，运行 rtk discover"
  cost_spike:
    threshold: "per-turn cost > 3x baseline"
    action: "检查是否在无缓存情况下使用 Pro 模型"
  latency_degradation:
    threshold: "p95 > 5s added"
    action: "检查 Headroom pipeline 是否超时"
```

## 质量保障

### 验证清单

在启用任何压缩策略后，验证以下项目：

| 验证项 | 方法 | 通过标准 |
|--------|------|----------|
| 代码生成质量 | 运行测试套件 | 100% 通过率 |
| 错误诊断准确度 | 注入已知 Bug | 根因正确且完整 |
| 上下文保持 | 多轮对话后检查记忆 | 不丢失关键决策信息 |
| 输出完整性 | 检查代码块/路径/URL | 逐字节正确 |
| 延迟可接受性 | 测量 P95 响应时间 | 不超过基线 2x |

### 回退策略

```bash
# 每个策略都有独立的关闭开关
rtk off                        # RTK 禁用
HEADROOM_ENABLED=0 claude      # Headroom 禁用
# caveman：从 CLAUDE.md 中移除压缩指令
# Reasonix：切换回原生 API 客户端
```

## 渐进采用路径

```
Week 1: caveman Lite → 无风险，立即生效
Week 2: RTK normal  → 验证测试输出无回退问题
Week 3: Headroom proxy → 验证压缩质量，关注边缘案例
Week 4: caveman Full → 在已验证质量的前提下启用
Week 5+: 微调规则、添加自定义命令、启用 CCR
```

## 综合建议

1. **从 caveman 开始**：零依赖、零配置、立即可用的基线优化
2. **DevOps 优先 RTK**：频繁运行 `git`、`pytest`、`npm test`、`docker` 时投入产出比最高
3. **数据密集型用 Headroom**：大量搜索、数据库查询、RAG 结果场景下无价
4. **DeepSeek 用户用 Reasonix**：5x 成本节省是自动的
5. **组合使用**：四工具优化不同 token 源，正交可叠加，不冲突
6. **始终验证**：每次启用新策略后运行测试确保质量无回退
