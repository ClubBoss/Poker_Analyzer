# Poker Analyzer - Content Schemas

This file describes the minimal schema that research output must follow.

## theory.md
- Plain text, ASCII-only.
- Contains required section headers exactly:
  - What it is
  - Why it matters
  - Rules of thumb
  - Mini example
  - Common mistakes
- Optional if needed:
  - Mini-glossary
  - Contrast line
- Word count target: 450-550.

## demos.jsonl
Each line: JSON object with fields
- id: "<module_id>:demo:NN"
- title: string
- steps: array<string>  // each string is single-line ASCII
- hints: array<string>  // optional, only if supported by app; each single-line ASCII

2-3 lines total.

## drills.jsonl
Each line: JSON object with fields
- id: "<module_id>:drill:NN"
- spotKind: string  // must exist in SSOT SpotKind list
- params: object
- target: array<string>  // each is snake_case: ^[a-z0-9_]+$
- rationale: string  // single-line ASCII

12-16 lines total.

Notes:
- IDs must be unique within a module file.
- Keep tokens concise for mobile UI. Avoid sentences in "target".
- Do not invent new SpotKind values in content.
