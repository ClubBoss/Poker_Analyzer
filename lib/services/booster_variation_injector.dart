import 'package:collection/collection.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import 'booster_cluster_engine.dart';
import 'booster_similarity_engine.dart';

/// Injects spot variations based on clusters of similar spots.
class BoosterVariationInjector {
  final BoosterSimilarityEngine _engine;
  final double _similarityThreshold;

  /// How many variation spots should be added for each original spot.
  final int _variationsPerSpot;

  const BoosterVariationInjector({
    BoosterSimilarityEngine? engine,
    double similarityThreshold = 0.8,
    int variationsPerSpot = 1,
  }) : _engine = engine ?? const BoosterSimilarityEngine(),
       _similarityThreshold = similarityThreshold,
       _variationsPerSpot = variationsPerSpot;

  /// Returns a copy of [pack] with additional variation spots added.
  TrainingPackTemplateV2 injectVariations(
    TrainingPackTemplateV2 pack,
    List<SpotCluster> clusters,
  ) {
    if (pack.spots.isEmpty || clusters.isEmpty) {
      return TrainingPackTemplateV2.fromJson(pack.toJson());
    }

    final idSet = {for (final s in pack.spots) s.id};
    final newSpots = <TrainingPackSpot>[];

    for (final cluster in clusters) {
      final originals = cluster.spots
          .where((s) => idSet.contains(s.id))
          .toList();
      if (originals.length <= 1) continue;
      for (final orig in originals) {
        var counter = 1;
        var added = 0;
        for (final cand in cluster.spots) {
          if (cand.id == orig.id) continue;
          // Ensure difference in key attributes.
          final boardA = orig.board.isNotEmpty ? orig.board : orig.hand.board;
          final boardB = cand.board.isNotEmpty ? cand.board : cand.hand.board;
          final diffCards = cand.hand.heroCards != orig.hand.heroCards;
          final diffPos = cand.hand.position != orig.hand.position;
          final diffBoard = !const ListEquality().equals(boardA, boardB);
          if (!diffCards && !diffPos && !diffBoard) continue;
          final res = _engine.analyzeSpots([orig, cand], threshold: -1);
          final sim = res.isNotEmpty ? res.first.similarity : 1.0;
          if (sim >= _similarityThreshold) continue;
          var newId = '${orig.id}_var$counter';
          while (idSet.contains(newId) || newSpots.any((s) => s.id == newId)) {
            counter++;
            newId = '${orig.id}_var$counter';
          }
          final copy = cand.copyWith(
            id: newId,
            meta: {...cand.meta, 'variation': true},
          );
          newSpots.add(copy);
          idSet.add(newId);
          added++;
          counter++;
          if (added >= _variationsPerSpot) break;
        }
      }
    }

    if (newSpots.isEmpty) {
      return TrainingPackTemplateV2.fromJson(pack.toJson());
    }

    final updated = [...pack.spots, ...newSpots];
    final map = pack.toJson();
    map['spots'] = [for (final s in updated) s.toJson()];
    map['spotCount'] = updated.length;
    final result = TrainingPackTemplateV2.fromJson(
      Map<String, dynamic>.from(map),
    );
    result.isGeneratedPack = pack.isGeneratedPack;
    result.isSampledPack = pack.isSampledPack;
    return result;
  }
}
