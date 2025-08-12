# Level 2 Training Packs

This directory contains automatically generated Level 2 packs. Two subtypes are available:

- `open_fold/` – preflop opening decisions for positions from EP through BB.
- `3bet_push/` – 3‑bet shove decisions grouped by stack‐depth buckets (10–15bb up to 35–40bb).

Each pack defines basic metadata and a list of spots used during generation. Packs chain via
`stage.unlockAfter` to enforce progression.
