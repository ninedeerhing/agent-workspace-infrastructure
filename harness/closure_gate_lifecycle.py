"""收口门控 · 检测关键任务 done 但缺 synthesis。

解析 TASK_TREES / loop-state / §5 与 METHODOLOGY_MEMORY 的 synthesis/M-xx/GP-xx。
纯 stdlib；`run --apply` 仅写索引。

用法（仓库根目录）::

    python harness/closure_gate_lifecycle.py run --apply
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

DEFAULT_LOOP_STATE = Path("harness/loop-state.json")
DEFAULT_TASK_TREES = Path("apps/quant_assistant/docs/TASK_TREES.md")
DEFAULT_PROJECT_STATUS = Path("apps/quant_assistant/docs/PROJECT_STATUS.md")
DEFAULT_METHODOLOGY = Path("apps/quant_assistant/docs/METHODOLOGY_MEMORY.md")
DEFAULT_INDEX_PATH = Path("harness/closure-gate-index.json")

_DONE_LINE = re.compile(r"^\d+\.\s+~~.+?~~\s*✅", re.MULTILINE)
_DONE_INLINE = re.compile(r"✅\s*loop\d+", re.IGNORECASE)
_SLICE_DONE = re.compile(r"(MINE-\d+|R0-M\d+|R1-M\d+|R2-M\d+|BENCH-\d+|KB-M\d+)", re.IGNORECASE)
_SECTION5 = re.compile(r"^### (5\.\d+)\s+(.+)$", re.MULTILINE)
_SYNTHESIS = re.compile(r"^## 收口 synthesis-([^\s]+)(?:\s*·\s*(.+))?$", re.MULTILINE)
_SYNTHESIS_STATUS = re.compile(r">\s*\*\*状态\*\*：(closed|open|没有)", re.IGNORECASE)
_M_GP_FROM_SYNTH = re.compile(r"### (M-\d+|GP-\d+)\s*[·\-]", re.MULTILINE)


@dataclass(slots=True)
class ClosureCandidate:
    task_ref: str
    source: str
    has_synthesis: bool = False
    synthesis_id: str = ""
    has_permanent_entry: bool = False
    permanent_ids: list[str] = field(default_factory=list)
    recommendation: str = "synthesize_closure_or_explicit_none"


@dataclass(slots=True)
class ClosureGateIndex:
    version: str = "1.0.0"
    updated_at: str = ""
    candidates: list[ClosureCandidate] = field(default_factory=list)
    open_count: int = 0
    closed_count: int = 0
    explicit_none_count: int = 0
    findings: list[dict[str, Any]] = field(default_factory=list)
    last_lifecycle: dict[str, Any] = field(default_factory=dict)


def _now_iso() -> str:
    return datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _extract_done_tasks_from_trees(text: str) -> list[str]:
    tasks: list[str] = []
    for line in text.splitlines():
        if "~~" in line and "✅" in line:
            for m in _SLICE_DONE.finditer(line):
                tasks.append(m.group(1).upper().replace("MINE", "MINE"))
    return list(dict.fromkeys(tasks))


def _extract_done_from_loop(loop_state: dict[str, Any]) -> list[str]:
    hints: list[str] = []
    for key in ("last_completed_note", "current_slice", "last_tick"):
        val = str(loop_state.get(key) or "")
        for m in _SLICE_DONE.finditer(val):
            hints.append(m.group(1))
    return list(dict.fromkeys(hints))


def _extract_recent_done_from_section5(text: str, limit: int = 8) -> list[str]:
    tasks: list[str] = []
    for match in _SECTION5.finditer(text):
        title = match.group(2)
        if any(tok in title.casefold() for tok in ("done", "pass", "验收", "stub", "修复")):
            for m in _SLICE_DONE.finditer(title):
                tasks.append(m.group(1))
        if len(tasks) >= limit:
            break
    return list(dict.fromkeys(tasks))


def _parse_synthesis_map(text: str) -> dict[str, dict[str, Any]]:
    result: dict[str, dict[str, Any]] = {}
    for match in _SYNTHESIS.finditer(text):
        sid = match.group(1).strip()
        if "{" in sid or "task-slug" in sid.casefold():
            continue
        title = (match.group(2) or "").strip()
        start = match.end()
        nxt = _SYNTHESIS.search(text, start)
        block = text[start : nxt.start() if nxt else len(text)]
        block_head = []
        for line in block.splitlines():
            if line.startswith("## ") and not line.startswith("### "):
                break
            block_head.append(line)
            if len(block_head) >= 50:
                break
        limited = "\n".join(block_head)
        status_m = _SYNTHESIS_STATUS.search(limited)
        status = status_m.group(1).casefold() if status_m else "open"
        permanents = [m.group(1) for m in _M_GP_FROM_SYNTH.finditer(limited)]
        result[sid] = {
            "title": title,
            "status": status,
            "permanent_ids": permanents,
            "block": limited,
        }
    return result


def _task_has_synthesis(task_ref: str, synthesis_map: dict[str, dict[str, Any]]) -> tuple[bool, str, bool, list[str]]:
    key = task_ref.casefold()
    for sid, meta in synthesis_map.items():
        blob = f"{sid} {meta.get('title', '')} {meta.get('block', '')}".casefold()
        if key in blob or key.replace("-", "") in blob.replace("-", ""):
            status = str(meta.get("status") or "")
            permanents = list(meta.get("permanent_ids") or [])
            if status == "没有":
                return True, sid, False, []
            return True, sid, bool(permanents), permanents
    return False, "", False, []


def analyze_closure_gate(
    *,
    loop_state: dict[str, Any],
    task_trees_text: str,
    project_status_text: str,
    methodology_text: str,
) -> ClosureGateIndex:
    synthesis_map = _parse_synthesis_map(methodology_text)
    done_tasks = list(
        dict.fromkeys(
            _extract_done_tasks_from_trees(task_trees_text)
            + _extract_done_from_loop(loop_state)
            + _extract_recent_done_from_section5(project_status_text)
        )
    )

    candidates: list[ClosureCandidate] = []
    findings: list[dict[str, Any]] = []
    open_count = 0
    closed_count = 0
    explicit_none = 0

    for task in done_tasks:
        has_syn, syn_id, has_perm, perm_ids = _task_has_synthesis(task, synthesis_map)
        rec = "ok"
        if not has_syn:
            rec = "synthesize_closure_or_explicit_none"
            open_count += 1
            findings.append(
                {
                    "severity": "warning",
                    "code": "CLO-MISSING-SYNTH",
                    "task_ref": task,
                    "detail": f"task {task} marked done but no synthesis-* section",
                    "recommendation": f"Add ## 收口 synthesis-{task.lower()} or record explicit 没有",
                }
            )
        elif has_syn and not has_perm:
            syn_status = synthesis_map.get(syn_id, {}).get("status", "")
            if syn_status == "没有":
                explicit_none += 1
                rec = "explicit_none"
            else:
                open_count += 1
                rec = "extract_m_or_gp"
                findings.append(
                    {
                        "severity": "info",
                        "code": "CLO-NO-PERMANENT",
                        "task_ref": task,
                        "detail": f"synthesis-{syn_id} closed without M-xx/GP-xx",
                        "recommendation": "Extract permanent entry or mark 状态：没有",
                    }
                )
        else:
            closed_count += 1
            rec = "closed"

        candidates.append(
            ClosureCandidate(
                task_ref=task,
                source="trees|loop|section5",
                has_synthesis=has_syn,
                synthesis_id=syn_id,
                has_permanent_entry=has_perm,
                permanent_ids=perm_ids,
                recommendation=rec,
            )
        )

    return ClosureGateIndex(
        updated_at=_now_iso(),
        candidates=candidates,
        open_count=open_count,
        closed_count=closed_count,
        explicit_none_count=explicit_none,
        findings=findings,
        last_lifecycle={
            "at": _now_iso(),
            "open_count": open_count,
            "closed_count": closed_count,
            "explicit_none_count": explicit_none,
            "candidate_count": len(candidates),
        },
    )


def save_index(path: Path, index: ClosureGateIndex) -> None:
    payload = asdict(index)
    payload["candidates"] = [asdict(c) for c in index.candidates]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def run_lifecycle(*, repo_root: Path, index_path: Path, apply: bool) -> dict[str, Any]:
    loop_path = repo_root / DEFAULT_LOOP_STATE
    trees_path = repo_root / DEFAULT_TASK_TREES
    status_path = repo_root / DEFAULT_PROJECT_STATUS
    mem_path = repo_root / DEFAULT_METHODOLOGY

    for p in (loop_path, trees_path, status_path, mem_path):
        if not p.is_file():
            raise FileNotFoundError(f"missing: {p}")

    loop_state = json.loads(loop_path.read_text(encoding="utf-8"))
    index = analyze_closure_gate(
        loop_state=loop_state,
        task_trees_text=trees_path.read_text(encoding="utf-8"),
        project_status_text=status_path.read_text(encoding="utf-8"),
        methodology_text=mem_path.read_text(encoding="utf-8"),
    )
    if apply:
        save_index(repo_root / index_path, index)

    return {
        "apply": apply,
        "open_count": index.open_count,
        "closed_count": index.closed_count,
        "explicit_none_count": index.explicit_none_count,
        "findings": index.findings,
        "candidates": [asdict(c) for c in index.candidates[:20]],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Closure gate lifecycle")
    parser.add_argument("command", choices=["run"], nargs="?", default="run")
    parser.add_argument("--repo-root", type=Path, default=Path("."))
    parser.add_argument("--index", type=Path, default=DEFAULT_INDEX_PATH)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    apply = bool(args.apply) and not args.dry_run
    result = run_lifecycle(repo_root=args.repo_root.resolve(), index_path=args.index, apply=apply)
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
