from __future__ import annotations

import json
from pathlib import Path

import pytest

from harness.worker_report_contracts import LedgerIntegrityError, ReportStatus, WorkerReport
from harness.worker_report_inbox import WorkerReportInbox


def _complete_current(inbox: WorkerReportInbox) -> None:
    assignment = inbox.dispatch_current()
    assert assignment is not None
    inbox.receive(WorkerReport(
        assignment_id=assignment.assignment_id,
        phase=assignment.phase,
        role=assignment.role,
        status=ReportStatus.COMPLETED,
        clean_state=True,
        summary=f"{assignment.phase.value} completed",
    ))


@pytest.mark.parametrize(
    ("mutation", "reason"),
    [
        ("duplicate_cursor", "receipt_ledger_cursor_sequence_invalid"),
        ("duplicate_hash", "receipt_ledger_hash_duplicate"),
        ("next_cursor", "receipt_ledger_next_cursor_invalid"),
    ],
)
def test_receipt_ledger_rejects_cursor_or_hash_invariant_drift(
    tmp_path: Path,
    mutation: str,
    reason: str,
) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id="ledger-invariants")
    _complete_current(inbox)
    _complete_current(inbox)
    path = tmp_path / "receipt-ledger.json"
    payload = json.loads(path.read_text(encoding="utf-8"))
    if mutation == "duplicate_cursor":
        payload["receipts"][1]["cursor"] = payload["receipts"][0]["cursor"]
    elif mutation == "duplicate_hash":
        payload["receipts"][1]["report_hash"] = payload["receipts"][0]["report_hash"]
    else:
        payload["next_cursor"] += 1
    path.write_text(json.dumps(payload), encoding="utf-8")

    with pytest.raises(LedgerIntegrityError, match=reason):
        WorkerReportInbox(tmp_path, workflow_id="ledger-invariants")


@pytest.mark.parametrize(
    ("mutation", "reason"),
    [
        ("unknown_transition", "dispatch_applied_transition_invalid"),
        ("missing_next_phase", "dispatch_applied_transition_invalid"),
        ("orphan_hash", "dispatch_applied_receipt_missing"),
        ("receipt_mismatch", "dispatch_applied_transition_mismatch"),
    ],
)
def test_dispatch_ledger_rejects_applied_transition_drift(
    tmp_path: Path,
    mutation: str,
    reason: str,
) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id="applied-invariants")
    _complete_current(inbox)
    dispatch_path = tmp_path / "dispatch-ledger.json"
    dispatch = json.loads(dispatch_path.read_text(encoding="utf-8"))
    report_hash = next(iter(dispatch["applied_receipts"]))
    if mutation == "unknown_transition":
        dispatch["applied_receipts"][report_hash]["transition"] = "unknown"
    elif mutation == "missing_next_phase":
        dispatch["applied_receipts"][report_hash]["next_phase"] = None
    elif mutation == "orphan_hash":
        dispatch["applied_receipts"]["f" * 64] = dispatch["applied_receipts"].pop(report_hash)
    else:
        dispatch["applied_receipts"][report_hash]["next_phase"] = "Review"
    dispatch_path.write_text(json.dumps(dispatch), encoding="utf-8")

    with pytest.raises(LedgerIntegrityError, match=reason):
        WorkerReportInbox(tmp_path, workflow_id="applied-invariants")
