from __future__ import annotations

import json
from pathlib import Path

import pytest

from harness.worker_report_contracts import (
    CANONICAL_PHASES,
    CanonicalPhase,
    ReportContractError,
    ReportStatus,
    WorkerReport,
)
from harness.worker_report_inbox import WorkerReportInbox


def _report(inbox: WorkerReportInbox, status: ReportStatus, *, clean: bool = True) -> WorkerReport:
    assignment = _current(inbox)
    return WorkerReport(
        assignment_id=assignment.assignment_id,
        phase=assignment.phase,
        role=assignment.role,
        status=status,
        clean_state=clean,
        summary=f"{assignment.phase.value} report",
    )


def _current(inbox: WorkerReportInbox):
    assignment = inbox.dispatch_current()
    assert assignment is not None
    return assignment


def _advance_to(inbox: WorkerReportInbox, target: CanonicalPhase) -> None:
    for phase in CANONICAL_PHASES:
        if phase is target:
            return
        result = inbox.receive(_report(inbox, ReportStatus.COMPLETED))
        assert result.transition == "advance"


@pytest.mark.parametrize("phase", CANONICAL_PHASES[:-1])
def test_completed_clean_report_advances_each_canonical_phase(
    tmp_path: Path,
    phase: CanonicalPhase,
) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id=f"flow-{phase.value}")
    _advance_to(inbox, phase)

    result = inbox.receive(_report(inbox, ReportStatus.COMPLETED))

    expected = CANONICAL_PHASES[CANONICAL_PHASES.index(phase) + 1]
    assert result.transition == "advance"
    assert result.next_phase is expected
    assert _current(inbox).phase is expected


def test_assignment_id_remains_constant_across_canonical_phases(tmp_path: Path) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id="stable-assignment")
    executor_assignment = _current(inbox)

    inbox.receive(_report(inbox, ReportStatus.COMPLETED))

    test_assignment = _current(inbox)
    assert executor_assignment.assignment_id == "stable-assignment"
    assert test_assignment.assignment_id == executor_assignment.assignment_id
    assert test_assignment.phase is CanonicalPhase.TEST


def test_completed_clean_sync_report_completes_workflow(tmp_path: Path) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id="flow-complete")
    _advance_to(inbox, CanonicalPhase.SYNC)

    result = inbox.receive(_report(inbox, ReportStatus.COMPLETED))

    assert result.transition == "complete"
    assert result.next_phase is None
    assert inbox.dispatch_current() is None


@pytest.mark.parametrize(
    ("status", "transition"),
    [
        (ReportStatus.PARTIAL, "retry_partial"),
        (ReportStatus.BLOCKED, "retry_blocked"),
        (ReportStatus.SYSTEM_ERROR, "retry_system_error"),
        (ReportStatus.WAITING_ON_APPROVAL, "retry_waiting_on_approval"),
    ],
)
def test_non_completed_status_retries_same_canonical_assignment(
    tmp_path: Path,
    status: ReportStatus,
    transition: str,
) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id=f"flow-{status.value}")
    original = inbox.dispatch_current()

    result = inbox.receive(_report(inbox, status))

    retried = inbox.dispatch_current()
    assert result.transition == transition
    assert retried is not None and original is not None
    assert retried.assignment_id == original.assignment_id
    assert retried.role == original.role
    assert retried.attempt == 2
    assert inbox.assignment_count == 1


def test_completed_non_clean_report_does_not_advance(tmp_path: Path) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id="flow-dirty")

    result = inbox.receive(_report(inbox, ReportStatus.COMPLETED, clean=False))

    assert result.transition == "retry_non_clean"
    assert _current(inbox).phase is CanonicalPhase.EXECUTOR


@pytest.mark.parametrize(
    "mutation",
    [
        {"status": "unknown"},
        {"role": "code-reviewer"},
        {"phase": "Review"},
        {"clean_state": "yes"},
        {"summary": ""},
    ],
)
def test_report_contract_rejects_invalid_or_mismatched_payload(
    tmp_path: Path,
    mutation: dict[str, str],
) -> None:
    inbox = WorkerReportInbox(tmp_path, workflow_id="flow-contract")
    assignment = inbox.dispatch_current()
    assert assignment is not None
    payload: dict[str, str | bool] = {
        "assignment_id": assignment.assignment_id,
        "phase": assignment.phase.value,
        "role": assignment.role,
        "status": "completed",
        "clean_state": True,
        "summary": "done",
    }
    payload.update(mutation)

    with pytest.raises(ReportContractError):
        inbox.receive_json(json.dumps(payload))

    assert inbox.receipt_count == 0
