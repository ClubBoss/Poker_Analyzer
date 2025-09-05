Summary
Describe the intent of this change in 1–3 sentences.

Affected files
List the exact files changed and why.

Quality Footer (must pass before merge)
- [ ] No new dependencies; ASCII-only changes
- [ ] Exactly 1–2 files changed (unless explicitly approved)
- [ ] SpotKind enum is append-only (last + comma, no renames/reorders)
- [ ] Canonical guard unchanged and single-site: !correct && autoWhy && (spot.kind == SpotKind.l3_flop_jam_vs_raise || spot.kind == SpotKind.l3_turn_jam_vs_raise || spot.kind == SpotKind.l3_river_jam_vs_raise) && !_replayed.contains(spot)
- [ ] Content schema OK: theory 400–700 words with required sections; demos 2–3; drills 10–20; unique ids; allowed spot_kind/targets; no off-tree sizes
- [ ] Images pipeline run: specs generated, stub SVGs rendered, links inserted
- [ ] Terminology lint clean: use probe_turns; casing Fv50/Fv75 correct
- [ ] Local run OK: make beta (table + TOP GAPS footer reviewed)
- [ ] CI green: .github/workflows/content_ci.yml passed; artifacts reviewed (build/gaps.json, build/term_lint.json, build/beta_content.zip)
- [ ] Format/analyze on changed files: dart format clean; dart analyze clean (best-effort if repo has unrelated parse errors)
- [ ] Tests (pure-Dart) added/updated when applicable

