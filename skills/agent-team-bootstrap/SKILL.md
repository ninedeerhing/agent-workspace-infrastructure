---
name: agent-team-bootstrap
description: Raindeer-AWI 团队建队工作流。触发条件：bootstrap -ProvisionTeam、导入后建队、生成 registry/mailbox、跨平台会话清单、orchestrator-Only 团队初始化。
---

# Agent Team Bootstrap

## 定位

将 `agents/` 全 roster 转为可运行团队：**1 orchestrator + 17 worker**，跨平台文件总线协作。

## 触发条件

- `bootstrap.ps1 -Mode full -ProvisionTeam`
- 用户要求「建队 / 配 registry / 初始化 mailbox」
- registry 与 agents/ 不同步

## 执行步骤

```powershell
# 1. 生成 registry / manifest / mailbox / worklog
.\harness\scripts\Build-AgentRegistryFromAgentsDir.ps1 -WriteFiles -EnsureScaffold

# 2. 注入 worker 会话边界
.\harness\scripts\Apply-WorkerBoundaryToAgents.ps1

# 3. 安装平台适配器
.\harness\adapters\Invoke-PlatformAdapter.ps1 -Platform auto

# 4. 合规验证
.\harness\compliance-check.ps1 -Mode post-bootstrap
```

## 输出物

| 文件 | 用途 |
|------|------|
| `harness/agent-registry.json` | 18 角色注册表 |
| `harness/team-manifest.default.json` | 默认团队清单 |
| `harness/mailbox/{role}/` | 文件总线 |
| `harness/worklogs/{role}.md` | worker 工作日志 |
| `docs/SESSION_SETUP.md` | 多会话创建清单 |
| `harness/platform-binding.json` | 平台绑定 |

## 硬约束

1. **orchestrator** 是唯一对用户会话。
2. worker 禁止直接对用户输出。
3. 任务分派用 `Send-MailboxMessage.ps1`。
4. bootstrap 后必须 post-bootstrap 合规检查通过。

## 验证标准

- `agent-registry.json` role_count = agents/*.md 数量
- 17 个 worker 含「会话边界（Worker 硬约束）」块
- `compliance-check.ps1 -Mode post-bootstrap` findings = 0
