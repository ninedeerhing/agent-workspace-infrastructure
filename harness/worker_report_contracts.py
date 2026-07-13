"""Typed contracts for the canonical AWI worker report pipeline."""

from __future__ import annotations

import json
from hashlib import sha256
from dataclasses import dataclass
from enum import StrEnum
from typing import Final, Literal, assert_never


class CanonicalPhase(StrEnum):
    EXECUTOR = "Executor"
    TEST = "Test"
    REVIEW = "Review"
    VERIFIER = "Verifier"
    SYNC = "Sync"


CANONICAL_PHASES: Final = tuple(CanonicalPhase)
PHASE_ROLES: Final = {
    CanonicalPhase.EXECUTOR: "executor",
    CanonicalPhase.TEST: "test-engineer",
    CanonicalPhase.REVIEW: "code-reviewer",
    CanonicalPhase.VERIFIER: "verifier",
    CanonicalPhase.SYNC: "orchestrator",
}


class ReportStatus(StrEnum):
    COMPLETED = "completed"
    PARTIAL = "partial"
    BLOCKED = "blocked"
    SYSTEM_ERROR = "systemError"
    WAITING_ON_APPROVAL = "waitingOnApproval"


type TransitionName = Literal[
    "advance",
    "complete",
    "pending",
    "retry_partial",
    "retry_blocked",
    "retry_system_error",
    "retry_waiting_on_approval",
    "retry_non_clean",
]


@dataclass(slots=True)
class ReportContractError(Exception):
    reason: str

    def __str__(self) -> str:
        return self.reason


@dataclass(slots=True)
class LedgerIntegrityError(Exception):
    reason: str

    def __str__(self) -> str:
        return self.reason


@dataclass(slots=True)
class ReceiptIntegrityError(Exception):
    reason: str

    def __str__(self) -> str:
        return self.reason


@dataclass(frozen=True, slots=True)
class WorkerReport:
    assignment_id: str
    phase: CanonicalPhase
    role: str
    status: ReportStatus
    clean_state: bool
    summary: str

    def canonical_json(self) -> str:
        return json.dumps(
            {
                "assignment_id": self.assignment_id,
                "clean_state": self.clean_state,
                "phase": self.phase.value,
                "role": self.role,
                "status": self.status.value,
                "summary": self.summary,
            },
            ensure_ascii=False,
            separators=(",", ":"),
            sort_keys=True,
        )


def canonical_report_hash(report: WorkerReport) -> str:
    """Hash the canonical six-field worker report payload."""
    return sha256(report.canonical_json().encode()).hexdigest()


@dataclass(frozen=True, slots=True)
class CanonicalAssignment:
    assignment_id: str
    phase: CanonicalPhase
    role: str
    attempt: int


@dataclass(frozen=True, slots=True)
class ReceiptResult:
    receipt_cursor: int
    report_hash: str
    transition: TransitionName
    next_phase: CanonicalPhase | None
    duplicate: bool = False


def retry_transition(report: WorkerReport) -> TransitionName | None:
    """Map every non-advancing status to one deterministic retry outcome."""
    match report.status:
        case ReportStatus.COMPLETED:
            return None if report.clean_state else "retry_non_clean"
        case ReportStatus.PARTIAL:
            return "retry_partial"
        case ReportStatus.BLOCKED:
            return "retry_blocked"
        case ReportStatus.SYSTEM_ERROR:
            return "retry_system_error"
        case ReportStatus.WAITING_ON_APPROVAL:
            return "retry_waiting_on_approval"
        case unreachable:
            assert_never(unreachable)


def parse_worker_report_json(raw: str) -> WorkerReport:
    """Parse an untrusted JSON report into the canonical typed contract."""
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ReportContractError("report_json_invalid") from exc
    match payload:
        case dict():
            pass
        case _:
            raise ReportContractError("report_payload_must_be_object")
    expected = {"assignment_id", "phase", "role", "status", "clean_state", "summary"}
    if set(payload) != expected:
        raise ReportContractError("report_fields_invalid")
    assignment_id = _nonempty_string(payload, "assignment_id")
    role = _nonempty_string(payload, "role")
    summary = _nonempty_string(payload, "summary")
    clean_state = payload["clean_state"]
    if not isinstance(clean_state, bool):
        raise ReportContractError("clean_state_must_be_boolean")
    try:
        phase = CanonicalPhase(_nonempty_string(payload, "phase"))
        status = ReportStatus(_nonempty_string(payload, "status"))
    except ValueError as exc:
        raise ReportContractError("report_enum_invalid") from exc
    return WorkerReport(
        assignment_id=assignment_id,
        phase=phase,
        role=role,
        status=status,
        clean_state=clean_state,
        summary=summary,
    )


def _nonempty_string(payload: dict[str, object], key: str) -> str:
    value = payload[key]
    if not isinstance(value, str) or not value.strip():
        raise ReportContractError(f"{key}_must_be_nonempty_string")
    return value.strip()
