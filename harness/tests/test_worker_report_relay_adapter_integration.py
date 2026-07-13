from __future__ import annotations

import json
from pathlib import Path

import pytest

from harness.worker_report_contracts import (
    CanonicalPhase,
    ReceiptIntegrityError,
    ReportStatus,
    WorkerReport,
    canonical_report_hash,
)
from harness.worker_report_relay_adapter import (
    CANONICAL_THREAD_IDS,
    DEFAULT_RELAY_LEDGER_ROOT,
    consume_relay_receipt,
)


def _receipt(
    report: WorkerReport,
    *,
    next_phase: str = "Test",
    canonical_thread_id: str = CANONICAL_THREAD_IDS[CanonicalPhase.TEST],
    replaces_hash_drift_receipt: bool = False,
) -> str:
    return json.dumps({
        "protocol": "WORKER_REPORT_RECEIPT_V1",
        "source_thread_id": "thread-executor",
        "source_message_id": "message-1",
        "assignment_id": report.assignment_id,
        "phase": report.phase.value,
        "role": report.role,
        "status": report.status.value,
        "clean_state": report.clean_state,
        "canonical_report_payload": json.loads(report.canonical_json()),
        "report_hash": canonical_report_hash(report),
        "verification": "19 focused; 37 harness; ruff/compile/diff passed",
        "next_phase": next_phase,
        "canonical_next_thread_id": canonical_thread_id,
        "replaces_hash_drift_receipt": replaces_hash_drift_receipt,
    })


def _executor_report(status: ReportStatus = ReportStatus.COMPLETED) -> WorkerReport:
    return WorkerReport(
        assignment_id="relay-flow",
        phase=CanonicalPhase.EXECUTOR,
        role="executor",
        status=status,
        clean_state=status is ReportStatus.COMPLETED,
        summary="canonical executor result",
    )


def _active_ledger_root(container: Path) -> Path:
    pointer = json.loads((container / "active-generation.json").read_text(encoding="utf-8"))
    return container / "generations" / pointer["active_generation_id"]


def test_relay_adapter_consumes_receipt_and_returns_dispatcher_handoff(tmp_path: Path) -> None:
    report = _executor_report()

    handoff = consume_relay_receipt(
        _receipt(report), workflow_id="relay-flow", ledger_root=tmp_path,
    )

    assert handoff is not None
    assert handoff.phase is CanonicalPhase.TEST
    assert handoff.role == "test-engineer"
    assert handoff.canonical_thread_id == CANONICAL_THREAD_IDS[CanonicalPhase.TEST]
    assert handoff.source_receipt_hash == canonical_report_hash(report)
    ledger = json.loads(
        (_active_ledger_root(tmp_path) / "receipt-ledger.json").read_text(encoding="utf-8"),
    )
    persisted = ledger["receipts"][0]
    assert persisted["assignment_id"] == report.assignment_id
    assert persisted["report_hash"] == canonical_report_hash(report)


def test_relay_adapter_accepts_next_phase_with_same_assignment_id(tmp_path: Path) -> None:
    consume_relay_receipt(
        _receipt(_executor_report()), workflow_id="relay-flow", ledger_root=tmp_path,
    )
    test_report = WorkerReport(
        assignment_id="relay-flow",
        phase=CanonicalPhase.TEST,
        role="test-engineer",
        status=ReportStatus.COMPLETED,
        clean_state=True,
        summary="canonical test result",
    )

    handoff = consume_relay_receipt(
        _receipt(
            test_report,
            next_phase="Review",
            canonical_thread_id=CANONICAL_THREAD_IDS[CanonicalPhase.REVIEW],
        ),
        workflow_id="relay-flow",
        ledger_root=tmp_path,
    )

    assert handoff is not None
    assert handoff.phase is CanonicalPhase.REVIEW
    assert handoff.assignment_id == "relay-flow"
    ledger = json.loads(
        (_active_ledger_root(tmp_path) / "receipt-ledger.json").read_text(encoding="utf-8"),
    )
    assert ledger["receipts"][1]["report_hash"] == canonical_report_hash(test_report)


def test_relay_adapter_does_not_handoff_blocked_report(tmp_path: Path) -> None:
    report = _executor_report(ReportStatus.BLOCKED)

    handoff = consume_relay_receipt(
        _receipt(
            report,
            next_phase="Executor",
            canonical_thread_id=CANONICAL_THREAD_IDS[CanonicalPhase.EXECUTOR],
        ),
        workflow_id="relay-flow",
        ledger_root=tmp_path,
    )

    assert handoff is None


def test_relay_adapter_rejects_noncanonical_report_hash(tmp_path: Path) -> None:
    payload = json.loads(_receipt(_executor_report()))
    payload["report_hash"] = "0" * 64

    with pytest.raises(ReceiptIntegrityError, match="relay_report_hash_mismatch"):
        consume_relay_receipt(json.dumps(payload), workflow_id="relay-flow", ledger_root=tmp_path)


def test_relay_adapter_has_fixed_production_ledger_root() -> None:
    assert DEFAULT_RELAY_LEDGER_ROOT.parts[-3:] == ("mailbox", "worker-report-inbox", "v1")
