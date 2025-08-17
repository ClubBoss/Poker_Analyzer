```markdown
# Poker Analyzer

Poker Analyzer is a production-ready platform for training and analyzing tournament poker decisions.

## Key Features
- Push/fold drills with EV and ICM metrics
- Postflop decision practice with mistake tracking
- Theory injection and interactive lessons
- Automated pack generation and plug-in converters
- Adaptive learning paths with progress charts

## Architecture Overview 
```

+-------------+       +-----------------+
\| Flutter UI  |<----->| Learning Engine |
+-------------+       +-----------------+
\|                      |
v                      v
+-----------------+    +----------------------+
\| Autogen Pipeline|    | Theory Integrity CI  |
+-----------------+    +----------------------+

````
- **Flutter UI** - visual interface for training and analytics  
- **Autogen Pipeline** - scripts compiling packs and theory data  
- **Learning Engine** - evaluates decisions and adapts paths  
- **Theory Integrity CI** - automated checks validating training content

## Installation & Setup
1. Install Flutter 3.0 or higher.
2. Run `flutter pub get` to install dependencies.
3. Run `flutter gen-l10n` to generate localization files.
4. Precompile training packs with `dart tools/precompile_all_packs.dart`.
5. Launch with `flutter run`.

### Demo Build
Run a lightweight demo:
```bash
flutter run -t main.dart
flutter build apk --target=main.dart
````

## Dev setup

Install pre-commit hooks:

```bash
ln -sf ../../tool/dev/precommit_sanity.sh .git/hooks/pre-commit
```

## Usage Examples

* **Run a training pack**: `flutter run`
* **Verify theory content**: `dart tools/validate_training_content.dart --ci`
* **Generate packs**: `dart tools/precompile_all_packs.dart`
* **Path YAML Visualizer**: open `tools/path_yaml_visualizer.html`
* **Pack Library Publisher Dashboard**: open `tools/publisher_dashboard.html`

## Contributing

* Use branches prefixed with `codex/<task>` using ASCII characters.
* Run tests with `flutter test` and validate content via `dart tools/validate_training_content.dart --ci`.
* Validate seed files: `dart run bin/usf_lint.dart <seed_directory>`.
* Precompile packs before committing: `dart tools/precompile_all_packs.dart`.
* For plug-in development, see [docs/plugins/README.md](docs/plugins/README.md) and [PLUGIN\_DEV\_GUIDE](docs/plugins/PLUGIN_DEV_GUIDE.md).

## Troubleshooting

If Git reports hidden characters in refs:

```bash
tools/check_head_refs.sh
echo 'ref: refs/heads/main' > .git/HEAD
```

## CI & QA

GitHub Actions run unit tests, build the demo APK, enforce theory integrity, and manage formatting.

### CI configuration

* **Fast checks (format+analyze)**: run on every PR, but **non-blocking**.

  * `dart format` issues auto-fixed and pushed back to PR branch.
  * `flutter analyze` runs in advisory mode (warnings visible, merge allowed).
* **Autoformat bot**: ensures consistent code style without manual work.
* **Coverage gate**: validates training theory coverage.

  * `COVERAGE_MODE` - `soft` (default) or `strict`.
  * `COVERAGE_MIN_UNIQUE_TAGS` - minimal distinct tags (default `5`).
  * `COVERAGE_MIN_PCT` - minimal tag coverage fraction (default `0.35`).

## License & Credits

© 2024 Poker Analyzer contributors. License pending.

# Developer Notes (local sanity)

## Quick Checks

Run the canonical guard test:

```bash
dart test -r expanded test/guard_single_site_test.dart
```

Run smoke tests (no Flutter required):

```bash
dart test -r expanded test/mvs_player_smoke_test.dart test/spotkind_integrity_smoke_test.dart
```

## CI parity

On every PR, the following run automatically:

* `dart format` (auto-fixed by bot if needed)
* `flutter analyze` (advisory only, non-blocking)
* smoke tests (pure Dart)

Reproduce locally:

```bash
dart format --set-exit-if-changed .
dart analyze
```

## FAQ

**Q:** PR упал из-за формата. Что делать?
**A:** Ничего — бот сам применит `dart format` и запушит изменения.

**Q:** Можно ли мержить PR с ворнингами от `flutter analyze`?
**A:** Да, анализатор работает в advisory-режиме.

**Q:** Какие тесты можно гонять без Flutter?
**A:** Все smoke-тесты:

* `mvs_player_smoke_test.dart`
* `spotkind_integrity_smoke_test.dart`
* `guard_single_site_test.dart`
