# Worker Report Inbox V1 Sync Audit

- assignment: `awi-worker-report-inbox-v1`
- status: `success`
- clean_state: `true`
- active_generation: `generation-2`
- rollover_reason: `defect_correction`
- replay_order: `Executor -> Test -> Review -> Verifier -> Sync`
- assignment_count: `5`
- receipt_count: `5`
- next_cursor: `6`
- dispatch_complete: `true`

## Canonical SHA256

| Cursor | Phase | Source thread | SHA256 | Transition |
|---:|---|---|---|---|
| 1 | Executor | `019eeece-c617-71c3-a80a-39a693ad3ac3` | `98ffc25ae2980fbb46a18667f74134b997f0b4596113fee7c34d401b845f3d18` | `advance -> Test` |
| 2 | Test | `019eeece-52d7-7b73-868a-7beb496ba303` | `37739947b0079e76853bf1eabbef564dd8bd28d0801e8ac34d6c0eb553eb6688` | `advance -> Review` |
| 3 | Review | `019eeed1-7e14-7342-9d45-d7948aec94d2` | `aab810a8a9ef9a2297b55283d98bb05833fdc9435c2a7c0ab7df9a01abb96ff4` | `advance -> Verifier` |
| 4 | Verifier | `019eeed2-dbc0-7313-8d64-f9c6f199c68b` | `3daf761cd0d9a32a49faa7baa454c808dc2afdddd868b7b160d546fe52b65d21` | `advance -> Sync` |
| 5 | Sync | `019ee9b4-0e6b-7ec0-a2fc-70ae7a5f8482` | `80a603b209bd13820b37d62cae8f4ba1f9bc74cd8c1f6cfbfb8e97527b786278` | `complete` |

## Lineage

- Legacy v2 root ledgers are preserved as immutable drift evidence.
- `generation-1` is preserved with `legacy_assignment_hash_drift` lineage and one consumed Executor receipt.
- `generation-2` is the reconciled correction generation; all five receipts are consumed and agree with `applied_receipts`.
- No mirror mismatch, hash mismatch, replay inconsistency, unresolved Test/Review/Verifier finding, secret access, DB/Docker startup, or runtime mutation was observed.

## Recovery Evidence

- Canonical Test Engineer and Code Reviewer turns that were stuck at CodeX approval were recovered without replacement: archive the same thread, unarchive it, then send a narrow no-approval follow-up.
- Thread ids, titles, responsibilities, and history remained unchanged. No duplicate mandatory worker was created.
- One emergency integration was recorded as `platform_recovery_integration`; it is not permission for routine Orchestrator business implementation.
