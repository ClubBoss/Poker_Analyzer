// ASCII-only; pure Dart.
// Usage: dart run tool/validate_curriculum_scaffolding.dart --every=3 --tracks=Core,Cash,Online

import 'dart:io';

void main(List<String> args) {
  int every = 3;
  List<String> tracks = const ['Core', 'Cash', 'Online'];

  for (final a in args) {
    final s = a.split('=');
    if (s.isEmpty) continue;
    final key = s.first.replaceAll('--', '').trim();
    final val = s.length > 1 ? s.sublist(1).join('=').trim() : '';
    if (key == 'every' && val.isNotEmpty) {
      final n = int.tryParse(val);
      if (n != null && n > 0) every = n;
    } else if (key == 'tracks' && val.isNotEmpty) {
      tracks = val
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }

  final prefixMap = <String, String>{
    'Core': 'core_',
    'Cash': 'cash_',
    'Online': 'online_',
  };

  final root = Directory('content');
  if (!root.existsSync()) {
    stderr.writeln('content directory not found');
    exit(1);
  }

  final allDirs =
      root
          .listSync(followLinks: false)
          .whereType<Directory>()
          .map((d) => d.path.split(Platform.pathSeparator).last)
          .toList()
        ..sort();

  final missing = <String>[];
  int checkedModules = 0;
  int missingRecap = 0;
  int missingQuiz = 0;

  for (final track in tracks) {
    final prefix = prefixMap[track];
    if (prefix == null) continue;
    final modules = allDirs.where((name) => name.startsWith(prefix)).toList();
    // 1-based index; check every N-th module.
    for (var i = 0; i < modules.length; i++) {
      final idx1 = i + 1;
      if (idx1 % every != 0) continue;
      final id = modules[i];
      final base = 'content/$id/v1';
      final recap = File('$base/recap.md');
      final quiz = File('$base/quiz.jsonl');
      checkedModules += 1;
      if (!recap.existsSync()) {
        missing.add('MISSING recap: $base/recap.md');
        missingRecap += 1;
      }
      if (!quiz.existsSync()) {
        missing.add('MISSING quiz: $base/quiz.jsonl');
        missingQuiz += 1;
      }
    }
  }

  if (missing.isEmpty) {
    print('OK');
    print('SUMMARY: checked $checkedModules modules; missing recap=0, quiz=0');
    exit(0);
  } else {
    for (final m in missing) {
      print(m);
    }
    print(
      'SUMMARY: checked $checkedModules modules; missing recap=$missingRecap, quiz=$missingQuiz',
    );
    exit(1);
  }
}
