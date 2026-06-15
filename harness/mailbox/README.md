# Mailbox 协议

Raindeer-AWI 跨 Agent 文件总线。任何平台无原生 `send_message` 时，**必须**使用本协议。

## 路径

```text
harness/mailbox/{role_id}/inbox/MSG-*.json   # 待处理
harness/mailbox/{role_id}/processed/         # 已处理归档
```

## 消息 Schema

```json
{
  "msg_id": "MSG-2026-06-15-120000-abc123",
  "correlation_id": "MSG-2026-06-15-120000-abc123",
  "from": "orchestrator",
  "to": "executor",
  "type": "dispatch_task",
  "tree_id": "TREE-RT",
  "payload": {},
  "compress": "none",
  "created_at": "2026-06-15T12:00:00+08:00",
  "requires_ack": true
}
```

## 消息类型

| type | 方向 | 用途 |
|------|------|------|
| `dispatch_task` | orchestrator → worker | 分派任务 |
| `report_changes` | worker → orchestrator | 回报实现与验证 |
| `fix_request` | orchestrator/planner/verifier → executor | 打回修复 |
| `acceptance_result` | verifier/planner → orchestrator | 验收结论 |
| `blocked` | worker → orchestrator | 阻塞上报（**不得直达用户**） |

## CLI

```powershell
.\harness\scripts\Send-MailboxMessage.ps1 -From orchestrator -To planner -Type dispatch_task -Payload @{ goal = "..." }
.\harness\scripts\Read-MailboxInbox.ps1 -RoleId executor
```

## 处理规则

1. Worker 每回合先读 inbox。
2. 处理完成后移至 `processed/`。
3. Worker 间可选 `compress: lite`（见 `harness/token-budget.json`）。
