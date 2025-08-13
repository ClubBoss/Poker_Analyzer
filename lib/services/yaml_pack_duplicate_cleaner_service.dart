import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';

class YamlPackDuplicateCleanerService {
  const YamlPackDuplicateCleanerService();

  Future<List<String>> removeDuplicates({
    String path = 'training_packs/library',
  }) async {
    if (!kDebugMode) return [];
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, path));
    if (!dir.existsSync()) return [];
    const reader = YamlReader();
    final groups = <String, List<(File, int, bool, DateTime)>>{};
    for (final f in dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
      try {
        final yaml = await f.readAsString();
        final map = reader.read(yaml);
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        final stat = await f.stat();
        groups.putIfAbsent(tpl.id, () => []).add((
          f,
          tpl.spots.length,
          map['evScore'] != null || tpl.meta['evScore'] != null,
          stat.modified,
        ));
      } catch (_) {}
    }
    final removed = <String>[];
    for (final list in groups.values) {
      if (list.length < 2) continue;
      list.sort((a, b) {
        final c1 = b.$2.compareTo(a.$2);
        if (c1 != 0) return c1;
        final c2 = (b.$3 ? 1 : 0) - (a.$3 ? 1 : 0);
        if (c2 != 0) return c2;
        return b.$4.compareTo(a.$4);
      });
      for (final item in list.skip(1)) {
        try {
          item.$1.deleteSync();
          removed.add(item.$1.path);
        } catch (_) {}
      }
    }
    return removed;
  }
}
