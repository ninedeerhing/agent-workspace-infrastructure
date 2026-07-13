from __future__ import annotations

import json
from dataclasses import replace
from pathlib import Path

import pytest

from harness.worker_report_contracts import (
    CanonicalPhase,
    ReceiptIntegrityError,
    ReportStatus,
    WorkerReport,
    canonical_report_hash,
)
from harness.worker_report_delivery_ack import (
    acknowledge_dispatch_delivery,
    build_target_delivery_receipt,
)
from harness.worker_report_relay_adapter import (
    CANONICAL_THREAD_IDS,
    DispatcherHandoff,
    consume_relay_receipt,
)


def _report(phase: CanonicalPhase) -> WorkerReport:
    roles = {
        CanonicalPhase.EXECUTOR: "executor",
        CanonicalPhase.TEST: "test-engineer",
        CanonicalPhase.REVIEW: "code-reviewer",
        CanonicalPhase.VERIFIER: "verifier",
    }
    return WorkerReport(
        assignment_id="delivery-flow",
        phase=phase,
        role=roles[phase],
        status=ReportStatus.COMPLETED,
        clean_state=True,
        summary=f"{phase.value} clean",
    )


def _receipt(
    phase: CanonicalPhase,
    next_phase: CanonicalPhase,
    *,
    no_phase_advance: bool = False,
) -> str:
    report = _report(phase)
    return json.dumps({
        "protocol": "WORKER_REPORT_RECEIPT_V1",
        "source_thread_id": CANONICAL_THREAD_IDS[phase],
        "assignment_id": report.assignment_id,
        "phase": phase.value,
        "role": report.role,
        "status": report.status.value,
        "clean_state": report.clean_state,
        "canonical_report_payload": json.loads(report.canonical_json()),
        "report_hash": canonical_report_hash(report),
        "verification": "verified",
        "next_phase": next_phase.value,
        "canonical_next_thread_id": CANONICAL_THREAD_IDS[next_phase],
        "no_phase_advance": no_phase_advance,
    })


def _consume(container: Path, phase: CanonicalPhase, next_phase: CanonicalPhase) -> None:
    consume_relay_receipt(
        _receipt(phase, next_phase),
        workflow_id="delivery-flow",
        ledger_root=container,
    )


def test_no_phase_advance_does_not_suppress_executor_to_test_delivery(
    tmp_path: Path,
) -> None:
    raw = _receipt(
        CanonicalPhase.EXECUTOR,
        CanonicalPhase.TEST,
        no_phase_advance=True,
    )

    handoff = consume_relay_receipt(
        raw,
        workflow_id="delivery-flow",
        ledger_root=tmp_path,
    )

    assert handoff is not None
    assert handoff.phase is CanonicalPhase.TEST
    assert handoff.delivery_mode == "deliver_then_ack"
    assert handoff.dispatch_id


def test_verifier_to_sync_is_a_deliver_then_ack_handoff(tmp_path: Path) -> None:
    _consume(tmp_path, CanonicalPhase.EXECUTOR, CanonicalPhase.TEST)
    _consume(tmp_path, CanonicalPhase.TEST, CanonicalPhase.REVIEW)
    _consume(tmp_path, CanonicalPhase.REVIEW, CanonicalPhase.VERIFIER)

    handoff = consume_relay_receipt(
        _receipt(CanonicalPhase.VERIFIER, CanonicalPhase.SYNC, no_phase_advance=True),
        workflow_id="delivery-flow",
        ledger_root=tmp_path,
    )

    assert handoff is not None
    assert handoff.phase is CanonicalPhase.SYNC
    assert handoff.delivery_mode == "deliver_then_ack"
    assert handoff.canonical_thread_id == CANONICAL_THREAD_IDS[CanonicalPhase.SYNC]

    receipt = build_target_delivery_receipt(
        dispatch_id=handoff.dispatch_id,
        target_thread_id=handoff.canonical_thread_id,
    )
    ack = acknowledge_dispatch_delivery(
        handoff,
        receipt,
        observed_source_thread_id=handoff.canonical_thread_id,
    )

    assert ack.dispatch_id == handoff.dispatch_id
    assert ack.target_thread_id == CANONICAL_THREAD_IDS[CanonicalPhase.SYNC]


def test_dispatch_ack_requires_actual_target_delivery_id() -> None:
    handoff = _handoff()
    ack_only = json.dumps({
        "protocol": "DISPATCHER_ACK_V1",
        "dispatch_id": handoff.dispatch_id,
        "target_thread_id": handoff.canonical_thread_id,
    })

    with pytest.raises(ReceiptIntegrityError, match="relay_dispatch_ack_missing"):
        acknowledge_dispatch_delivery(
            handoff,
            ack_only,
            observed_source_thread_id=handoff.canonical_thread_id,
        )


def test_dispatch_ack_rejects_wrong_target_thread() -> None:
    handoff = _handoff()
    receipt = _delivery_receipt(handoff, target_thread_id="wrong-thread")

    with pytest.raises(ReceiptIntegrityError, match="relay_dispatch_target_mismatch"):
        acknowledge_dispatch_delivery(
            handoff,
            receipt,
            observed_source_thread_id=handoff.canonical_thread_id,
        )


