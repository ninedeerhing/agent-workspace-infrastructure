"""Loop Engineering tick — 机器态续跑桥接（跨 turn / Automation 共用）。

用法（仓库根目录）::

    python harness/loop_tick.py status
    python harness/loop_tick.py prepare          # 写 session-handoff + tick-brief
    python harness/loop_tick.py emit-prompt      #  stdout 输出 loop-tick prompt 正文
    python harness/loop_tick.py advance --note "done KB-M2" --next "MINE-2 ..."
"""

from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
LOOP_STATE_PATH = REPO_ROOT / "harness" / "loop-state.json"
METHODOLOGY_INDEX_PATH = REPO_ROOT / "harness" / "methodology-memory-index.json"
SYNC_COHERENCE_INDEX_PATH = REPO_ROOT / "harness" / "sync-coherence-index.json"
VERIFICATION_INDEX_PATH = REPO_ROOT / "harness" / "verification-snapshot-index.json"
CLOSURE_GATE_INDEX_PATH = REPO_ROOT / "harness" / "closure-gate-index.json"
LIFECYCLE_ERROR_LOG = REPO_ROOT / "harness" / "loop-lifecycle-errors.log"
TICK_PROMPT_PATH = REPO_ROOT / "harness" / "templates" / "loop-tick-prompt.md"
HANDOFF_PATH = REPO_ROOT / "harness" / "session-handoff.md"
TICK_BRIEF_PATH = REPO_ROOT / "harness" / "loop-tick-brief.md"
CONTINUATION_PATH = REPO_ROOT / "apps" / "quant_assistant" / "docs" / "CONTINUATION_PROMPT.md"

SYNC_SOURCES = (
    "TASK_TREES.md",
    "CONTINUATION_PROMPT.md",
    "PROJECT_STATUS.md §5",
    "METHODOLOGY_MEMORY.md",
    "WORKFLOWS.md",
    "harness/reports/orchestrator/latest.md",
    "harness/reports/workers/*.md",
)

# M-17 零写入时 §5 台账末尾强制留痕（见 METHODOLOGY_MEMORY §轮次-20260619-loop49-56）
DEFAULT_M17_ZERO_WRITE_REF = "§轮次-20260619-loop49-56"


def format_methodology_gate_tail(
    *,
    zero_write: bool = True,
    reference: str = DEFAULT_M17_ZERO_WRITE_REF,
) -> str:
    """§5 台账末尾一行 — M-17 零写入留痕或 digest/synthesis 指向。"""
    if zero_write:
        return f"方法论门控：M-17 零写入 · 见 METHODOLOGY {reference}"
    return "方法论门控：见 METHODOLOGY_MEMORY §步骤-digest-* 或 §收口 synthesis-*"


