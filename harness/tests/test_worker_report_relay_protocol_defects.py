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

_THREADS = {
    CanonicalPhase.EXECUTOR: "019eeece-c617-71c3-a80a-39a693ad3ac3",
    CanonicalPhase.TEST: "019eeece-52d7-7b73-868a-7beb496ba303",
    CanonicalPhase.REVIEW: "019eeed1-7e14-7342-9d45-d7948aec94d2",
    CanonicalPhase.VERIFIER: "019eeed2-dbc0-7313-8d64-f9c6f199c68b",
}


def _report(phase: CanonicalPhase) -> WorkerReport:
    roles = {
        CanonicalPhase.EXECUTOR: "executor",
        CanonicalPhase.TEST: "test-engineer",
        CanonicalPhase.REVIEW: "code-reviewer",
        CanonicalPhase.VERIFIER: "verifier",
    }
    return WorkerReport(
        assignment_id="protocol-flow",
        phase=phase,
        role=roles[phase],
        status=ReportStatus.COMPLETED,
        clean_state=True,
        summary=f"{phase.value} clean",
    )


def _payload(report: WorkerReport, next_phase: CanonicalPhase) -> dict[str, object]:
    return {
        "protocol": "WORKER_REPORT_RECEIPT_V1",
        "source_thread_id": _THREADS[report.phase],
        "assignment_id": report.assignment_id,
        "phase": report.phase.value,
        "role": report.role,
        "status": report.status.value,
        "clean_state": report.clean_state,
        "canonical_report_payload": json.loads(report.canonical_json()),
        "report_hash": canonical_report_hash(report),
        "verification": "verified",
        "next_phase": next_phase.value,
        "canonical_next_thread_id": _THREADS[next_phase],
    }


def _consume(container: Path, phase: CanonicalPhase, next_phase: CanonicalPhase) -> None:
    consume_relay_receipt(
        json.dumps(_payload(_report(phase), next_phase)),
        workflow_id="protocol-flow",
        ledger_root=container,
    )


def test_relay_rejects_arbitrary_canonical_next_thread(tmp_path: Path) -> None:
    payload = _payload(_report(CanonicalPhase.EXECUTOR), CanonicalPhase.TEST)
    payload["canonical_next_thread_id"] = "attacker-selected-thread"

    with pytest.raises(ReceiptIntegrityError, match="relay_next_thread_id_invalid"):
        consume_relay_receipt(
            json.dumps(payload), workflow_id="protocol-flow", ledger_root=tmp_path,
        )


def test_relay_rejects_payload_source_that_differs_from_observed_sender(
    tmp_path: Path,
) -> None:
    payload = _payload(_report(CanonicalPhase.EXECUTOR), CanonicalPhase.TEST)

    with pytest.raises(ReceiptIntegrityError, match="relay_source_thread_mismatch"):
        consume_relay_receipt(
            json.dumps(payload),
            workflow_id="protocol-flow",
            ledger_root=tmp_path,
            observed_source_thread_id="different-sender-thread",
        )


@pytest.mark.parametrize("origin", [CanonicalPhase.REVIEW, CanonicalPhase.VERIFIER])
def test_hot_path_correction_restarts_test_review_verifier_without_skip(
    tmp_path: Path,
    origin: CanonicalPhase,
) -> None:
    _consume(tmp_path, CanonicalPhase.EXECUTOR, CanonicalPhase.TEST)
    _consume(tmp_path, CanonicalPhase.TEST, CanonicalPhase.REVIEW)
    if origin is CanonicalPhase.VERIFIER:
        _consume(tmp_path, CanonicalPhase.REVIEW, CanonicalPhase.VERIFIER)
    correction = _payload(_report(CanonicalPhase.EXECUTOR), CanonicalPhase.TEST)
    correction.update({
        "protocol": "HOT_PATH_WORKER_REPORT_V1",
        "dispatch_protocol": "dispatcher_defect_correction_cycle_v1",
        "correction_cycle": 1,
        "origin_phase": origin.value,
        "retry_same_worker": False,
        "no_duplicate_worker": True,
    })

    test_handoff = consume_relay_receipt(
        json.dumps(correction), workflow_id="protocol-flow", ledger_root=tmp_path,
    )
    review_handoff = consume_relay_receipt(
        json.dumps(_payload(_report(CanonicalPhase.TEST), CanonicalPhase.REVIEW)),
        workflow_id="protocol-flow",
        ledger_root=tmp_path,
    )
    verifier_handoff = consume_relay_receipt(
        json.dumps(_payload(_report(CanonicalPhase.REVIEW), CanonicalPhase.VERIFIER)),
        workflow_id="protocol-flow",
        ledger_root=tmp_path,
    )

    assert test_handoff is not None and test_handoff.phase is CanonicalPhase.TEST
    assert review_handoff is not None and review_handoff.phase is CanonicalPhase.REVIEW
    assert verifier_handoff is not None and verifier_handoff.phase is CanonicalPhase.VERIFIER
    assert len(list((tmp_path / "generations").iterdir())) == 2


def test_hot_path_rejects_invalid_correction_worker_identity(tmp_path: Path) -> None:
    _consume(tmp_path, CanonicalPhase.EXECUTOR, CanonicalPhase.TEST)
    payload = _payload(_report(CanonicalPhase.EXECUTOR), CanonicalPhase.TEST)
    payload.update({
        "protocol": "HOT_PATH_WORKER_REPORT_V1",
        "dispatch_protocol": "dispatcher_defect_correction_cycle_v1",
        "correction_cycle": 1,
        "origin_phase": "Test",
        "retry_same_worker": True,
        "no_duplicate_worker": True,
    })

    with pytest.raises(ReceiptIntegrityError, match="relay_correction_protocol_invalid"):
        consume_relay_receipt(
            json.dumps(payload), workflow_id="protocol-flow", ledger_root=tmp_path,
        )
