import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../core/training/generation/yaml_reader.dart';
import '../core/training/generation/yaml_writer.dart';
import '../models/v2/training_pack_template_v2.dart';

class EvaluationScoringService {
  const EvaluationScoringService();

  Future<int> evaluateAll({String path = 'training_packs/library'}) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$path');
    if (!dir.existsSync()) return 0;
    const reader = YamlReader();
    const writer = YamlWriter();
    var count = 0;
    for (final file in dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'))) {
      try {
        final yaml = await file.readAsString();
        final map = reader.read(yaml);
        TrainingPackTemplateV2.fromYamlAuto(yaml);
        final spots = map['spots'] as List? ?? [];
        var evSum = 0.0;
        var evCount = 0;
        var icmSum = 0.0;
        var icmCount = 0;
        for (final s in spots) {
          if (s is Map) {
            final eval = s['evaluation'];
            if (eval is Map) {
              final ev = (eval['equityDiff'] as num?)?.toDouble();
              final icm = (eval['icmDiff'] as num?)?.toDouble();
              if (ev != null) {
                evSum += ev.abs();
                evCount++;
              }
              if (icm != null) {
                icmSum += icm.abs();
                icmCount++;
              }
            }
          }
        }
        final meta = Map<String, dynamic>.from(map['meta'] as Map? ?? {});
        if (evCount > 0) {
          meta['evScore'] = double.parse(
            (100 - (evSum / evCount) * 100).toStringAsFixed(2),
          );
        }
        if (icmCount > 0) {
          meta['icmScore'] = double.parse(
            (100 - (icmSum / icmCount) * 100).toStringAsFixed(2),
          );
        }
        map['meta'] = meta;
        await writer.write(map, file.path);
        count++;
      } catch (_) {}
    }
    return count;
  }
}
