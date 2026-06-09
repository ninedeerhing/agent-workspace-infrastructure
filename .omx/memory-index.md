# OMX Memory Index — 语义搜索规范

OMX Memory Index 是 `AWI` 的语义搜索子系统规范，定义记忆索引的结构、检索算法、相关性排序和集成方式。与 `memory.md` 共同构成完整的记忆管理栈。

**版本:** 1.0.0

---

## 1. 架构概览

```
┌──────────────────────────────────────────────────────────────────┐
│                       OMX Memory Search                          │
│                                                                  │
│  ┌────────────────┐    ┌────────────────┐    ┌───────────────┐  │
│  │  Query Parser  │ -> │  Multi-Stage   │ -> │  Result       │  │
│  │  (分词/归一化)  │    │  Ranker        │    │  Collator     │  │
│  └────────────────┘    │  (多策略打分)   │    │  (去重/合并)  │  │
│                        └───────┬────────┘    └───────────────┘  │
│                                │                                  │
│         ┌──────────────────────┼──────────────────────┐          │
│         ▼                      ▼                      ▼          │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │  Exact Match │    │  Fuzzy Match │    │  Semantic    │       │
│  │  (关键词精确) │    │  (模糊/编辑距)│    │  (词向量相似)│       │
│  │  weight: 1.0 │    │  weight: 0.7 │    │  weight: 0.5 │       │
│  └──────────────┘    └──────────────┘    └──────────────┘       │
│                                                                  │
│  Data Sources:                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  .omx/memory-index.json  (主索引：结构化搜索索引)         │   │
│  │  .omx/project-memory.json (原始记忆：全量记忆数据)        │   │
│  │  .omx/notepad.md         (记事本：全文检索补充)           │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. 索引文件规范

### 2.1 主索引文件：`.omx/memory-index.json`

```json
{
  "version": "1.0.0",
  "updated_at": "2026-06-09T22:00:00Z",
  "indexes": [
    {
      "id": "mem-abc123",
      "category": "TECH_STACK",
      "scope": "PROJECT",
      "content": "项目使用 TypeScript + React + Vite 技术栈",
      "tokens": ["typescript", "react", "vite", "技术栈"],
      "embedding": null,
      "metadata": {
        "source_agent": "claude",
        "source_provider": "anthropic",
        "created_at_utc": "2026-06-09T10:30:00Z",
        "access_count": 5,
        "last_accessed_at": "2026-06-09T21:00:00Z",
        "confidence": 1.0,
        "supersedes": null,
        "superseded_by": null
      },
      "aliases": ["ts", "react", "前端技术栈"],
      "tags": ["frontend", "build-tool"]
    }
  ]
}
```

### 2.2 索引条目字段说明

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | 是 | 唯一标识符，格式 `mem-{6位随机}` |
| `category` | enum | 是 | 记忆类别：`TECH_STACK` / `BUILD` / `CONVENTION` / `STRUCTURE` / `DECISION` / `NOTE` / `DIRECTIVE` |
| `scope` | enum | 是 | 作用域：`PROJECT` / `SESSION` / `AGENT` / `TURN` |
| `content` | string | 是 | 记忆原始文本（可检索字段） |
| `tokens` | string[] | 是 | 分词后的关键词列表，用于精确匹配和模糊匹配 |
| `embedding` | number[] | 否 | 文本向量嵌入（可选，启用语义搜索时使用） |
| `metadata` | object | 是 | 元数据（来源、时间戳、访问计数等） |
| `aliases` | string[] | 否 | 内容别名，用于扩展匹配 |
| `tags` | string[] | 否 | 自由标签，用于分类过滤 |

### 2.3 元数据字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `source_agent` | string | 创建或更新此记忆的代理名称 |
| `source_provider` | string | 代理提供商 |
| `created_at_utc` | string | ISO 8601 创建时间 |
| `access_count` | number | 累计访问次数（用于记忆冒泡） |
| `last_accessed_at` | string | 最近一次被检索命中的时间 |
| `confidence` | number | 置信度 0.0-1.0。1.0 = 已确认事实 |
| `supersedes` | string | 被此记忆替代的旧记忆 ID |
| `superseded_by` | string | 替代此记忆的新记忆 ID |

---

## 3. 检索策略

### 3.1 三阶段检索流水线

```
Query Input
    │
    ▼
