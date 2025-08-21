import 'dart:io';

import '../models/v2/training_pack_template_v2.dart';
import 'booster_similarity_engine.dart';

/// Removes highly similar spots from booster packs.
class BoosterSimilarityPruner {
  final BoosterSimilarityEngine _engine;
  final double _threshold;

  const BoosterSimilarityPruner({
    BoosterSimilarityEngine? engine,
    double threshold = 0.85,
  })  : _engine = engine ?? const BoosterSimilarityEngine(),
        _threshold = threshold;

  /// Returns a copy of [pack] with similar spots removed.
  TrainingPackTemplateV2 prune(
    TrainingPackTemplateV2 pack, {
    double? threshold,
  }) {
    final thr = threshold ?? _threshold;
    final results = _engine.analyzePack(pack, threshold: thr);
    if (results.isEmpty) return TrainingPackTemplateV2.fromJson(pack.toJson());

    final idPos = <String, int>{};
    for (var i = 0; i < pack.spots.length; i++) {
      idPos[pack.spots[i].id] = i;
    }

    final toRemove = <String>{};
    for (final r in results) {
      if (r.similarity < thr) break;
      final idA = r.idA;
      final idB = r.idB;
      if (toRemove.contains(idA) || toRemove.contains(idB)) continue;
      final posA = idPos[idA] ?? 0;
      final posB = idPos[idB] ?? 0;
      if (posA <= posB) {
        toRemove.add(idB);
      } else {
        toRemove.add(idA);
      }
    }

    if (toRemove.isEmpty) return TrainingPackTemplateV2.fromJson(pack.toJson());

    final spots = [
      for (final s in pack.spots)
        if (!toRemove.contains(s.id)) s,
    ];
    final copy = TrainingPackTemplateV2.fromJson(pack.toJson());
    copy.spots
      ..clear()
      ..addAll(spots);
    copy.spotCount = spots.length;
    return copy;
  }

  /// Scans [dir] for YAML booster packs, prunes duplicates and saves files.
  /// Returns the number of updated files.
  Future<int> pruneAndSaveAll({String dir = 'yaml_out/boosters'}) async {
    final directory = Directory(dir);
    if (!directory.existsSync()) return 0;
    final files = directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.yaml'));
    var count = 0;
    for (final file in files) {
      try {
        final yaml = await file.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlString(yaml);
        final pruned = prune(tpl);
        if (pruned.spots.length != tpl.spots.length) {
          await file.writeAsString(pruned.toYamlString());
          count++;
        }
      } catch (_) {}
    }
    return count;
  }
}
