# Loop Tick Brief

generated_at: 2026-06-19T17:00:45Z
mode: autonomous
current_tree: PL-C-MINE
current_slice: TREE-2-index-weight-wiring
last_tick: loop64-governance-park-corpus

## Execute Now

TREE-2 index_weight 接线收尾 — executor loop64（backfill_runner 已接线 · 2 unit tests fail · 勿重复）

## Then

月切片 watermark 续跑 + gap list 刷新 · 后接 BENCH-2 ②（env deferred）

## Blockers

- [env] WSL2-BENCH-1: BENCH-2 顺序（用户权威）：① WSL+stub SOP closed/env deferred · wsl -l -v 仍仅 docker-desktop · ② QuantaAlpha 需用户授权
- [code] INDEX-WEIGHT-UNIT-TESTS: index_weight_backfill 2 unit tests fail — executor loop64 收尾中

## Agent Instruction

Do NOT ask the user to continue. Execute `next_atomic_action`, sync five sources,
update loop-state.json, then immediately start the next item in the same session.

Full protocol: harness/templates/loop-tick-prompt.md