def test_duplicate_delivery_ack_is_idempotent() -> None:
    handoff = _handoff()
    receipt = _delivery_receipt(handoff)

    first = acknowledge_dispatch_delivery(
        handoff,
        receipt,
        observed_source_thread_id=handoff.canonical_thread_id,
    )
    duplicate = acknowledge_dispatch_delivery(
        handoff,
        receipt,
        observed_source_thread_id=handoff.canonical_thread_id,
    )

    assert duplicate == first
    assert first.dispatch_id == handoff.dispatch_id
    assert first.target_delivery_id


def test_dispatch_ack_rejects_forged_receiver_delivery_id() -> None:
    handoff = _handoff()
    receipt = _delivery_receipt(handoff, target_delivery_id="forged-id")

    with pytest.raises(
        ReceiptIntegrityError,
        match="relay_dispatch_target_delivery_id_mismatch",
    ):
        acknowledge_dispatch_delivery(
            handoff,
            receipt,
            observed_source_thread_id=handoff.canonical_thread_id,
        )


@pytest.mark.parametrize("delivery_id", ["", None])
def test_dispatch_ack_rejects_unbound_receiver_delivery_id(
    delivery_id: str | None,
) -> None:
    handoff = _handoff()
    receipt = _delivery_receipt(handoff, target_delivery_id=delivery_id)

    with pytest.raises(
        ReceiptIntegrityError,
        match="relay_dispatch_ack_missing",
    ):
        acknowledge_dispatch_delivery(
            handoff,
            receipt,
            observed_source_thread_id=handoff.canonical_thread_id,
        )


def test_dispatch_ack_rejects_wrong_observed_source_thread() -> None:
    handoff = _handoff()
    receipt = _delivery_receipt(handoff)

    with pytest.raises(
        ReceiptIntegrityError,
        match="relay_dispatch_source_thread_mismatch",
    ):
        acknowledge_dispatch_delivery(
            handoff,
            receipt,
            observed_source_thread_id="not-the-canonical-target",
        )


def test_dispatch_ack_rejects_missing_handoff_dispatch_id() -> None:
    handoff = replace(_handoff(), dispatch_id="")

    with pytest.raises(
        ReceiptIntegrityError,
        match="relay_dispatch_id_missing",
    ):
        acknowledge_dispatch_delivery(
            handoff,
            "{}",
            observed_source_thread_id=handoff.canonical_thread_id,
        )


def test_duplicate_pending_handoff_keeps_same_dispatch_identity(tmp_path: Path) -> None:
    raw = _receipt(CanonicalPhase.EXECUTOR, CanonicalPhase.TEST)

    first = consume_relay_receipt(
        raw, workflow_id="delivery-flow", ledger_root=tmp_path,
    )
    duplicate = consume_relay_receipt(
        raw, workflow_id="delivery-flow", ledger_root=tmp_path,
    )

    assert first is not None and duplicate is not None
    assert duplicate.dispatch_id == first.dispatch_id
    assert duplicate.canonical_thread_id == first.canonical_thread_id


def _handoff() -> DispatcherHandoff:
    return DispatcherHandoff(
        assignment_id="delivery-flow",
        phase=CanonicalPhase.TEST,
        role="test-engineer",
        canonical_thread_id=CANONICAL_THREAD_IDS[CanonicalPhase.TEST],
        source_receipt_hash="a" * 64,
        dispatch_id="dispatch-1",
        delivery_mode="deliver_then_ack",
    )


def _delivery_receipt(
    handoff: DispatcherHandoff,
    *,
    target_thread_id: str | None = None,
    target_delivery_id: object = ...,
) -> str:
    target = target_thread_id or handoff.canonical_thread_id
    payload = json.loads(build_target_delivery_receipt(
        dispatch_id=handoff.dispatch_id,
        target_thread_id=target,
    ))
    if target_delivery_id is not ...:
        payload["target_delivery_id"] = target_delivery_id
    return json.dumps(payload)


def test_receiver_originated_receipt_is_deterministic_and_correlated() -> None:
    handoff = _handoff()

    first = build_target_delivery_receipt(
        dispatch_id=handoff.dispatch_id,
        target_thread_id=handoff.canonical_thread_id,
    )
    second = build_target_delivery_receipt(
        dispatch_id=handoff.dispatch_id,
        target_thread_id=handoff.canonical_thread_id,
    )

    assert first == second
    payload = json.loads(first)
    assert payload == {
        "protocol": "CODEX_TARGET_DELIVERY_RECEIPT_V1",
        "dispatch_id": handoff.dispatch_id,
        "target_thread_id": handoff.canonical_thread_id,
        "target_delivery_id": payload["target_delivery_id"],
    }
    assert payload["target_delivery_id"]


def test_agent_contracts_require_receiver_receipt_before_ack() -> None:
    root = Path(__file__).resolve().parents[2]
    dispatcher = (root / "agents" / "dispatcher.md").read_text(encoding="utf-8")
    relay = (root / "agents" / "report-relay.md").read_text(encoding="utf-8")

    assert "deliver_then_ack" in dispatcher
    assert "send_message_to_thread" in dispatcher
    assert "receiver" in dispatcher.lower()
    assert "observed_source_thread_id" in dispatcher
    assert "dispatcher_ack_only" in relay
    assert "relay_dispatch_ack_missing" in relay
    assert "receiver" in relay.lower()
