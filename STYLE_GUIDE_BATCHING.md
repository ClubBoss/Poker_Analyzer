# STYLE_GUIDE_BATCHING.md — Adaptive Style for Batch Generation (Ultimate v3.1)

## Purpose
Single source of truth for content style when generating batches via Research + Zip. Ensures beginner-friendly tone, full explanations, and Live/Online specificity. Applies to all modules in CURRICULUM_STRUCTURE.md v3.1.

---

## Global Style Tenets
1) Beginner-first: no jargon without an in-line definition.  
2) Explain “why”: every rule and mistake must include the reason.  
3) Step-by-step: build from street fundamentals → advanced patterns.  
4) Live vs Online: call out differences explicitly when relevant.  
5) Mobile-first: short paragraphs, scannable bullets, clear headings.  
6) ASCII-only (7-bit): use '-' not '–/—'; plain quotes; '%' only.  
7) Consistency: IDs and counts per schema; pass content audit before delivery.

---

## Per-File Requirements
### theory.md (450–550 words)
Sections in order:
1. **What it is** (2–3 lines) — define terms plainly.  
2. **Why it matters** (2–3 lines) — outcomes if mastered vs ignored.  
3. **Rules of thumb** (3–5 bullets) — each bullet ends with a short “why”.  
4. **Mini example** (3–5 lines) — include sizing/position, narrate decision.  
5. **Common mistakes** (3 bullets) — each with cause and correction.

### demos.jsonl (2–3 items)
- `steps`: each step ≤ 1 line; narrative for quick replay.  
- Optional `hints` aligned to beginner obstacles.  
- ID format: `<moduleId>:demo:NN` where NN = 01..03.

### drills.jsonl (12–16 items)
- Rationale ≤ 1 line; focus on the key lever.  
- ID format: `<moduleId>:drill:NN` where NN = 01..16.  
- Targets use canonical tokens per spot spec.  
- Include a mix of easy/medium/hard per batch.

---

## Terminology Policy
- First occurrence of a technical term must include a parenthetical gloss.  
  - Example: “string bet (многоходовое внесение фишек, считается нарушением)”  
- Avoid unexplained shorthand (e.g., “dominated”, “reverse implied odds”).  
  - Use: “dominated (ваша рука часто хуже старшей у оппонента)”  
- If a term is live-only or online-only, mark it with `(live)` or `(online)` in-line.

---

## Live vs Online Rubric
- **Acting out of turn / string betting** → mark as **(live)** and explain enforcement.  
- **Auto bet-sizing tools, hotkeys** → mark as **(online)** and risks.  
- **Splashing the pot, chip visibility** → **(live)** with rationale.  
- **Timing tells** → separate bullets for live vs online (latency, multi-tabling).

---

## Math Integration Ladder
- Core: pot odds, EV, fold equity, simple combos — all with concrete numbers.  
- Cash/MTT/HU: only math that directly drives decision in the example.  
- Math Path: deeper derivations; link concepts back to gameplay examples.

---

## Accessibility & Tone
- Neutral, concise, instructional. No hype.  
- Short sentences, active voice.  
- Avoid multi‑clause chains; prefer lists.

---

## Quality Gates (must pass before ZIP delivery)
- ASCII-only check.  
- JSONL validity; unique IDs.  
- Count checks: demos 2–3, drills 12–16.  
- No non-ASCII dashes/quotes.  
- `dart format`, `dart analyze`, `dart run tooling/content_audit.dart` = OK.

---

## STYLE OVERRIDE Template (drop-in for Research prompts)

Audience: beginner-friendly, mobile-first
Theory.md = 450-550 words
  1) What it is (2-3 lines; define terms in plain words)
  2) Why it matters (2-3 lines; outcome if mastered vs ignored)
  3) Rules of thumb (3-5 bullets; each ends with “why”)
  4) Mini example (3-5 lines; position + sizing; narrate reasoning)
  5) Common mistakes (3 bullets; cause + correction)
Demos.jsonl: 2-3 items; each step <= 1 line
Drills.jsonl: 12-16 items; rationale <= 1 line
Terminology: first-use gloss in parentheses; mark (live) or (online) where relevant
ASCII-only (7-bit). Use "-" not "–/—"; plain quotes; "%" only
JSONL valid; IDs per schema; pass `content_audit` before delivery

---

## Example Bullet with “Why”
- Small c-bet on dry A-high boards (extracts thin value and denies random overcards).

## Example Mistake with Fix
- Barreling turn without equity or blockers (часто переигрываете блефы). **Fix:** check more on cards, усиливающих диапазон оппонента.

---

## Enforcement
- Research must copy the STYLE OVERRIDE template verbatim into each batch prompt.  
- Zip must refuse delivery if any gate fails and echo offending files/lines.

