import json
import shutil
import subprocess
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


def run_memory_validator(repo_root: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [
            sys.executable,
            str(REPO_ROOT / "harness" / "validate_awi_memory.py"),
            "--repo-root",
            str(repo_root),
            "--json",
        ],
        cwd=REPO_ROOT,
        text=True,
        capture_output=True,
        check=False,
    )


def test_memory_os_contract_is_valid() -> None:
    result = run_memory_validator(REPO_ROOT)

    assert result.returncode == 0, result.stdout + result.stderr
    report = json.loads(result.stdout)
    assert report["summary"]["findings"] == 0
    assert any(
        check["name"] == "memory-os invariants" and check["status"] == "PASS"
        for check in report["checks"]
    )


def test_memory_validator_rejects_unknown_source_reference(tmp_path: Path) -> None:
    harness_dir = tmp_path / "harness"
    harness_dir.mkdir()
    shutil.copy(REPO_ROOT / "harness" / "memory-os.json", harness_dir / "memory-os.json")
    shutil.copy(REPO_ROOT / "harness" / "memory-os.schema.json", harness_dir / "memory-os.schema.json")
    shutil.copy(REPO_ROOT / "harness" / "source-index.json", harness_dir / "source-index.json")

    memory_os_path = harness_dir / "memory-os.json"
    memory_os = json.loads(memory_os_path.read_text(encoding="utf-8"))
    memory_os["slots"][0]["source_refs"].append("missing-source-id")
    memory_os_path.write_text(json.dumps(memory_os, ensure_ascii=False), encoding="utf-8")

    result = run_memory_validator(tmp_path)

    assert result.returncode == 1
    report = json.loads(result.stdout)
    assert any(finding["code"] == "MEM-SOURCE-REF" for finding in report["findings"])
