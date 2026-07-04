from __future__ import annotations

from harness.loop_tick import should_stop


def test_should_stop_ignores_closed_closure_gate_when_next_action_exists() -> None:
    state = {
        "stop_reason": "",
        "next_atomic_action": "NEXT_CORE_LOOP",
        "closure_gate": {"status": "closed"},
    }

    stopped, reason = should_stop(state)

    assert stopped is False
    assert reason == ""


def test_should_stop_allows_explicit_stop_reason() -> None:
    state = {
        "stop_reason": "FORMAL_HUMAN_REVIEW_REQUIRED",
        "next_atomic_action": "NEXT_CORE_LOOP",
        "closure_gate": {"status": "closed"},
    }

    stopped, reason = should_stop(state)

    assert stopped is True
    assert reason == "stop_reason=FORMAL_HUMAN_REVIEW_REQUIRED"


def test_should_stop_allows_closed_closure_gate_without_next_action() -> None:
    state = {
        "stop_reason": "",
        "next_atomic_action": "",
        "closure_gate": {"status": "closed"},
    }

    stopped, reason = should_stop(state)

    assert stopped is True
    assert reason == "closure_gate=closed"
