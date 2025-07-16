import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';

class TrainingPackIndexWriter {
  const TrainingPackIndexWriter();

  Future<void> writeIndex({
    String src = 'assets/packs/v2',
    String out = 'assets/packs/v2/library_index.json',
  }) async {
    final dir = Directory(src);
    if (!dir.existsSync()) return;
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'))
        .toList();
    final reader = const YamlReader();
    final list = <Map<String, dynamic>>[];
    for (final file in files) {
      try {
        final map = reader.read(await file.readAsString());
        final tpl = TrainingPackTemplateV2.fromJson(map);
        list.add({
          'title': tpl.name,
          if (tpl.tags.isNotEmpty) 'tags': tpl.tags,
          if (tpl.audience != null && tpl.audience!.isNotEmpty)
            'audience': tpl.audience,
          if (tpl.category != null && tpl.category!.isNotEmpty)
            'mainTag': tpl.category,
          if (tpl.goal.isNotEmpty) 'goal': tpl.goal,
          'path': p.relative(file.path, from: src),
        });
      } catch (_) {}
    }
    final file = File(out)..createSync(recursive: true);
    await file.writeAsString(jsonEncode(list), flush: true);
  }
}
