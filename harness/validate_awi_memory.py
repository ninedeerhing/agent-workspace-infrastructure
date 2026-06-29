#!/usr/bin/env python3
"""Validate AWI Memory OS contracts.

The validator intentionally uses only the Python standard library so it can run
inside CodeX self-check without project dependencies.
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
        report.finding("MEM-FILE-MISSING", "error", "Required Memory OS file missing", str(path))
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # pragma: no cover - CLI safety
        report.check(f"json:{path.name}", "FAIL", str(exc))
        report.finding("MEM-JSON", "error", "Memory OS JSON parse failed", f"{path}: {exc}")
        return None
    report.check(f"json:{path.name}", "PASS", "parse ok")
    return data


def validate_memory_os(data: dict[str, Any], schema: dict[str, Any], source_ids: set[str], report: Report) -> None:
    for key in schema.get("required", []):
        if key not in data:
            report.finding("MEM-REQUIRED", "error", "Required key missing", f"memory-os.{key}")

    allowed_slot_types = set(schema.get("slot_types", []))
    required_slot_types = set(schema.get("required_slot_types", []))
    slots = data.get("slots", [])
    slot_ids: set[str] = set()
    slot_types: set[str] = set()

    for slot in slots:
        slot_id = str(slot.get("id", ""))
        slot_type = str(slot.get("slot_type", ""))
        if not slot_id:
            report.finding("MEM-SLOT-ID", "error", "Memory slot id missing", repr(slot))
            continue
        if slot_id in slot_ids:
            report.finding("MEM-SLOT-DUP", "error", "Duplicate memory slot id", slot_id)
        slot_ids.add(slot_id)
        slot_types.add(slot_type)
        if slot_type not in allowed_slot_types:
            report.finding("MEM-SLOT-TYPE", "error", "Unknown memory slot type", f"{slot_id}: {slot_type}")
        for key in ("owner", "summary", "store_path", "latest_ref", "source_refs", "promotion_target"):
            if key not in slot or slot.get(key) in ("", [], None):
                report.finding("MEM-SLOT-KEY", "error", "Memory slot required field missing", f"{slot_id}.{key}")
        store_path = str(slot.get("store_path", ""))
        if ".env" in store_path.lower() or "secret" in store_path.lower():
            report.finding("MEM-SECRET-PATH", "error", "Memory slot points at forbidden secret-like path", f"{slot_id}: {store_path}")
        for source_ref in slot.get("source_refs", []):
            if source_ref not in source_ids:
                report.finding("MEM-SOURCE-REF", "error", "Memory slot references unknown source id", f"{slot_id}: {source_ref}")

    missing_slot_types = required_slot_types - slot_types
    if missing_slot_types:
        report.finding("MEM-REQUIRED-SLOT-TYPE", "error", "Required memory slot type missing", ", ".join(sorted(missing_slot_types)))

    load_policy = data.get("load_policy", {})
    if load_policy.get("default_mode") != "hot_path_light":
        report.finding("MEM-HOT-PATH", "error", "Memory OS must default to hot_path_light", str(load_policy.get("default_mode")))
    if int(load_policy.get("hot_path_max_slots", 999)) > 5:
        report.finding("MEM-HOT-PATH", "error", "hot_path_max_slots must stay <= 5", str(load_policy.get("hot_path_max_slots")))
    if load_policy.get("external_content_is_data") is not True:
        report.finding("MEM-PROMPT-DEFENSE", "error", "Memory OS must mark external content as data", "external_content_is_data")
    if load_policy.get("secret_policy") != "never_copy_or_print_secrets":
        report.finding("MEM-SECRET-POLICY", "error", "Memory OS secret policy must be explicit", str(load_policy.get("secret_policy")))

    promotion_rules = data.get("promotion_rules", [])
    for rule in promotion_rules:
        rule_id = str(rule.get("id", ""))
        if rule.get("from_slot_type") not in allowed_slot_types or rule.get("to_slot_type") not in allowed_slot_types:
            report.finding("MEM-PROMOTION-TYPE", "error", "Promotion rule references unknown slot type", rule_id)
        if not rule.get("trigger"):
            report.finding("MEM-PROMOTION-TRIGGER", "error", "Promotion rule lacks trigger", rule_id)
        if not rule.get("required_evidence"):
            report.finding("MEM-PROMOTION-EVIDENCE", "error", "Promotion rule lacks required evidence", rule_id)

    retrieval_policy = data.get("retrieval_policy", {})
    if retrieval_policy.get("source_index_required") is not True:
        report.finding("MEM-RETRIEVAL-SOURCE", "error", "Retrieval must require source-index backed refs", "source_index_required")
    graph_recall = retrieval_policy.get("graph_recall", {})
    if graph_recall.get("enabled") is not True:
        report.finding("MEM-GRAPH", "error", "Graph recall must be explicitly enabled", "graph_recall.enabled")
    if int(graph_recall.get("max_hops", 99)) > 1:
        report.finding("MEM-GRAPH", "error", "Graph recall max_hops must stay <= 1 for context control", str(graph_recall.get("max_hops")))

    lifecycle_policy = data.get("lifecycle_policy", {})
    if int(lifecycle_policy.get("promotion_count_threshold", 0)) < 3:
        report.finding("MEM-LIFECYCLE", "error", "Promotion count threshold must be >= 3", str(lifecycle_policy.get("promotion_count_threshold")))
    for required in ("truth_source_update", "verification_evidence", "clean_worktree"):
        if required not in lifecycle_policy.get("completion_requires", []):
            report.finding("MEM-COMPLETION", "error", "Completion requirement missing", required)

    status = "PASS" if not report.findings else "CHECKED"
    report.check(
        "memory-os invariants",
        status,
        f"slots={len(slot_ids)} slot_types={len(slot_types)} promotion_rules={len(promotion_rules)}",
    )


def validate_repo(repo_root: Path) -> Report:
    report = Report()
    harness = repo_root / "harness"
    schema = load_json(harness / "memory-os.schema.json", report)
    memory_os = load_json(harness / "memory-os.json", report)
    source_index = load_json(harness / "source-index.json", report)
    if not isinstance(schema, dict) or not isinstance(memory_os, dict) or not isinstance(source_index, dict):
        return report
    source_ids = {str(source.get("id", "")) for source in source_index.get("sources", [])}
    validate_memory_os(memory_os, schema, source_ids, report)
    return report


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate AWI Memory OS contracts")
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
