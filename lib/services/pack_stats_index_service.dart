import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';

class PackStatsIndexService {
  PackStatsIndexService();

  Future<int> buildStatsIndex({String path = 'training_packs/library'}) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, path));
    if (!dir.existsSync()) return 0;
    final tagFile = File(p.join(dir.path, 'tag_stats.json'));
    final Map<String, int> tagCounts = {};
    if (tagFile.existsSync()) {
      try {
        final data = jsonDecode(await tagFile.readAsString());
        if (data is Map) {
          for (final e in data.entries) {
            final v = (e.value as Map?)?['count'];
            if (v is num) tagCounts[e.key.toString()] = v.toInt();
          }
        }
      } catch (_) {}
    }
    final frequent = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTags = {for (final e in frequent.take(20)) e.key};
    const reader = YamlReader();
    final list = <Map<String, dynamic>>[];
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    for (final f in files) {
      try {
        final yaml = await f.readAsString();
        final map = reader.read(yaml);
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        final tags = <String>{for (final t in tpl.tags) t.trim().toLowerCase()}
          ..removeWhere((e) => e.isEmpty);
        final uniq = tags.where((t) => tagCounts[t] == 1).length;
        final match = tags.where(topTags.contains).length;
        list.add({
          'id': tpl.id,
          'count': tpl.spotCount,
          if (map['evScore'] != null || tpl.meta['evScore'] != null)
            'ev':
                (map['evScore'] as num?)?.toDouble() ??
                (tpl.meta['evScore'] as num?)?.toDouble(),
          if (map['icmScore'] != null || tpl.meta['icmScore'] != null)
            'icm':
                (map['icmScore'] as num?)?.toDouble() ??
                (tpl.meta['icmScore'] as num?)?.toDouble(),
          if (map['meta']?['rankScore'] != null ||
              tpl.meta['rankScore'] != null)
            'difficulty':
                (map['meta']?['rankScore'] as num?)?.toDouble() ??
                (tpl.meta['rankScore'] as num?)?.toDouble(),
          if (tags.isNotEmpty) 'rarity': uniq / tags.length,
          if (tags.isNotEmpty) 'tagsMatch': match / tags.length,
        });
      } catch (_) {}
    }
    final file = File(p.join(dir.path, 'pack_stats.json'))
      ..createSync(recursive: true);
    await file.writeAsString(jsonEncode(list), flush: true);
    return list.length;
  }
}
