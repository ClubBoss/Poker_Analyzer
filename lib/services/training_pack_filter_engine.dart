import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';

class TrainingPackFilterEngine {
  const TrainingPackFilterEngine();

  Future<List<TrainingPackTemplateV2>> filter({
    double? minEv,
    double? minRating,
    List<String>? tags,
    String? audience,
    String path = 'training_packs/library',
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, path));
    if (!dir.existsSync()) return [];
    const reader = YamlReader();
    final reqTags = tags?.map((e) => e.trim().toLowerCase()).toSet() ?? {};
    final list = <TrainingPackTemplateV2>[];
    for (final f in dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((e) => e.path.toLowerCase().endsWith('.yaml'))) {
      try {
        final yaml = await f.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        final map = tpl.toJson();
        final meta = tpl.meta;
        final ev = (meta['evScore'] as num?)?.toDouble();
        final rating = (meta['rating'] as num?)?.toDouble();
        if (minEv != null && (ev == null || ev < minEv)) continue;
        if (minRating != null && (rating == null || rating < minRating)) {
          continue;
        }
        if (audience != null && audience.isNotEmpty) {
          final a = tpl.audience;
          if (a != null && a.isNotEmpty && a != audience) continue;
        }
        if (reqTags.isNotEmpty) {
          final tplTags = <String>{
            for (final t in tpl.tags) t.trim().toLowerCase()
          };
          if (!reqTags.every(tplTags.contains)) continue;
        }
        list.add(tpl);
      } catch (_) {}
    }
    list.sort((a, b) {
      final ar = (a.meta['rating'] as num?)?.toDouble() ?? 0;
      final br = (b.meta['rating'] as num?)?.toDouble() ?? 0;
      return br.compareTo(ar);
    });
    return list;
  }
}