┌─────────────────────────────────────────────┐
│ Stage 1: Query Normalization                │
│ - 小写转换                                   │
│ - 去除标点/停用词                             │
│ - 提取关键词（按空格/标点分词）                │
│ - 展开别名（中文 ↔ 英文对应）                  │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│ Stage 2: Candidate Retrieval                │
│ - 精确匹配：tokens 完全命中                   │
│ - 子串匹配：content 包含查询词                 │
│ - 别名匹配：aliases 命中                      │
│ - 标签匹配：tags 命中                         │
│ - 类别过滤：category 筛选                     │
│ - 作用域过滤：scope 筛选                      │
│ - 被替代记忆自动排除（superseded_by 非空）     │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────┐
│ Stage 3: Relevance Ranking                  │
│ - 精确匹配加权 (×1.0)                        │
│ - 模糊匹配加权 (×0.7，Levenshtein 距离)       │
│ - 类别匹配加权 (×0.3 加分)                    │
│ - 访问频次加权 (log(access_count + 1) × 0.1) │
│ - 置信度加权 (confidence × 0.2)              │
│ - 别名匹配降权 (×0.6)                         │
│ - 内容新鲜度加权（越新越高，0.0-0.1）          │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
             Ranked Results
```

### 3.2 相关性评分公式

```
Score = Σ(MatchType_weight × MatchCount)
      + CategoryBonus
      + log(access_count + 1) × 0.1
      + confidence × 0.2
      + FreshnessBonus

其中：
  MatchType_weight:
    - TokenExactMatch  = 1.0
    - ContentSubstring = 0.8
    - TokenFuzzyMatch  = 0.7  (Levenshtein distance <= 2)
    - AliasMatch       = 0.6
    - TagMatch         = 0.4

  CategoryBonus:
    - 查询指定类别时，匹配类别的条目 +0.3

  FreshnessBonus:
    - 基于 last_accessed_at 与当前时间的距离
    - 7天内访问过: +0.1
    - 30天内访问过: +0.05
    - 更久: 0.0
```

### 3.3 搜索模式

| 模式 | 触发条件 | 行为 |
|------|----------|------|
| **自然语言** | 输入为完整句子（> 3 词） | 分词后多路召回，综合排序 |
| **关键词** | 输入为 1-3 个词 | 精确+模糊匹配，Top-K 返回 |
| **类别限定** | `category:BUILD` 前缀 | 先按类别过滤，再检索 |
| **标签限定** | `tag:frontend` 前缀 | 先按标签过滤，再检索 |
| **ID 查找** | `id:mem-abc123` 前缀 | 直接按 ID 查找，跳过检索 |

---

## 4. 索引维护操作

### 4.1 索引重建

当 `project-memory.json` 发生变更时触发：

```
触发条件：
  - 写入了新记忆（project_memory_write）
  - 添加了新笔记（project_memory_add_note）
  - 添加了新指令（project_memory_add_directive）
  - 记忆被替代（superseded）

重建流程：
  1. 读取 project-memory.json 全量数据
  2. 对每条记忆执行分词（Tokenization）
  3. 提取别名和标签
  4. 生成 memory-index.json
  5. 输出增量变更摘要
```

### 4.2 增量更新

对于单条记忆的 CRUD，采用增量策略而非全量重建：

```
Add:    追加新条目到 indexes 数组
Update: 在原位置替换条目内容
Delete: 标记 superseded_by 而非物理删除
```

### 4.3 分词策略

| 语言 | 策略 |
|------|------|
| 英文 | 空格分词 → 小写 → 词干提取（Porter Stemmer 简化版）→ 去除停用词 |
| 中文 | 双字组 + 单字补充 → 过滤纯标点 → 保留 2-4 字词组 |
| 混合 | 先按 Unicode 区块分离中英文，分别分词后合并 |

中英文停用词表：

```
英文: a, an, the, is, are, was, were, be, been, being, have, has, had,
      do, does, did, will, would, could, should, may, might, can, shall,
      to, of, in, for, on, with, at, by, from, as, into, through, during,
      and, but, or, nor, not, so, yet, both, either, neither, each, every,
      this, that, these, those, it, its

