"""Non-destructive generation selection for Relay worker-report ledgers."""

from __future__ import annotations

import json
import os
import re
import tempfile
import time
from contextlib import contextmanager
from pathlib import Path
from collections.abc import Iterator

from harness.worker_report_contracts import (
    CanonicalPhase,
    ReceiptIntegrityError,
    ReportStatus,
    WorkerReport,
    canonical_report_hash,
)

_POINTER_NAME = "active-generation.json"
_GENERATIONS_NAME = "generations"
_LOCK_NAME = ".relay-generation.lock"
_GENERATION_PATTERN = re.compile(r"generation-([1-9][0-9]*)")
_POINTER_FIELDS = {
    "version",
    "workflow_id",
    "active_generation_id",
    "rollover_report_hash",
    "rollover_reason",
}


class RelayLedgerGenerations:
    """Resolve one active ledger generation without mutating retired ledgers."""

    def __init__(self, container: Path, *, workflow_id: str) -> None:
        self.container = container
        self.workflow_id = workflow_id
        self.pointer_path = container / _POINTER_NAME
        self.generations_root = container / _GENERATIONS_NAME
        self._lock_path = container / _LOCK_NAME

    def select(
        self,
        report: WorkerReport,
        *,
        report_hash: str,
        source_thread_id: str,
        replaces_hash_drift_receipt: bool,
        replaced_report_hash: str | None = None,
    ) -> Path:
        """Return the legacy root or an atomically selected generation."""
        self.container.mkdir(parents=True, exist_ok=True)
        with self._locked():
            if self.pointer_path.exists():
                return self._active_generation(report_hash=report_hash)
            dispatch_exists = (self.container / "dispatch-ledger.json").exists()
            receipts_exist = (self.container / "receipt-ledger.json").exists()
            if dispatch_exists != receipts_exist:
                raise ReceiptIntegrityError("relay_legacy_ledger_pair_incomplete")
            if dispatch_exists:
                if not replaces_hash_drift_receipt:
                    return self.container
                if not self._confirmed_legacy_hash_drift(
                    report,
                    report_hash=report_hash,
                    source_thread_id=source_thread_id,
                    replaced_report_hash=replaced_report_hash,
                ):
                    raise ReceiptIntegrityError("relay_hash_drift_not_confirmed")
                return self._create_generation(
                    report_hash=report_hash,
                    reason="legacy_assignment_hash_drift",
                )
            if replaces_hash_drift_receipt:
                raise ReceiptIntegrityError("relay_hash_drift_not_confirmed")
            return self._create_generation(report_hash=None, reason="fresh")

    def start_correction(self, *, report_hash: str) -> Path:
        """Start one immutable correction generation, idempotently by report hash."""
        self.container.mkdir(parents=True, exist_ok=True)
        with self._locked():
            if self.pointer_path.exists():
                pointer = self._read_json(
                    self.pointer_path, "relay_generation_pointer_invalid",
                )
                if (
                    pointer.get("rollover_reason") == "defect_correction"
                    and pointer.get("rollover_report_hash") == report_hash
                ):
                    return self._active_generation(report_hash=report_hash)
            return self._create_generation(
                report_hash=report_hash,
                reason="defect_correction",
            )

    def _active_generation(self, *, report_hash: str) -> Path:
        pointer = self._read_json(self.pointer_path, "relay_generation_pointer_invalid")
        if set(pointer) != _POINTER_FIELDS:
            raise ReceiptIntegrityError("relay_generation_pointer_invalid")
        if pointer.get("version") != 1 or pointer.get("workflow_id") != self.workflow_id:
            raise ReceiptIntegrityError("relay_generation_pointer_invalid")
        generation_id = pointer.get("active_generation_id")
        rollover_hash = pointer.get("rollover_report_hash")
        reason = pointer.get("rollover_reason")
        if not isinstance(generation_id, str) or _GENERATION_PATTERN.fullmatch(generation_id) is None:
            raise ReceiptIntegrityError("relay_generation_pointer_invalid")
        if rollover_hash is not None and not isinstance(rollover_hash, str):
            raise ReceiptIntegrityError("relay_generation_pointer_invalid")
        if reason not in {"fresh", "legacy_assignment_hash_drift", "defect_correction"}:
            raise ReceiptIntegrityError("relay_generation_pointer_invalid")
        generation = self.generations_root / generation_id
        if generation.parent != self.generations_root or not generation.is_dir():
            raise ReceiptIntegrityError("relay_generation_pointer_invalid")
        return generation

    def _create_generation(self, *, report_hash: str | None, reason: str) -> Path:
        self.generations_root.mkdir(parents=True, exist_ok=True)
        indexes = [
            int(match.group(1))
            for path in self.generations_root.iterdir()
            if path.is_dir() and (match := _GENERATION_PATTERN.fullmatch(path.name)) is not None
        ]
        generation_id = f"generation-{max(indexes, default=0) + 1}"
        generation = self.generations_root / generation_id
        generation.mkdir()
        self._write_json_atomic({
            "version": 1,
            "workflow_id": self.workflow_id,
            "active_generation_id": generation_id,
            "rollover_report_hash": report_hash,
            "rollover_reason": reason,
        })
        return generation

    def _confirmed_legacy_hash_drift(
        self,
        report: WorkerReport,
        *,
        report_hash: str,
        source_thread_id: str,
        replaced_report_hash: str | None,
    ) -> bool:
        if report.phase is not CanonicalPhase.EXECUTOR:
            return False
        dispatch = self._read_json(
            self.container / "dispatch-ledger.json", "relay_legacy_ledger_invalid",
        )
        receipts = self._read_json(
            self.container / "receipt-ledger.json", "relay_legacy_ledger_invalid",
        )
        if (
            dispatch.get("version") != 2
            or receipts.get("version") != 2
            or dispatch.get("workflow_id") != self.workflow_id
            or receipts.get("workflow_id") != self.workflow_id
            or dispatch.get("current_phase") != CanonicalPhase.TEST.value
        ):
            return False
        applied = dispatch.get("applied_receipts")
        rows = receipts.get("receipts")
        if not isinstance(applied, dict) or not isinstance(rows, list):
            raise ReceiptIntegrityError("relay_legacy_ledger_invalid")
        legacy_hashes = {
            row.get("report_hash")
            for row in rows
            if isinstance(row, dict)
        }
        if replaced_report_hash is None or replaced_report_hash not in legacy_hashes:
            raise ReceiptIntegrityError("relay_replacement_evidence_invalid")
        for row in rows:
            if self._legacy_row_matches(
                row,
                report_hash=report_hash,
                source_thread_id=source_thread_id,
                applied=applied,
                replaced_report_hash=replaced_report_hash,
            ):
                return True
        return False

    def _legacy_row_matches(
        self,
        row: object,
        *,
        report_hash: str,
        source_thread_id: str,
        applied: dict[object, object],
        replaced_report_hash: str,
    ) -> bool:
        if not isinstance(row, dict):
            raise ReceiptIntegrityError("relay_legacy_ledger_invalid")
        if (
            row.get("assignment_id") != f"{self.workflow_id}:Executor"
            or row.get("phase") != CanonicalPhase.EXECUTOR.value
            or row.get("role") != "executor"
            or row.get("source_thread_id") != source_thread_id
            or row.get("consumed") is not True
            or row.get("transition") != "advance"
            or row.get("next_phase") != CanonicalPhase.TEST.value
        ):
            if row.get("report_hash") == replaced_report_hash:
                raise ReceiptIntegrityError("relay_replacement_evidence_invalid")
            return False
        try:
            legacy = WorkerReport(
                assignment_id=str(row["assignment_id"]),
                phase=CanonicalPhase(str(row["phase"])),
                role=str(row["role"]),
                status=ReportStatus(str(row["status"])),
                clean_state=row["clean_state"],
                summary=str(row["summary"]),
            )
        except (KeyError, ValueError) as exc:
            raise ReceiptIntegrityError("relay_legacy_ledger_invalid") from exc
        if not isinstance(legacy.clean_state, bool):
            raise ReceiptIntegrityError("relay_legacy_ledger_invalid")
        legacy_hash = canonical_report_hash(legacy)
        return (
            row.get("report_hash") == legacy_hash
            and legacy_hash == replaced_report_hash
            and legacy_hash in applied
            and legacy_hash != report_hash
        )

    @contextmanager
    def _locked(self) -> Iterator[None]:
        descriptor: int | None = None
        for _ in range(200):
            try:
                descriptor = os.open(self._lock_path, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
                break
            except FileExistsError:
                time.sleep(0.005)
        if descriptor is None:
            raise ReceiptIntegrityError("relay_generation_lock_unavailable")
        try:
            os.write(descriptor, str(os.getpid()).encode())
            os.fsync(descriptor)
            yield
        finally:
            os.close(descriptor)
            self._lock_path.unlink(missing_ok=True)

    @staticmethod
    def _read_json(path: Path, reason: str) -> dict[str, object]:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise ReceiptIntegrityError(reason) from exc
        if not isinstance(payload, dict):
            raise ReceiptIntegrityError(reason)
        return payload

    def _write_json_atomic(self, payload: dict[str, object]) -> None:
        descriptor, temporary_name = tempfile.mkstemp(
            dir=self.container,
            prefix=f".{_POINTER_NAME}.",
            suffix=".tmp",
        )
        temporary = Path(temporary_name)
        try:
            with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
                json.dump(payload, stream, ensure_ascii=False, indent=2)
                stream.write("\n")
                stream.flush()
                os.fsync(stream.fileno())
            os.replace(temporary, self.pointer_path)
        finally:
            temporary.unlink(missing_ok=True)
