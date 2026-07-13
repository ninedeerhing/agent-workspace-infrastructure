from __future__ import annotations

import json
from pathlib import Path

import pytest

from harness.worker_report_contracts import (
    CanonicalPhase,
    LedgerIntegrityError,
    ReceiptIntegrityError,
    ReportStatus,
    WorkerReport,
    canonical_report_hash,
)
from harness.worker_report_inbox import WorkerReportInbox


def _completed_report(inbox: WorkerReportInbox) -> WorkerReport:
    assignment = _current(inbox)
    return WorkerReport(
        assignment_id=assignment.assignment_id,
        phase=assignment.phase,
        role=assignment.role,
        status=ReportStatus.COMPLETED,
        clean_state=True,
        summary="verified completion",
    )


def _current(inbox: WorkerReportInbox):
    assignment = inbox.dispatch_current()
    assert assignment is not None
    return assignment


def test_dispatch_and_receipt_ledgers_persist_hash_cursor_and_consumption(tmp_path: Path) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id="flow-ledgers")

    result = inbox.receive(_completed_report(inbox))

    dispatch = json.loads((tmp_path / "dispatch-ledger.json").read_text(encoding="utf-8"))
    receipts = json.loads((tmp_path / "receipt-ledger.json").read_text(encoding="utf-8"))
    assert dispatch["workflow_id"] == "flow-ledgers"
    assert dispatch["current_phase"] == "Test"
    assert [item["role"] for item in dispatch["assignments"]] == ["executor", "test-engineer"]
    assert receipts["next_cursor"] == 2
    assert receipts["receipts"][0]["cursor"] == 1
    assert len(receipts["receipts"][0]["report_hash"]) == 64
    assert receipts["receipts"][0]["consumed"] is True
    assert result.receipt_cursor == 1


def test_duplicate_receipt_is_idempotent_after_phase_advance(tmp_path: Path) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id="flow-duplicate")
    report = _completed_report(inbox)
    first = inbox.receive(report)

    duplicate = inbox.receive(report)

    assert duplicate.duplicate is True
    assert duplicate.receipt_cursor == first.receipt_cursor
    assert inbox.receipt_count == 1
    assert _current(inbox).phase is CanonicalPhase.TEST
    assert inbox.assignment_count == 2


def test_pending_duplicate_is_consumed_when_redelivered_with_consume(tmp_path: Path) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id="flow-pending-duplicate")
    report = _completed_report(inbox)
    inbox.receive(report, consume=False)

    duplicate = inbox.receive(report, consume=True)

    assert duplicate.duplicate is True
    assert duplicate.transition == "advance"
    assert _current(inbox).phase is CanonicalPhase.TEST
    assert inbox.receipt_count == 1


def test_restart_recovers_unconsumed_receipt_once(tmp_path: Path) -> None:
    first_process = WorkerReportInbox(tmp_path, workflow_id="flow-recovery")
    pending = first_process.receive(_completed_report(first_process), consume=False)
    assert pending.transition == "pending"
    assert _current(first_process).phase is CanonicalPhase.EXECUTOR

    restarted = WorkerReportInbox(tmp_path, workflow_id="flow-recovery")
    recovered = restarted.recover()

    assert len(recovered) == 1
    assert recovered[0].transition == "advance"
    assert _current(restarted).phase is CanonicalPhase.TEST
    assert restarted.recover() == ()


def test_retry_survives_restart_without_duplicate_role_assignment(tmp_path: Path) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id="flow-retry")
    assignment = inbox.dispatch_current()
    assert assignment is not None
    report = WorkerReport(
        assignment_id=assignment.assignment_id,
        phase=assignment.phase,
        role=assignment.role,
        status=ReportStatus.BLOCKED,
        clean_state=False,
        summary="channel unavailable",
    )
    inbox.receive(report)

    restarted = WorkerReportInbox(tmp_path, workflow_id="flow-retry")
    retried = restarted.dispatch_current()

    assert retried is not None
    assert retried.assignment_id == assignment.assignment_id
    assert retried.attempt == 2
    assert restarted.assignment_count == 1


def test_recovery_quarantines_receipt_with_non_boolean_clean_state(tmp_path: Path) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id="flow-corrupt-receipt")
    inbox.receive(_completed_report(inbox), consume=False)
    path = tmp_path / "receipt-ledger.json"
    payload = json.loads(path.read_text(encoding="utf-8"))
    payload["receipts"][0]["clean_state"] = "false"
    path.write_text(json.dumps(payload), encoding="utf-8")

    restarted = WorkerReportInbox(tmp_path, workflow_id="flow-corrupt-receipt")
    with pytest.raises(ReceiptIntegrityError, match="receipt_clean_state_invalid"):
        restarted.recover()

    assert _current(restarted).phase is CanonicalPhase.EXECUTOR
    assert (tmp_path / "receipt-quarantine.jsonl").is_file()


@pytest.mark.parametrize(
    ("mutation", "reason"),
    [
        ("missing_summary", "receipt_schema_invalid"),
        ("wrong_hash", "receipt_report_hash_mismatch"),
    ],
)
def test_recovery_quarantines_receipt_schema_or_hash_drift(
    tmp_path: Path,
    mutation: str,
    reason: str,
) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id=f"flow-{mutation}")
    inbox.receive(_completed_report(inbox), consume=False)
    path = tmp_path / "receipt-ledger.json"
    payload = json.loads(path.read_text(encoding="utf-8"))
    receipt = payload["receipts"][0]
    if mutation == "missing_summary":
        del receipt["summary"]
    else:
        receipt["report_hash"] = "0" * 64
    path.write_text(json.dumps(payload), encoding="utf-8")

    restarted = WorkerReportInbox(tmp_path, workflow_id=f"flow-{mutation}")
    with pytest.raises(ReceiptIntegrityError, match=reason):
        restarted.recover()

    assert _current(restarted).phase is CanonicalPhase.EXECUTOR


