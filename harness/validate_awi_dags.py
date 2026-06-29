#!/usr/bin/env python3
"""Validate AWI Capability DAG and Runtime Task DAG contracts.

This validator intentionally uses only the Python standard library so it can run
inside CodeX self-check without installing project dependencies.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any


@dataclass
class Report:
    checks: list[dict[str, str]] = field(default_factory=list)
    findings: list[dict[str, str]] = field(default_factory=list)

    def check(self, name: str, status: str, detail: str) -> None:
        self.checks.append({"name": name, "status": status, "detail": detail})

    def finding(self, code: str, severity: str, title: str, detail: str) -> None:
        self.findings.append(
            {"code": code, "severity": severity, "title": title, "detail": detail}
        )


def load_json(path: Path, report: Report) -> Any | None:
    if not path.exists():
        report.check(f"file:{path.name}", "FAIL", "missing")
        report.finding("DAG-FILE-MISSING", "error", "Required DAG file missing", str(path))
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # pragma: no cover - exercised by CLI safety
        report.check(f"json:{path.name}", "FAIL", str(exc))
        report.finding("DAG-JSON", "error", "DAG JSON parse failed", f"{path}: {exc}")
        return None
    report.check(f"json:{path.name}", "PASS", "parse ok")
    return data


def require_keys(obj: dict[str, Any], keys: list[str], label: str, report: Report) -> None:
    for key in keys:
        if key not in obj:
            report.finding("DAG-REQUIRED", "error", "Required key missing", f"{label}.{key}")


def validate_capability_dag(data: dict[str, Any], report: Report) -> tuple[set[str], set[str]]:
    require_keys(
        data,
        ["schema_version", "capabilities", "phase_bundles", "active", "selection_policy"],
        "capability_dag",
        report,
    )
    capabilities = data.get("capabilities", [])
    phase_bundles = data.get("phase_bundles", [])
    cap_ids: set[str] = set()
    phase_ids: set[str] = set()

    for cap in capabilities:
        cap_id = str(cap.get("id", ""))
        if not cap_id:
            report.finding("CAP-ID", "error", "Capability id missing", repr(cap))
            continue
        if cap_id in cap_ids:
            report.finding("CAP-DUP", "error", "Duplicate capability id", cap_id)
        cap_ids.add(cap_id)

    for cap in capabilities:
        cap_id = str(cap.get("id", ""))
        for dep in cap.get("depends_on", []):
            if dep not in cap_ids:
                report.finding("CAP-MISSING-DEP", "error", "Capability dependency missing", f"{cap_id} -> {dep}")

    for bundle in phase_bundles:
        bundle_id = str(bundle.get("id", ""))
        capability_id = str(bundle.get("capability_id", ""))
        if not bundle_id:
            report.finding("BUNDLE-ID", "error", "Phase bundle id missing", repr(bundle))
            continue
        if bundle_id in phase_ids:
            report.finding("BUNDLE-DUP", "error", "Duplicate phase bundle id", bundle_id)
        phase_ids.add(bundle_id)
        if capability_id not in cap_ids:
            report.finding("BUNDLE-CAP", "error", "Phase bundle capability missing", f"{bundle_id} -> {capability_id}")
        items = bundle.get("items", [])
        if not (3 <= len(items) <= 7):
            report.finding("BUNDLE-SIZE", "error", "Phase bundle item count outside 3-7", f"{bundle_id}: {len(items)}")
        if not str(bundle.get("core_artifact", "")).strip():
            report.finding("BUNDLE-CORE", "error", "Phase bundle lacks core artifact", bundle_id)
        if not bundle.get("acceptance"):
            report.finding("BUNDLE-ACCEPT", "error", "Phase bundle lacks acceptance evidence", bundle_id)

    active = data.get("active", {})
    for key in ("awi_capability_id", "product_capability_id"):
        value = active.get(key)
        if value and value not in cap_ids:
            report.finding("ACTIVE-CAP", "error", "Active capability id missing", f"{key}={value}")
    for key in ("awi_phase_bundle_id", "product_phase_bundle_id"):
        value = active.get(key)
        if value and value not in phase_ids:
            report.finding("ACTIVE-BUNDLE", "error", "Active phase bundle id missing", f"{key}={value}")

    if data.get("selection_policy", {}).get("loop_must_select_phase_bundle") is not True:
        report.finding("POLICY-BUNDLE", "error", "Selection policy must require phase bundle", "loop_must_select_phase_bundle")
    if data.get("selection_policy", {}).get("no_free_floating_micro_tasks") is not True:
        report.finding("POLICY-MICRO", "error", "Selection policy must reject free-floating micro tasks", "no_free_floating_micro_tasks")

    report.check("capability-dag invariants", "PASS" if not report.findings else "CHECKED", f"capabilities={len(cap_ids)} bundles={len(phase_ids)}")
    return cap_ids, phase_ids


def _reachable(start: str, target: str, edges: dict[str, list[str]], seen: set[str] | None = None) -> bool:
    seen = seen or set()
    if start == target:
        return True
    if start in seen:
        return False
    seen.add(start)
    return any(_reachable(child, target, edges, seen) for child in edges.get(start, []))


def validate_runtime_dag(data: dict[str, Any], cap_ids: set[str], phase_ids: set[str], report: Report, label: str = "runtime") -> None:
    require_keys(data, ["dag_id", "goal_id", "phase_bundle_id", "nodes", "edges", "validation_rules", "fallback"], label, report)
    goal_id = str(data.get("goal_id", ""))
    phase_bundle_id = str(data.get("phase_bundle_id", ""))
    if goal_id not in cap_ids:
        report.finding("RUNTIME-GOAL", "error", "Runtime DAG goal_id must link to Capability DAG", f"{label}: {goal_id}")
    if phase_bundle_id not in phase_ids:
        report.finding("RUNTIME-BUNDLE", "error", "Runtime DAG phase_bundle_id must link to Capability DAG", f"{label}: {phase_bundle_id}")

    nodes = data.get("nodes", [])
    node_ids: set[str] = set()
    graph: dict[str, list[str]] = {}
    for node in nodes:
        node_id = str(node.get("id", ""))
        if not node_id:
            report.finding("NODE-ID", "error", "Runtime node id missing", label)
            continue
        if node_id in node_ids:
            report.finding("NODE-DUP", "error", "Duplicate runtime node id", f"{label}: {node_id}")
        node_ids.add(node_id)
        graph.setdefault(node_id, [])

    for node in nodes:
        node_id = str(node.get("id", ""))
        for dep in node.get("depends_on", []):
            if dep not in node_ids:
                report.finding("NODE-MISSING-DEP", "error", "Runtime node dependency missing", f"{label}: {node_id} depends_on {dep}")
            else:
                graph.setdefault(dep, []).append(node_id)
        if node.get("kind") in {"worker", "tool"} and not node.get("owner"):
            report.finding("NODE-OWNER", "error", "Worker/tool node lacks owner", f"{label}: {node_id}")
        if not node.get("outputs"):
            report.finding("NODE-OUTPUT", "error", "Runtime node lacks outputs", f"{label}: {node_id}")
        if "write_scope" not in node:
            report.finding("NODE-WRITE-SCOPE", "error", "Runtime node lacks write_scope", f"{label}: {node_id}")

    for edge in data.get("edges", []):
        source = edge.get("from")
        target = edge.get("to")
        if source not in node_ids or target not in node_ids:
            report.finding("EDGE-REF", "error", "Runtime edge references missing node", f"{label}: {source}->{target}")

    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(node_id: str) -> bool:
        if node_id in visiting:
            return True
        if node_id in visited:
            return False
        visiting.add(node_id)
        for child in graph.get(node_id, []):
            if visit(child):
                return True
        visiting.remove(node_id)
        visited.add(node_id)
        return False

    if any(visit(node_id) for node_id in list(node_ids)):
        report.finding("DAG-CYCLE", "error", "Runtime DAG contains a cycle", label)

    for race_group in data.get("race_groups", []):
        race_id = race_group.get("id", "<missing>")
        members = race_group.get("nodes", [])
        if len(members) != len(set(members)):
            report.finding("RACE-DUP", "error", "Race group has duplicate members", f"{label}: {race_id}")
        for member in members:
            if member not in node_ids:
                report.finding("RACE-REF", "error", "Race group references missing node", f"{label}: {race_id}->{member}")
        if race_group.get("winner_policy") == "first_success" and race_group.get("cancel_losers") is not True:
            report.finding("RACE-CANCEL", "error", "first_success race groups must cancel losers", f"{label}: {race_id}")

    if not any(node.get("kind") in {"aggregation", "handoff"} for node in nodes):
        report.finding("DAG-AGG", "error", "Runtime DAG must include aggregation or handoff node", label)

    fallback = data.get("fallback", {})
    for key in ("on_invalid_graph", "on_worker_unavailable", "on_verification_failure"):
        if not fallback.get(key):
            report.finding("DAG-FALLBACK", "error", "Runtime DAG fallback missing", f"{label}.{key}")

    write_nodes = [node for node in nodes if node.get("write_scope")]
    for i, left in enumerate(write_nodes):
        for right in write_nodes[i + 1 :]:
            left_id = left["id"]
            right_id = right["id"]
            if _reachable(left_id, right_id, graph) or _reachable(right_id, left_id, graph):
                continue
            overlap = set(left.get("write_scope", [])) & set(right.get("write_scope", []))
            if overlap:
                report.finding("WRITE-CONFLICT", "error", "Parallel write_scope conflict", f"{label}: {left_id}/{right_id}: {sorted(overlap)}")

    report.check(f"runtime-dag invariants:{label}", "PASS", f"nodes={len(node_ids)}")


def validate_repo(repo_root: Path) -> Report:
    report = Report()
    harness = repo_root / "harness"
    for required in (
        harness / "capability-dag.json",
        harness / "capability-dag.schema.json",
        harness / "runtime-task-dag.schema.json",
    ):
        load_json(required, report)

    capability_data = load_json(harness / "capability-dag.json", report)
    if not isinstance(capability_data, dict):
        return report
    cap_ids, phase_ids = validate_capability_dag(capability_data, report)

    runtime_dir = harness / "runtime-task-dags"
    runtime_files = sorted(runtime_dir.glob("*.json")) if runtime_dir.exists() else []
    if not runtime_files:
        report.finding("RUNTIME-NONE", "error", "No runtime task DAG examples found", str(runtime_dir))
    for runtime_file in runtime_files:
        runtime_data = load_json(runtime_file, report)
        if isinstance(runtime_data, dict):
            validate_runtime_dag(runtime_data, cap_ids, phase_ids, report, runtime_file.name)

    return report


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate AWI DAG contracts")
    parser.add_argument("--repo-root", default=".")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = validate_repo(Path(args.repo_root).resolve())
    payload = {
        "summary": {
            "checks": len(report.checks),
            "findings": len(report.findings),
            "pass": sum(1 for check in report.checks if check["status"] == "PASS"),
        },
        "checks": report.checks,
        "findings": report.findings,
    }
    if args.json:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    else:
        for check in report.checks:
            print(f"[{check['status']}] {check['name']} - {check['detail']}")
        for finding in report.findings:
            print(f"[{finding['severity']}] {finding['code']}: {finding['title']} - {finding['detail']}")
    return 1 if report.findings else 0


if __name__ == "__main__":
    raise SystemExit(main())