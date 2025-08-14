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

# Only low-SPR (<1) jams, ranked by delta
dart run bin/ev_rank_jam_fold_deltas.dart --dir reports/ --spr low --action jam

# Absolute impact on high-SPR (>=2) spots only
dart run bin/ev_rank_jam_fold_deltas.dart --glob "reports/**/*.json" --spr high --abs-delta --min-delta 1.0
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