def test_recovery_quarantines_legacy_phase_suffixed_assignment_hash(tmp_path: Path) -> None:
    workflow_id = "flow-legacy-hash"
    inbox = WorkerReportInbox(tmp_path, workflow_id=workflow_id)
    report = _completed_report(inbox)
    inbox.receive(report, consume=False)
    path = tmp_path / "receipt-ledger.json"
    payload = json.loads(path.read_text(encoding="utf-8"))
    receipt = payload["receipts"][0]
    legacy_report = WorkerReport(
        assignment_id=f"{workflow_id}:Executor",
        phase=CanonicalPhase.EXECUTOR,
        role="executor",
        status=ReportStatus.COMPLETED,
        clean_state=True,
        summary=report.summary,
    )
    receipt["assignment_id"] = legacy_report.assignment_id
    receipt["report_hash"] = canonical_report_hash(legacy_report)
    path.write_text(json.dumps(payload), encoding="utf-8")

    restarted = WorkerReportInbox(tmp_path, workflow_id=workflow_id)
    with pytest.raises(ReceiptIntegrityError, match="receipt_legacy_assignment_hash_drift"):
        restarted.recover()

    assert _current(restarted).phase is CanonicalPhase.EXECUTOR
    assert (tmp_path / "receipt-quarantine.jsonl").is_file()


def test_recovery_finishes_receipt_after_dispatch_was_durably_applied(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id="flow-crash-window")
    original_save = inbox._store.save_receipts
    calls = 0

    def fail_second_receipt_save(payload: dict[str, object]) -> None:
        nonlocal calls
        calls += 1
        if calls == 2:
            raise OSError("simulated process exit after dispatch fsync")
        original_save(payload)

    monkeypatch.setattr(inbox._store, "save_receipts", fail_second_receipt_save)
    with pytest.raises(OSError, match="simulated process exit"):
        inbox.receive(_completed_report(inbox))

    restarted = WorkerReportInbox(tmp_path, workflow_id="flow-crash-window")
    recovered = restarted.recover()
    assert len(recovered) == 1
    assert recovered[0].transition == "advance"
    assert _current(restarted).phase is CanonicalPhase.TEST
    receipt_payload = json.loads(
        (tmp_path / "receipt-ledger.json").read_text(encoding="utf-8"),
    )
    assert receipt_payload["receipts"][0]["consumed"] is True


def test_stale_writers_reload_ledgers_before_each_serialized_write(tmp_path: Path) -> None:
    first = WorkerReportInbox(tmp_path, workflow_id="flow-writers")
    second = WorkerReportInbox(tmp_path, workflow_id="flow-writers")
    first_assignment = _current(first)
    second_assignment = _current(second)
    first.receive(WorkerReport(
        assignment_id=first_assignment.assignment_id,
        phase=first_assignment.phase,
        role=first_assignment.role,
        status=ReportStatus.PARTIAL,
        clean_state=False,
        summary="first partial",
    ))

    second.receive(WorkerReport(
        assignment_id=second_assignment.assignment_id,
        phase=second_assignment.phase,
        role=second_assignment.role,
        status=ReportStatus.PARTIAL,
        clean_state=False,
        summary="second partial",
    ))

    restarted = WorkerReportInbox(tmp_path, workflow_id="flow-writers")
    assert restarted.receipt_count == 2
    assert _current(restarted).attempt == 3


def test_corrupted_dispatch_ledger_rejects_duplicate_assignment_phase(tmp_path: Path) -> None:
    WorkerReportInbox(tmp_path, workflow_id="flow-corrupt-dispatch")
    path = tmp_path / "dispatch-ledger.json"
    payload = json.loads(path.read_text(encoding="utf-8"))
    payload["assignments"].append(dict(payload["assignments"][0]))
    path.write_text(json.dumps(payload), encoding="utf-8")

    with pytest.raises(LedgerIntegrityError, match="dispatch_assignment_phase_duplicate"):
        WorkerReportInbox(tmp_path, workflow_id="flow-corrupt-dispatch")


def test_corrupted_dispatch_ledger_rejects_reused_internal_assignment_key(
    tmp_path: Path,
) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id="flow-corrupt-key")
    inbox.receive(_completed_report(inbox))
    path = tmp_path / "dispatch-ledger.json"
    payload = json.loads(path.read_text(encoding="utf-8"))
    payload["assignments"][1]["internal_assignment_key"] = (
        payload["assignments"][0]["internal_assignment_key"]
    )
    path.write_text(json.dumps(payload), encoding="utf-8")

    with pytest.raises(LedgerIntegrityError, match="dispatch_assignment_key_invalid"):
        WorkerReportInbox(tmp_path, workflow_id="flow-corrupt-key")


def test_receipt_persists_optional_source_metadata(tmp_path: Path) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id="flow-source-metadata")

    inbox.receive(
        _completed_report(inbox),
        source_thread_id="thread-executor",
        source_message_id="message-42",
    )

    payload = json.loads((tmp_path / "receipt-ledger.json").read_text(encoding="utf-8"))
    receipt = payload["receipts"][0]
    assert receipt["source_thread_id"] == "thread-executor"
    assert receipt["source_message_id"] == "message-42"
