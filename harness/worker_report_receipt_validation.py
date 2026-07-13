"""Fail-closed validation for persisted worker report receipts."""

from __future__ import annotations

from harness.worker_report_contracts import (
    PHASE_ROLES,
    CanonicalPhase,
    ReceiptIntegrityError,
    ReportStatus,
    WorkerReport,
    canonical_report_hash,
)

RECEIPT_TRANSITIONS = {
    "advance", "complete", "pending", "retry_partial", "retry_blocked",
    "retry_system_error", "retry_waiting_on_approval", "retry_non_clean",
}


def parse_persisted_receipt(
    receipt: dict[str, object],
    *,
    workflow_id: str,
) -> WorkerReport:
    """Validate receipt schema, types, provenance, and canonical hash."""
    required = {
        "cursor", "report_hash", "assignment_id", "phase", "role", "status",
        "clean_state", "summary", "consumed", "transition", "next_phase",
    }
    optional = {"source_thread_id", "source_message_id", "quarantined", "quarantine_reason"}
    if not required.issubset(receipt) or not set(receipt).issubset(required | optional):
        raise ReceiptIntegrityError("receipt_schema_invalid")
    if not isinstance(receipt["clean_state"], bool):
        raise ReceiptIntegrityError("receipt_clean_state_invalid")
    cursor = receipt["cursor"]
    if isinstance(cursor, bool) or not isinstance(cursor, int) or cursor < 1:
        raise ReceiptIntegrityError("receipt_cursor_invalid")
    for key in ("assignment_id", "phase", "role", "status", "summary", "report_hash"):
        if not isinstance(receipt[key], str) or not receipt[key]:
            raise ReceiptIntegrityError(f"receipt_{key}_invalid")
    if not isinstance(receipt["consumed"], bool):
        raise ReceiptIntegrityError("receipt_consumed_invalid")
    if receipt["transition"] not in RECEIPT_TRANSITIONS:
        raise ReceiptIntegrityError("receipt_transition_invalid")
    _optional_metadata(receipt.get("source_thread_id"), "source_thread_id")
    _optional_metadata(receipt.get("source_message_id"), "source_message_id")
    try:
        phase = CanonicalPhase(receipt["phase"])
        status = ReportStatus(receipt["status"])
    except ValueError as exc:
        raise ReceiptIntegrityError("receipt_enum_invalid") from exc
    if receipt["role"] != PHASE_ROLES[phase]:
        raise ReceiptIntegrityError("receipt_role_invalid")
    if receipt["assignment_id"] == f"{workflow_id}:{phase.value}":
        raise ReceiptIntegrityError("receipt_legacy_assignment_hash_drift")
    if receipt["assignment_id"] != workflow_id:
        raise ReceiptIntegrityError("receipt_assignment_id_invalid")
    report = WorkerReport(
        assignment_id=receipt["assignment_id"], phase=phase, role=receipt["role"],
        status=status, clean_state=receipt["clean_state"], summary=receipt["summary"],
    )
    if canonical_report_hash(report) != receipt["report_hash"]:
        raise ReceiptIntegrityError("receipt_report_hash_mismatch")
    return report


def _optional_metadata(value: object, name: str) -> None:
    if value is not None and (not isinstance(value, str) or not value.strip()):
        raise ReceiptIntegrityError(f"receipt_{name}_invalid")
