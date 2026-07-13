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
from harness.worker_report_relay_adapter import consume_relay_receipt


def _legacy_report() -> WorkerReport:
    return WorkerReport(
        assignment_id="evidence-flow:Executor",
        phase=CanonicalPhase.EXECUTOR,
        role="executor",
        status=ReportStatus.COMPLETED,
        clean_state=True,
        summary="legacy rewritten report",
    )


def _write_legacy(container: Path) -> None:
    legacy = _legacy_report()
    legacy_hash = canonical_report_hash(legacy)
    (container / "dispatch-ledger.json").write_text(json.dumps({
        "version": 2,
        "workflow_id": "evidence-flow",
        "current_phase": "Test",
        "complete": False,
        "assignments": [
            {
                "assignment_id": "evidence-flow:Executor",
                "phase": "Executor",
                "role": "executor",
                "attempt": 1,
                "state": "completed",
            },
            {
                "assignment_id": "evidence-flow:Test",
                "phase": "Test",
                "role": "test-engineer",
                "attempt": 1,
                "state": "active",
            },
        ],
        "applied_receipts": {legacy_hash: {"transition": "advance", "next_phase": "Test"}},
    }), encoding="utf-8")
    (container / "receipt-ledger.json").write_text(json.dumps({
        "version": 2,
        "workflow_id": "evidence-flow",
        "next_cursor": 2,
        "receipts": [{
            "cursor": 1,
            "report_hash": legacy_hash,
            "assignment_id": legacy.assignment_id,
            "phase": legacy.phase.value,
            "role": legacy.role,
            "status": legacy.status.value,
            "clean_state": legacy.clean_state,
            "summary": legacy.summary,
            "consumed": True,
            "transition": "advance",
            "next_phase": "Test",
            "source_thread_id": "thread-executor",
        }],
    }), encoding="utf-8")


def _replacement_payload(evidence: str | None) -> str:
    report = WorkerReport(
        assignment_id="evidence-flow",
        phase=CanonicalPhase.EXECUTOR,
        role="executor",
        status=ReportStatus.COMPLETED,
        clean_state=True,
        summary="canonical replacement",
    )
    payload = {
        "protocol": "WORKER_REPORT_RECEIPT_V1",
        "source_thread_id": "thread-executor",
        "assignment_id": report.assignment_id,
        "phase": report.phase.value,
        "role": report.role,
        "status": report.status.value,
        "clean_state": report.clean_state,
        "canonical_report_payload": json.loads(report.canonical_json()),
        "report_hash": canonical_report_hash(report),
        "verification": "verified",
        "next_phase": "Test",
        "canonical_next_thread_id": "019eeece-52d7-7b73-868a-7beb496ba303",
        "replaces_hash_drift_receipt": True,
    }
    if evidence is not None:
        payload["replaced_report_hash"] = evidence
    return json.dumps(payload)


@pytest.mark.parametrize("evidence", [None, "f" * 64])
def test_replacement_requires_exact_legacy_report_hash_evidence(
    tmp_path: Path,
    evidence: str | None,
) -> None:
    _write_legacy(tmp_path)

    with pytest.raises(ReceiptIntegrityError, match="relay_replacement_evidence_invalid"):
        consume_relay_receipt(
            _replacement_payload(evidence),
            workflow_id="evidence-flow",
            ledger_root=tmp_path,
        )


def test_replacement_accepts_matching_legacy_report_hash_evidence(tmp_path: Path) -> None:
    _write_legacy(tmp_path)

    handoff = consume_relay_receipt(
        _replacement_payload(canonical_report_hash(_legacy_report())),
        workflow_id="evidence-flow",
        ledger_root=tmp_path,
    )

    assert handoff is not None and handoff.phase is CanonicalPhase.TEST


@pytest.mark.parametrize(
    ("field", "value"),
    [
        ("consumed", False),
        ("transition", "pending"),
        ("next_phase", None),
    ],
)
def test_replacement_rejects_incomplete_legacy_consumption_evidence(
    tmp_path: Path,
    field: str,
    value: object,
) -> None:
    _write_legacy(tmp_path)
    path = tmp_path / "receipt-ledger.json"
    payload = json.loads(path.read_text(encoding="utf-8"))
    payload["receipts"][0][field] = value
    path.write_text(json.dumps(payload), encoding="utf-8")

    with pytest.raises(ReceiptIntegrityError, match="relay_replacement_evidence_invalid"):
        consume_relay_receipt(
            _replacement_payload(canonical_report_hash(_legacy_report())),
            workflow_id="evidence-flow",
            ledger_root=tmp_path,
        )