def _now_iso() -> str:
    return datetime.now(UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def load_loop_state() -> dict[str, Any]:
    if not LOOP_STATE_PATH.is_file():
        raise FileNotFoundError(f"missing {LOOP_STATE_PATH}")
    return json.loads(LOOP_STATE_PATH.read_text(encoding="utf-8"))


def save_loop_state(state: dict[str, Any]) -> None:
    state["updated_at"] = _now_iso()
    LOOP_STATE_PATH.write_text(
        json.dumps(state, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def should_stop(state: dict[str, Any]) -> tuple[bool, str]:
    stop_reason = str(state.get("stop_reason") or "").strip()
    if stop_reason:
        return True, f"stop_reason={stop_reason}"
    next_action = str(state.get("next_atomic_action") or "").strip()
    gate = state.get("closure_gate") or {}
    if str(gate.get("status") or "").lower() == "closed" and not next_action:
        return True, "closure_gate=closed"
    return False, ""


def build_tick_brief(state: dict[str, Any]) -> str:
    stopped, reason = should_stop(state)
    lines = [
        "# Loop Tick Brief",
        "",
        f"generated_at: {_now_iso()}",
        f"mode: {state.get('mode', 'autonomous')}",
        f"current_tree: {state.get('current_tree', '')}",
        f"current_slice: {state.get('current_slice', '')}",
        f"last_tick: {state.get('last_tick', '')}",
        "",
        "## Execute Now",
        "",
        str(state.get("next_atomic_action") or "(unset)"),
        "",
        "## Then",
        "",
        str(state.get("next_after") or "(unset)"),
        "",
    ]
    blockers = state.get("blockers") or []
    if blockers:
        lines.extend(["## Blockers", ""])
        for item in blockers:
            if isinstance(item, dict):
                lines.append(f"- [{item.get('severity', 'info')}] {item.get('id', '?')}: {item.get('note', '')}")
        lines.append("")

    if stopped:
        lines.extend(["## STOP", "", reason, ""])
    else:
        lines.extend(
            [
                "## Agent Instruction",
                "",
                "Do NOT ask the user to continue. Execute `next_atomic_action`, sync five sources,",
                "update loop-state.json, then immediately start the next item in the same session.",
                "",
                f"Full protocol: {TICK_PROMPT_PATH.relative_to(REPO_ROOT).as_posix()}",
                "",
            ]
        )
    return "\n".join(lines)


def build_handoff(state: dict[str, Any]) -> str:
    stopped, reason = should_stop(state)
    return "\n".join(
        [
            "# Session Handoff",
            "",
            f"updated_at: {_now_iso()}",
            "",
            "## Current Objective",
            "",
            str(state.get("next_atomic_action") or "awaiting loop-state"),
            "",
            "## Next Step",
            "",
            str(state.get("next_after") or "see loop-state.json"),
            "",
            "## Loop Machine State",
            "",
            f"- tree: {state.get('current_tree')}",
            f"- slice: {state.get('current_slice')}",
            f"- last_tick: {state.get('last_tick')}",
            f"- stop: {reason if stopped else 'none'}",
            "",
            "## Resume Command",
            "",
            "Any new message in Cursor/Trae → read loop-state.json and continue (no new user prompt required).",
            "",
            "```powershell",
            "python harness/loop_tick.py prepare",
            "```",
            "",
        ]
    )


def _load_index_last_lifecycle(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}
    last = payload.get("last_lifecycle")
    return dict(last) if isinstance(last, dict) else {}


def _load_last_lifecycle_run() -> dict[str, Any]:
    return _load_index_last_lifecycle(METHODOLOGY_INDEX_PATH)


def _load_all_lifecycle_runs() -> dict[str, Any]:
    return {
        "methodology_memory": _load_index_last_lifecycle(METHODOLOGY_INDEX_PATH),
        "work_reports": _load_index_last_lifecycle(REPO_ROOT / "harness" / "work-reports-index.json"),
        "sync_coherence": _load_index_last_lifecycle(SYNC_COHERENCE_INDEX_PATH),
        "verification_snapshot": _load_index_last_lifecycle(VERIFICATION_INDEX_PATH),
        "closure_gate": _load_index_last_lifecycle(CLOSURE_GATE_INDEX_PATH),
    }


def _log_lifecycle_failure(*, script: str, detail: str, returncode: int | None = None) -> None:
    """Fail-closed：写入 harness 日志，不阻断 loop（除非脚本本身不可执行）。"""
    rc = "?" if returncode is None else str(returncode)
    line = f"{_now_iso()} FAIL {script} rc={rc} {detail.strip()[:800]}\n"
    try:
        LIFECYCLE_ERROR_LOG.parent.mkdir(parents=True, exist_ok=True)
        with LIFECYCLE_ERROR_LOG.open("a", encoding="utf-8") as handle:
            handle.write(line)
    except OSError:
        pass


def _run_lifecycle_subprocess(script_rel: str, extra_args: list[str] | None = None) -> dict[str, Any]:
    import subprocess
    import sys

    script_path = REPO_ROOT / "harness" / script_rel
    cmd = [sys.executable, str(script_path), "run", "--apply"]
    if extra_args:
        cmd.extend(extra_args)
    result: dict[str, Any] = {"script": script_rel, "ok": False, "returncode": None}
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(REPO_ROOT),
            check=False,
            capture_output=True,
            text=True,
            timeout=180,
        )
        result["returncode"] = proc.returncode
        result["ok"] = proc.returncode == 0
        if not result["ok"]:
            detail = (proc.stderr or proc.stdout or "non-zero exit").strip()
            _log_lifecycle_failure(script=script_rel, detail=detail, returncode=proc.returncode)
    except subprocess.TimeoutExpired:
        _log_lifecycle_failure(script=script_rel, detail="timeout after 180s")
        result["error"] = "timeout"
    except OSError as exc:
        _log_lifecycle_failure(script=script_rel, detail=str(exc))
        result["error"] = str(exc)
    return result


def _run_tick_lifecycle(*, tick_id: str = "", note: str = "") -> list[dict[str, Any]]:
    """每轮 prepare/advance 必跑：五真源 lifecycle + 三治理 lifecycle（与 §5 台账同级）。"""
    work_args: list[str] = []
    if tick_id:
        work_args.extend(["--tick-id", tick_id])
    if note:
        work_args.extend(["--action", note])
    return [
        _run_lifecycle_subprocess("methodology_memory_lifecycle.py"),
        _run_lifecycle_subprocess("work_report_lifecycle.py", work_args or None),
        _run_lifecycle_subprocess("sync_coherence_lifecycle.py"),
        _run_lifecycle_subprocess("verification_snapshot_lifecycle.py"),
        _run_lifecycle_subprocess("closure_gate_lifecycle.py"),
    ]


def cmd_status() -> dict[str, Any]:
    state = load_loop_state()
    stopped, reason = should_stop(state)
    return {
        "stopped": stopped,
        "stop_detail": reason,
        "next_atomic_action": state.get("next_atomic_action"),
        "next_after": state.get("next_after"),
        "updated_at": state.get("updated_at"),
        "last_tick": state.get("last_tick"),
        "last_lifecycle_run": _load_last_lifecycle_run(),
        "lifecycle_runs": _load_all_lifecycle_runs(),
    }


def cmd_prepare(*, run_lifecycle: bool = True) -> dict[str, Any]:
    state = load_loop_state()
    lifecycle: list[dict[str, Any]] = []
    if run_lifecycle:
        lifecycle = _run_tick_lifecycle()
    TICK_BRIEF_PATH.write_text(build_tick_brief(state), encoding="utf-8")
    HANDOFF_PATH.write_text(build_handoff(state), encoding="utf-8")
    return {
        "tick_brief": str(TICK_BRIEF_PATH.relative_to(REPO_ROOT)),
        "session_handoff": str(HANDOFF_PATH.relative_to(REPO_ROOT)),
        "next_atomic_action": state.get("next_atomic_action"),
        "methodology_gate_tail": format_methodology_gate_tail(),
        "lifecycle_runs": lifecycle,
        "last_lifecycle_run": _load_last_lifecycle_run(),
        "lifecycle_index_runs": _load_all_lifecycle_runs(),
    }


def cmd_emit_prompt() -> str:
    if not TICK_PROMPT_PATH.is_file():
        raise FileNotFoundError(TICK_PROMPT_PATH)
    state = load_loop_state()
    stopped, reason = should_stop(state)
    body = TICK_PROMPT_PATH.read_text(encoding="utf-8")
    header = (
        f"<!-- loop-tick generated {_now_iso()} -->\n"
        f"<!-- next_atomic_action: {state.get('next_atomic_action')} -->\n"
    )
    if stopped:
        header += f"<!-- STOP: {reason} -->\n"
    return header + body


def cmd_advance(*, note: str, next_action: str, next_after: str, tick_id: str) -> dict[str, Any]:
    state = load_loop_state()
    state["last_tick"] = tick_id or state.get("last_tick")
    if note:
        state["last_completed_note"] = note
    if next_action:
        state["next_atomic_action"] = next_action
    if next_after:
        state["next_after"] = next_after
    state["last_sync_sources"] = list(SYNC_SOURCES)
    save_loop_state(state)
    lifecycle = _run_tick_lifecycle(tick_id=tick_id, note=note)
    cmd_prepare(run_lifecycle=False)
    status = cmd_status()
    status["lifecycle_runs"] = lifecycle
    status["methodology_gate_tail"] = format_methodology_gate_tail()
    return status


def main() -> int:
    parser = argparse.ArgumentParser(description="Loop Engineering tick bridge")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("status", help="Print loop machine status JSON")
    sub.add_parser("prepare", help="Write loop-tick-brief + session-handoff")
    sub.add_parser("emit-prompt", help="Print loop-tick prompt for Automation")

    adv = sub.add_parser("advance", help="Update loop-state after completing an action")
    adv.add_argument("--note", default="", help="Completed action note")
    adv.add_argument("--next", dest="next_action", required=True, help="Next atomic action")
    adv.add_argument("--next-after", default="", help="Action after next")
    adv.add_argument("--tick-id", default="", help="Tick id e.g. loop5")

    args = parser.parse_args()

    if args.command == "status":
        print(json.dumps(cmd_status(), ensure_ascii=False, indent=2))
        return 0
    if args.command == "prepare":
        print(json.dumps(cmd_prepare(), ensure_ascii=False, indent=2))
        return 0
    if args.command == "emit-prompt":
        print(cmd_emit_prompt())
        return 0
    if args.command == "advance":
        print(
            json.dumps(
                cmd_advance(
                    note=args.note,
                    next_action=args.next_action,
                    next_after=args.next_after,
                    tick_id=args.tick_id,
                ),
                ensure_ascii=False,
                indent=2,
            )
        )
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
