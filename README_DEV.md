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
