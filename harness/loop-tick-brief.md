# Loop Tick Brief

generated_at: 2026-06-19T17:08:37Z
mode: autonomous
current_tree: TREE-2
current_slice: index-weight-continuous
last_tick: loop65-tree2-watermark-snapshot

## Execute Now

backfill_runner 补 index_master 前置 stage + index_weight continuous 续跑（94 月 remaining）

## Then

BENCH-2 ② QuantaAlpha 完整安装 step2（env deferred · 需用户授权 Ubuntu）

## Blockers

- [env] WSL2-BENCH-1: BENCH-2 顺序（用户权威）：① WSL+stub SOP closed/env deferred · wsl -l -v 仍仅 docker-desktop · ② QuantaAlpha 需用户授权
- [blocker] INDEX-MASTER-PREREQ: backfill_runner 缺 index_master stage — 空库首跑 index_weight FK fail · loop65 运维 seed 后 2 月 ingested

## Agent Instruction

Do NOT ask the user to continue. Execute `next_atomic_action`, sync five sources,
update loop-state.json, then immediately start the next item in the same session.

Full protocol: harness/templates/loop-tick-prompt.md
