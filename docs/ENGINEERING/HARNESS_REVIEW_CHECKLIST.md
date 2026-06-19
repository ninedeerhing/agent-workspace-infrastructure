# Engineering Review Checklist

Project-level methodology is governed by `AGENTS.md`. This document provides review check questions only.

## 1. Entry & Fact Source

- Has the corresponding fact source document been updated?
- Can the entry still be quickly found from `AGENTS.md`?

## 2. Risk & Boundaries

- Have high-risk boundaries been declared?
- Have failure modes and rollback methods been described?
- Has the shared environment `fail-closed` principle been preserved?

## 3. Environment & Testing

- Have executable verification commands been provided?
- Have minimal regression tests been added?
- Have `db` or `external` tests been incorrectly placed in CI fast gates?

## 4. Document Freshness

- Has new stale information been introduced?
- Has `docs/PROJECT_STATUS.md` update been missed?

## 5. Conclusion

- Is this change genuinely proven by harness evidence, not just subjective judgment?
