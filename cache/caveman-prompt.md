# Caveman Token 压缩提示策略

> 基于 [caveman](https://github.com/JuliusBrussee/caveman) 项目（34.8K+ Stars, MIT License）的实践经验，本文档提供在 AI 编程代理中启用 Caveman 模式的完整指南。

---

## 1. 核心原则

**用最少 token 传达完整技术信息。**

Caveman 模式的核心假设是：LLM 的内部推理能力不受输出风格影响。模型的"大脑"完全相同——改变的是"说话方式"。

- 正常输出中 60-75% 的 token 是"胶水词"——`the`、`is`、`because`、`I recommend`、`you should consider`——它们让文本对人类更友好，但不增加信息量
- Caveman 模式剥离胶水词，保留信号
- 实测在真实编码任务中节省 14-21% 输出 token（基线已被要求"简洁"时）；在解释型问答中可节省 60-75%

**关键洞察**：LLM 极擅长填充语言缝隙。Caveman 模式只删除 LLM 可可靠重建的内容。

---

## 2. 三级强度定义

### 2.1 Lite 模式

**触发方式**：在提示末尾添加 `Caveman Lite.`

**行为**：
- 删除礼貌用语（"当然"、"很高兴帮助你"）
- 删除过度解释的引导句（"这可能是由以下原因造成的..."）
- 保留自然语法结构
- 保留必要的连接词

**适用场景**：日常编码辅助、简短问答、代码审查回复

**示例**：

```
正常：The performance issues you're experiencing are likely caused by the
       fact that your application is making multiple redundant API calls on
       each page load.

Lite：Performance issues caused by redundant API calls on each page load.
```

**预期节省**：10-20% 输出 token

### 2.2 Full 模式

**触发方式**：在提示末尾添加 `Caveman mode ON.` 或在 Claude Code 中加载 caveman skill

**行为**：
- 删除所有填充词（the, a, an, is, are, etc. 在可删除处）
- 使用箭头（→）、等号（=）、vs 替代完整句子
- 使用关键词而非完整描述
- 每个回复控制在最短可行长度
- 假设用户足够聪明，无需额外解释

**适用场景**：代码实现、调试、错误解释、提交消息、测试结果解读

**示例**：

```
正常：The error occurs because the variable is undefined at the point where
       you're trying to access it. You should check if the initialization
       runs before this code path.

Full：Variable undefined → init before access. Check order.
```

**预期节省**：14-21% 输出 token（严谨基线）；40-60%（宽松基线）

### 2.3 Ultra 模式

**触发方式**：`Caveman Ultra. Symbols only when needed.`

**行为**：
- Full 模式全部规则
- 代码符号（函数名、变量名、文件路径）优先于自然语言
- 不保留任何语法结构
- 极端压缩，类似笔记风格
- **守卫规则**：代码、URL、路径字节原样保留，绝不压缩

**适用场景**：大批量代码审查、自动化流水线中的 agent 间通信、CI 日志诊断

**示例**：

```
正常：The test failure is in the UserAuthentication module, specifically
       the test_oauth_callback function. The expected status code was 302
       but the actual result was 401 Unauthorized.

Ultra：[test_oauth_callback] UserAuthentication → 401 vs 302 expected
       └─ token refresh path, check expires_in
```

**预期节省**：40-60% 输出 token

**风险警告**：Ultra 模式可能导致不同模型间可读性差异显著。在关键任务中先用 Full 模式验证。

---

## 3. 文言文模式（Wenyan 模式）

Caveman 项目原生支持的中文优化方案。分三级与上述对应，但针对中文语境优化。

### 3.1 Wenyan-Lite

```
文言Lite。去赘字。留文意。
```

- 删除"的"、"了"、"吗"、"呢"等虚词（可省处）
- 保留基本句法
- 适合中文代码审查回复

### 3.2 Wenyan-Full

```
文言Full。极简。用符号。无虚词。
```

- 删除所有可省的虚词
- 使用符号替代语法标记
- 适合中文技术问答

### 3.3 Wenyan-Ultra

```
文言Ultra。符号化。代码/路径原样保留。
```

- 极端压缩，文言文风格
- 代码符号优先级最高
- 适合中文 agent 间通信

---

## 4. 压缩规则清单

### 4.1 删除（Always Strip）

| 类别 | 示例 | 说明 |
|------|------|------|
| 礼貌用语 | "当然"、"Sure"、"Happy to help" | 零信息量 |
| 引导句式 | "I would recommend"、"你或许可以考虑" | 不增加决策依据 |
| 冗余修饰 | "very"、"really"、"quite"、"非常"、"相当" | 移除不影响语义 |
| 过度解释 | "This is because..."、"原因是..." | 直接给结论 |
| 重复确认 | "Let me know if you need anything else" | 无操作价值 |
| 自我引用 | "As I mentioned earlier"、"如前所述" | 上下文已存在 |

### 4.2 保留（Always Keep）

| 类别 | 说明 |
|------|------|
| 代码块 | 完整代码，零压缩 |
| 文件路径 | `src/utils/helper.ts` 原样保留 |
| URL | 完整 URL，字节精确 |
| 错误消息 | 原始错误文本，不改写 |
| 命令 | `git status`、`npm run build` 原样 |
| 版本号 | `v1.2.3` 精确保留 |
| 数值/配置 | `port: 3000`、`timeout: 5000` 精确值 |

### 4.3 可选压缩

| 类别 | 策略 |
|------|------|
| 解释性段落 | 压缩为要点列表 |
| 多步骤说明 | 用 `→` 链替代 |
| 对比分析 | 用表格或 `vs` 替代 |
| 背景信息 | 仅保留与决策直接相关的 |

---

## 5. 何时不应使用 Caveman 模式

| 场景 | 原因 |
|------|------|
| **正式文档编写** | 需要完整语法和专业语气 |
| **用户面消息** | 终端用户不应看到压缩风格 |
| **API 文档/规范** | 需要精确、无歧义的自然语言 |
| **法律/合规文本** | 任何压缩都可能引入歧义 |
| **代码注释** | 注释应与代码同样可读 |
| **教学/培训材料** | 学习者需要完整的语法线索 |
| **跨团队沟通** | 压缩风格可能被误读为不专业 |
| **多语言翻译输出** | 压缩破坏目标语言的语法结构 |

---

## 6. 激活与停止指令

### 6.1 Claude Code / Cursor / 通用 Agent

**激活**：

```
# Full 模式（推荐日常使用）
Caveman mode ON. No filler, no grammar if not needed, use symbols (→, =, vs).
Output = shortest correct answer. Code/URLs/paths preserved byte-exact.

# Lite 模式
Caveman Lite. Be concise, skip pleasantries, keep technical substance.

# Ultra 模式
Caveman Ultra. Symbols only. Code symbols first. No natural language grammar.
Code/URLs/paths preserved byte-exact. Assume user smart.
```

**停止**：

```
Caveman mode OFF. Resume normal communication style.
```

### 6.2 持久化配置（Claude Code）

在 `CLAUDE.md` 中添加：

```markdown
## Communication Style
- Caveman mode ON by default for all technical replies
- Code, URLs, file paths preserved verbatim
- Switch to normal mode when user explicitly requests documentation or explanation
```

### 6.3 Skill 方式（推荐）

```bash
# 安装 caveman skill（自动适配 Claude Code / Codex / Cursor / Windsurf）
npx caveman install
```

安装后，回复自动压缩。无需每次手动激活。

---

## 7. 实战示例

### 7.1 代码审查回复

```
// 正常回复（~120 tokens）
I've reviewed the changes in userService.ts. There's a potential race
condition in the updateUser function where the database read and write
are not wrapped in a transaction. I would recommend adding a transaction
wrapper around lines 45-52 to ensure atomicity. Additionally, the error
handling on line 78 doesn't catch the specific DatabaseError type, which
could mask connection pool exhaustion issues.

// Caveman 回复（~40 tokens，节省 67%）
userService.ts:35-52 → race condition, read/write not in transaction
└─ wrap 45-52 in transaction
L78 → catch generic, not DatabaseError → masks pool exhaustion
```

### 7.2 错误解释

```
// 正常（~80 tokens）
The build is failing because the TypeScript compiler can't resolve the
import for '../utils/formatter'. This usually happens when the file has
been moved or deleted without updating the import paths. Check if
formatter.ts still exists at that relative path.

// Caveman（~25 tokens，节省 69%）
build fail → '../utils/formatter' unresolved
→ file moved/deleted? check path exists
```

### 7.3 提交消息

```
// 正常
Fix the bug where user sessions were not being properly invalidated after
password change, which allowed old tokens to remain valid for up to the
configured TTL duration.

// Caveman
fix(auth): session not invalidated after password change → old tokens survive TTL
```

### 7.4 技术问答

```
// 正常（~150 tokens）
React re-renders occur when state or props change. The component function
is called again with the new values. To optimize this, you can use
React.memo to prevent re-renders when props haven't changed, or useMemo
and useCallback to stabilize references. The key insight is that React
uses reference equality for comparison, so creating new objects or
functions on every render will trigger child re-renders even if the
values are logically the same.

// Caveman（~50 tokens，节省 67%）
React re-render → state/props change → component re-executes
Optimize:
- React.memo → skip if same props
- useMemo/useCallback → stable refs
Key: reference equality → new {} or () each render = child re-render
```

---

## 8. 基准数据

基于 Kuba Guzik 的独立基准测试（2026 年 4 月），72 次运行，Claude Sonnet + Opus：

| 模型 | 基线 tokens | Caveman Full (552t) | Caveman Micro (85t) |
|------|------------|---------------------|---------------------|
| **Claude Sonnet** | 259 avg | 225 avg (-13%) | 223 avg (-14%) |
| **Claude Opus** | 227 avg | 207 avg (-9%) | 180 avg (-21%) |

关键发现：
- 552 token 的完整 skill 提示与 85 token 的微缩版效果相当甚至更差
- 注入的提示本身也消耗 token——需权衡净收益
- 质量零损失：72 次运行中，100% 正确答案保留
- 如果基线已包含"简洁"指令，节省率从 75% 降到 14-21%

---

## 9. 注意事项

1. **净收益计算**：Caveman 提示本身消耗 token。552 token 的 skill 注入 + 节省 30 token = 净负。微缩版（<100 token）才能保证净正。
2. **模型差异**：Opus 对压缩指令响应更好（21% vs 9%），Sonnet 本身就更简洁。
3. **任务类型影响**：解释型任务节省高（60-75%），结构化提取任务节省低（14-21%）。
4. **不可用于 Subagent 的逆向分析**：如果子代理的输出要被主代理进一步分析，压缩可能丢失关键上下文线索。
5. **渐进采用**：先 Lite，确认质量无损失后升级到 Full。Ultra 仅在自动化流水线中使用。
