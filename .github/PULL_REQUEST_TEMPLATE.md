## Scope guard (auto-read by assistants)
- Allowed changes: `bin/**`, `test/ev/**`, `tool/l3/**`, `lib/l3/**`
- Must run: `bash tool/dev/precommit_sanity.sh`
- Do NOT edit: `.github/workflows/**` (except calling the sanity script), `lib/services/**` (non-L3), `lib/l10n/**`, `docs/**`, `README.md`
- ASCII only (CI enforced). To fix: `tool/dev/ascii_fix_all.sh`
