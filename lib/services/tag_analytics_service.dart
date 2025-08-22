import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';

class TagAnalyticsService {
  TagAnalyticsService();

  Future<void> analyzeTags({String path = 'training_packs/library'}) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$path');
    if (!dir.existsSync()) return;
    const reader = YamlReader();
    final stats = <String, _TagStat>{};
    final tagSets = <String, int>{};
    final packs = <_PackInfo>[];
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
        if (tags.isEmpty) continue;
        final key = (tags.toList()..sort()).join('|');
        tagSets[key] = (tagSets[key] ?? 0) + 1;
        final ev =
            (map['evScore'] as num?)?.toDouble() ??
            (tpl.meta['evScore'] as num?)?.toDouble();
        final icm =
            (map['icmScore'] as num?)?.toDouble() ??
            (tpl.meta['icmScore'] as num?)?.toDouble();
        final rank =
            (map['meta']?['rankScore'] as num?)?.toDouble() ??
            (tpl.meta['rankScore'] as num?)?.toDouble();
        packs.add(_PackInfo(tags, key));
        for (final t in tags) {
          final s = stats.putIfAbsent(t, () => _TagStat());
          s.count++;
          if (ev != null) {
            s.ev += ev;
            s.evCount++;
          }
          if (icm != null) {
            s.icm += icm;
            s.icmCount++;
          }
          if (rank != null) {
            s.rank += rank;
            s.rankCount++;
          }
        }
      } catch (_) {}
    }
    for (final pInfo in packs) {
      if (tagSets[pInfo.key] == 1) {
        for (final t in pInfo.tags) {
          final s = stats[t];
          if (s != null) s.unique++;
        }
      }
    }
    final result = <String, dynamic>{};
    for (final e in stats.entries) {
      final s = e.value;
      result[e.key] = {
        'count': s.count,
        if (s.evCount > 0) 'ev': s.ev / s.evCount,
        if (s.icmCount > 0) 'icm': s.icm / s.icmCount,
        if (s.rankCount > 0) 'rankScore': s.rank / s.rankCount,
        'uniqueShare': s.count > 0 ? s.unique / s.count : 0,
      };
    }
    final file = File(p.join(dir.path, 'tag_stats.json'))
      ..createSync(recursive: true);
    await file.writeAsString(jsonEncode(result), flush: true);
  }
}

class _TagStat {
  int count = 0;
  double ev = 0;
  int evCount = 0;
  double icm = 0;
  int icmCount = 0;
  double rank = 0;
  int rankCount = 0;
  int unique = 0;
}

class _PackInfo {
  final Set<String> tags;
  final String key;
  const _PackInfo(this.tags, this.key);
}
