# Style Guide for Content Generation — Single‑Module Mode (v3)

Batch mode is deprecated. Every prompt targets **one module** and includes `MODULE SPECIFICS` and `VICTORY CONDITIONS`.

---

## Global Rules
- Audience and tone tailored per module.
- Theory.md: 450–550 words with mandatory sections.
- Demos: 2–3 items, steps single‑line.
- Drills: 12–16 items, rationale <= 1 line.
- ASCII‑only; no smart quotes/dashes; use plain quotes and "-".
- JSONL: line‑delimited; unique IDs (<moduleId>:demo:NN, <moduleId>:drill:NN).

## Mandatory Sections in Theory.md
1) What it is — define simply.  
2) Why it matters — connect to win rate/EV.  
3) Rules of thumb — 3–5 bullets, each with a short **why**.  
4) Mini example — concrete, minimal math, readable on mobile.  
5) Common mistakes — exactly 3 bullets. For each provide:
   - **Why this is a mistake** (mechanics/EV/coverage),
   - **Why players make it** (habit, bias, misread).
6) Mini‑glossary (conditional) — 2–4 entries if new terms appear.  
7) Contrast line (Core only) — one sentence that distinguishes this module from the adjacent one.

## MODULE SPECIFICS (required)
Include a block named `MODULE SPECIFICS` in every prompt with 5–7 bullets:
- Emphasis (math depth, exploit vs GTO, live vs online).
- Constraints (positions, stacks, bet sizes, board types).
- Example guidance (what hands/boards to use).
- Pitfalls to spotlight.

## VICTORY CONDITIONS (required)
At the end of every prompt, include a checklist that must be satisfied in the output:
- Theory.md contains all required sections.  
- Demos.jsonl and drills.jsonl counts and formats match spec, IDs unique.  
- For Math modules: a one‑line **sanity check** validates the formula in the example.  
- For HU/Live modules: include a **population exploit hook** line in drills.  
- ASCII‑only; passes `content_audit.dart` and smoke tests.

## Examples
### Core fundamentals
- Audience: beginner‑friendly; tone: coach‑like, structured
- Emphasis: practical rules and common leaks
- Must include a contrast line to adjacent core modules

### Math modules
- Audience: intermediate; tone: precise, didactic
- Emphasis: step‑by‑step procedures; add a sanity‑check line

### HU/Live modules
- Audience: practical grinders; tone: concise, actionable
- Emphasis: real‑table dynamics; add a population‑exploit hook in drills