中文: 的, 了, 在, 是, 我, 有, 和, 就, 不, 人, 都, 一, 一个, 上, 也,
      很, 到, 说, 要, 去, 你, 会, 着, 没有, 看, 好, 自己, 这
```

---

## 5. 检索接口

### 5.1 脚本调用接口

```powershell
# 自然语言搜索
.\memory-search.ps1 -Query "项目的技术栈是什么"

# 关键词搜索
.\memory-search.ps1 -Query "TypeScript React"

# 类别过滤搜索
.\memory-search.ps1 -Query "构建命令" -Category "BUILD"

# 标签过滤搜索
.\memory-search.ps1 -Query "部署" -Tag "deploy"

# 指定返回数量
.\memory-search.ps1 -Query "TypeScript" -TopK 5

# 输出 JSON 格式（供程序消费）
.\memory-search.ps1 -Query "TypeScript" -OutputJson

# 重建索引
.\memory-search.ps1 -Action rebuild

# 查看索引统计
.\memory-search.ps1 -Action stats
```

### 5.2 编程接口（内部函数）

```powershell
# 搜索记忆 — 返回排序后的结果数组
Search-Memory -Query "string" [-Category "string"] [-Tag "string"] [-TopK int]

# 重建索引 — 从 project-memory.json 重新生成 memory-index.json
Rebuild-MemoryIndex

# 获取索引统计 — 返回条目数、类别分布、大小等
Get-MemoryIndexStats

# 分词 — 将文本拆分为搜索 Token
Tokenize-Text -Text "string"

# 相关性评分 — 计算查询与候选条目的匹配分数
Score-Relevance -QueryTokens "string[]" -Candidate indexEntry
```

---

## 6. 与 OMX Memory 的集成

### 6.1 数据流

```
project_memory_write (memory.md 定义)
        │
        ▼
  memory-index.json 维护
        │
        ├── 自动触发增量更新
        │
        ▼
  memory-search.ps1 检索
        │
        ▼
  返回排序后的记忆条目
```

### 6.2 与其他技能的配合

| 技能 | 使用方式 |
|------|----------|
| `$brainstorming` | `Search-Memory -Category "TECH_STACK" -TopK 3` 加载技术栈上下文 |
| `$writing-plans` | `Search-Memory -Category "BUILD,CONVENTION"` 获取构建命令和约定 |
| `$executor` | 执行前检索 `DIRECTIVE` 类记忆，确保不违反硬约束 |
| `$code-review` | 检索 `CONVENTION` 类记忆作为审查基准 |
| `$deep-interview` | 检索 `DECISION` 类记忆避免与历史决策冲突 |
| `$finishing-dev-branch` | 检索 `NOTE` 类记忆获取部署相关笔记 |

### 6.3 记忆冒泡（Memory Bubbling）

每次检索命中后，更新被命中条目的 `access_count` 和 `last_accessed_at`：

```
高频访问 → access_count ↑ → 相关性加分 ↑ → 排名提升
低频访问 → 自然衰减在排序中不占优
```

---

## 7. 安全与隔离

### 7.1 数据隔离

- 索引文件存储在项目本地 `.omx/` 目录，不走网络
- 不同项目的索引完全隔离
- 不依赖外部嵌入模型服务（可选增强）

### 7.2 输入验证

- 查询字符串长度限制：<= 500 字符
- 拒绝空查询
- 特殊字符转义处理
- 防止 JSON 注入（输出时使用 `ConvertTo-Json` 安全序列化）

---

## 8. 性能约束

| 指标 | 目标值 | 说明 |
|------|--------|------|
| 索引条目上限 | 10,000 条 | 超过后建议归档旧记忆 |
| 单次查询耗时 | < 200ms | 不计索引重建 |
| 索引重建耗时 | < 2s | 10,000 条目规模 |
| 索引文件大小 | < 5MB | JSON 格式，UTF-8 编码 |
| 返回结果上限 | 50 条 | 超过此数建议缩小查询范围 |

---

## 9. 版本兼容

| 索引版本 | 变更说明 |
|----------|----------|
| 1.0.0 | 初始版本：多策略检索、三阶段流水线、JSON 索引存储 |

索引版本号记录在 `memory-index.json` 的 `version` 字段中，升级时自动执行迁移。
