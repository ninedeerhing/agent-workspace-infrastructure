from __future__ import annotations

import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "harness"))

import validate_awi_dags as dag_validator  # noqa: E402


def _base_runtime_dag():
    return {
        "schema_version": "1.0.0",
        "dag_id": "test-dag",
        "goal_id": "CAP-1",
        "phase_bundle_id": "BUNDLE-1",
        "created_at": "2026-06-29T00:00:00+08:00",
        "nodes": [
            {
                "id": "plan",
                "kind": "plan",
                "owner": "planner",
                "task": "plan",
                "depends_on": [],
                "write_scope": [],
                "outputs": ["loop_plan"],
                "status": "planned",
            },
            {
                "id": "aggregate",
                "kind": "aggregation",
                "owner": "orchestrator",
                "task": "aggregate",
                "depends_on": ["plan"],
                "write_scope": [],
                "outputs": ["integrated_report"],
                "status": "planned",
            },
        ],
        "edges": [{"from": "plan", "to": "aggregate", "type": "feeds"}],
        "race_groups": [],
        "validation_rules": ["all depends_on references must point to existing nodes"],
        "fallback": {
            "on_invalid_graph": "fail_closed_to_planner_replan",
            "on_worker_unavailable": "mark_channel_stale",
            "on_verification_failure": "return_to_executor_or_block_with_report",
        },
    }


def test_repo_awi_dags_are_valid():
    report = dag_validator.validate_repo(REPO_ROOT)
    assert report.findings == []


def test_runtime_dag_rejects_missing_dependency():
    dag = _base_runtime_dag()
    dag["nodes"][0]["depends_on"] = ["missing"]
    report = dag_validator.Report()
    dag_validator.validate_runtime_dag(dag, {"CAP-1"}, {"BUNDLE-1"}, report, "missing-dep")
    assert any(finding["code"] == "NODE-MISSING-DEP" for finding in report.findings)


def test_runtime_dag_rejects_cycle():
    dag = _base_runtime_dag()
    dag["nodes"][0]["depends_on"] = ["aggregate"]
    report = dag_validator.Report()
    dag_validator.validate_runtime_dag(dag, {"CAP-1"}, {"BUNDLE-1"}, report, "cycle")
    assert any(finding["code"] == "DAG-CYCLE" for finding in report.findings)


def test_runtime_dag_rejects_invalid_race_group():
    dag = _base_runtime_dag()
    dag["race_groups"] = [
        {"id": "race", "nodes": ["plan", "missing"], "winner_policy": "first_success", "cancel_losers": False}
    ]
    report = dag_validator.Report()
    dag_validator.validate_runtime_dag(dag, {"CAP-1"}, {"BUNDLE-1"}, report, "race")
    codes = {finding["code"] for finding in report.findings}
    assert {"RACE-REF", "RACE-CANCEL"}.issubset(codes)