# Daily Git Push Report - 20260628

- **Checked at**: 2026-06-28 20:01:51
- **Dry run**: False
- **Schedule task id**: `daily-ops` calls `daily-git-push` after `daily-compliance`
- **Policy**: main-only local branch | dual-repo | upstream-aware ahead count | push only when ahead > 0 | no force | fail-closed on non-main / staged secrets

## Dual-repo model

| Label | GitHub repo | Scope |
|-------|-------------|-------|
| Raindeer-AWI | `agent-workspace-infrastructure` | AWI architecture only |
| Quant Assistant | `raindeer-quant-assistant` | Separate product repo |

## Summary

| Repo | GitHub | Local branch | Upstream | Ahead | Action | Reason |
|------|--------|--------------|----------|-------|--------|--------|
| `Raindeer-AWI` | `agent-workspace-infrastructure` | main | origin/raindeer-AWI | 3 | pushed | ahead=3 |
| `Quant Assistant` | `raindeer-quant-assistant` | main | origin/main | 3 | pushed | ahead=3 |

## Details

### Raindeer-AWI - `agent-workspace-infrastructure`

- scope: AWI architecture / Harness / governance only
- path: `E:\raindeer`
- action: **pushed**
- local branch: main | upstream: origin/raindeer-AWI | ahead: 3
- push target: `git push origin HEAD:raindeer-AWI`
- reason: ahead=3
```text
## main...origin/raindeer-AWI [ahead 3]
 m apps/quant_assistant
 M harness/closure-gate-index.json
 M harness/methodology-memory-index.json
 M harness/sync-coherence-index.json
 M harness/verification-snapshot-index.json
 M harness/work-reports-index.json
?? harness/reports/daily-compliance-20260628.md
```

**push output:**
```text
To https://github.com/ninedeerhing/agent-workspace-infrastructure.git
   a3e1914..41d22fb  HEAD -> raindeer-AWI
```

### Quant Assistant - `raindeer-quant-assistant`

- scope: Separate product repo; not part of AWI publish
- path: `E:\raindeer\apps\quant_assistant`
- action: **pushed**
- local branch: main | upstream: origin/main | ahead: 3
- push target: `git push origin HEAD:main`
- reason: ahead=3
```text
## main...origin/main [ahead 3]
 M src/qa/quant_mining/mining_runner.py
 M src/qa/ui/chat_brain.py
 M src/qa/ui/factor_library_insights.py
?? src/qa/quant_mining/operator_reviewer_authorization_evidence_review.py
?? tests/test_operator_reviewer_authorization_evidence_review_surface_unit.py
?? tests/test_operator_reviewer_authorization_evidence_review_unit.py
```

**push output:**
```text
To https://github.com/ninedeerhing/raindeer-quant-assistant.git
   ed420d2..80366f5  HEAD -> main
```

## Fail-closed rules

- Block if local branch is not `main` (policy: main-only development; merge/delete branch and checkout main)
- Block push if staged files match: `.env` | `.env.local` | `credentials.json` | `secrets.*`
- Never use `git push --force` or `--force-with-lease`
- Skip when no upstream tracking branch or no commits ahead of upstream
- AWI root must **not** assume `origin/main` when upstream is `origin/raindeer-AWI`
- Do **not** auto-delete user branches; blocked exit 1 surfaces in Automation
