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
