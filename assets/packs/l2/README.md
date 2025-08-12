# Level 2 Training Packs

This directory contains automatically generated Level 2 packs. Three subtypes are available:

- `open-fold/` – preflop opening decisions for positions from EP through BB.
- `3bet-push/` – 3‑bet shove decisions grouped by stack‑depth buckets.
- `limped/` – post‑flop play in limped pots from the blinds.

Each pack defines basic metadata and a list of spots used during generation. Packs chain via
`stage.unlockAfter` to enforce progression.
