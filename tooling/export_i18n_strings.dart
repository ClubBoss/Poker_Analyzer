// Export RU/EN UI strings for lesson flow and review runner.
// Usage:
//   dart run tooling/export_i18n_strings.dart [--out build/i18n] [--quiet]
// ASCII-only. Deterministic ordering by key. Exit 0.

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  var outDir = 'build/i18n';
  var quiet = false;
  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--out' && i + 1 < args.length) {
      outDir = args[++i];
    } else if (a == '--quiet') {
      quiet = true;
    }
  }

  final out = Directory(outDir);
  out.createSync(recursive: true);

  // Flat keys, sorted to ensure deterministic output.
  const keys = [
    'actions.read',
    'actions.try_demo',
    'actions.start_drills',
    'labels.theory',
    'labels.demos',
    'labels.drills',
    'status.done',
    'status.next',
    'status.unlockable',
    'status.locked',
    'kpi.missed_probes',
    'kpi.family_errors',
    'kpi.answered',
    'kpi.correct',
    'nav.see_also',
    'nav.search_placeholder',
    'buttons.show_token',
    'buttons.continue',
    'buttons.back',
    'buttons.schedule',
    'consent.privacy_note',
    'about.licenses',
  ];

  final en = <String, String>{
    'actions.read': 'Read',
    'actions.try_demo': 'Try demo',
    'actions.start_drills': 'Start drills',
    'labels.theory': 'Theory',
    'labels.demos': 'Demo',
    'labels.drills': 'Drill',
    'status.done': 'Done',
    'status.next': 'Next',
    'status.unlockable': 'Unlockable',
    'status.locked': 'Locked',
    'kpi.missed_probes': 'Missed probes',
    'kpi.family_errors': 'Family errors',
    'kpi.answered': 'Answered',
    'kpi.correct': 'Correct',
    'nav.see_also': 'See also',
    'nav.search_placeholder': 'Search tokens or modules',
    'buttons.show_token': 'Show token',
    'buttons.continue': 'Continue',
    'buttons.back': 'Back',
    'buttons.schedule': 'Schedule',
    'consent.privacy_note': 'Privacy note',
    'about.licenses': 'About & Licenses',
  };

  final ru = <String, String>{
    'actions.read': 'Читать',
    'actions.try_demo': 'Попробовать демо',
    'actions.start_drills': 'Начать тренировки',
    'labels.theory': 'Теория',
    'labels.demos': 'Демо',
    'labels.drills': 'Тренировки',
    'status.done': 'Готово',
    'status.next': 'Далее',
    'status.unlockable': 'Доступно',
    'status.locked': 'Заблокировано',
    'kpi.missed_probes': 'Пропущенные пробы',
    'kpi.family_errors': 'Ошибки семейств',
    'kpi.answered': 'Отвечено',
    'kpi.correct': 'Верно',
    'nav.see_also': 'См. также',
    'nav.search_placeholder': 'Поиск по токенам и модулям',
    'buttons.show_token': 'Показать токен',
    'buttons.continue': 'Продолжить',
    'buttons.back': 'Назад',
    'buttons.schedule': 'Запланировать',
    'consent.privacy_note': 'Уведомление о конфиденциальности',
    'about.licenses': 'О программе и лицензии',
  };

  // Write files in deterministic key order.
  final enOrdered = <String, String>{};
  final ruOrdered = <String, String>{};
  for (final k in keys) {
    enOrdered[k] = en[k] ?? '';
    ruOrdered[k] = ru[k] ?? '';
  }

  File('${out.path}/en.json').writeAsStringSync(jsonEncode(enOrdered));
  File('${out.path}/ru.json').writeAsStringSync(jsonEncode(ruOrdered));

  if (!quiet) {
    stdout.writeln('I18N out=${out.path} files=2 keys=${keys.length}');
  }
}
