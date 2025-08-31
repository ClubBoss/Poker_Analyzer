import 'dart:convert';
import 'dart:io';

class WordRange {
  final int min;
  final int max;
  const WordRange(this.min, this.max);
}

final Map<String, WordRange> _ranges = <String, WordRange>{
  // базовые модули
  'core_rules_and_setup': WordRange(450, 550),
  'core_positions_and_initiative': WordRange(450, 600),
  // подняли потолок до 700
  'core_pot_odds_equity': WordRange(450, 700),
};

final Map<String, List<String>> _requiredPhrases = <String, List<String>>{
  // минимальные обязательные фразы для контроля покрытия
  'core_positions_and_initiative': <String>[
    'opening ranges by seat',
    'initiative vs no-initiative',
  ],
  // при желании можно добавить для других модулей
};

String _stripForCount(String s) {
  // убрать [[IMAGE: ...]] и код-блоки ```...```, схлопнуть пробелы
  s = s.replaceAll(RegExp(r'\[\[IMAGE:[^\]]+\]\]'), ' ');
  s = s.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s.trim();
}

int _countWords(String text) {
  if (text.isEmpty) return 0;
  final parts = text.split(RegExp(r'\s+'));
  return parts.where((w) => w.isNotEmpty).length;
}

List<String> _checkJsonlSpotKind(String path) {
  final errs = <String>[];
  if (!File(path).existsSync()) return errs;
  final lines = File(path).readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    final raw = lines[i].trim();
    if (raw.isEmpty) continue;
    try {
      final obj = jsonDecode(raw);
      if (obj is! Map || !obj.containsKey('spot_kind')) {
        errs.add('$path line ${i + 1}: missing spot_kind');
      }
    } catch (_) {
      errs.add('$path line ${i + 1}: invalid json');
    }
  }
  return errs;
}

int _runForId(String id) {
  final contentDir = 'content/$id/v1';
  final theoryPath = '$contentDir/theory.md';
  final drillsPath = '$contentDir/drills.jsonl';
  final demosPath = '$contentDir/demos.jsonl';

  final errors = <String>[];

  // наличие файлов
  if (!File(theoryPath).existsSync()) {
    errors.add('missing file: $theoryPath');
  }
  if (!File(drillsPath).existsSync()) {
    errors.add('missing file: $drillsPath');
  }
  if (!File(demosPath).existsSync()) {
    errors.add('missing file: $demosPath');
  }

  // wordcount
  final range = _ranges[id] ?? const WordRange(450, 600);
  if (File(theoryPath).existsSync()) {
    final raw = File(theoryPath).readAsStringSync();
    final counted = _stripForCount(raw);
    final wc = _countWords(counted);
    if (wc < range.min || wc > range.max) {
      errors.add('theory.md words=$wc not in [${range.min},${range.max}]');
    }

    // обязательные фразы
    final req = _requiredPhrases[id] ?? const <String>[];
    for (final phrase in req) {
      if (!raw.contains(phrase)) {
        errors.add('missing phrase: "$phrase"');
      }
    }
  }

  // drills: наличие spot_kind
  errors.addAll(_checkJsonlSpotKind(drillsPath));

  if (errors.isEmpty) {
    print('OK id=$id');
    return 0;
  } else {
    for (final e in errors) {
      stderr.writeln(e);
    }
    return 2;
  }
}

void main(List<String> args) {
  String? id;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--id') {
      if (i + 1 >= args.length) {
        stderr.writeln('missing id');
        exit(2);
      }
      id = args[++i];
    } else {
      // игнорировать прочие аргументы, чтобы не ломать вызовы
    }
  }
  if (id == null) {
    stderr.writeln('missing id');
    exit(2);
  }
  final code = _runForId(id!);
  exit(code);
}