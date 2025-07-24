import '../models/v2/training_pack_spot.dart';
import 'weakness_cluster_engine.dart';
import 'tag_mastery_service.dart';
import 'session_log_service.dart';
import '../repositories/training_pack_repository.dart';

/// Injects targeted spots at the start of a training pack based on player's weaknesses.
class SmartSpotInjector {
  SmartSpotInjector({
    this.clusterEngine = const WeaknessClusterEngine(),
    this.repository = const TrainingPackRepository(),
  });

  static final SmartSpotInjector instance = SmartSpotInjector();

  /// When disabled, [injectWeaknessSpots] returns [originalSpots] unchanged.
  bool enabled = false;

  final WeaknessClusterEngine clusterEngine;
  final TrainingPackRepository repository;

  /// Returns [originalSpots] prefixed with up to three weakness spots.
  Future<List<TrainingPackSpot>> injectWeaknessSpots({
    required List<TrainingPackSpot> originalSpots,
    required SessionLogService logs,
    required TagMasteryService mastery,
    int maxSpots = 3,
  }) async {
    if (!enabled) return originalSpots;

    await logs.load();
    final progress = await logs.getUserProgress();
    final masteryMap = await mastery.computeMastery();
    final clusters = clusterEngine.detectWeaknesses(
      results: progress.history,
      tagMastery: masteryMap,
    );

    final weakTags = <String>[];
    for (final c in clusters) {
      final value = masteryMap[c.tag] ?? 1.0;
      if (value < 0.5) weakTags.add(c.tag);
      if (weakTags.length >= maxSpots) break;
    }

    final added = <TrainingPackSpot>[];
    final used = <String>{};
    for (final tag in weakTags) {
      final spots = await repository.getSpotsByTag(tag);
      for (final s in spots) {
        if (used.add(s.id)) {
          added.add(TrainingPackSpot.fromJson(s.toJson()));
          if (added.length >= maxSpots) break;
        }
      }
      if (added.length >= maxSpots) break;
    }

    if (added.isEmpty) return originalSpots;
    return [...added, ...originalSpots];
  }
}
