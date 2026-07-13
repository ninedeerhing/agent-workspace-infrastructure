# Worker Report Inbox V1 Sync Audit

- assignment: `awi-worker-report-inbox-v1`
- status: `success`
- clean_state: `true`
- active_generation: `generation-3`
- rollover_reason: `defect_correction`
- replay_order: `Executor -> Test -> Review -> Verifier -> Sync`
- assignment_count: `5`
- receipt_count: `5`
- next_cursor: `6`
- dispatch_complete: `true`

## Canonical SHA256

| Cursor | Phase | Source thread | SHA256 | Transition |
|---:|---|---|---|---|
| 1 | Executor | `019eeece-c617-71c3-a80a-39a693ad3ac3` | `ed79d819984acb19ee9f2e11624985bcd6208a4e071003ee36e0a4e095aef9e4` | `advance -> Test` |
| 2 | Test | `019eeece-52d7-7b73-868a-7beb496ba303` | `7001afa21c184e5d193fd09a3c8c7e48732043f0a7c20662c128a033acd1c9c9` | `advance -> Review` |
| 3 | Review | `019eeed1-7e14-7342-9d45-d7948aec94d2` | `4f70773abcd98b78e18aa34f09b66924170aea5e6d9239f1060bd41a018e8527` | `advance -> Verifier` |
| 4 | Verifier | `019eeed2-dbc0-7313-8d64-f9c6f199c68b` | `e84e5bb6a6c95c3be3a15dbe27df2b2c5a7fe1e2d3a48a1bba0fe27fe4cc1b00` | `advance -> Sync` |
| 5 | Sync | `019ee9b4-0e6b-7ec0-a2fc-70ae7a5f8482` | `946b02d8e01da0f4bbd4878177b5ec570a56bcb034dce5f571ab0c926422429c` | `complete` |

## Lineage

- Legacy v2 root ledgers are preserved as immutable drift evidence.
- `generation-1` is preserved with `legacy_assignment_hash_drift` lineage and one consumed Executor receipt.
- `generation-2` remains preserved as the first reconciled correction audit generation.
- `generation-3` is the active correction-cycle-1 replay; all five receipts are consumed and agree with `applied_receipts`.
- Test, Review, and Verifier canonical payloads were re-attested by their original permanent worker threads before Sync computed their hashes; no old-generation hash was reused.
- No mirror mismatch, hash mismatch, replay inconsistency, unresolved Test/Review/Verifier finding, secret access, DB/Docker startup, or runtime mutation was observed.

## Recovery Evidence

- Canonical Test Engineer and Code Reviewer turns that were stuck at CodeX approval were recovered without replacement: archive the same thread, unarchive it, then send a narrow no-approval follow-up.
- Thread ids, titles, responsibilities, and history remained unchanged. No duplicate mandatory worker was created.
- One emergency integration was recorded as `platform_recovery_integration`; it is not permission for routine Orchestrator business implementation.
