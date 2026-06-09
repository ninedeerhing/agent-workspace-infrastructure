# EverOS 任务队列机制分析

> **来源**：EverOS GitHub 仓库 (`EverMind-AI/EverOS`)，官方文档 `docs/architecture.md`、`docs/how-memory-works.md`、`docs/api.md`
> **分析日期**：2026-06-09
> **系统版本**：EverOS 1.0.0

---

## 1. 概述

EverOS 的任务队列机制内建于其 **三件套存储架构**（Markdown + SQLite + LanceDB）之中，没有独立的 MQ 中间件。所有队列逻辑均由 SQLite 中的 `system.db` 承载，通过进程内协程（cascade daemon）和异步策略引擎（OME）驱动。核心设计原则：**Markdown 是唯一真相来源，SQLite 管理状态和队列，LanceDB 是可重建的派生索引**。

---

## 2. 队列层次全景

EverOS 中存在 **四个层级的队列/缓冲机制**，分别服务于不同的生命周期阶段：

```
┌─────────────────────────────────────────────────────────────────┐
│                     EverOS Queue Hierarchy                       │
├───────────────┬─────────────────────┬───────────────────────────┤
│ 名称           │ 存储位置             │ 用途                       │
├───────────────┼─────────────────────┼───────────────────────────┤
│ Buffer Queue  │ SQLite unprocessed  │ 消息累积，等 boundary 触发  │
│               │ _buffer 表           │ 批量提取 MemCell           │
├───────────────┼─────────────────────┼───────────────────────────┤
│ OME Queue     │ SQLite ome.db       │ 异步策略调度                │
│               │ + ome.aps.db        │ atomic_facts / foresight   │
│               │                     │ profile / cases / skills   │
├───────────────┼─────────────────────┼───────────────────────────┤
│ Cascade Queue │ SQLite md_change_   │ Markdown → LanceDB 同步    │
│               │ state 表             │ 基于 LSN 的崩溃恢复        │
├───────────────┼─────────────────────┼───────────────────────────┤
│ Audit Log     │ SQLite system.db    │ 不可变操作审计               │
│               │                     │ 状态变更追踪               │
└───────────────┴─────────────────────┴───────────────────────────┘
```

---

## 3. Buffer Queue — 消息缓冲与边界检测

### 3.1 设计目的

原始消息不会立即变成持久化记忆。消息通过 `/add` 端点进入后，首先在 SQLite 的 `unprocessed_buffer` 表中累积，等待 **边界检测器**（boundary detector）判断是否满足提取条件。

### 3.2 数据结构

```text
Buffer Key: (session_id, app_id, project_id)
每条 buffer 记录包含:
  - sender_id / sender_name / role / timestamp
  - content (文本或多模态 ContentItem)
  - tool_calls / tool_call_id (可选)
```

### 3.3 触发提取的条件

- **自动触发**：边界检测器（boundary detector）检测到会话自然断点，例如：
  - 话题语义漂移
  - 时间间隔超过阈值
  - 消息数量达到批次上限
- **手动触发**：客户端调用 `POST /api/v1/memory/flush` 强制排空缓冲

### 3.4 提取流程

```
POST /add → unprocessed_buffer (累积)
     │
     ├─ boundary detector 自然触发 ─┐
     │                              ▼
     │                     POST /flush (强制) ──→ 一次 LLM 调用
     │                              │
     │                              ▼
     │                        提取 MemCell
     │                              │
     │              ┌───────────────┴───────────────┐
     │              ▼                               ▼
     │     UserMemoryPipeline (同步)     AgentMemoryPipeline (fire-and-forget)
     │     写入 episode .md             发出 AgentPipelineStarted 事件
     │              │
     ▼              ▼
response 返回 (status: "extracted")
```

**关键一致性保证**：当 `/flush` 返回 `extracted` 时，episode markdown 已同步写入磁盘（fsync），不会因进程崩溃而丢失。但 LanceDB 索引是最终一致性的——见下文 Cascade Queue。

---

## 4. OME Queue — 离线记忆引擎调度

### 4.1 设计目的

OME（Offline Memory Engine）是一个 **进程内异步策略引擎**，负责将 MemCell 派生为更细粒度的记忆类型。它在请求路径之外异步运行，不阻塞 `/add` 或 `/flush` 的响应。

### 4.2 策略注册与调度

OME 维护 5 种策略，每种策略由独立的事件触发：

| 策略名称 | 产物 | 写入策略 | 触发源 |
|---------|------|---------|--------|
| `extract_atomic_facts` | `.atomic_facts/atomic_fact-<date>.md` | daily-log 追加 | 新 episode 事件 |
| `extract_foresight` | `.foresights/foresight-<date>.md` | daily-log 追加 | 新 episode 事件 |
| `extract_user_profile` | `user.md` | 单文件覆写 | 累积阈值 / 定时 |
| `extract_agent_case` | `.cases/agent_case-<date>.md` | daily-log 追加 | 新 agent cell 事件 |
| `extract_agent_skill` | `skills/skill_<name>/SKILL.md` | 目录命名 | 关联 case 聚类触发 |

### 4.3 调度架构

```
OME 内部组件:
├── ome.db          — 运行记录、计数器、策略状态
├── ome.aps.db      — APScheduler 作业存储（独立文件避免锁竞争）
├── ome.db.lock     — portalocker 单引擎守护锁
└── ome.toml        — 用户可编辑的策略开关配置（热重载 ~2 秒）
```

