"""验证快照 · 记录与新鲜度索引。

追加/轮转 `harness/verification-latest.json`；可选 JSONL 归档。
纯 stdlib。

用法（仓库根目录）::

    python harness/verification_snapshot_lifecycle.py record --pytest-passed 1658 --ruff ok
    python harness/verification_snapshot_lifecycle.py run --apply
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from dataclasses import asdict, dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

DEFAULT_LOOP_STATE = Path("harness/loop-state.json")
DEFAULT_PROJECT_STATUS = Path("apps/quant_assistant/docs/PROJECT_STATUS.md")
DEFAULT_SNAPSHOT_PATH = Path("harness/verification-latest.json")
DEFAULT_ARCHIVE_PATH = Path("harness/verification-archive.jsonl")
DEFAULT_INDEX_PATH = Path("harness/verification-snapshot-index.json")

_SECTION5 = re.compile(r"^### (5\.\d+)\s+.+$", re.MULTILINE)
_PYTEST_IN_S5 = re.compile(r"pytest[^\d]*(\d+)\s+passed", re.IGNORECASE)
_RUFF_IN_S5 = re.compile(r"ruff\s*[✅ok]", re.IGNORECASE)


@dataclass(slots=True)
class VerificationSnapshot:
    recorded_at: str = ""
    last_tick: str = ""
    pytest_passed: int | None = None
    ruff: str = ""
    evidence_paths: list[str] = field(default_factory=list)
    section5_ref: str = ""
    source: str = "manual"  # manual | scan


@dataclass(slots=True)
class VerificationIndex:
    version: str = "1.0.0"
    updated_at: str = ""
    snapshot_path: str = ""
    archive_path: str = ""
    latest: VerificationSnapshot = field(default_factory=VerificationSnapshot)
    git_dirty: bool = False
    age_hours: float | None = None
    stale: bool = False
    findings: list[dict[str, Any]] = field(default_factory=list)
    last_lifecycle: dict[str, Any] = field(default_factory=dict)


def _now_iso() -> str:
    return datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def _parse_iso(ts: str) -> datetime | None:
    text = str(ts or "").strip()
    if not text:
        return None
    try:
        return datetime.fromisoformat(text.replace("Z", "+00:00"))
    except ValueError:
        return None


def _load_loop_state(repo_root: Path) -> dict[str, Any]:
    path = repo_root / DEFAULT_LOOP_STATE
    if not path.is_file():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}


def _git_dirty(repo_root: Path) -> bool:
    try:
        proc = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=str(repo_root),
            capture_output=True,
            text=True,
            check=False,
            timeout=30,
        )
        return bool(proc.stdout.strip())
    except (OSError, subprocess.TimeoutExpired):
        return False


def _scan_section5_evidence(text: str) -> tuple[int | None, str, str]:
    latest_num = ""
    m = _SECTION5.search(text)
    if m:
        raw = m.group(1)
        latest_num = raw.split(".", 1)[-1] if "." in raw else raw
    section_start = text.find(f"### 5.{latest_num}") if latest_num else -1
    chunk = text[section_start : section_start + 2500] if section_start >= 0 else text[:2500]
    pytest_n: int | None = None
    pm = _PYTEST_IN_S5.search(chunk)
    if pm:
        pytest_n = int(pm.group(1))
    ruff_ok = "ok" if _RUFF_IN_S5.search(chunk) else ""
    return pytest_n, ruff_ok, latest_num


def load_snapshot(path: Path) -> VerificationSnapshot | None:
    if not path.is_file():
        return None
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return None
    if not isinstance(payload, dict):
        return None
    return VerificationSnapshot(
        recorded_at=str(payload.get("recorded_at") or ""),
        last_tick=str(payload.get("last_tick") or ""),
        pytest_passed=payload.get("pytest_passed"),
        ruff=str(payload.get("ruff") or ""),
        evidence_paths=list(payload.get("evidence_paths") or []),
        section5_ref=str(payload.get("section5_ref") or ""),
        source=str(payload.get("source") or "manual"),
    )


def save_snapshot(path: Path, snapshot: VerificationSnapshot) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(asdict(snapshot), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def append_archive(path: Path, snapshot: VerificationSnapshot) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(asdict(snapshot), ensure_ascii=False) + "\n")


def record_snapshot(
    *,
    repo_root: Path,
    snapshot_path: Path,
    archive_path: Path,
    pytest_passed: int | None,
    ruff: str,
    evidence_paths: list[str],
    apply: bool,
) -> dict[str, Any]:
    loop_state = _load_loop_state(repo_root)
    status_path = repo_root / DEFAULT_PROJECT_STATUS
    section5_ref = ""
    if status_path.is_file():
        _, _, s5_num = _scan_section5_evidence(status_path.read_text(encoding="utf-8"))
        section5_ref = f"5.{s5_num}" if s5_num else ""

    snapshot = VerificationSnapshot(
        recorded_at=_now_iso(),
        last_tick=str(loop_state.get("last_tick") or ""),
        pytest_passed=pytest_passed,
        ruff=ruff,
        evidence_paths=evidence_paths,
        section5_ref=section5_ref,
        source="manual",
    )
    if apply:
        save_snapshot(repo_root / snapshot_path, snapshot)
        append_archive(repo_root / archive_path, snapshot)
    return {"apply": apply, "snapshot": asdict(snapshot)}


def run_lifecycle(*, repo_root: Path, snapshot_path: Path, archive_path: Path, index_path: Path, apply: bool) -> dict[str, Any]:
    snap_file = repo_root / snapshot_path
    latest = load_snapshot(snap_file)

    if latest is None:
        status_path = repo_root / DEFAULT_PROJECT_STATUS
        if status_path.is_file():
            pytest_n, ruff_ok, s5_num = _scan_section5_evidence(status_path.read_text(encoding="utf-8"))
            loop_state = _load_loop_state(repo_root)
            latest = VerificationSnapshot(
                recorded_at=_now_iso(),
                last_tick=str(loop_state.get("last_tick") or ""),
                pytest_passed=pytest_n,
                ruff=ruff_ok,
                section5_ref=f"5.{s5_num}" if s5_num else "",
                source="scan",
            )
            if apply:
                save_snapshot(snap_file, latest)

    findings: list[dict[str, Any]] = []
    dirty = _git_dirty(repo_root)
    age_hours: float | None = None
    stale = False

    if latest and latest.recorded_at:
        recorded = _parse_iso(latest.recorded_at)
        if recorded:
            age_hours = (datetime.now(UTC) - recorded.astimezone(UTC)).total_seconds() / 3600.0
            if age_hours > 24 and dirty:
                stale = True
                findings.append(
                    {
                        "severity": "warning",
                        "code": "VER-STALE",
                        "detail": f"verification snapshot age={age_hours:.1f}h with git dirty",
                        "recommendation": "Run record after verify: python harness/verification_snapshot_lifecycle.py record ...",
                    }
                )
    elif dirty:
        stale = True
        findings.append(
            {
                "severity": "warning",
                "code": "VER-MISSING",
                "detail": "no verification snapshot while git dirty",
                "recommendation": "python harness/verification_snapshot_lifecycle.py record --pytest-passed N --ruff ok",
            }
        )

    index = VerificationIndex(
        updated_at=_now_iso(),
        snapshot_path=str(snapshot_path.as_posix()),
        archive_path=str(archive_path.as_posix()),
        latest=latest or VerificationSnapshot(),
        git_dirty=dirty,
        age_hours=age_hours,
        stale=stale,
        findings=findings,
        last_lifecycle={
            "at": _now_iso(),
            "apply": apply,
            "stale": stale,
            "git_dirty": dirty,
            "age_hours": age_hours,
        },
    )
    if apply:
        payload = asdict(index)
        payload["latest"] = asdict(index.latest)
        (repo_root / index_path).parent.mkdir(parents=True, exist_ok=True)
        (repo_root / index_path).write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    return {
        "apply": apply,
        "stale": stale,
        "git_dirty": dirty,
        "age_hours": age_hours,
        "findings": findings,
        "latest": asdict(latest) if latest else None,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Verification snapshot lifecycle")
    sub = parser.add_subparsers(dest="command", required=True)

    rec = sub.add_parser("record", help="Record a fresh verification snapshot")
    rec.add_argument("--repo-root", type=Path, default=Path("."))
    rec.add_argument("--snapshot", type=Path, default=DEFAULT_SNAPSHOT_PATH)
    rec.add_argument("--archive", type=Path, default=DEFAULT_ARCHIVE_PATH)
    rec.add_argument("--pytest-passed", type=int, default=None)
    rec.add_argument("--ruff", default="")
    rec.add_argument("--evidence", action="append", default=[])
    rec.add_argument("--apply", action="store_true")
    rec.add_argument("--dry-run", action="store_true")

    run = sub.add_parser("run", help="Refresh staleness index")
    run.add_argument("--repo-root", type=Path, default=Path("."))
    run.add_argument("--snapshot", type=Path, default=DEFAULT_SNAPSHOT_PATH)
    run.add_argument("--archive", type=Path, default=DEFAULT_ARCHIVE_PATH)
    run.add_argument("--index", type=Path, default=DEFAULT_INDEX_PATH)
    run.add_argument("--apply", action="store_true")
    run.add_argument("--dry-run", action="store_true")

    args = parser.parse_args()
    repo_root = args.repo_root.resolve()

    if args.command == "record":
        apply = bool(args.apply) and not args.dry_run
        result = record_snapshot(
            repo_root=repo_root,
            snapshot_path=args.snapshot,
            archive_path=args.archive,
            pytest_passed=args.pytest_passed,
            ruff=args.ruff,
            evidence_paths=list(args.evidence or []),
            apply=apply,
        )
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 0

    apply = bool(args.apply) and not args.dry_run
    result = run_lifecycle(
        repo_root=repo_root,
        snapshot_path=args.snapshot,
        archive_path=args.archive,
        index_path=args.index,
        apply=apply,
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
