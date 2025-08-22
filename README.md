Poker Analyzer

Poker Analyzer - платформа для анализа и обучения принятию решений в покере (Texas Hold'em). Проект фокусируется на корректности и измеримой выгоде (EV-first), автоматизации пайплайна и минимальных диффах при разработке.

What it does

Session Player (L2/L3/L4)
Тренажёр спотов: префлоп push/fold (L2), постфлоп jam vs bet/raise (L3), ICM-сценарии (L4). Ошибки сохраняются, повторное обучение ускоряется.

EV инструменты (CLI)
Генерация и обогащение отчётов jam vs fold EV, агрегирование/ранжирование дельт, CSV/JSONL вывод для быстрой аналитики.

Data-driven маппинги
Действия и сабтайтлы задаются картами (SSOT), без разнесённых switch.

Автоген паков/данных
Сборка тренировочных паков, конвертеры форматов, интеграция с проверками целостности.

CI-поддержка дисциплины
Автоформат, advisory-анализ, дымовые тесты и охранные проверки на этапе PR.

Приложение не ограничено «турнирным» режимом в формулировке; модули включают турнирные аспекты (ICM), но архитектурно ориентировано на решения в целом.

Architecture (high-level)
+-------------+       +-----------------+
| Flutter UI  |<----->| Learning Engine |
+-------------+       +-----------------+
        |                      |
        v                      v
+-----------------+    +----------------------+
| Autogen Pipeline|    | Theory/EV Integrity  |
+-----------------+    +----------------------+


Flutter UI - интерфейс тренажёра и отчётов

Learning Engine - исполнение сценариев и логика обучения

Autogen Pipeline - сборка паков/данных, конвертеры

Integrity - проверки данных/теории/EV в CI

Install & Run

Flutter 3.0+

flutter pub get

flutter gen-l10n (локализация)

(опц.) Предсобрать паки: dart run tool/precompile_all_packs.dart

Старт:

flutter run -t main.dart
# или сборка демо
flutter build apk --target=main.dart

Dev workflow

Release-driven, EV-first. Минимальные диффы (1–2 файла), обратимость.

Codex цикл: Prompt → Codex → PR → анализ → следующий Prompt.

PR Template (Quality Footer) - чек-лист дисциплины в каждом PR.

CI (PR):

Autoformat - применяет dart format и пушит фикс в PR-ветку;

Fast checks - flutter analyze в advisory-режиме (не блокирует merge).

Enum discipline: SpotKind - append-only; dev-guard ловит переименования/перестановки.

Canonical guard централизован (ровно 1 вызов, контролируется тестом):

!correct && autoWhy && (spot.kind == SpotKind.l3_flop_jam_vs_raise || spot.kind == SpotKind.l3_turn_jam_vs_raise || spot.kind == SpotKind.l3_river_jam_vs_raise) && !_replayed.contains(spot)

Local quick checks (без Flutter)
# Один охранный тест (ровно одно место canonical guard)
dart test -r expanded test/guard_single_site_test.dart

# Дымовые тесты (пример)
dart test -r expanded test/mvs_player_smoke_test.dart test/spotkind_integrity_smoke_test.dart


Актуальные CLI-команды для EV (подробнее см. README_DEV.md):

# Запуск unit-тестов проекта
flutter test

# Валидация теории/контента
dart run tool/validate_training_content.dart --ci

# Предсборка тренировочных паков
dart run tool/precompile_all_packs.dart

Contributing

Ветки в ASCII, именование codex/<task>.

Соблюдать enum append-only, single guard site, tiny diffs.

Дополнительные инструкции см. в AGENTS.md.

dart format и flutter analyze проходят в CI автоматически; локально можно воспроизвести:

dart format --set-exit-if-changed .
dart analyze

Troubleshooting

Если Git жалуется на refs/HEAD:

tool/dev/check_head_refs.sh
echo 'ref: refs/heads/main' > .git/HEAD


Case-sensitive конфликты в .github/* (macOS): нормализуйте регистр через git mv или восстановление из origin/main.

License

© 2024 Poker Analyzer contributors. License pending.