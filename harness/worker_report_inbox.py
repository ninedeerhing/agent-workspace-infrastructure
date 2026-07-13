"""Persistent, idempotent inbox for canonical AWI worker reports."""

from __future__ import annotations

from dataclasses import replace
from pathlib import Path

from harness.worker_report_contracts import (
    CANONICAL_PHASES,
    PHASE_ROLES,
    CanonicalAssignment,
    CanonicalPhase,
    ReceiptIntegrityError,
    ReceiptResult,
    ReportContractError,
    ReportStatus,
    TransitionName,
    WorkerReport,
    canonical_report_hash,
    parse_worker_report_json,
    retry_transition,
)
from harness.worker_report_ledger_store import WorkerReportLedgerStore
from harness.worker_report_receipt_validation import parse_persisted_receipt


class WorkerReportInbox:
    """Own the mutable dispatch and receipt ledgers for one workflow."""

    def __init__(self, root: Path, *, workflow_id: str) -> None:
        if not workflow_id.strip():
            raise ReportContractError("workflow_id_must_be_nonempty")
        self._workflow_id = workflow_id.strip()
        self._store = WorkerReportLedgerStore(root, workflow_id=self._workflow_id)
        with self._store.locked():
            dispatch_exists = self._store.dispatch_path.is_file()
            receipt_exists = self._store.receipt_path.is_file()
            if dispatch_exists != receipt_exists:
                raise ReceiptIntegrityError("worker_report_ledger_pair_incomplete")
            if not dispatch_exists:
                self._store.save_dispatch(self._initial_dispatch())
                self._store.save_receipts(self._initial_receipts())
            self._reload()

    @property
    def assignment_count(self) -> int:
        self._reload()
        return len(self._dispatch["assignments"])

    @property
    def receipt_count(self) -> int:
        self._reload()
        return len(self._receipts["receipts"])

    def dispatch_current(self) -> CanonicalAssignment | None:
        self._reload()
        return self._current_assignment()

    def _current_assignment(self) -> CanonicalAssignment | None:
        if self._dispatch["complete"]:
            return None
        phase = CanonicalPhase(self._dispatch["current_phase"])
        row = self._assignment_for(phase)
        return CanonicalAssignment(
            assignment_id=row["assignment_id"], phase=phase,
            role=row["role"], attempt=row["attempt"],
        )

    def receive_json(self, raw: str, *, consume: bool = True) -> ReceiptResult:
        return self.receive(parse_worker_report_json(raw), consume=consume)

    def receive(
        self,
        report: WorkerReport,
        *,
        consume: bool = True,
        source_thread_id: str | None = None,
        source_message_id: str | None = None,
    ) -> ReceiptResult:
        self._validate_report_types(report)
        source_thread_id = self._optional_metadata(source_thread_id, "source_thread_id")
        source_message_id = self._optional_metadata(source_message_id, "source_message_id")
        report_hash = canonical_report_hash(report)
        with self._store.locked():
            self._reload()
            duplicate = self._receipt_by_hash(report_hash)
            if duplicate is not None:
                self._validated_persisted_report(duplicate)
                result = self._consume(duplicate) if consume and not duplicate["consumed"] else (
                    self._result_from_receipt(duplicate)
                )
                return replace(result, duplicate=True)
            self._validate_current_report(report)
            receipt = self._new_receipt(
                report, report_hash=report_hash,
                source_thread_id=source_thread_id, source_message_id=source_message_id,
            )
            self._receipts["receipts"].append(receipt)
            self._receipts["next_cursor"] += 1
            self._save_receipts()
            return self._consume(receipt) if consume else self._result_from_receipt(receipt)

    def recover(self) -> tuple[ReceiptResult, ...]:
        with self._store.locked():
            self._reload()
            pending = sorted(
                (
                    row for row in self._receipts["receipts"]
                    if not row.get("consumed") and not row.get("quarantined")
                ),
                key=lambda row: row.get("cursor", 0),
            )
            return tuple(self._consume(row) for row in pending)

    def _consume(self, receipt: dict[str, object]) -> ReceiptResult:
        report = self._validated_persisted_report(receipt)
        report_hash = str(receipt["report_hash"])
        applied = self._dispatch["applied_receipts"]
        if report_hash in applied:
            prior = applied[report_hash]
            receipt["transition"] = prior["transition"]
            receipt["next_phase"] = prior["next_phase"]
            receipt["consumed"] = True
            self._save_receipts()
            return self._result_from_receipt(receipt)
        self._validate_current_report(report)
        retry = retry_transition(report)
        if retry is None:
            transition, next_phase = self._advance(report.phase)
        else:
            transition, next_phase = retry, report.phase
            assignment = self._assignment_for(report.phase)
            assignment["attempt"] += 1
            assignment["state"] = retry
        next_value = next_phase.value if next_phase is not None else None
        applied[report_hash] = {"transition": transition, "next_phase": next_value}
        receipt.update({"transition": transition, "next_phase": next_value})
        self._save_dispatch()
        receipt["consumed"] = True
        self._save_receipts()
        return self._result_from_receipt(receipt)

    def _validated_persisted_report(self, receipt: dict[str, object]) -> WorkerReport:
        try:
            return parse_persisted_receipt(receipt, workflow_id=self._workflow_id)
        except ReceiptIntegrityError as exc:
            receipt.update({"quarantined": True, "quarantine_reason": exc.reason})
            self._store.quarantine(receipt, reason=exc.reason)
            self._save_receipts()
            raise

    def _advance(self, phase: CanonicalPhase) -> tuple[TransitionName, CanonicalPhase | None]:
        self._assignment_for(phase)["state"] = "completed"
        index = CANONICAL_PHASES.index(phase)
        if index == len(CANONICAL_PHASES) - 1:
            self._dispatch["complete"] = True
            return "complete", None
        next_phase = CANONICAL_PHASES[index + 1]
        self._dispatch["current_phase"] = next_phase.value
        self._dispatch["assignments"].append(self._new_assignment(next_phase))
        return "advance", next_phase

    def _validate_current_report(self, report: WorkerReport) -> None:
        assignment = self._current_assignment()
        if assignment is None:
            raise ReportContractError("workflow_already_complete")
        if report.assignment_id != assignment.assignment_id:
            raise ReportContractError("assignment_id_mismatch")
        if report.phase is not assignment.phase:
            raise ReportContractError("phase_mismatch")
        if report.role != assignment.role:
            raise ReportContractError("role_mismatch")

    @staticmethod
    def _validate_report_types(report: WorkerReport) -> None:
        if not isinstance(report.phase, CanonicalPhase) or not isinstance(report.status, ReportStatus):
            raise ReportContractError("report_enum_invalid")
        if not isinstance(report.clean_state, bool):
            raise ReportContractError("clean_state_must_be_boolean")
        if not report.assignment_id.strip() or not report.role.strip() or not report.summary.strip():
            raise ReportContractError("report_string_field_invalid")

    @staticmethod
    def _optional_metadata(value: object, name: str) -> str | None:
        if value is None:
            return None
        if not isinstance(value, str) or not value.strip():
            raise ReportContractError(f"{name}_invalid")
        return value.strip()

    def _new_receipt(
        self,
        report: WorkerReport,
        *,
        report_hash: str,
        source_thread_id: str | None,
        source_message_id: str | None,
    ) -> dict[str, object]:
        receipt: dict[str, object] = {
            "cursor": self._receipts["next_cursor"], "report_hash": report_hash,
            "assignment_id": report.assignment_id, "phase": report.phase.value,
            "role": report.role, "status": report.status.value,
            "clean_state": report.clean_state, "summary": report.summary,
            "consumed": False, "transition": "pending", "next_phase": None,
        }
        if source_thread_id is not None:
            receipt["source_thread_id"] = source_thread_id
        if source_message_id is not None:
            receipt["source_message_id"] = source_message_id
        return receipt

    def _initial_dispatch(self) -> dict[str, object]:
        return {
            "version": 3, "workflow_id": self._workflow_id,
            "current_phase": CanonicalPhase.EXECUTOR.value, "complete": False,
            "assignments": [self._new_assignment(CanonicalPhase.EXECUTOR)],
            "applied_receipts": {},
        }

    def _initial_receipts(self) -> dict[str, object]:
        return {"version": 3, "workflow_id": self._workflow_id, "next_cursor": 1, "receipts": []}

    def _new_assignment(self, phase: CanonicalPhase) -> dict[str, object]:
        return {
            "assignment_id": self._workflow_id,
            "internal_assignment_key": (
                f"{self._workflow_id}|{phase.value}|{PHASE_ROLES[phase]}"
            ),
            "phase": phase.value,
            "role": PHASE_ROLES[phase], "attempt": 1, "state": "active",
        }

    def _assignment_for(self, phase: CanonicalPhase) -> dict[str, object]:
        return next(row for row in self._dispatch["assignments"] if row["phase"] == phase.value)

    def _receipt_by_hash(self, report_hash: str) -> dict[str, object] | None:
        return next((row for row in self._receipts["receipts"] if row.get("report_hash") == report_hash), None)

    @staticmethod
    def _result_from_receipt(receipt: dict[str, object]) -> ReceiptResult:
        next_value = receipt["next_phase"]
        return ReceiptResult(
            receipt_cursor=receipt["cursor"], report_hash=receipt["report_hash"],
            transition=receipt["transition"],
            next_phase=CanonicalPhase(next_value) if next_value is not None else None,
        )

    def _reload(self) -> None:
        self._dispatch = self._store.load_dispatch()
        self._receipts = self._store.load_receipts()
        self._store.validate_consistency(self._dispatch, self._receipts)

    def _save_dispatch(self) -> None:
        self._store.save_dispatch(self._dispatch)

    def _save_receipts(self) -> None:
        self._store.save_receipts(self._receipts)
