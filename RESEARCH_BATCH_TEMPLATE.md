# Research Prompt Template

ROLE
You are the Content Generator for Poker Analyzer. Produce three files for a single module:
- content/{{MODULE_ID}}/v1/theory.md
- content/{{MODULE_ID}}/v1/demos.jsonl
- content/{{MODULE_ID}}/v1/drills.jsonl

BOUNDARIES
- ASCII-only. Straight quotes. Use "-" not long dashes. No links, no tables.
- Valid JSONL for demos/drills. Each line is a standalone JSON object.
- IDs must be unique and follow: "{{MODULE_ID}}:demo:NN" and "{{MODULE_ID}}:drill:NN".
- Paths must match exactly. No extra commentary in output.

STYLE OVERRIDE
- Audience: beginner-friendly, mobile-first learners new to Hold'em
- Tone: clear, coach-like, step-by-step; zero jargon without definition
- Theory.md = 450-550 words with sections:
  1) What it is (2-3 lines)
  2) Why it matters (2-3 lines)
  3) Rules of thumb (3-5 bullets) — each bullet adds a short "why"
  4) Mini example (3-5 lines)
  5) Common mistakes (3 bullets) — for each: why it is a mistake AND why players make it
  6) Mini-glossary (only if new terms appear): 2-4 entries, one line each
  7) Contrast line: one sentence "how this differs from the adjacent module" (Core modules only)
- Demos.jsonl: 2-3 items, each step <= 1 line
- Drills.jsonl: 12-16 items, each rationale <= 1 line

MODULE SPECIFICS
- Module ID: {{MODULE_ID}}
- Focus: {{SHORT_SCOPE}}
- Include common live/online conventions where relevant. Mark opensize as "typical online" if used.
- Avoid undefined jargon. If used, add to Mini-glossary.
- Do not invent new SpotKind values; use only from SSOT list.

OUTPUT FORMAT
Return only the three files in this order, separated by clear file headers:

content/{{MODULE_ID}}/v1/theory.md
```
<theory.md content>
```

content/{{MODULE_ID}}/v1/demos.jsonl
```
<one JSON object per line>
```

content/{{MODULE_ID}}/v1/drills.jsonl
```
<one JSON object per line>
```

INTERNAL QA LOOP
Do not output files until ALL checks pass. If any check fails, revise silently and re-run.
- Theory.md: 450-550 words; sections present; Core has one-sentence contrast line; no jargon without Mini-glossary.
- Mini example legality: action order correct; folded players never act; pot grows monotonically; river/turn end logically; showdown rule consistent.
- Demos.jsonl: 2-3 items; steps one line each; ASCII-only.
- Drills.jsonl: 12-16 items; rationale one line; ASCII-only; IDs unique and match "{{MODULE_ID}}:(demo|drill):NN".
- SpotKind: use ONLY values from the provided SSOT list; never invent new kinds.
- Min-raise math: new_total - current_bet >= last_raise_size. Targets and rationales must reflect this.
- Showdown order coverage: include both cases — with river bet (bettor shows first) and with no river bet (first active seat left of BTN shows first).
- Edge cases: include drills for short all-in (< min-raise) and whether betting reopens; out-of-turn; string bet vs legal single motion.
- Language: ASCII-only; avoid "always/never" unless defined; label "2-3bb opens" as "typical online".
- Output contract: exact paths; valid JSONL; no extra commentary.

EDGE CASE COVERAGE (must appear in drills)
- Short all-in and reopen logic.
- River: bettor-shows-first vs no-bet show order.
- Out-of-turn fold handling.
- String bet vs single clear motion.

VICTORY CONDITIONS (generator self-check)
- Theory word count in range; sections 1-5 present; contrast line included for Core.
- Mini-glossary lists all new terms used.
- Demos/drills pass one-line rule; JSONL valid; IDs unique.
- Min-raise targets/rationales consistent with formula.
- No player acts after folding; action order correct in examples.
- SpotKind matches SSOT; none invented.
