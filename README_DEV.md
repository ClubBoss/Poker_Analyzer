# Developer Notes

## Theory Injection Stack — Build & Test

Run static analysis and tests:

```sh
./tool/test_all.sh
```

To experiment locally you can toggle preferences:

```dart
SharedPreferences prefs = await SharedPreferences.getInstance();
await prefs.setBool('theory.schedulerEnabled', true);
await prefs.setBool('theory.ablationEnabled', false); // flip ablation
await prefs.setInt('theory.maxPerModule', 3); // adjust caps
```

## Jam/Fold EV Enrichment

Run only the enrichment tests:

```sh
dart test test/ev/jam_fold_evaluator_test.dart
```

Generate jam vs fold EV for existing reports:

```sh
dart run bin/ev_enrich_jam_fold.dart --in report.json --out report.json
```
