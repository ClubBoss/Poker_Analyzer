# Prompt Rules - Poker Analyzer

- Single-module flow. Header format must be: `GO MODULE: <id>`.
- Dispatcher must inject `{{MODULE_ID}}`, `{{SHORT_SCOPE}}`, and `{{SPOTKIND_ALLOWLIST}}` from SSOT.
- Use ASCII in prompts. Replace any smart quotes or bullets with ASCII equivalents.
- After content is produced, run: `dart run tooling/content_audit.dart <module_id>` before merge.
- Do not invent SpotKind values. If allowlist is insufficient, file a Codex PR first.
