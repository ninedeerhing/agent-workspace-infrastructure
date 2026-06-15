# Raindeer-AWI 使用指南

> 仓库：[agent-workspace-infrastructure](https://github.com/ninedeerhing/agent-workspace-infrastructure)  
> 默认分支：**`main`**

## 核心原则

- **你只和 orchestrator 一个会话说话**
- 其余 17 个 `agents/*.md` 角色都是 **Worker**，只干活、不对用户
- Worker 之间通过 `harness/mailbox/` 文件总线协作
- 协议由 Compliance Kernel 自动 enforcement（hooks + compliance-check + schedule），无需你反复提醒

---

## 一条命令导入（推荐）

### 场景 A：全新项目（空目录或刚 clone）

在 **PowerShell** 中执行（Windows / macOS / Linux 均可用 `pwsh`）：

```powershell
git clone https://github.com/ninedeerhing/agent-workspace-infrastructure.git my-project; cd my-project; .\bootstrap.ps1 -TargetPath . -ProjectName my-project -Mode full -ProvisionTeam -Platform auto
```

**这一条命令会：**

1. 拉取 `main` 分支（默认）
2. 完整部署 agents / skills / harness / 规则
3. 生成 18 角色 registry、mailbox 脚手架、worklog
4. 注入 17 个 Worker 会话边界
5. 安装当前 IDE 的平台适配器（Cursor / Trae / generic 等）
6. 生成 `docs/SESSION_SETUP.md` 多会话清单
7. 运行 post-bootstrap 合规检查

### 场景 B：已有代码的项目（增量导入治理层）

先审计（**不修改任何文件**）：

```powershell
git clone https://github.com/ninedeerhing/agent-workspace-infrastructure.git _awi; .\_awi\bootstrap.ps1 -TargetPath "D:\your-existing-project" -SourcePath .\_awi -ProjectName YourApp -Mode audit
```

确认无冲突后，一条命令完整导入 + 建队：

```powershell
git clone https://github.com/ninedeerhing/agent-workspace-infrastructure.git _awi; .\_awi\bootstrap.ps1 -TargetPath "D:\your-existing-project" -SourcePath .\_awi -ProjectName YourApp -Mode full -ProvisionTeam -Platform auto -Force
```

> `-Force` 仅覆盖 AWI 框架文件，不会删除你的业务代码。若需最安全模式，先用 `-Mode minimum` 只加 harness 层，再手动 `-Mode full -ProvisionTeam`。

### 场景 C：已 clone 本仓库，在当前目录配置

```powershell
.\bootstrap.ps1 -TargetPath . -ProjectName MyProject -Mode full -ProvisionTeam -Platform auto
```

### 平台参数

| `-Platform` | 说明 |
|-------------|------|
| `auto` | 自动检测 Cursor / Trae / Codex / Claude Code，默认 **推荐** |
| `cursor` | 安装 `.cursor/hooks.json` + orchestrator/worker 规则 |
| `trae` | 生成 `.trae/rules/raindeer-awi.md` |
| `generic` | 仅文件总线 + `SESSION_SETUP.md`，任意 IDE 可用 |

---

## 导入后怎么用

### 1. 打开会话

阅读自动生成的 **`docs/SESSION_SETUP.md`**，按表创建 IDE 会话。

**日常只打开 orchestrator 会话。** Worker 会话按需后台开着即可。

### 2. 首条消息

| 会话 | 粘贴文件 |
|------|----------|
| orchestrator | `harness/templates/orchestrator-init-prompt.md` |
| 各 worker | `harness/templates/worker-init-prompt.md`（把 `ROLE_ID` 换成对应角色） |

### 3. 开始对话

只对 orchestrator 说：

```
加载工作区，告诉我当前项目状态和主线任务
```

或：

```
我要做 XXX，请按 Raindeer-AWI 流程推进
```

orchestrator 会通过 mailbox 分派 worker，汇总结果后再回复你。

### 4. 验证导入成功

```powershell
.\harness\compliance-check.ps1 -Mode post-bootstrap
```

期望：`findings=0`，exit code `0`。

---

## 常用命令

```powershell
# 合规检查（日常）
.\harness\compliance-check.ps1 -Mode baseline

# 阶段门禁（orchestrator 切换 workflow 阶段前）
.\harness\gate-runner.ps1 -Workflow standard -FromPhase RESEARCH -ToPhase PLAN

# 分派任务给 worker
$h = @{ goal = "实现某功能" }
.\harness\scripts\Send-MailboxMessage.ps1 -From orchestrator -To executor -Type dispatch_task -Payload $h

# 读取 worker inbox
.\harness\scripts\Read-MailboxInbox.ps1 -RoleId executor

# 重新同步 registry（增删 agents/*.md 后）
.\harness\scripts\Build-AgentRegistryFromAgentsDir.ps1 -WriteFiles -EnsureScaffold
.\harness\scripts\Apply-WorkerBoundaryToAgents.ps1 -Force
```

---

## 关键文件索引

| 文件 | 作用 |
|------|------|
| `docs/SESSION_BOOT.md` | 所有会话的最小启动契约 |
| `docs/SESSION_SETUP.md` | 多会话创建清单（bootstrap 生成） |
| `docs/TASK_TREES.md` | 任务树 / 当前主线 |
| `docs/PROJECT_STATUS.md` §5 | 绝对可追溯台账 |
| `harness/agent-registry.json` | 18 角色注册表 |
| `harness/mailbox/README.md` | 文件总线协议 |
| `harness/workflow-state.json` | 工作流阶段状态 |
| `docs/ENGINEERING/RAINDEER-AWI-NORTHSTAR.md` | 北极星设计 |

---

## 环境要求

- **PowerShell 5.1+** 或 **PowerShell 7+**（推荐 `pwsh`）
- Git
- 任意 AI IDE（Cursor、Trae、Claude Code、Codex CLI 等）

> Windows 上若脚本报编码错误，请用 PowerShell 7，或确保使用仓库内已带 UTF-8 BOM 的 `harness/**/*.ps1`。

---

## 与历史分支的关系

`main` 即 Raindeer-AWI 正式主线（原 `raindeer-AWI` 分支内容已并入）。直接 `git clone` 即可，无需指定 `-b`。
