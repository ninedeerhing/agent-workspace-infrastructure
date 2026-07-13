"""Relay-to-Dispatcher adapter for canonical worker report receipts."""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from harness.worker_report_contracts import (
    CanonicalPhase,
    ReceiptIntegrityError,
    ReportContractError,
    WorkerReport,
    canonical_report_hash,
    parse_worker_report_json,
)
from harness.worker_report_inbox import WorkerReportInbox
from harness.worker_report_relay_generations import RelayLedgerGenerations

PROTOCOL = "WORKER_REPORT_RECEIPT_V1"
HOT_PATH_PROTOCOL = "HOT_PATH_WORKER_REPORT_V1"
CORRECTION_PROTOCOL = "dispatcher_defect_correction_cycle_v1"
DEFAULT_RELAY_LEDGER_ROOT = Path(__file__).resolve().parent / "mailbox" / "worker-report-inbox" / "v1"
CANONICAL_THREAD_IDS = {
    CanonicalPhase.EXECUTOR: "019eeece-c617-71c3-a80a-39a693ad3ac3",
    CanonicalPhase.TEST: "019eeece-52d7-7b73-868a-7beb496ba303",
    CanonicalPhase.REVIEW: "019eeed1-7e14-7342-9d45-d7948aec94d2",
    CanonicalPhase.VERIFIER: "019eeed2-dbc0-7313-8d64-f9c6f199c68b",
}


@dataclass(frozen=True, slots=True)
class DispatcherHandoff:
    assignment_id: str
    phase: CanonicalPhase
    role: str
    canonical_thread_id: str
    source_receipt_hash: str


@dataclass(frozen=True, slots=True)
class RelayReceipt:
    protocol: str
    report: WorkerReport
    report_hash: str
    source_thread_id: str
    source_message_id: str | None
    verification: str
    next_phase: CanonicalPhase
    canonical_next_thread_id: str
    replaces_hash_drift_receipt: bool
    replaced_report_hash: str | None
    correction_cycle: int | None
    origin_phase: CanonicalPhase | None


def consume_relay_receipt(
    raw: str,
    *,
    workflow_id: str,
    ledger_root: Path = DEFAULT_RELAY_LEDGER_ROOT,
) -> DispatcherHandoff | None:
    """Persist one relay receipt and return only a clean downstream dispatch."""
    receipt = parse_relay_receipt(raw)
    if receipt.report.assignment_id != workflow_id:
        raise ReceiptIntegrityError("relay_assignment_id_mismatch")
    generations = RelayLedgerGenerations(ledger_root, workflow_id=workflow_id)
    if receipt.correction_cycle is not None:
        active_root = generations.start_correction(report_hash=receipt.report_hash)
    else:
        active_root = generations.select(
            receipt.report,
            report_hash=receipt.report_hash,
            source_thread_id=receipt.source_thread_id,
            replaces_hash_drift_receipt=receipt.replaces_hash_drift_receipt,
            replaced_report_hash=receipt.replaced_report_hash,
        )
    inbox = WorkerReportInbox(active_root, workflow_id=workflow_id)
    try:
        result = inbox.receive(
            receipt.report,
            source_thread_id=receipt.source_thread_id,
            source_message_id=receipt.source_message_id,
        )
    except ReportContractError as exc:
        raise ReceiptIntegrityError("relay_current_assignment_mismatch") from exc
    if result.next_phase is not receipt.next_phase:
        raise ReceiptIntegrityError("relay_next_phase_mismatch")
    if result.transition != "advance":
        return None
    assignment = inbox.dispatch_current()
    if assignment is None or assignment.phase is not receipt.next_phase:
        raise ReceiptIntegrityError("relay_dispatch_assignment_missing")
    return DispatcherHandoff(
        assignment_id=assignment.assignment_id,
        phase=assignment.phase,
        role=assignment.role,
        canonical_thread_id=receipt.canonical_next_thread_id,
        source_receipt_hash=receipt.report_hash,
    )


