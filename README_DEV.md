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
