"""Durable single-writer JSON storage for the worker report inbox."""

from __future__ import annotations

import json
import os
import tempfile
import time
from collections.abc import Iterator
from contextlib import contextmanager
from pathlib import Path

from harness.worker_report_contracts import (
    CANONICAL_PHASES,
    PHASE_ROLES,
    CanonicalPhase,
    LedgerIntegrityError,
)

_RETRY_TRANSITIONS = {
    "retry_partial",
    "retry_blocked",
    "retry_system_error",
    "retry_waiting_on_approval",
    "retry_non_clean",
}

DISPATCH_LEDGER_NAME = "dispatch-ledger.json"
RECEIPT_LEDGER_NAME = "receipt-ledger.json"
QUARANTINE_NAME = "receipt-quarantine.jsonl"
_LOCK_NAME = ".worker-report-inbox.lock"


class WorkerReportLedgerStore:
    """Serialize ledger transactions and validate persisted dispatch state."""

    def __init__(self, root: Path, *, workflow_id: str) -> None:
        self.root = root
        self.workflow_id = workflow_id
        self.dispatch_path = root / DISPATCH_LEDGER_NAME
        self.receipt_path = root / RECEIPT_LEDGER_NAME
        self.quarantine_path = root / QUARANTINE_NAME
        self._lock_path = root / _LOCK_NAME
        root.mkdir(parents=True, exist_ok=True)

    @contextmanager
    def locked(self) -> Iterator[None]:
        descriptor: int | None = None
        for _ in range(200):
            try:
                descriptor = os.open(self._lock_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
                break
            except FileExistsError:
                time.sleep(0.005)
        if descriptor is None:
            raise LedgerIntegrityError("worker_report_ledger_lock_unavailable")
        try:
            os.write(descriptor, str(os.getpid()).encode())
            os.fsync(descriptor)
            yield
        finally:
            os.close(descriptor)
            self._lock_path.unlink(missing_ok=True)

    def load_dispatch(self) -> dict[str, object]:
        payload = self._read_json(self.dispatch_path)
        self._validate_dispatch(payload)
        return payload

    def load_receipts(self) -> dict[str, object]:
        payload = self._read_json(self.receipt_path)
        self._validate_receipt_ledger(payload)
        return payload

    def save_dispatch(self, payload: dict[str, object]) -> None:
        self._validate_dispatch(payload)
        self._write_json(self.dispatch_path, payload)

    def save_receipts(self, payload: dict[str, object]) -> None:
        self._validate_receipt_ledger(payload)
        self._write_json(self.receipt_path, payload)

    def validate_consistency(
        self,
        dispatch: dict[str, object],
        receipts: dict[str, object],
    ) -> None:
        """Cross-check applied transitions against their durable receipts."""
        receipt_by_hash = {
            row["report_hash"]: row
            for row in receipts["receipts"]
        }
        for report_hash, applied in dispatch["applied_receipts"].items():
            self._validate_applied_transition(applied)
            receipt = receipt_by_hash.get(report_hash)
            if receipt is None:
                raise LedgerIntegrityError("dispatch_applied_receipt_missing")
            durable_crash_window = (
                receipt.get("consumed") is False
                and receipt.get("transition") == "pending"
                and receipt.get("next_phase") is None
            )
            if not durable_crash_window and (
                receipt.get("transition") != applied["transition"]
                or receipt.get("next_phase") != applied["next_phase"]
                or receipt.get("consumed") is not True
            ):
                raise LedgerIntegrityError("dispatch_applied_transition_mismatch")

    def quarantine(self, receipt: dict[str, object], *, reason: str) -> None:
        record = {
            "cursor": receipt.get("cursor"),
            "report_hash": receipt.get("report_hash"),
            "reason": reason,
        }
        with self.quarantine_path.open("a", encoding="utf-8") as stream:
            stream.write(json.dumps(record, ensure_ascii=False, sort_keys=True) + "\n")
            stream.flush()
            os.fsync(stream.fileno())

    def _validate_dispatch(self, payload: dict[str, object]) -> None:
        expected = {
            "version", "workflow_id", "current_phase", "complete", "assignments",
            "applied_receipts",
        }
        if set(payload) != expected or payload.get("workflow_id") != self.workflow_id:
            raise LedgerIntegrityError("dispatch_ledger_contract_invalid")
        if payload.get("version") != 3 or not isinstance(payload.get("complete"), bool):
            raise LedgerIntegrityError("dispatch_ledger_metadata_invalid")
        try:
            current_phase = CanonicalPhase(str(payload["current_phase"]))
        except ValueError as exc:
            raise LedgerIntegrityError("dispatch_current_phase_invalid") from exc
        assignments = payload.get("assignments")
        if not isinstance(assignments, list) or not assignments:
            raise LedgerIntegrityError("dispatch_assignments_invalid")
        phases: list[CanonicalPhase] = []
        roles: list[str] = []
        internal_keys: list[str] = []
        for row in assignments:
            phase, role, internal_key = self._validate_assignment(row)
            phases.append(phase)
            roles.append(role)
            internal_keys.append(internal_key)
        if len(phases) != len(set(phases)):
            raise LedgerIntegrityError("dispatch_assignment_phase_duplicate")
        if len(roles) != len(set(roles)):
            raise LedgerIntegrityError("dispatch_assignment_role_duplicate")
        if len(internal_keys) != len(set(internal_keys)):
            raise LedgerIntegrityError("dispatch_assignment_key_duplicate")
        expected_phases = list(CANONICAL_PHASES[: CANONICAL_PHASES.index(current_phase) + 1])
        if phases != expected_phases:
            raise LedgerIntegrityError("dispatch_assignment_sequence_invalid")
        applied = payload.get("applied_receipts")
        if not isinstance(applied, dict) or not all(isinstance(key, str) for key in applied):
            raise LedgerIntegrityError("dispatch_applied_receipts_invalid")
        for transition in applied.values():
            self._validate_applied_transition(transition)

    @staticmethod
    def _validate_applied_transition(value: object) -> None:
        if not isinstance(value, dict) or set(value) != {"transition", "next_phase"}:
            raise LedgerIntegrityError("dispatch_applied_transition_invalid")
        transition = value["transition"]
        next_phase = value["next_phase"]
        if transition == "advance":
            try:
                CanonicalPhase(str(next_phase))
            except ValueError as exc:
                raise LedgerIntegrityError("dispatch_applied_transition_invalid") from exc
            return
        if transition == "complete" and next_phase is None:
            return
        if transition in _RETRY_TRANSITIONS:
            try:
                CanonicalPhase(str(next_phase))
            except ValueError as exc:
                raise LedgerIntegrityError("dispatch_applied_transition_invalid") from exc
            return
        raise LedgerIntegrityError("dispatch_applied_transition_invalid")

    def _validate_assignment(self, value: object) -> tuple[CanonicalPhase, str, str]:
        if not isinstance(value, dict) or set(value) != {
            "assignment_id", "internal_assignment_key", "phase", "role", "attempt", "state",
        }:
            raise LedgerIntegrityError("dispatch_assignment_contract_invalid")
        try:
            phase = CanonicalPhase(str(value["phase"]))
        except ValueError as exc:
            raise LedgerIntegrityError("dispatch_assignment_phase_invalid") from exc
        role = value["role"]
        assignment_id = value["assignment_id"]
        internal_key = value["internal_assignment_key"]
        attempt = value["attempt"]
        if role != PHASE_ROLES[phase]:
            raise LedgerIntegrityError("dispatch_assignment_role_invalid")
        if assignment_id != self.workflow_id:
            raise LedgerIntegrityError("dispatch_assignment_id_invalid")
        expected_key = f"{self.workflow_id}|{phase.value}|{PHASE_ROLES[phase]}"
        if internal_key != expected_key:
            raise LedgerIntegrityError("dispatch_assignment_key_invalid")
        if isinstance(attempt, bool) or not isinstance(attempt, int) or attempt < 1:
            raise LedgerIntegrityError("dispatch_assignment_attempt_invalid")
        if not isinstance(value["state"], str) or not value["state"]:
            raise LedgerIntegrityError("dispatch_assignment_state_invalid")
        return phase, str(role), str(internal_key)

    def _validate_receipt_ledger(self, payload: dict[str, object]) -> None:
        if set(payload) != {"version", "workflow_id", "next_cursor", "receipts"}:
            raise LedgerIntegrityError("receipt_ledger_contract_invalid")
        if payload.get("version") != 3 or payload.get("workflow_id") != self.workflow_id:
            raise LedgerIntegrityError("receipt_ledger_metadata_invalid")
        cursor = payload.get("next_cursor")
        receipts = payload.get("receipts")
        if isinstance(cursor, bool) or not isinstance(cursor, int) or cursor < 1:
            raise LedgerIntegrityError("receipt_ledger_cursor_invalid")
        if not isinstance(receipts, list) or not all(isinstance(row, dict) for row in receipts):
            raise LedgerIntegrityError("receipt_ledger_rows_invalid")
        cursors = [row.get("cursor") for row in receipts]
        if cursors != list(range(1, len(receipts) + 1)):
            raise LedgerIntegrityError("receipt_ledger_cursor_sequence_invalid")
        hashes = [row.get("report_hash") for row in receipts]
        if any(not isinstance(value, str) or not value for value in hashes):
            raise LedgerIntegrityError("receipt_ledger_hash_invalid")
        if len(hashes) != len(set(hashes)):
            raise LedgerIntegrityError("receipt_ledger_hash_duplicate")
        if cursor != len(receipts) + 1:
            raise LedgerIntegrityError("receipt_ledger_next_cursor_invalid")

    @staticmethod
    def _read_json(path: Path) -> dict[str, object]:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise LedgerIntegrityError(f"ledger_json_invalid:{path.name}") from exc
        if not isinstance(payload, dict):
            raise LedgerIntegrityError(f"ledger_payload_invalid:{path.name}")
        return payload

    @staticmethod
    def _write_json(path: Path, payload: dict[str, object]) -> None:
        descriptor, temporary_name = tempfile.mkstemp(
            dir=path.parent, prefix=f".{path.name}.", suffix=".tmp",
        )
        temporary = Path(temporary_name)
        try:
            with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
                json.dump(payload, stream, ensure_ascii=False, indent=2)
                stream.write("\n")
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)
