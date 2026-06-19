"""五真源同步一致性 · 只读校验 + 索引。

校验 loop-state / CONTINUATION / TASK_TREES / PROJECT_STATUS 顶部摘要与 §5 是否漂移。
纯 stdlib；`run --apply` 仅写入索引，不自动改写 prose 文档。

用法（仓库根目录）::

    python harness/sync_coherence_lifecycle.py run --apply
    python harness/sync_coherence_lifecycle.py run --dry-run
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
DEFAULT_CONTINUATION = Path("apps/quant_assistant/docs/CONTINUATION_PROMPT.md")
DEFAULT_TASK_TREES = Path("apps/quant_assistant/docs/TASK_TREES.md")
DEFAULT_PROJECT_STATUS = Path("apps/quant_assistant/docs/PROJECT_STATUS.md")
DEFAULT_INDEX_PATH = Path("harness/sync-coherence-index.json")

_TOP_SECTION_END = re.compile(r"^## (?!心流模式当前轮)", re.MULTILINE)
_SECTION5 = re.compile(r"^### (5\.\d+)\s+(.+)$", re.MULTILINE)
_FOREGROUND_TREE = re.compile(r"\*\*当前前台主线\*\*：`([^`]+)`")
_FOREGROUND_SLICE = re.compile(r"\*\*当前主执行切片\*\*：`([^`]+)`")
_NEXT_ATOMIC_ITEM = re.compile(
    r"^\d+\.\s+(?:(?:~~.+?~~\s*)+|(?:\*\*)?)([^✅\n]+?)(?:\*\*)?(?:\s*✅.*)?$",
    re.MULTILINE,
)
_CONT_NEXT = re.compile(r"\*\*下一动作\*\*：\*\*(.+?)\*\*")
_LOOP_REF = re.compile(r"§5\.(\d+)")
_TICK_REF = re.compile(r"loop\d+[\w-]*", re.IGNORECASE)


@dataclass(slots=True)
class Finding:
    severity: str  # info | warning | error
    code: str
    paths: list[str]
    detail: str
    recommendation: str


@dataclass(slots=True)
class SyncCoherenceIndex:
    version: str = "1.0.0"
    updated_at: str = ""
    loop_state_path: str = ""
    continuation_path: str = ""
    task_trees_path: str = ""
    project_status_path: str = ""
    loop_next_atomic_action: str = ""
    continuation_next_action: str = ""
    task_trees_next_hint: str = ""
    foreground_tree: str = ""
    foreground_slice: str = ""
    latest_section5_id: str = ""
    latest_section5_title: str = ""
    top_summary_section5_ref: str = ""
    top_summary_last_tick: str = ""
    loop_last_tick: str = ""
    findings: list[Finding] = field(default_factory=list)
    last_lifecycle: dict[str, Any] = field(default_factory=dict)


def _now_iso() -> str:
    return datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _normalize_action(text: str) -> str:
    return re.sub(r"\s+", " ", str(text or "").strip().casefold())


def _extract_top_summary_block(text: str) -> str:
    marker = "## 心流模式当前轮"
    start = text.find(marker)
    if start < 0:
        return ""
    rest = text[start + len(marker) :]
    end_match = _TOP_SECTION_END.search(rest)
    end = start + len(marker) + (end_match.start() if end_match else len(rest))
    return text[start:end]


def _latest_section5(text: str) -> tuple[str, str]:
    for match in _SECTION5.finditer(text):
        raw = match.group(1)
        num = raw.split(".", 1)[-1] if "." in raw else raw
        return num, match.group(2).strip()
    return "", ""


def _top_section5_ref(top_block: str) -> str:
    refs = _LOOP_REF.findall(top_block)
    return refs[0] if refs else ""


def _top_last_tick(top_block: str) -> str:
    for line in top_block.splitlines():
        if "**last_tick**" in line:
            m = _TICK_REF.search(line)
            if m:
                return m.group(0)
    return ""


def _parse_next_atomic_from_trees(text: str) -> str:
    section = ""
    marker = "### 下一原子动作"
    idx = text.find(marker)
    if idx >= 0:
        section = text[idx : idx + 4000]
    for line in section.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if "~~" in stripped and "✅" in stripped:
            continue
        if stripped.startswith(tuple(f"{n}." for n in range(1, 20))):
            cleaned = re.sub(r"^\d+\.\s+", "", stripped)
            cleaned = re.sub(r"\*\*", "", cleaned)
            cleaned = re.sub(r"~~.+?~~\s*", "", cleaned)
            cleaned = cleaned.split("✅")[0].strip(" ·-")
            if cleaned:
                return cleaned
    return ""


def _actions_align(a: str, b: str) -> bool:
    na, nb = _normalize_action(a), _normalize_action(b)
    if not na or not nb:
        return True
    return na in nb or nb in na


def validate_sync_coherence(
    *,
    loop_state: dict[str, Any],
    continuation_text: str,
    task_trees_text: str,
    project_status_text: str,
) -> SyncCoherenceIndex:
    loop_next = str(loop_state.get("next_atomic_action") or "").strip()
    loop_tick = str(loop_state.get("last_tick") or "").strip()
    cont_match = _CONT_NEXT.search(continuation_text)
    cont_next = cont_match.group(1).strip() if cont_match else ""
    trees_next = _parse_next_atomic_from_trees(task_trees_text)
    fg_tree_m = _FOREGROUND_TREE.search(task_trees_text)
    fg_slice_m = _FOREGROUND_SLICE.search(task_trees_text)
    foreground_tree = fg_tree_m.group(1) if fg_tree_m else ""
    foreground_slice = fg_slice_m.group(1) if fg_slice_m else ""

    top_block = _extract_top_summary_block(project_status_text)
    latest_id, latest_title = _latest_section5(project_status_text)
    top_s5 = _top_section5_ref(top_block)
    top_tick = _top_last_tick(top_block)

    findings: list[Finding] = []

    if loop_next and cont_next and not _actions_align(loop_next, cont_next):
        findings.append(
            Finding(
                severity="warning",
                code="SYNC-LOOP-CONT",
                paths=[str(DEFAULT_LOOP_STATE), str(DEFAULT_CONTINUATION)],
                detail=f"loop-state next_atomic_action={loop_next!r} vs CONTINUATION 下一动作={cont_next!r}",
                recommendation="对齐 loop-state.json 与 CONTINUATION_PROMPT 下一动作字段。",
            )
        )

    if loop_next and trees_next and not _actions_align(loop_next, trees_next):
        findings.append(
            Finding(
                severity="info",
                code="SYNC-LOOP-TREES",
                paths=[str(DEFAULT_LOOP_STATE), str(DEFAULT_TASK_TREES)],
                detail=f"loop-state={loop_next!r} vs TASK_TREES 下一未勾选项={trees_next!r}",
                recommendation="确认 TASK_TREES 排序与 loop-state 已同步。",
            )
        )

    current_tree = str(loop_state.get("current_tree") or "")
    if foreground_slice and current_tree and current_tree.casefold() not in foreground_slice.casefold():
        findings.append(
            Finding(
                severity="info",
                code="SYNC-TREE-SLICE",
                paths=[str(DEFAULT_LOOP_STATE), str(DEFAULT_TASK_TREES)],
                detail=f"loop-state current_tree={current_tree!r} vs TASK_TREES 切片={foreground_slice!r}",
                recommendation="核对 loop-state current_tree/current_slice 与 TASK_TREES 当前主执行切片。",
            )
        )

    if latest_id and top_s5:
        try:
            if int(latest_id) > int(top_s5):
                findings.append(
                    Finding(
                        severity="warning",
                        code="SYNC-TOP-STALE",
                        paths=[str(DEFAULT_PROJECT_STATUS)],
                        detail=(
                            f"§5 最新为 5.{latest_id} ({latest_title})，"
                            f"但顶部现状概述仍引用 §5.{top_s5}"
                        ),
                        recommendation=(
                            "每轮原子任务后更新 PROJECT_STATUS 顶部「心流模式当前轮」"
                            "（1–3 句：模式/本批/下一动作/阻塞），与 §5 最新条目对齐。"
                        ),
                    )
                )
        except ValueError:
            pass
    elif latest_id and not top_s5:
        findings.append(
            Finding(
                severity="warning",
                code="SYNC-TOP-MISSING",
                paths=[str(DEFAULT_PROJECT_STATUS)],
                detail="顶部现状概述未引用任何 §5.x 编号",
                recommendation="在「心流模式当前轮」块写入最新 §5 编号与 last_tick。",
            )
        )

    if loop_tick and top_tick and loop_tick.casefold() not in top_tick.casefold() and top_tick.casefold() not in loop_tick.casefold():
        findings.append(
            Finding(
                severity="info",
                code="SYNC-TICK-DRIFT",
                paths=[str(DEFAULT_LOOP_STATE), str(DEFAULT_PROJECT_STATUS)],
                detail=f"loop-state last_tick={loop_tick!r} vs 顶部 last_tick={top_tick!r}",
                recommendation="更新 PROJECT_STATUS 顶部 last_tick 与 loop-state 一致。",
            )
        )

    if loop_next and top_block and not _actions_align(loop_next, top_block):
        findings.append(
            Finding(
                severity="warning",
                code="SYNC-TOP-NEXT",
                paths=[str(DEFAULT_PROJECT_STATUS), str(DEFAULT_LOOP_STATE)],
                detail=f"顶部摘要未体现 loop-state 下一动作：{loop_next!r}",
                recommendation="更新顶部「下一方向」与 next_atomic_action 一致。",
            )
        )

    return SyncCoherenceIndex(
        updated_at=_now_iso(),
        loop_state_path=str(DEFAULT_LOOP_STATE.as_posix()),
        continuation_path=str(DEFAULT_CONTINUATION.as_posix()),
        task_trees_path=str(DEFAULT_TASK_TREES.as_posix()),
        project_status_path=str(DEFAULT_PROJECT_STATUS.as_posix()),
        loop_next_atomic_action=loop_next,
        continuation_next_action=cont_next,
        task_trees_next_hint=trees_next,
        foreground_tree=foreground_tree,
        foreground_slice=foreground_slice,
        latest_section5_id=latest_id,
        latest_section5_title=latest_title,
        top_summary_section5_ref=top_s5,
        top_summary_last_tick=top_tick,
        loop_last_tick=loop_tick,
        findings=findings,
        last_lifecycle={
            "at": _now_iso(),
            "finding_count": len(findings),
            "warning_count": sum(1 for f in findings if f.severity == "warning"),
            "error_count": sum(1 for f in findings if f.severity == "error"),
        },
    )


def save_index(path: Path, index: SyncCoherenceIndex) -> None:
    payload = asdict(index)
    payload["findings"] = [asdict(f) for f in index.findings]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def run_lifecycle(*, repo_root: Path, index_path: Path, apply: bool) -> dict[str, Any]:
    loop_path = repo_root / DEFAULT_LOOP_STATE
    cont_path = repo_root / DEFAULT_CONTINUATION
    trees_path = repo_root / DEFAULT_TASK_TREES
    status_path = repo_root / DEFAULT_PROJECT_STATUS

    for p in (loop_path, cont_path, trees_path, status_path):
        if not p.is_file():
            raise FileNotFoundError(f"missing required source: {p}")

    loop_state = json.loads(loop_path.read_text(encoding="utf-8"))
    index = validate_sync_coherence(
        loop_state=loop_state,
        continuation_text=cont_path.read_text(encoding="utf-8"),
        task_trees_text=trees_path.read_text(encoding="utf-8"),
        project_status_text=status_path.read_text(encoding="utf-8"),
    )
    if apply:
        save_index(repo_root / index_path, index)

    return {
        "apply": apply,
        "finding_count": len(index.findings),
        "latest_section5": index.latest_section5_id,
        "top_section5_ref": index.top_summary_section5_ref,
        "findings": [asdict(f) for f in index.findings],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync coherence lifecycle (read-only validation)")
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
