import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../tooling/curriculum_ids.dart'; // kCurriculumIds

void main() {
  final ids = List<String>.from(kCurriculumIds);
  final dir = Directory('lib/packs');
  if (!dir.existsSync()) {
    stderr.writeln('lib/packs not found');
    exit(2);
  }

  // Собираем покрытие из существующих *_loader.dart
  final covered = <String>{};
  for (final e in dir.listSync(recursive: false)) {
    if (e is File && e.path.endsWith('_loader.dart')) {
      final base = p.basenameWithoutExtension(e.path); // foo_loader
      final id = base.replaceFirst(RegExp(r'_loader$'), '');
      covered.add(id);
    }
  }

  // Оставляем только те covered, что есть в SSOT, и сортируем в порядке SSOT
  final filtered = ids.where(covered.contains).toList();

  // Проверка префикса: filtered должен быть строгим префиксом ids
  for (var i = 0; i < filtered.length; i++) {
    if (filtered[i] != ids[i]) {
      stderr.writeln(
        'Order mismatch at $i: expected ${ids[i]}, got ${filtered[i]}',
      );
      exit(3);
    }
  }

  // Перезаписываем curriculum_status.json
  final out = {'modules_done': filtered};
  File(
    'curriculum_status.json',
  ).writeAsStringSync(JsonEncoder.withIndent('  ').convert(out));
  stdout.writeln(
    'Rewrote curriculum_status.json with ${filtered.length} modules_done.',
  );
}
