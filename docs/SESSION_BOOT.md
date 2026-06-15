# SESSION_BOOT

Raindeer-AWI 的最小启动契约。任何会话开始工作前，先读本文件，再执行首个原子动作。

## 1. 会话角色

- `orchestrator`：唯一对用户说话的会话。
- `agents/` 下其余角色：全部是 worker，只能对 `orchestrator` 或 mailbox 响应。
- worker 若遇到阻塞，只能发 `blocked` 给 `orchestrator`，不得直接向用户提问。

## 2. 最小预加载

按顺序确认以下内容：

1. `AGENTS-lite.md`
2. `docs/PROJECT_STATUS.md` 第 5、6 节
3. `docs/TASK_TREES.md` 当前主线
4. `harness/workflow-state.json`
5. 本文件

## 3. 开工前必须确认

- 当前唯一前台主线是哪一个 `TREE`
- 本回合属于哪个 workflow / phase
- 这一步是否需要写入 §5 台账
- 这一步是否会触发 gate / 验证命令

## 4. 硬约束

- 不允许跳过 `TASK_TREES` 单主线规则
- 不允许有变更但不写 `docs/PROJECT_STATUS.md` §5
- 不允许无验证声称完成
- 不允许 worker 直接对用户输出
- 不允许把协议文件当作“可选参考”

## 5. Token 与连续性

- 上下文接近阈值时，优先触发压缩与 handoff
- 不要等用户提醒“压缩一下”或“继续上次”

## 6. 首个原子动作

- `orchestrator`：读取当前主线与台账，决定要投递的 worker 子集
- worker：先查自己的 inbox / worklog，再开始执行

