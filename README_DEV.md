# Developer Notes

## Jam/Fold EV Enrichment

Exactly one of `--in`, `--dir`, or `--glob` must be provided. `--out` can only be used with `--in`.

Run only the enrichment tests:

```sh
dart test test/ev/jam_fold_evaluator_test.dart
```

Generate jam vs fold EV for existing reports:

```sh
dart run bin/ev_enrich_jam_fold.dart --in report.json --out report.json
```

Batch enrich an entire directory:

```sh
dart run bin/ev_enrich_jam_fold.dart --dir reports/
```

Use a glob pattern:

```sh
dart run bin/ev_enrich_jam_fold.dart --glob "reports/**/*.json"
```

Preview changes without writing:

```sh
dart run bin/ev_enrich_jam_fold.dart --dir reports/ --dry-run
```

## Jam/Fold Report Summary

Aggregate jam/fold data from enriched reports. Exactly one of `--in`, `--dir`, or `--glob` must be provided. Use `--validate` to ensure every spot has `jamFold` with a `bestAction` of `jam` or `fold`.

Summarize a directory:

```sh
dart run bin/ev_report_jam_fold.dart --dir reports/
```

Validate a single report:

```sh
dart run bin/ev_report_jam_fold.dart --in report.json --validate
```

Fail if jam rate drops below a threshold:

```sh
dart run bin/ev_report_jam_fold.dart --dir reports/ --fail-under 0.95
```

## Jam/Fold Pack Summary

Summarize jam/fold decisions across reports:

```sh
dart run bin/ev_summary_jam_fold.dart --dir reports/
```

## Jam/Fold Delta Ranking

Surface the most impactful jam/fold spots:

```sh
# top 10 hottest spots across a tree
dart run bin/ev_rank_jam_fold_deltas.dart --dir reports/ --limit 10

# rank by absolute impact
dart run bin/ev_rank_jam_fold_deltas.dart --glob "reports/**/*.json" --abs-delta

# top 50, only positive jams with delta >= 0.5
dart run bin/ev_rank_jam_fold_deltas.dart --dir reports/ --limit 50 --action jam --min-delta 0.5

# absolute impact >= 1.0 regardless of action
dart run bin/ev_rank_jam_fold_deltas.dart --glob "reports/**/*.json" --abs-delta --min-delta 1.0

# Only consider reports under "packs/hot/**"
dart run bin/ev_rank_jam_fold_deltas.dart --dir reports/ --include "packs/hot/**"

# Broad include, then exclude archived packs
dart run bin/ev_rank_jam_fold_deltas.dart \
  --glob "reports/**/*.json" \
  --include "reports/**" --exclude "reports/**/archive/**"

# Combine with other filters and CSV
dart run bin/ev_rank_jam_fold_deltas.dart \
  --dir reports/ \
  --include "packs/**" --exclude "packs/**/old/**" \
  --abs-delta --min-delta 1.0 --format csv --fields path,delta,bestAction

> **Shell globbing:** quote patterns to avoid your shell expanding them. Use single quotes on macOS/Linux/PowerShell. On cmd.exe, the shell doesn't expand globs; just quote patterns with spaces, e.g. `--include "* *"`.
> Examples:
> * **bash/zsh:** `--include '* *'`
> * **PowerShell:** `--include '* *'`
> * **cmd.exe:** `--include "* *"`
> If you see `Unknown or incomplete argument: A*s`, wrap the pattern in quotes.

# Only AK combos anywhere
dart run bin/ev_rank_jam_fold_deltas.dart --dir reports/ --include-hand "A*s K*s,A*h K*h"

# Include broad, then exclude suited broadways
dart run bin/ev_rank_jam_fold_deltas.dart \
  --glob "reports/**/*.json" \
  --include-hand "A* K*,Q* J*" --exclude-hand "*s *s"

# Compose with other filters & CSV
dart run bin/ev_rank_jam_fold_deltas.dart \
  --dir reports/ \
  --include-hand "A* A*" \
  --spr mid --action jam --abs-delta --min-delta 0.5 \
  --format csv --fields path,hand,delta

> **Note:** Hand and path glob matching is **case-sensitive** (same as `_globToRegExp`).
> The examples assume uppercase ranks and lowercase suits (e.g., `As Ks`, `*s *s`).
> **Shell globbing:** quote patterns to avoid your shell expanding them. Use single quotes on macOS/Linux/PowerShell. On cmd.exe, the shell doesn't expand globs; just quote patterns with spaces, e.g. `--include-hand "* *"`.
> Examples:
> * **bash/zsh:** `--include-hand '* *'`
> * **PowerShell:** `--include-hand '* *'`
> * **cmd.exe:** `--include-hand "* *"`
> If you see `Unknown or incomplete argument: A*s`, wrap the pattern in quotes.

# Only low-SPR (<1) jams, ranked by delta
dart run bin/ev_rank_jam_fold_deltas.dart --dir reports/ --spr low --action jam

# Absolute impact on high-SPR (>=2) spots only
dart run bin/ev_rank_jam_fold_deltas.dart --glob "reports/**/*.json" --spr high --abs-delta --min-delta 1.0

# Only 'wet' boards (per classifier)
dart run bin/ev_rank_jam_fold_deltas.dart --dir reports/ --texture wet

# Multiple tags: either 'wet' or 'paired'
dart run bin/ev_rank_jam_fold_deltas.dart --glob "reports/**/*.json" --texture wet,paired --limit 50

# Only flop spots, ranked by delta
dart run bin/ev_rank_jam_fold_deltas.dart --dir reports/ --street flop

# Turn-only with absolute impact and CSV fields
dart run bin/ev_rank_jam_fold_deltas.dart \
  --glob "reports/**/*.json" \
  --street turn --abs-delta --min-delta 0.5 \
  --format csv --fields path,board,delta

# One hottest spot per file
dart run bin/ev_rank_jam_fold_deltas.dart --dir reports/ --unique-by path

# One hottest per board across the tree (by absolute impact)
dart run bin/ev_rank_jam_fold_deltas.dart --glob "reports/**/*.json" --abs-delta --unique-by board

# Combine with filters & CSV
dart run bin/ev_rank_jam_fold_deltas.dart \
  --dir reports/ --spr mid --action jam --min-delta 0.5 \
  --unique-by hand --format csv --fields path,hand,delta

# Keep at most 2 hottest spots per file
dart run bin/ev_rank_jam_fold_deltas.dart --dir reports/ --per path --per-limit 2

# Top-3 per hand across the whole tree (by absolute impact)
dart run bin/ev_rank_jam_fold_deltas.dart --glob "reports/**/*.json" --abs-delta --per hand --per-limit 3

# Compose with filters & CSV
dart run bin/ev_rank_jam_fold_deltas.dart \
  --dir reports/ --spr mid --action jam --min-delta 0.5 \
  --per board --per-limit 2 \
  --format csv --fields path,board,delta
```

Alternate output formats:

```sh
# JSONL for easy piping
dart run bin/ev_rank_jam_fold_deltas.dart --dir reports/ --format jsonl

# CSV with selected columns and filters
dart run bin/ev_rank_jam_fold_deltas.dart \
  --glob "reports/**/*.json" \
  --abs-delta --min-delta 1.0 --action any \
  --format csv --fields path,spotIndex,delta,bestAction
```
