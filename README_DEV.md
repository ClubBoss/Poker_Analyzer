# Developer Notes

## Jam/Fold EV Enrichment

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
