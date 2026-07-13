# Report Relay Worker Report

- role_id: `report-relay`
- canonical_thread_id: `019f59d6-f86d-75d3-9266-082079e31d71`
- status: `idle`
- last_task: `awi-worker-report-inbox-v1`
- result: Hot receipts were accepted in canonical phase order and forwarded to Dispatcher; final Sync cold mirror completed with no mismatch.
- boundary: Receipt validation, dedupe, relay, Dispatcher ACK lineage, and cold-mirror audit only.
- next: Await the next canonical Worker receipt; never advance business phases independently.
