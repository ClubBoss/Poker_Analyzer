import 'package:uuid/uuid.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';
import '../core/training/engine/training_type_engine.dart';
import '../models/game_type.dart';
import 'training_spot_library.dart';

/// Builds ad-hoc booster packs from existing spots filtered by tags.
class BoosterPackFactory {
  BoosterPackFactory();

  /// Returns a training pack containing spots matching [tags].
  /// The result may be `null` if no suitable spots are found.
  static Future<TrainingPackTemplateV2?> buildFromTags(
    List<String> tags, {
    int spotsPerTag = 3,
  }) async {
    final lib = TrainingSpotLibrary();
    final spots = <TrainingPackSpot>[];
    final used = <String>{};

    for (final tag in tags) {
      final list = await lib.indexByTag(tag);
      for (final spot in list) {
        if (used.add(spot.id)) {
          spots.add(TrainingPackSpot.fromJson(spot.toJson()));
          if (spots.length >= spotsPerTag * tags.length) break;
        }
      }
      if (spots.length >= spotsPerTag * tags.length) break;
    }

    if (spots.isEmpty) return null;

    final positions = <HeroPosition>{for (final s in spots) s.hand.position};

    final tpl = TrainingPackTemplateV2(
      id: const Uuid().v4(),
      name: 'Daily Review',
      tags: List<String>.from(tags),
      trainingType: TrainingType.pushFold,
      spots: spots,
      spotCount: spots.length,
      created: DateTime.now(),
      gameType: GameType.tournament,
      positions: [for (final p in positions) p.name],
    );
    tpl.trainingType = const TrainingTypeEngine().detectTrainingType(tpl);
    return tpl;
  }
}
