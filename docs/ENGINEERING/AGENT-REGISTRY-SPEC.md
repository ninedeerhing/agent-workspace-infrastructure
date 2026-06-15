# Agent Registry 规范

## 来源

`harness/scripts/Build-AgentRegistryFromAgentsDir.ps1` 扫描 `agents/*.md` 生成。

## Schema

```json
{
  "version": "0.1.0",
  "role_count": 18,
  "hub_role": "orchestrator",
  "roles": [
    {
      "role_id": "orchestrator",
      "kind": "hub",
      "user_facing": true,
      "session_name": "orchestrator",
      "model": "opus",
      "source_file": "agents/orchestrator.md"
    },
    {
      "role_id": "planner",
      "kind": "worker",
      "user_facing": false,
      "session_name": "planner",
      "model": "sonnet",
      "source_file": "agents/planner.md"
    }
  ]
}
```

## 字段说明

| 字段 | 说明 |
|------|------|
| `role_id` | 与文件名一致（不含 .md） |
| `kind` | `hub` 或 `worker` |
| `user_facing` | 仅 orchestrator 为 true |
| `session_name` | IDE 中建议的会话名 |
| `model` | 默认模型档位 |
| `source_file` | 角色提示词路径 |

## 同步规则

- 增删 `agents/*.md` 后重新运行 builder。
- registry 与 mailbox/worklog 目录必须一致。
- post-bootstrap 合规检查要求 registry 存在。

## 协作总线

Worker 间通信见 `harness/mailbox/README.md`。
