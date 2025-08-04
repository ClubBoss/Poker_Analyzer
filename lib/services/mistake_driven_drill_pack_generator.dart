import 'package:uuid/uuid.dart';

import '../models/mistake_history_entry.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/hero_position.dart';
import '../models/game_type.dart';
import '../core/training/engine/training_type_engine.dart';
import 'mistake_history_query_service.dart';

/// Builds a training pack from recent unrecovered mistakes.
class MistakeDrivenDrillPackGenerator {
  final MistakeHistoryQueryService history;
  final Future<TrainingPackSpot?> Function(String spotId) loadSpot;

  const MistakeDrivenDrillPackGenerator({
    required this.history,
    required this.loadSpot,
  });

  /// Generates a pack titled "Fix Your Mistakes" containing up to [limit]
  /// recent mistakes that haven't been recovered yet.
  Future<TrainingPackTemplateV2?> generate({int limit = 10}) async {
    if (limit <= 0) return null;
    final entries = await history.queryMistakes(limit: limit * 3);
    final added = <String>{};
    final spots = <TrainingPackSpot>[];
    final tags = <String>{};

    for (final e in entries) {
      if (spots.length >= limit) break;
      if (e.wasRecovered) continue;
      if (!added.add(e.spotId)) continue;
      final spot = await loadSpot(e.spotId);
      if (spot == null) continue;
      spots.add(TrainingPackSpot.fromJson(spot.toJson()));
      tags.add(e.tag);
    }

    if (spots.isEmpty) return null;

    final positions = <HeroPosition>{for (final s in spots) s.hand.position};
    final engine = const TrainingTypeEngine();
    final trainingType = engine.detectTrainingType(
      TrainingPackTemplateV2(
        id: '',
        name: '',
        trainingType: TrainingType.pushFold,
        spots: spots,
      ),
    );

    return TrainingPackTemplateV2(
      id: const Uuid().v4(),
      name: 'Fix Your Mistakes',
      trainingType: trainingType,
      tags: tags.toList(),
      spots: spots,
      spotCount: spots.length,
      created: DateTime.now(),
      gameType: GameType.tournament,
      positions: [for (final p in positions) p.name],
      meta: const {'origin': 'mistake-drill'},
    );
  }
}
