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
from harness.worker_report_relay_adapter import CANONICAL_THREAD_IDS, consume_relay_receipt


def _report(phase: CanonicalPhase, role: str, summary: str) -> WorkerReport:
    return WorkerReport(
        assignment_id="rollover-flow",
        phase=phase,
        role=role,
        status=ReportStatus.COMPLETED,
        clean_state=True,
        summary=summary,
    )


def _envelope(
    report: WorkerReport,
    *,
    next_phase: CanonicalPhase,
    replacement: bool = False,
) -> str:
    return json.dumps({
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
        "next_phase": next_phase.value,
        "canonical_next_thread_id": CANONICAL_THREAD_IDS[next_phase],
        "replaces_hash_drift_receipt": replacement,
        **(
            {"replaced_report_hash": canonical_report_hash(WorkerReport(
                assignment_id="rollover-flow:Executor",
                phase=CanonicalPhase.EXECUTOR,
                role="executor",
                status=ReportStatus.COMPLETED,
                clean_state=True,
                summary="legacy rewritten report",
            ))}
            if replacement else {}
        ),
    })


def _write_legacy_hash_drift(container: Path) -> tuple[bytes, bytes]:
    legacy = WorkerReport(
        assignment_id="rollover-flow:Executor",
        phase=CanonicalPhase.EXECUTOR,
        role="executor",
        status=ReportStatus.COMPLETED,
        clean_state=True,
        summary="legacy rewritten report",
    )
    dispatch = {
        "version": 2,
        "workflow_id": "rollover-flow",
        "current_phase": "Test",
        "complete": False,
        "assignments": [
            {
                "assignment_id": "rollover-flow:Executor",
                "phase": "Executor",
                "role": "executor",
                "attempt": 1,
                "state": "completed",
            },
            {
                "assignment_id": "rollover-flow:Test",
                "phase": "Test",
                "role": "test-engineer",
                "attempt": 1,
                "state": "active",
            },
        ],
        "applied_receipts": {
            canonical_report_hash(legacy): {"transition": "advance", "next_phase": "Test"},
        },
    }
    receipts = {
        "version": 2,
        "workflow_id": "rollover-flow",
        "next_cursor": 2,
        "receipts": [{
            "cursor": 1,
            "report_hash": canonical_report_hash(legacy),
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
    }
    dispatch_bytes = json.dumps(dispatch, indent=2).encode()
    receipt_bytes = json.dumps(receipts, indent=2).encode()
    (container / "dispatch-ledger.json").write_bytes(dispatch_bytes)
    (container / "receipt-ledger.json").write_bytes(receipt_bytes)
    return dispatch_bytes, receipt_bytes


def _active_root(container: Path) -> Path:
    pointer = json.loads((container / "active-generation.json").read_text(encoding="utf-8"))
    return container / "generations" / pointer["active_generation_id"]


def test_replacement_rolls_over_confirmed_legacy_hash_drift_without_mutating_old_ledgers(
    tmp_path: Path,
) -> None:
    old_dispatch, old_receipts = _write_legacy_hash_drift(tmp_path)
    replacement = _report(CanonicalPhase.EXECUTOR, "executor", "canonical replacement")

    handoff = consume_relay_receipt(
        _envelope(replacement, next_phase=CanonicalPhase.TEST, replacement=True),
        workflow_id="rollover-flow",
        ledger_root=tmp_path,
    )

    assert handoff is not None and handoff.phase is CanonicalPhase.TEST
    assert (tmp_path / "dispatch-ledger.json").read_bytes() == old_dispatch
    assert (tmp_path / "receipt-ledger.json").read_bytes() == old_receipts
    active_receipts = json.loads(
        (_active_root(tmp_path) / "receipt-ledger.json").read_text(encoding="utf-8"),
    )
    assert active_receipts["receipts"][0]["report_hash"] == canonical_report_hash(replacement)


def test_replaying_same_replacement_reuses_active_generation(tmp_path: Path) -> None:
    _write_legacy_hash_drift(tmp_path)
    replacement = _report(CanonicalPhase.EXECUTOR, "executor", "canonical replacement")
    raw = _envelope(replacement, next_phase=CanonicalPhase.TEST, replacement=True)
    first = consume_relay_receipt(raw, workflow_id="rollover-flow", ledger_root=tmp_path)

    replay = consume_relay_receipt(raw, workflow_id="rollover-flow", ledger_root=tmp_path)

    assert first == replay
    assert len(list((tmp_path / "generations").iterdir())) == 1


def test_following_phase_uses_active_generation_automatically(tmp_path: Path) -> None:
    _write_legacy_hash_drift(tmp_path)
    executor = _report(CanonicalPhase.EXECUTOR, "executor", "canonical replacement")
    consume_relay_receipt(
        _envelope(executor, next_phase=CanonicalPhase.TEST, replacement=True),
        workflow_id="rollover-flow",
        ledger_root=tmp_path,
    )
    test_report = _report(CanonicalPhase.TEST, "test-engineer", "tests passed")

    handoff = consume_relay_receipt(
        _envelope(test_report, next_phase=CanonicalPhase.REVIEW),
        workflow_id="rollover-flow",
        ledger_root=tmp_path,
    )

    assert handoff is not None and handoff.phase is CanonicalPhase.REVIEW
    assert len(list((tmp_path / "generations").iterdir())) == 1


def test_replacement_without_confirmed_hash_drift_fails_closed(tmp_path: Path) -> None:
    replacement = _report(CanonicalPhase.EXECUTOR, "executor", "unproven replacement")

    with pytest.raises(ReceiptIntegrityError, match="relay_hash_drift_not_confirmed"):
        consume_relay_receipt(
            _envelope(replacement, next_phase=CanonicalPhase.TEST, replacement=True),
            workflow_id="rollover-flow",
            ledger_root=tmp_path,
        )


@pytest.mark.parametrize(
    "pointer",
    [
        {"version": 1, "workflow_id": "rollover-flow", "active_generation_id": "../escape"},
        {"version": 1, "workflow_id": "wrong", "active_generation_id": "generation-1"},
        {"version": "1", "workflow_id": "rollover-flow", "active_generation_id": "generation-1"},
    ],
)
def test_active_generation_pointer_corruption_fails_closed(
    tmp_path: Path,
    pointer: dict[str, str | int],
) -> None:
    (tmp_path / "active-generation.json").write_text(json.dumps(pointer), encoding="utf-8")
    report = _report(CanonicalPhase.EXECUTOR, "executor", "canonical report")

    with pytest.raises(ReceiptIntegrityError, match="relay_generation_pointer_invalid"):
        consume_relay_receipt(
            _envelope(report, next_phase=CanonicalPhase.TEST),
            workflow_id="rollover-flow",
            ledger_root=tmp_path,
        )
