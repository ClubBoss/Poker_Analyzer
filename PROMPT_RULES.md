# Prompt Rules
Dispatcher injects allowlists; run audit; do not invent SpotKind.

---

## ALLOWLIST ENFORCEMENT
- tooling/allowlists/target_tokens_allowlist_<module>.txt MUST list all unique 'target' tokens from content/<module>/v1/drills.jsonl, one per line, ASCII-only.
- 'none' is not allowed.
- Packs without a correct allowlist are rejected by auditor, pre-commit, and CI.
