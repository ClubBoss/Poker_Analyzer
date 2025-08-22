# NEXT Runbook — Poker Analyzer

## Purpose
Define how to compute NEXT batch/module for skeleton or content.

## Rules
1. Content source (Research) = RESEARCH_QUEUE.md.
   Skeleton source (Codex)  = tooling/curriculum_ids.dart.
2. Status file = curriculum_status.json (tracks completed modules).  
3. NEXT = first module in RESEARCH_QUEUE.md that is not present at same index in curriculum_status.json.  

## Flow
- Codex: adds skeleton loader + updates curriculum_status.json.  
- Research: generates batch content using STYLE OVERRIDE.  
- Zip: packages, audits, commits.  

## Notes
- Never edit enums retroactively (append-only).  
- Content audit must always pass before merging.  
- Live vs Online differences must be explicit.  
- Math modules progress step-by-step; no skipping.
