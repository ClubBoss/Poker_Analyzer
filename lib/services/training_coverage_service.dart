import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;

import '../core/training/generation/yaml_reader.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'pack_matrix_config.dart';

class TrainingCoverageService {
  const TrainingCoverageService();

  Future<Map<String, dynamic>> analyzeCoverage(
    List<TrainingPackTemplateV2> all,
  ) async {
    final counts = <String, Map<String, int>>{};
    final dup = <String, int>{};
    for (final t in all) {
      final audience = t.audience?.trim();
      if (audience == null || audience.isEmpty) continue;
      for (final tag in t.tags) {
        final tg = tag.trim();
        if (tg.isEmpty) continue;
        counts[audience] ??= <String, int>{};
        counts[audience]![tg] = (counts[audience]![tg] ?? 0) + 1;
        final key = '$audience|$tg|${t.goal.trim()}';
        dup[key] = (dup[key] ?? 0) + 1;
      }
    }
    final matrix = await const PackMatrixConfig().loadMatrix();
    final missing = <Map<String, String>>[];
    final weak = <Map<String, String>>[];
    for (final item in matrix) {
      final a = item.$1;
      for (final tag in item.$2) {
        final c = counts[a]?[tag] ?? 0;
        if (c == 0) {
          missing.add({'audience': a, 'tag': tag});
        } else if (c < 2) {
          weak.add({'audience': a, 'tag': tag});
        }
      }
    }
    final dups = <Map<String, dynamic>>[];
    dup.forEach((k, v) {
      if (v > 1) {
        final parts = k.split('|');
        dups.add({
          'audience': parts[0],
          'tag': parts[1],
          'goal': parts.length > 2 ? parts[2] : '',
          'count': v,
        });
      }
    });
    return {
      'matrix': counts,
      'missing': missing,
      'weak': weak,
      'duplicates': dups,
    };
  }

  Future<void> exportCoverageReport({
    String src = 'assets/packs/v2',
    String out = 'assets/packs/v2/coverage_report.json',
  }) async {
    final list = <TrainingPackTemplateV2>[];
    var processed = false;
    final indexFile = File(p.join(src, 'library_index.json'));
    if (indexFile.existsSync()) {
      try {
        final data = jsonDecode(await indexFile.readAsString());
        if (data is List) {
          for (final item in data) {
            if (item is Map) {
              final tpl = TrainingPackTemplateV2.fromJson(
                Map<String, dynamic>.from(item),
              );
              if (tpl.meta['manualSource'] == true) continue;
              list.add(tpl);
            }
          }
          processed = true;
        }
      } catch (_) {}
    }
    if (!processed) {
      final dir = Directory(src);
      if (dir.existsSync()) {
        const reader = YamlReader();
        final files = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.yaml'));
        for (final f in files) {
          try {
            final yaml = await f.readAsString();
            final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
            if (tpl.meta['manualSource'] == true) continue;
            list.add(tpl);
            processed = true;
          } catch (_) {}
        }
      }
    }
    final report = await analyzeCoverage(list);
    final file = File(out)..createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(report));
  }
}
