"""Validate actual canonical-thread delivery before acknowledging a dispatch."""

from __future__ import annotations

import json
from dataclasses import dataclass
from hashlib import sha256
from typing import Final, Literal

from harness.worker_report_contracts import ReceiptIntegrityError
from harness.worker_report_relay_adapter import DispatcherHandoff

TARGET_DELIVERY_PROTOCOL: Final = "CODEX_TARGET_DELIVERY_RECEIPT_V1"
ACK_PROTOCOL: Final = "RELAY_DISPATCH_ACK_V1"


@dataclass(frozen=True, slots=True)
class DispatcherDeliveryAck:
    dispatch_id: str
    target_thread_id: str
    target_delivery_id: str
    delivery_mode: Literal["deliver_then_ack"] = "deliver_then_ack"

    def to_json(self) -> dict[str, str]:
        return {
            "protocol": ACK_PROTOCOL,
            "dispatch_id": self.dispatch_id,
            "target_thread_id": self.target_thread_id,
            "target_delivery_id": self.target_delivery_id,
            "delivery_mode": self.delivery_mode,
        }


def acknowledge_dispatch_delivery(
    handoff: DispatcherHandoff,
    raw_target_receipt: str,
    *,
    observed_source_thread_id: str | None,
) -> DispatcherDeliveryAck:
    """Create an ACK only from a correlated receiver-originated receipt."""
    if handoff.delivery_mode != "deliver_then_ack":
        raise ReceiptIntegrityError("relay_dispatch_mode_invalid")
    if (
        not isinstance(handoff.dispatch_id, str)
        or not handoff.dispatch_id.strip()
    ):
        raise ReceiptIntegrityError("relay_dispatch_id_missing")
    if (
        not isinstance(observed_source_thread_id, str)
        or observed_source_thread_id.strip() != handoff.canonical_thread_id
    ):
        raise ReceiptIntegrityError("relay_dispatch_source_thread_mismatch")
    payload = _parse_target_receipt(raw_target_receipt)
    dispatch_id = _required_string(payload, "dispatch_id")
    target_thread_id = _required_string(payload, "target_thread_id")
    target_delivery_id = _required_string(payload, "target_delivery_id")
    if dispatch_id != handoff.dispatch_id:
        raise ReceiptIntegrityError("relay_dispatch_id_mismatch")
    if target_thread_id != handoff.canonical_thread_id:
        raise ReceiptIntegrityError("relay_dispatch_target_mismatch")
    if target_delivery_id != _target_delivery_id(dispatch_id, target_thread_id):
        raise ReceiptIntegrityError("relay_dispatch_target_delivery_id_mismatch")
    return DispatcherDeliveryAck(
        dispatch_id=dispatch_id,
        target_thread_id=target_thread_id,
        target_delivery_id=target_delivery_id,
    )


def build_target_delivery_receipt(
    *,
    dispatch_id: str,
    target_thread_id: str,
) -> str:
    """Build the deterministic receipt returned by the canonical target."""
    if not isinstance(dispatch_id, str) or not dispatch_id.strip():
        raise ReceiptIntegrityError("relay_dispatch_id_missing")
    if not isinstance(target_thread_id, str) or not target_thread_id.strip():
        raise ReceiptIntegrityError("relay_dispatch_target_missing")
    dispatch_id = dispatch_id.strip()
    target_thread_id = target_thread_id.strip()
    return json.dumps(
        {
            "protocol": TARGET_DELIVERY_PROTOCOL,
            "dispatch_id": dispatch_id,
            "target_thread_id": target_thread_id,
            "target_delivery_id": _target_delivery_id(
                dispatch_id,
                target_thread_id,
            ),
        },
        sort_keys=True,
        separators=(",", ":"),
    )


def _target_delivery_id(dispatch_id: str, target_thread_id: str) -> str:
    identity = "|".join(
        (TARGET_DELIVERY_PROTOCOL, dispatch_id, target_thread_id),
    )
    return sha256(identity.encode()).hexdigest()


def _parse_target_receipt(raw: str) -> dict[str, object]:
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ReceiptIntegrityError("relay_dispatch_ack_missing") from exc
    required = {
        "protocol", "dispatch_id", "target_thread_id", "target_delivery_id",
    }
    if not isinstance(payload, dict) or set(payload) != required:
        raise ReceiptIntegrityError("relay_dispatch_ack_missing")
    if payload.get("protocol") != TARGET_DELIVERY_PROTOCOL:
        raise ReceiptIntegrityError("relay_dispatch_ack_missing")
    return payload


def _required_string(payload: dict[str, object], key: str) -> str:
    value = payload.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ReceiptIntegrityError("relay_dispatch_ack_missing")
    return value.strip()