def parse_relay_receipt(raw: str) -> RelayReceipt:
    """Parse and cross-check a relay envelope against its canonical report."""
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ReceiptIntegrityError("relay_json_invalid") from exc
    if not isinstance(payload, dict):
        raise ReceiptIntegrityError("relay_payload_invalid")
    required = {
        "protocol", "source_thread_id", "assignment_id", "phase", "role", "status",
        "clean_state", "canonical_report_payload", "report_hash", "verification",
        "next_phase", "canonical_next_thread_id",
    }
    optional = {
        "source_message_id", "replaces_hash_drift_receipt", "replaced_report_hash",
        "dispatch_protocol", "correction_cycle", "origin_phase", "retry_same_worker",
        "no_duplicate_worker",
    }
    if not required.issubset(payload) or not set(payload).issubset(required | optional):
        raise ReceiptIntegrityError("relay_fields_invalid")
    protocol = payload["protocol"]
    if protocol not in {PROTOCOL, HOT_PATH_PROTOCOL}:
        raise ReceiptIntegrityError("relay_protocol_invalid")
    canonical_payload = payload["canonical_report_payload"]
    if not isinstance(canonical_payload, dict):
        raise ReceiptIntegrityError("relay_canonical_payload_invalid")
    report = parse_worker_report_json(json.dumps(canonical_payload, ensure_ascii=False))
    expected_top_level = {
        "assignment_id": report.assignment_id,
        "phase": report.phase.value,
        "role": report.role,
        "status": report.status.value,
        "clean_state": report.clean_state,
    }
    if any(payload[key] != value for key, value in expected_top_level.items()):
        raise ReceiptIntegrityError("relay_report_fields_mismatch")
    report_hash = _string(payload, "report_hash")
    if report_hash != canonical_report_hash(report):
        raise ReceiptIntegrityError("relay_report_hash_mismatch")
    source_thread_id = _string(payload, "source_thread_id")
    source_message_id = payload.get("source_message_id")
    if source_message_id is not None and (
        not isinstance(source_message_id, str) or not source_message_id.strip()
    ):
        raise ReceiptIntegrityError("relay_source_message_id_invalid")
    replaces_hash_drift_receipt = payload.get("replaces_hash_drift_receipt", False)
    if not isinstance(replaces_hash_drift_receipt, bool):
        raise ReceiptIntegrityError("relay_replaces_hash_drift_receipt_invalid")
    try:
        next_phase = CanonicalPhase(_string(payload, "next_phase"))
    except ValueError as exc:
        raise ReceiptIntegrityError("relay_next_phase_invalid") from exc
    canonical_next_thread_id = _string(payload, "canonical_next_thread_id")
    expected_thread_id = CANONICAL_THREAD_IDS.get(next_phase)
    if expected_thread_id is not None and canonical_next_thread_id != expected_thread_id:
        raise ReceiptIntegrityError("relay_next_thread_id_invalid")
    correction_cycle, origin_phase = _correction_metadata(payload, protocol, report, next_phase)
    replaced_report_hash = payload.get("replaced_report_hash")
    if replaced_report_hash is not None and (
        not isinstance(replaced_report_hash, str) or len(replaced_report_hash) != 64
    ):
        raise ReceiptIntegrityError("relay_replacement_evidence_invalid")
    return RelayReceipt(
        protocol=protocol,
        report=report,
        report_hash=report_hash,
        source_thread_id=source_thread_id,
        source_message_id=source_message_id,
        verification=_string(payload, "verification"),
        next_phase=next_phase,
        canonical_next_thread_id=canonical_next_thread_id,
        replaces_hash_drift_receipt=replaces_hash_drift_receipt,
        replaced_report_hash=replaced_report_hash,
        correction_cycle=correction_cycle,
        origin_phase=origin_phase,
    )


def _correction_metadata(
    payload: dict[str, object],
    protocol: object,
    report: WorkerReport,
    next_phase: CanonicalPhase,
) -> tuple[int | None, CanonicalPhase | None]:
    correction_fields = {
        "dispatch_protocol", "correction_cycle", "origin_phase",
        "retry_same_worker", "no_duplicate_worker",
    }
    present = correction_fields.intersection(payload)
    if protocol == PROTOCOL:
        if present:
            raise ReceiptIntegrityError("relay_correction_protocol_invalid")
        return None, None
    if present != correction_fields:
        raise ReceiptIntegrityError("relay_correction_protocol_invalid")
    cycle = payload["correction_cycle"]
    try:
        origin = CanonicalPhase(str(payload["origin_phase"]))
    except ValueError as exc:
        raise ReceiptIntegrityError("relay_correction_protocol_invalid") from exc
    if (
        payload["dispatch_protocol"] != CORRECTION_PROTOCOL
        or isinstance(cycle, bool)
        or not isinstance(cycle, int)
        or cycle < 1
        or origin not in {CanonicalPhase.REVIEW, CanonicalPhase.VERIFIER}
        or report.phase is not CanonicalPhase.EXECUTOR
        or report.role != "executor"
        or next_phase is not CanonicalPhase.TEST
        or payload["retry_same_worker"] is not False
        or payload["no_duplicate_worker"] is not True
        or payload["source_thread_id"] != CANONICAL_THREAD_IDS[CanonicalPhase.EXECUTOR]
    ):
        raise ReceiptIntegrityError("relay_correction_protocol_invalid")
    return cycle, origin


def _string(payload: dict[str, object], key: str) -> str:
    value = payload[key]
    if not isinstance(value, str) or not value.strip():
        raise ReceiptIntegrityError(f"relay_{key}_invalid")
    return value.strip()
