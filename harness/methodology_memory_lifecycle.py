"""方法论永久记忆 · 生命周期管理（Dream / 去重 / 过期清理）。

纯 stdlib；可被 compliance-check、Cursor Automations、orchestrator 调用。

用法（仓库根目录）::
    python harness/methodology_memory_lifecycle.py run --apply
    python harness/methodology_memory_lifecycle.py run --dry-run
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
from dataclasses import asdict, dataclass, field
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any

DEFAULT_MEMORY_PATH = Path("apps/quant_assistant/docs/METHODOLOGY_MEMORY.md")
DEFAULT_INDEX_PATH = Path("harness/methodology-memory-index.json")
DEFAULT_ARCHIVE_PATH = Path("apps/quant_assistant/docs/archive/METHODOLOGY_MEMORY_ARCHIVE.md")
DEFAULT_ROUND_TTL_DAYS = 180
DEFAULT_DREAM_MIN_ROUND_MENTIONS = 2

_M_ENTRY = re.compile(r"^### (M-\d+)\s*[·\-]\s*(.+)$", re.MULTILINE)
_GP_ENTRY = re.compile(r"^### (GP-\d+)\s*[·\-]\s*(.+)$", re.MULTILINE)
_M_FIELD = re.compile(r"^\-\s+\*\*(场景|规则|复现条件|来源)\*\*：(.+)$", re.MULTILINE)
_GP_FIELD = re.compile(r"^\-\s+\*\*(场景|规则|复现条件|来源)\*\*：(.+)$", re.MULTILINE)
_ROUND = re.compile(r"^## (轮次-\d{8}-[^\s]+)\s*(?:·\s*(.+))?$", re.MULTILINE)
_STEP_DIGEST = re.compile(r"^## 步骤 digest-([^\s]+)(?:\s*·\s*(.+))?$", re.MULTILINE)
_CLOSURE = re.compile(r"^## 收口 synthesis-([^\s]+)(?:\s*·\s*(.+))?$", re.MULTILINE)
_SUPERSEDED = re.compile(r"superseded by (M-\d+|GP-\d+|收口 synthesis-[^\s]+)", re.IGNORECASE)
_DIGEST_TASK = re.compile(r"^\-\s+\*\*关联任务\*\*：(.+)$", re.MULTILINE)
_DIGEST_FP = re.compile(r"^\-\s+\*\*指纹\*\*：`([^`]+)`", re.MULTILINE)


@dataclass(slots=True)
class MethodologyEntry:
    entry_id: str
    title: str
    scenario: str = ""
    rule: str = ""
    trigger: str = ""
    source: str = ""
    fingerprint: str = ""
    status: str = "active"  # active | superseded | expired
    superseded_by: str | None = None
    last_seen_at: str = ""
    mention_count: int = 1


@dataclass(slots=True)
class RoundRecord:
    round_id: str
    title: str = ""
    archived: bool = False
    archived_at: str | None = None


@dataclass(slots=True)
class StepDigestRecord:
    digest_id: str
    title: str = ""
    task_ref: str = ""
    fingerprint: str = ""
    status: str = "active"  # active | superseded
    superseded_by: str | None = None


@dataclass(slots=True)
class ClosureRecord:
    closure_id: str
    title: str = ""
    task_refs: list[str] = field(default_factory=list)
    status: str = "open"  # open | closed
    archived_digests: list[str] = field(default_factory=list)


@dataclass(slots=True)
class MethodologyIndex:
    version: str = "1.1.0"
    updated_at: str = ""
    memory_path: str = ""
    active_entry_count: int = 0
    archived_round_count: int = 0
    entries: dict[str, MethodologyEntry] = field(default_factory=dict)
    gp_entries: dict[str, MethodologyEntry] = field(default_factory=dict)
    rounds: dict[str, RoundRecord] = field(default_factory=dict)
    step_digests: dict[str, StepDigestRecord] = field(default_factory=dict)
    closures: dict[str, ClosureRecord] = field(default_factory=dict)
    dream_candidates: list[dict[str, Any]] = field(default_factory=list)
    closure_candidates: list[dict[str, Any]] = field(default_factory=list)
    last_lifecycle: dict[str, Any] = field(default_factory=dict)


def _now_iso() -> str:
    return datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _normalize_fingerprint(text: str) -> str:
    lowered = re.sub(r"\s+", " ", str(text or "").strip().casefold())
    return hashlib.sha256(lowered.encode("utf-8")).hexdigest()[:16]


def _entry_fingerprint(scenario: str, rule: str) -> str:
    return _normalize_fingerprint(f"{scenario}|{rule}")


def _section_end(text: str, start: int, patterns: tuple[re.Pattern[str], ...]) -> int:
    positions = [len(text)]
    for pat in patterns:
        nxt = pat.search(text, start)
        if nxt:
            positions.append(nxt.start())
    return min(positions)


def _parse_entry_block(
    block: str,
    entry_id: str,
    title: str,
    *,
    field_pattern: re.Pattern[str] = _M_FIELD,
) -> MethodologyEntry:
    fields: dict[str, str] = {}
    for field_match in field_pattern.finditer(block):
        fields[field_match.group(1)] = field_match.group(2).strip()

    scenario = fields.get("场景", "")
    rule = fields.get("规则", "")
    status = "active"
    superseded_by: str | None = None
    if "superseded by" in block.casefold():
        sup = _SUPERSEDED.search(block)
        if sup:
            status = "superseded"
            superseded_by = sup.group(1)

    return MethodologyEntry(
        entry_id=entry_id,
        title=title,
        scenario=scenario,
        rule=rule,
        trigger=fields.get("复现条件", ""),
        source=fields.get("来源", ""),
        fingerprint=_entry_fingerprint(scenario, rule),
        status=status,
        superseded_by=superseded_by,
        last_seen_at=_now_iso(),
    )


def parse_step_digests(text: str) -> dict[str, StepDigestRecord]:
    """Parse `## 步骤 digest-*` sections."""
    digests: dict[str, StepDigestRecord] = {}
    section_patterns = (_STEP_DIGEST, _CLOSURE, _ROUND, _M_ENTRY)

    for match in _STEP_DIGEST.finditer(text):
        digest_id = match.group(1)
        title = (match.group(2) or "").strip()
        block_start = match.end()
        block_end = _section_end(text, block_start, section_patterns)
        block = text[block_start:block_end]

        task_match = _DIGEST_TASK.search(block)
        fp_match = _DIGEST_FP.search(block)
        task_ref = task_match.group(1).strip() if task_match else ""
        fingerprint = fp_match.group(1).strip() if fp_match else _normalize_fingerprint(block[:400])

        status = "active"
        superseded_by: str | None = None
        if "superseded by" in block.casefold() or "**状态**：superseded" in block:
            status = "superseded"
            sup = re.search(r"superseded by (收口 synthesis-[^\s]+|[^\s]+)", block, re.IGNORECASE)
            if sup:
                superseded_by = sup.group(1)

        digests[digest_id] = StepDigestRecord(
            digest_id=digest_id,
            title=title,
            task_ref=task_ref,
            fingerprint=fingerprint,
            status=status,
            superseded_by=superseded_by,
        )
    return digests


def parse_closures(text: str) -> dict[str, ClosureRecord]:
    """Parse `## 收口 synthesis-*` sections."""
    closures: dict[str, ClosureRecord] = {}
    section_patterns = (_STEP_DIGEST, _CLOSURE, _ROUND, _M_ENTRY)

    for match in _CLOSURE.finditer(text):
        closure_id = match.group(1)
        title = (match.group(2) or "").strip()
        block_start = match.end()
        block_end = _section_end(text, block_start, section_patterns)
        block = text[block_start:block_end]

        task_refs: list[str] = []
        for line in block.splitlines():
            stripped = line.strip()
            if stripped.startswith("- ") and any(
                tok in stripped for tok in ("MINE-", "GEN-", "KB-", "PL-C-", "loop")
            ):
                task_refs.append(stripped.lstrip("- ").strip())

        status = "closed" if "**状态**：closed" in block or "status: closed" in block.casefold() else "open"
        archived: list[str] = []
        for arch in re.finditer(r"digest-([^\s`]+)", block):
            did = arch.group(1)
            if did != closure_id:
                archived.append(did)

        closures[closure_id] = ClosureRecord(
            closure_id=closure_id,
            title=title,
            task_refs=task_refs,
            status=status,
            archived_digests=archived,
        )
    return closures


def find_closure_candidates(
    digests: dict[str, StepDigestRecord],
    *,
    completed_tasks: list[str] | None = None,
    min_digests_per_task: int = 1,
) -> list[dict[str, Any]]:
    """Suggest closure synthesis when key tasks have active step digests."""
    completed = {t.strip().casefold() for t in (completed_tasks or []) if t.strip()}
    by_task: dict[str, list[StepDigestRecord]] = {}
    for digest in digests.values():
        if digest.status != "active":
            continue
        key = digest.task_ref.casefold() or digest.digest_id.casefold()
        by_task.setdefault(key, []).append(digest)

    candidates: list[dict[str, Any]] = []
    for task_key, group in sorted(by_task.items()):
        if len(group) < min_digests_per_task:
            continue
        matched = not completed or any(ct in task_key for ct in completed)
        if matched and completed:
            candidates.append(
                {
                    "task_ref": group[0].task_ref or task_key,
                    "digest_ids": [d.digest_id for d in group],
                    "digest_count": len(group),
                    "action": "synthesize_closure",
                }
            )
        elif not completed and len(group) >= 2:
            candidates.append(
                {
                    "task_ref": group[0].task_ref or task_key,
                    "digest_ids": [d.digest_id for d in group],
                    "digest_count": len(group),
                    "action": "review_for_closure",
                }
            )
    return candidates


def mark_digests_superseded(text: str, digest_ids: list[str], closure_id: str) -> str:
    """Mark step digests as superseded after closure synthesis."""
    updated = text
    marker = f"superseded by 收口 synthesis-{closure_id}"
    for digest_id in digest_ids:
        heading = f"## 步骤 digest-{digest_id}"
        idx = updated.find(heading)
        if idx < 0:
            continue
        section_end = _section_end(
            updated,
            idx + len(heading),
            (_STEP_DIGEST, _CLOSURE, _ROUND),
        )
        section = updated[idx:section_end]
        if marker.casefold() in section.casefold():
            continue
        insert_at = updated.find("\n", idx) + 1
        status_line = f"> **状态**：superseded · {marker}\n"
        updated = updated[:insert_at] + status_line + updated[insert_at:]
    return updated


def parse_methodology_markdown(
    text: str,
) -> tuple[
    dict[str, MethodologyEntry],
    dict[str, MethodologyEntry],
    dict[str, RoundRecord],
    dict[str, StepDigestRecord],
    dict[str, ClosureRecord],
]:
    entries: dict[str, MethodologyEntry] = {}
    gp_entries: dict[str, MethodologyEntry] = {}
    rounds: dict[str, RoundRecord] = {}
    section_patterns = (_M_ENTRY, _GP_ENTRY, _ROUND, _STEP_DIGEST, _CLOSURE)

    for match in _M_ENTRY.finditer(text):
        entry_id = match.group(1)
        title = match.group(2).strip()
        block_start = match.end()
        block_end = _section_end(text, block_start, section_patterns)
        block = text[block_start:block_end]
        entries[entry_id] = _parse_entry_block(block, entry_id, title)

    for match in _GP_ENTRY.finditer(text):
        entry_id = match.group(1)
        title = match.group(2).strip()
        block_start = match.end()
        block_end = _section_end(text, block_start, section_patterns)
        block = text[block_start:block_end]
        gp_entries[entry_id] = _parse_entry_block(block, entry_id, title, field_pattern=_GP_FIELD)

    for match in _ROUND.finditer(text):
        round_id = match.group(1)
        title = (match.group(2) or "").strip()
        archived = "<!-- archived -->" in text[match.start() : match.start() + 400]
        rounds[round_id] = RoundRecord(round_id=round_id, title=title, archived=archived)

    step_digests = parse_step_digests(text)
    closures = parse_closures(text)

    return entries, gp_entries, rounds, step_digests, closures


def dedupe_entries(entries: dict[str, MethodologyEntry]) -> list[dict[str, Any]]:
    """同 fingerprint 保留编号最大者，其余标记 superseded。"""
    actions: list[dict[str, Any]] = []
    by_fp: dict[str, list[MethodologyEntry]] = {}
    for entry in entries.values():
        if not entry.fingerprint:
            continue
        by_fp.setdefault(entry.fingerprint, []).append(entry)

    for fp, group in by_fp.items():
        if len(group) < 2:
            continue
        ordered = sorted(group, key=lambda e: int(e.entry_id.split("-")[1]))
        keeper = ordered[-1]
        for dup in ordered[:-1]:
            if dup.status == "superseded" and dup.superseded_by == keeper.entry_id:
                continue
            dup.status = "superseded"
            dup.superseded_by = keeper.entry_id
            actions.append(
                {
                    "action": "dedupe",
                    "from": dup.entry_id,
                    "to": keeper.entry_id,
                    "fingerprint": fp,
                }
            )
    return actions


def dream_from_rounds(text: str, *, min_mentions: int = DEFAULT_DREAM_MIN_ROUND_MENTIONS) -> list[dict[str, Any]]:
    """从轮次「失败/根因」表提取重复主题，供 Dream 晋升 M-xx。"""
    themes: dict[str, int] = {}
    row_pattern = re.compile(r"^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|", re.MULTILINE)
    for match in row_pattern.finditer(text):
        item, _phenomenon, root = (match.group(1).strip(), match.group(2).strip(), match.group(3).strip())
        if item in {"项", "---", ""} or item.startswith("-"):
            continue
        key = _normalize_fingerprint(root or item)
        themes[key] = themes.get(key, 0) + 1

    candidates: list[dict[str, Any]] = []
    for key, count in sorted(themes.items(), key=lambda kv: kv[1], reverse=True):
        if count >= min_mentions:
            candidates.append({"theme_fingerprint": key, "mention_count": count, "promote": "review_for_M_xx"})
    return candidates


def apply_dedupe_to_markdown(text: str, actions: list[dict[str, Any]]) -> str:
    updated = text
    for action in actions:
        from_id = str(action.get("from") or "")
        to_id = str(action.get("to") or "")
        if not from_id or not to_id:
            continue
        marker = f"superseded by {to_id}"
        heading = f"### {from_id}"
        idx = updated.find(heading)
        if idx < 0:
            continue
        section_end = updated.find("\n### M-", idx + len(heading))
        if section_end < 0:
            section_end = updated.find("\n## ", idx + len(heading))
        if section_end < 0:
            section_end = len(updated)
        section = updated[idx:section_end]
        if marker.casefold() in section.casefold():
            continue
        insert_at = updated.find("\n", idx) + 1
        updated = updated[:insert_at] + f"- **状态**：{marker}\n" + updated[insert_at:]
    return updated


def render_dream_section(candidates: list[dict[str, Any]], existing: str) -> str:
    if not candidates:
        return existing
    lines = [
        "## Dream _digest（自动生成 · 待人工晋升 M-xx）",
        "",
        f"> 更新时间：{_now_iso()} · 重复失败主题 ≥ {DEFAULT_DREAM_MIN_ROUND_MENTIONS} 次",
        "",
        "| theme_fingerprint | mentions | 建议 |",
        "|-------------------|----------|------|",
    ]
    for item in candidates[:12]:
        lines.append(
            f"| `{item['theme_fingerprint']}` | {item['mention_count']} | {item.get('promote', 'review')} |"
        )
    lines.append("")
    dream_block = "\n".join(lines)

    if "## Dream _digest" in existing:
        return re.sub(
            r"## Dream _digest（自动生成[^]*?(?=\n## |\Z)",
            dream_block + "\n",
            existing,
            count=1,
        )
    anchor = "## 永久方法论库"
    if anchor in existing:
        return existing.replace(anchor, dream_block + "\n" + anchor, 1)
    return dream_block + "\n\n" + existing


def expire_old_rounds(
    text: str,
    *,
    ttl_days: int = DEFAULT_ROUND_TTL_DAYS,
    dry_run: bool = True,
) -> tuple[str, list[str], str]:
    """将超 TTL 轮次移到 archive 文件（正文标记 archived）。"""
    cutoff = datetime.now(UTC) - timedelta(days=ttl_days)
    archived_ids: list[str] = []
    archive_chunks: list[str] = []
    updated = text

    for match in list(_ROUND.finditer(text)):
        round_id = match.group(1)
        date_str = round_id.split("-")[1][:8] if "-" in round_id else ""
        try:
            round_date = datetime.strptime(date_str, "%Y%m%d").replace(tzinfo=UTC)
        except ValueError:
            continue
        if round_date >= cutoff:
            continue
        if "<!-- archived -->" in text[match.start() : match.start() + 200]:
            continue

        next_match = _ROUND.search(text, match.end())
        end = next_match.start() if next_match else len(text)
        chunk = text[match.start() : end].strip()
        archive_chunks.append(chunk)
        archived_ids.append(round_id)
        if not dry_run:
            replacement = f"## {round_id} <!-- archived --> · {match.group(2) or ''}\n\n> 已归档至 `docs/archive/METHODOLOGY_MEMORY_ARCHIVE.md`\n"
            updated = updated[: match.start()] + replacement + updated[end:]

    archive_body = ""
    if archive_chunks and not dry_run:
        archive_body = "\n\n---\n\n".join(archive_chunks) + "\n"

    return updated, archived_ids, archive_body


def load_loop_completed_tasks(repo_root: Path) -> list[str]:
    """Read completed task hints from loop-state.json."""
    path = repo_root / "harness" / "loop-state.json"
    if not path.is_file():
        return []
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return []
    tasks: list[str] = []
    for key in ("last_completed_note", "current_slice", "last_tick"):
        val = str(payload.get(key) or "").strip()
        if val:
            tasks.append(val)
    return tasks


def load_index(path: Path) -> MethodologyIndex:
    if not path.is_file():
        return MethodologyIndex()
    payload = json.loads(path.read_text(encoding="utf-8"))
    entries = {
        k: MethodologyEntry(**v)
        for k, v in dict(payload.get("entries") or {}).items()
        if isinstance(v, dict)
    }
    gp_entries = {
        k: MethodologyEntry(**v)
        for k, v in dict(payload.get("gp_entries") or {}).items()
        if isinstance(v, dict)
    }
    rounds = {
        k: RoundRecord(**v)
        for k, v in dict(payload.get("rounds") or {}).items()
        if isinstance(v, dict)
    }
    step_digests = {
        k: StepDigestRecord(**v)
        for k, v in dict(payload.get("step_digests") or {}).items()
        if isinstance(v, dict)
    }
    closures = {
        k: ClosureRecord(**v)
        for k, v in dict(payload.get("closures") or {}).items()
        if isinstance(v, dict)
    }
    return MethodologyIndex(
        version=str(payload.get("version") or "1.1.0"),
        updated_at=str(payload.get("updated_at") or ""),
        memory_path=str(payload.get("memory_path") or ""),
        active_entry_count=int(payload.get("active_entry_count") or 0),
        archived_round_count=int(payload.get("archived_round_count") or 0),
        entries=entries,
        gp_entries=gp_entries,
        rounds=rounds,
        step_digests=step_digests,
        closures=closures,
        dream_candidates=list(payload.get("dream_candidates") or []),
        closure_candidates=list(payload.get("closure_candidates") or []),
        last_lifecycle=dict(payload.get("last_lifecycle") or {}),
    )


def save_index(path: Path, index: MethodologyIndex) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "version": index.version,
        "updated_at": index.updated_at,
        "memory_path": index.memory_path,
        "active_entry_count": index.active_entry_count,
        "archived_round_count": index.archived_round_count,
        "entries": {k: asdict(v) for k, v in index.entries.items()},
        "gp_entries": {k: asdict(v) for k, v in index.gp_entries.items()},
        "rounds": {k: asdict(v) for k, v in index.rounds.items()},
        "step_digests": {k: asdict(v) for k, v in index.step_digests.items()},
        "closures": {k: asdict(v) for k, v in index.closures.items()},
        "dream_candidates": index.dream_candidates,
        "closure_candidates": index.closure_candidates,
        "last_lifecycle": index.last_lifecycle,
    }
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def run_lifecycle(
    *,
    repo_root: Path,
    memory_path: Path,
    index_path: Path,
    archive_path: Path,
    apply: bool,
    ttl_days: int,
) -> dict[str, Any]:
    memory_file = repo_root / memory_path
    if not memory_file.is_file():
        raise FileNotFoundError(f"METHODOLOGY_MEMORY not found: {memory_file}")

    text = memory_file.read_text(encoding="utf-8")
    entries, gp_entries, rounds, step_digests, closures = parse_methodology_markdown(text)
    dedupe_actions = dedupe_entries(entries)
    dedupe_gp_actions = dedupe_entries(gp_entries)
    dream_candidates = dream_from_rounds(text)
    completed_tasks = load_loop_completed_tasks(repo_root)
    closure_candidates = find_closure_candidates(step_digests, completed_tasks=completed_tasks)
    expired_text, archived_ids, archive_append = expire_old_rounds(text, ttl_days=ttl_days, dry_run=not apply)

    updated_text = expired_text
    if apply:
        for closure in closures.values():
            if closure.status == "closed" and closure.archived_digests:
                updated_text = mark_digests_superseded(
                    updated_text,
                    closure.archived_digests,
                    closure.closure_id,
                )
                for did in closure.archived_digests:
                    if did in step_digests:
                        step_digests[did].status = "superseded"

    if apply:
        updated_text = apply_dedupe_to_markdown(updated_text, dedupe_actions + dedupe_gp_actions)
        updated_text = render_dream_section(dream_candidates, updated_text)
        memory_file.write_text(updated_text, encoding="utf-8")
        if archive_append:
            archive_file = repo_root / archive_path
            archive_file.parent.mkdir(parents=True, exist_ok=True)
            header = f"\n\n---\n\n# Archive append · {_now_iso()}\n\n"
            if archive_file.is_file():
                archive_file.write_text(archive_file.read_text(encoding="utf-8") + header + archive_append, encoding="utf-8")
            else:
                archive_file.write_text(f"# METHODOLOGY_MEMORY Archive\n{header}{archive_append}", encoding="utf-8")

    active_count = sum(1 for e in entries.values() if e.status == "active")
    active_gp = sum(1 for e in gp_entries.values() if e.status == "active")
    active_digests = sum(1 for d in step_digests.values() if d.status == "active")
    index = MethodologyIndex(
        version="1.1.0",
        updated_at=_now_iso(),
        memory_path=str(memory_path.as_posix()),
        active_entry_count=active_count + active_gp,
        archived_round_count=sum(1 for r in rounds.values() if r.archived) + len(archived_ids),
        entries=entries,
        gp_entries=gp_entries,
        rounds=rounds,
        step_digests=step_digests,
        closures=closures,
        dream_candidates=dream_candidates,
        closure_candidates=closure_candidates,
        last_lifecycle={
            "at": _now_iso(),
            "apply": apply,
            "dedupe_actions": len(dedupe_actions) + len(dedupe_gp_actions),
            "dream_candidates": len(dream_candidates),
            "closure_candidates": len(closure_candidates),
            "archived_rounds": archived_ids,
            "active_step_digests": active_digests,
            "completed_tasks_hint": completed_tasks,
            "ttl_days": ttl_days,
        },
    )
    if apply:
        save_index(repo_root / index_path, index)

    return {
        "apply": apply,
        "dedupe_actions": dedupe_actions + dedupe_gp_actions,
        "dream_candidates": dream_candidates,
        "closure_candidates": closure_candidates,
        "archived_rounds": archived_ids,
        "active_entries": active_count,
        "active_gp_entries": active_gp,
        "active_step_digests": active_digests,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Methodology memory lifecycle")
    parser.add_argument("command", choices=["run", "index-only"], nargs="?", default="run")
    parser.add_argument("--repo-root", type=Path, default=Path("."))
    parser.add_argument("--memory", type=Path, default=DEFAULT_MEMORY_PATH)
    parser.add_argument("--index", type=Path, default=DEFAULT_INDEX_PATH)
    parser.add_argument("--archive", type=Path, default=DEFAULT_ARCHIVE_PATH)
    parser.add_argument("--ttl-days", type=int, default=DEFAULT_ROUND_TTL_DAYS)
    parser.add_argument("--apply", action="store_true", help="Write changes (default dry-run)")
    parser.add_argument("--dry-run", action="store_true", help="Explicit dry-run")
    args = parser.parse_args()

    apply = bool(args.apply) and not args.dry_run
    repo_root = args.repo_root.resolve()
    result = run_lifecycle(
        repo_root=repo_root,
        memory_path=args.memory,
        index_path=args.index,
        archive_path=args.archive,
        apply=apply,
        ttl_days=args.ttl_days,
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
