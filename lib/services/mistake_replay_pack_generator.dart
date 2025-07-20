import 'package:uuid/uuid.dart';

import '../models/training_result.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';
import '../core/training/engine/training_type_engine.dart';

/// Generates a training pack replaying the user's own mistakes.
class MistakeReplayPackGenerator {
  const MistakeReplayPackGenerator();

  /// Builds a pack containing up to [maxSpots] mistaken spots.
  ///
  /// [results] should contain recent training results with optional `spotId`,
  /// `heroEv` and `isCorrect` fields. Spots with low EV (< 0.8) or incorrect
  /// answers are selected. Spot data is pulled from [sourcePacks].
  TrainingPackTemplateV2 generateMistakePack({
    required List<TrainingResult> results,
    required List<TrainingPackTemplateV2> sourcePacks,
    int maxSpots = 15,
  }) {
    final mistakeIds = <String>{};

    String? _spotId(dynamic r) {
      try {
        final id = r.spotId;
        if (id is String && id.isNotEmpty) return id;
      } catch (_) {}
      return null;
    }

    bool _isCorrect(dynamic r) {
      try {
        final v = r.isCorrect;
        if (v is bool) return v;
      } catch (_) {}
      try {
        final v = r.correct;
        if (v is bool) return v;
      } catch (_) {}
      return true;
    }

    double? _heroEv(dynamic r) {
      try {
        final v = r.heroEv;
        if (v is num) return v.toDouble();
      } catch (_) {}
      return null;
    }

    for (final r in results) {
      final id = _spotId(r);
      if (id == null) continue;
      final correct = !_isCorrect(r);
      final ev = _heroEv(r);
      if (correct || (ev != null && ev < 0.8)) {
        mistakeIds.add(id);
        if (mistakeIds.length >= maxSpots) break;
      }
    }

    final spotMap = <String, TrainingPackSpot>{};
    for (final p in sourcePacks) {
      for (final s in p.spots) {
        spotMap[s.id] = s;
      }
    }

    final spots = <TrainingPackSpot>[];
    for (final id in mistakeIds) {
      final s = spotMap[id];
      if (s != null) {
        spots.add(TrainingPackSpot.fromJson(s.toJson()));
        if (spots.length >= maxSpots) break;
      }
    }

    final positions = <HeroPosition>{for (final s in spots) s.hand.position};
    final trainingType = sourcePacks.isNotEmpty
        ? sourcePacks.first.trainingType
        : const TrainingTypeEngine().detectTrainingType(
            TrainingPackTemplateV2(
              id: '',
              name: '',
              trainingType: TrainingType.pushFold,
            ),
          );

    return TrainingPackTemplateV2(
      id: const Uuid().v4(),
      name: 'Review Mistakes',
      trainingType: trainingType,
      tags: const [],
      spots: spots,
      spotCount: spots.length,
      created: DateTime.now(),
      gameType: GameType.tournament,
      positions: [for (final p in positions) p.name],
      meta: {'origin': 'mistake_replay'},
    );
  }
}