### 4.4 策略配置（ome.toml）

```toml
[strategies.extract_foresight]
enabled = false        # 关闭预测性记忆提取

[strategies.extract_user_profile]
enabled = true         # 开启用户画像聚合
```

### 4.5 对客户端的影响

`/flush` 返回 `extracted` 后，**episode** 在 cascade 索引完成即可查询。但 **atomic_facts / profile / agent_cases** 需要等待对应 OME 策略执行完毕（通常数秒）。需要即时读取的客户端应使用轮询+退避机制。

---

## 5. Cascade Queue — 索引同步队列

### 5.1 设计目的

Cascade daemon 是连接 Markdown（真相来源）与 LanceDB（检索索引）的关键桥梁。它确保对 `.md` 文件的任何变更最终都会反映到检索索引中。

### 5.2 核心架构

```
Markdown Tree (.md files)
     │
     ▼
watchdog (FSEvents / inotify)  ← 跨平台文件监听
     │
     ▼
md_change_state (SQLite 表)    ← 持久化排队，崩溃安全
     │
     ▼
Cascade Worker                 ← 进程内协程
     │  ├─ entry-level diff (content_sha256 去重)
     │  ├─ 仅重嵌变更条目
     │  └─ LanceDB upsert (单事务)
     ▼
LanceDB (.index/lancedb/*.lance)
```

### 5.3 md_change_state 表结构

| 字段 | 类型 | 用途 |
|------|------|------|
| `id` | integer | 主键 |
| `file_path` | text | 变更的 `.md` 文件路径 |
| `change_type` | text | `added` / `modified` / `removed` |
| `entry_id` | text | 受影响的条目 ID |
| `status` | text | `pending` / `processing` / `done` / `failed` |
| `lsn` | integer | 日志序列号（Log Sequence Number） |
| `created_at` | text | 入队时间戳 |

### 5.4 延迟与性能特性

| 指标 | 典型值 |
|------|--------|
| debounce 窗口 | 500ms |
| 正常索引延迟 | < 1 秒 |
| 高负载索引延迟 | 10–15 秒 |
| 处理粒度 | entry 级别（非文件级别） |

### 5.5 运维命令

```bash
everos cascade status    # 查看队列状态 / LSN 摘要
everos cascade sync      # 强制排空整个索引队列
everos cascade fix       # 列出失败行 / 重新入队可重试的
```

### 5.6 崩溃恢复

- 文件变更先入 `md_change_state` 表（SQLite 持久化），再处理
- 崩溃后重启，daemon 从断点重放入队事项
- LSN 水印确保重放顺序正确
- 索引完全可重建：`rm -rf .index/lancedb` 后重启即自动重建

**没有 `everos reindex` 命令**——删除 `.index/lancedb` 目录后重启服务器，cascade 自动从 markdown 重建。

---

## 6. 一致性模型

| 路径 | 保证级别 | 详情 |
|------|---------|------|
| **写入** (`/add`, `/flush`) | **强一致性** | episode `.md` 在返回前已 fsync 到磁盘；从不等待 LanceDB |
| **读取** (`/search`, `/get`) | **最终一致性** | 读取 LanceDB，延迟于 md 写入，典型 <1s，最坏约 10–15s |
| **索引** | **最终一致性** | LanceDB 不可用不影响响应，变更入队缓冲在 SQLite `md_change_state` 中 |

### 6.1 完整性不变式

- `id` / `entry_id`（frontmatter 中的字段）是不可变的联结键
- `content_sha256` 决定条目是否需要重嵌
- LSN 水印（`system.db` 中）排序重建
- `md_change_state` 是重放审计轨道

---

## 7. 零外部依赖的设计考量

EverOS 的任务队列完全基于嵌入式组件运行，不需要独立的消息队列服务：

```
传统栈:
  PostgreSQL + Redis/Kafka + Elasticsearch + Milvus

EverOS 栈:
  Markdown (真相) + SQLite (队列/状态) + LanceDB (嵌入式向量/BM25)
```

**优点**：
- 单目录部署，可直接备份或 Git 版本控制
- 无运维负担，无需管理多个服务
- 所有非 markdown 数据均可从 markdown 重建

**限制**：
- 单进程架构，不支持分布式队列
- 高并发场景下 SQLite 写入锁可能成为瓶颈
- 当前没有自动的 "grep over markdown" 降级搜索路径

---

## 8. 与 TRAE Workspace 的对照

| 维度 | EverOS | TRAE Workspace (Harness) |
|------|--------|--------------------------|
| 任务状态 | SQLite `md_change_state` + OME 策略 | `harness/feature_list.json` |
| 队列持久化 | SQLite (嵌入式) | JSON 文件 (非队列模式) |
| 审计日志 | SQLite system.db | `harness/progress.md` + `ultragoal/ledger.md` |
| 一致性 | 强写 + 最终读 | 文件系统级别 |
| 崩溃恢复 | LSN + md_change_state 重放 | `harness/archive/` 快照机制 |

**关键差异**：EverOS 的任务队列是**数据驱动的流水线**（消息→提取→索引），而 TRAE Workspace 的 Harness 是**代理行为的状态追踪系统**。EverOS 的队列设计对于需要内置记忆系统的代理平台有直接参考价值——特别是 SQLite 作为嵌入式队列存储和 LSN 崩溃恢复机制。
