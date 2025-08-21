import 'dart:math';

import '../core/training/engine/training_type_engine.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/game_type.dart';
import '../repositories/training_pack_repository.dart';
import 'tag_weakness_detector_service.dart';

/// Generates a booster training pack from the user's weakest tags.
class WeakTagBoosterGeneratorService {
  final TagWeaknessDetectorService weaknessDetector;
  final TrainingPackRepository spotLibrary;
  final Random _rng;

  WeakTagBoosterGeneratorService({
    TagWeaknessDetectorService? weaknessDetector,
    TrainingPackRepository? spotLibrary,
    Random? random,
  })  : weaknessDetector = weaknessDetector ?? TagWeaknessDetectorService(),
        spotLibrary = spotLibrary ?? const TrainingPackRepository(),
        _rng = random ?? Random();

  /// Builds a [TrainingPackTemplateV2] by sampling spots from the weakest tags.
  Future<TrainingPackTemplateV2> generateWeakTagBooster() async {
    final weakTags = await weaknessDetector.getWeakTags(maxSessions: 20);
    final selectedTags = weakTags.take(5).toList();

    final spots = <TrainingPackSpot>[];
    final used = <String>{};

    for (final tag in selectedTags) {
      final list = await spotLibrary.getSpotsByTag(tag);
      if (list.isEmpty) continue;
      list.shuffle(_rng);
      final maxCount = min(5, list.length);
      final count = maxCount < 3 ? maxCount : 3 + _rng.nextInt(maxCount - 2);
      for (final spot in list.take(count)) {
        if (used.add(spot.id)) {
          spots.add(TrainingPackSpot.fromJson(spot.toJson()));
        }
      }
    }

    final now = DateTime.now();
    return TrainingPackTemplateV2(
      id: 'booster_${now.millisecondsSinceEpoch}',
      name: 'Weak Tag Booster',
      trainingType: TrainingType.booster,
      spots: spots,
      spotCount: spots.length,
      tags: selectedTags,
      created: now,
      gameType: GameType.tournament,
      meta: const {'type': 'booster'},
    );
  }
}
