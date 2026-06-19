"""Orchestrator / Worker 工作汇报生命周期（索引 · 去重 · last_updated）。

纯 stdlib；可被 compliance-check、loop_tick、orchestrator 调用。

用法（仓库根目录）::

    python harness/work_report_lifecycle.py run --apply
    python harness/work_report_lifecycle.py run --dry-run
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

DEFAULT_ORCHESTRATOR_DIR = Path("harness/reports/orchestrator")
DEFAULT_WORKERS_DIR = Path("harness/reports/workers")
DEFAULT_INDEX_PATH = Path("harness/work-reports-index.json")

WORKER_IDS: tuple[str, ...] = (
    "architect",
    "code-reviewer",
    "constitution-guardian",
    "critic",
    "debugger",
    "designer",
    "executor",
    "explore",
    "explorer",
    "git-master",
    "governance-coordinator",
    "growth-engineer",
    "planner",
    "qa-tester",
    "researcher",
    "scientist",
    "security-reviewer",
    "test-engineer",
    "tracer",
    "verifier",
    "writer",
)

_FIELD = re.compile(r"^\-\s+\*\*(任务 ID|任务树|动作|涉及文件|验证|状态|更新时间)\*\*：(.+)$", re.MULTILINE)
_TICK = re.compile(r"^## Tick\s+(.+)$", re.MULTILINE)


@dataclass(slots=True)
class WorkReportRecord:
    report_id: str
    worker_id: str
    task_id: str = ""
    tree: str = ""
    action: str = ""
    files: list[str] = field(default_factory=list)
    verification: str = ""
    status: str = "pending"  # pending | assigned | in_progress | done | blocked
    last_updated_at: str = ""
    source_path: str = ""


@dataclass(slots=True)
class WorkReportsIndex:
    version: str = "1.0.0"
    updated_at: str = ""
    orchestrator_path: str = ""
    workers_dir: str = ""
    worker_count: int = 0
    records: dict[str, WorkReportRecord] = field(default_factory=dict)
    last_lifecycle: dict[str, Any] = field(default_factory=dict)


def _now_iso() -> str:
    return datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _parse_files(raw: str) -> list[str]:
    text = str(raw or "").strip()
    if not text or text in {"—", "-", "无"}:
        return []
    return [part.strip() for part in re.split(r"[;；,，]", text) if part.strip()]


def parse_report_markdown(text: str, *, worker_id: str, source_path: str) -> WorkReportRecord | None:
    tick_match = _TICK.search(text)
    report_id = tick_match.group(1).strip() if tick_match else f"{worker_id}-latest"

    fields: dict[str, str] = {}
    for match in _FIELD.finditer(text):
        fields[match.group(1)] = match.group(2).strip()

    if not fields and worker_id == "orchestrator":
        return WorkReportRecord(
            report_id=report_id,
            worker_id=worker_id,
            source_path=source_path,
            last_updated_at=_now_iso(),
            status="pending",
        )

    return WorkReportRecord(
        report_id=report_id,
        worker_id=worker_id,
        task_id=fields.get("任务 ID", ""),
        tree=fields.get("任务树", ""),
        action=fields.get("动作", ""),
        files=_parse_files(fields.get("涉及文件", "")),
        verification=fields.get("验证", ""),
        status=fields.get("状态", "pending") or "pending",
        last_updated_at=fields.get("更新时间", "") or _now_iso(),
        source_path=source_path,
    )


def dedupe_records(records: dict[str, WorkReportRecord]) -> list[dict[str, Any]]:
    """同 worker_id + task_id 保留 last_updated_at 最新者。"""
    actions: list[dict[str, Any]] = []
    groups: dict[tuple[str, str], list[WorkReportRecord]] = {}
    for record in records.values():
        key = (record.worker_id, record.task_id or record.report_id)
        groups.setdefault(key, []).append(record)

    keep_ids: set[str] = set()
    for key, group in groups.items():
        ordered = sorted(group, key=lambda item: item.last_updated_at or "")
        keeper = ordered[-1]
        keep_ids.add(f"{keeper.worker_id}:{keeper.report_id}")
        for dup in ordered[:-1]:
            actions.append(
                {
                    "action": "dedupe",
                    "worker_id": key[0],
                    "from": dup.report_id,
                    "to": keeper.report_id,
                }
            )

    drop_keys = [k for k, rec in records.items() if f"{rec.worker_id}:{rec.report_id}" not in keep_ids]
    for key in drop_keys:
        del records[key]
    return actions


def render_orchestrator_template(*, tick_id: str, action: str, tree: str) -> str:
    return "\n".join(
        [
            f"# Orchestrator 工作汇报 · {tick_id}",
            "",
            f"更新时间：{_now_iso()}",
            "",
            "## Tick orchestrator",
            "",
            "- **任务 ID**：",
            f"- **任务树**：{tree}",
            f"- **动作**：{action}",
            "- **涉及文件**：",
            "- **验证**：",
            "- **状态**：in_progress",
            f"- **更新时间**：{_now_iso()}",
            "",
            "## 委派记录",
            "",
            "| worker | task_id | status |",
            "|--------|---------|--------|",
            "",
            "## 同步真源",
            "",
            "- TASK_TREES.md",
            "- PROJECT_STATUS.md §5",
            "- CONTINUATION_PROMPT.md",
            "- METHODOLOGY_MEMORY.md",
            "- WORKFLOWS.md",
            "- loop-state.json",
            "- harness/reports/workers/*.md",
            "",
        ]
    )


def render_worker_template(*, worker_id: str) -> str:
    return "\n".join(
        [
            f"# Worker 工作汇报 · {worker_id}",
            "",
            f"更新时间：{_now_iso()}",
            "",
            f"## Tick {worker_id}-idle",
            "",
            "- **任务 ID**：",
            "- **任务树**：",
            "- **动作**：待委派",
            "- **涉及文件**：",
            "- **验证**：",
            "- **状态**：pending",
            f"- **更新时间**：{_now_iso()}",
            "",
            "> 被委派切片时更新本节；同步 TASK_TREES + §5 + CONTINUATION + METHODOLOGY + WORKFLOWS + loop-state + 本报告。",
            "",
        ]
    )


def ensure_report_scaffold(
    repo_root: Path,
    *,
    orchestrator_dir: Path,
    workers_dir: Path,
    apply: bool,
    tick_id: str = "",
    action: str = "",
    tree: str = "",
) -> list[str]:
    created: list[str] = []
    orch_dir = repo_root / orchestrator_dir
    worker_root = repo_root / workers_dir

    if apply:
        orch_dir.mkdir(parents=True, exist_ok=True)
        worker_root.mkdir(parents=True, exist_ok=True)

        latest = orch_dir / "latest.md"
        if not latest.is_file():
            latest.write_text(
                render_orchestrator_template(
                    tick_id=tick_id or "bootstrap",
                    action=action or "初始化 orchestrator 汇报",
                    tree=tree or "PL-C-GEN",
                ),
                encoding="utf-8",
            )
            created.append(str(latest.relative_to(repo_root)))

        index_path = orch_dir / "index.json"
        if not index_path.is_file():
            index_path.write_text(
                json.dumps({"version": "1.0.0", "updated_at": _now_iso(), "ticks": []}, ensure_ascii=False, indent=2)
                + "\n",
                encoding="utf-8",
            )
            created.append(str(index_path.relative_to(repo_root)))

        for worker_id in WORKER_IDS:
            worker_path = worker_root / f"{worker_id}.md"
            if not worker_path.is_file():
                worker_path.write_text(render_worker_template(worker_id=worker_id), encoding="utf-8")
                created.append(str(worker_path.relative_to(repo_root)))

    return created


def collect_records(repo_root: Path, *, orchestrator_dir: Path, workers_dir: Path) -> dict[str, WorkReportRecord]:
    records: dict[str, WorkReportRecord] = {}

    orch_latest = repo_root / orchestrator_dir / "latest.md"
    if orch_latest.is_file():
        parsed = parse_report_markdown(
            orch_latest.read_text(encoding="utf-8"),
            worker_id="orchestrator",
            source_path=str(orch_latest.relative_to(repo_root)),
        )
        if parsed is not None:
            records[f"orchestrator:{parsed.report_id}"] = parsed

    workers_root = repo_root / workers_dir
    if workers_root.is_dir():
        for worker_id in WORKER_IDS:
            path = workers_root / f"{worker_id}.md"
            if not path.is_file():
                continue
            parsed = parse_report_markdown(
                path.read_text(encoding="utf-8"),
                worker_id=worker_id,
                source_path=str(path.relative_to(repo_root)),
            )
            if parsed is not None:
                records[f"{worker_id}:{parsed.report_id}"] = parsed

    return records


def load_index(path: Path) -> WorkReportsIndex:
    if not path.is_file():
        return WorkReportsIndex()
    payload = json.loads(path.read_text(encoding="utf-8"))
    records = {
        k: WorkReportRecord(**v)
        for k, v in dict(payload.get("records") or {}).items()
        if isinstance(v, dict)
    }
    return WorkReportsIndex(
        version=str(payload.get("version") or "1.0.0"),
        updated_at=str(payload.get("updated_at") or ""),
        orchestrator_path=str(payload.get("orchestrator_path") or ""),
        workers_dir=str(payload.get("workers_dir") or ""),
        worker_count=int(payload.get("worker_count") or 0),
        records=records,
        last_lifecycle=dict(payload.get("last_lifecycle") or {}),
    )


def save_index(path: Path, index: WorkReportsIndex) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "version": index.version,
        "updated_at": index.updated_at,
        "orchestrator_path": index.orchestrator_path,
        "workers_dir": index.workers_dir,
        "worker_count": index.worker_count,
        "records": {k: asdict(v) for k, v in index.records.items()},
        "last_lifecycle": index.last_lifecycle,
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def run_lifecycle(
    *,
    repo_root: Path,
    orchestrator_dir: Path,
    workers_dir: Path,
    index_path: Path,
    apply: bool,
    tick_id: str = "",
    action: str = "",
    tree: str = "",
) -> dict[str, Any]:
    created = ensure_report_scaffold(
        repo_root,
        orchestrator_dir=orchestrator_dir,
        workers_dir=workers_dir,
        apply=apply,
        tick_id=tick_id,
        action=action,
        tree=tree,
    )
    records = collect_records(repo_root, orchestrator_dir=orchestrator_dir, workers_dir=workers_dir)
    dedupe_actions = dedupe_records(records)

    index = WorkReportsIndex(
        updated_at=_now_iso(),
        orchestrator_path=str(orchestrator_dir.as_posix()),
        workers_dir=str(workers_dir.as_posix()),
        worker_count=len(WORKER_IDS),
        records=records,
        last_lifecycle={
            "at": _now_iso(),
            "apply": apply,
            "dedupe_actions": len(dedupe_actions),
            "record_count": len(records),
            "created": created,
        },
    )
    if apply:
        save_index(repo_root / index_path, index)

    return {
        "apply": apply,
        "dedupe_actions": dedupe_actions,
        "record_count": len(records),
        "created": created,
        "worker_ids": list(WORKER_IDS),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Work report lifecycle")
    parser.add_argument("command", choices=["run", "index-only"], nargs="?", default="run")
    parser.add_argument("--repo-root", type=Path, default=Path("."))
    parser.add_argument("--orchestrator-dir", type=Path, default=DEFAULT_ORCHESTRATOR_DIR)
    parser.add_argument("--workers-dir", type=Path, default=DEFAULT_WORKERS_DIR)
    parser.add_argument("--index", type=Path, default=DEFAULT_INDEX_PATH)
    parser.add_argument("--tick-id", default="")
    parser.add_argument("--action", default="")
    parser.add_argument("--tree", default="")
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    apply = bool(args.apply) and not args.dry_run
    result = run_lifecycle(
        repo_root=args.repo_root.resolve(),
        orchestrator_dir=args.orchestrator_dir,
        workers_dir=args.workers_dir,
        index_path=args.index,
        apply=apply,
        tick_id=args.tick_id,
        action=args.action,
        tree=args.tree,
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
