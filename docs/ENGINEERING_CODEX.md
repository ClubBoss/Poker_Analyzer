# Engineering Codex

## Versions & Tooling
- Flutter 3.27.x (зафиксировано в CI).
- Dart берём из Flutter (`flutter dart --version`).
- CLI приоритет флагов: `--weights` > `--weightsPreset` > default; при одновременной передаче выводится warning в stderr.

## Branches & Commits
- Бранчи: feat/fix/chore/docs/hotfix.
- Conventional commits: `feat: ...`, `fix: ...`, `chore: ...`, `test: ...`, `docs: ...`, `refactor: ...`.

## Pre-commit
Установка:
```bash
ln -sf ../../tool/dev/precommit_sanity.sh .git/hooks/pre-commit
Флаги:

PRECOMMIT_SCOPE=all - формат/анализ по всему репо.

PRECOMMIT_RUN_TESTS=1 - дополнительно гоняет dart test test/l3_*.dart.

Testing
Hermetic CLI tests: временная директория через Directory.systemTemp.

Проверяем структуру и заголовки, избегаем "хрупких" абсолютных значений.

Фиксируем seed (например, 111) для генеративных путей.

L3 Pipeline
Генерация: tool/autogen/l3_board_generator.dart

Запуск: tool/l3/pack_run_cli.dart

Метрики/отчёты: tool/metrics/l3_packrun_report.dart, tool/metrics/l3_ab_diff.dart

CI
Слои L2/L3. В main - только после зелёного CI.

Артефакты: l3_ab_<seed>.md, l3_report_<seed>.md (см. Actions artifacts).