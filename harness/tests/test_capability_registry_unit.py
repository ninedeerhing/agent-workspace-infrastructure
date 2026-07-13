import json
from pathlib import Path


REGISTRY_PATH = Path(__file__).resolve().parents[1] / "capability-registry.json"
AGENT_REGISTRY_PATH = Path(__file__).resolve().parents[1] / "agent-registry.json"


def test_capability_registry_separates_mandatory_chain_from_extensible_capabilities() -> None:
    registry = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))

    assert registry["mandatory_phase_chain"] == [
        "Executor", "Test", "Review", "Verifier", "Sync",
    ]
    assert registry["proposal_lifecycle"] == [
        "proposed", "user_approved", "registered", "routable",
    ]
    assert registry["dispatch_policy"]["hard_worker_count_limit"] is None
    assert registry["dispatch_policy"]["new_worker_or_skill_requires_user_approval"] is True
    assert registry["dispatch_policy"]["model_override_allowed"] is False


def test_capability_registry_has_unique_routable_canonical_threads() -> None:
    registry = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
    capabilities = registry["capabilities"]
    ids = [row["capability_id"] for row in capabilities]
    threads = [row["canonical_thread_id"] for row in capabilities]

    assert len(ids) == len(set(ids))
    assert len(threads) == len(set(threads))
    assert all(row["state"] == "routable" for row in capabilities)
    assert all(row["responsibility"] for row in capabilities)
    assert all(row["adjacent_boundary"] for row in capabilities)


def test_report_relay_is_registered_as_one_permanent_non_user_facing_worker() -> None:
    registry = json.loads(AGENT_REGISTRY_PATH.read_text(encoding="utf-8"))
    relays = [row for row in registry["roles"] if row["role_id"] == "report-relay"]

    assert len(relays) == 1
    assert relays[0]["enabled"] is True
    assert relays[0]["user_facing"] is False
    assert relays[0]["model"] is None
    assert relays[0]["platform_binding"]["session_id"] == (
        "019f59d6-f86d-75d3-9266-082079e31d71"
    )
    assert registry["role_count"] == len(registry["roles"])
    assert registry["worker_count"] == sum(
        row["kind"] == "worker" for row in registry["roles"]
    )
