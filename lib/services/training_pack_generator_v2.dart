import 'package:uuid/uuid.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';
import '../models/game_type.dart';
import 'weakness_cluster_engine_v2.dart';
import '../repositories/training_pack_repository.dart';
import '../core/training/engine/training_type_engine.dart';

/// Generates training pack templates targeting player's weaknesses.
class TrainingPackGeneratorV2 {
  final TrainingPackRepository repository;
  final Uuid _uuid;

  TrainingPackGeneratorV2({TrainingPackRepository? repository, Uuid? uuid})
    : repository = repository ?? const TrainingPackRepository(),
      _uuid = uuid ?? const Uuid();

  /// Builds a training pack template from [cluster] using weakest tags
  /// from [mastery]. At most [spotCount] spots are included.
  Future<TrainingPackTemplateV2> generateFromWeakness({
    required WeaknessCluster cluster,
    required Map<String, double> mastery,
    int spotCount = 10,
  }) async {
    // Pick up to three weakest tags below 0.5 mastery.
    final entries = mastery.entries.where((e) => e.value < 0.5).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final tags = <String>[];
    final label = cluster.label.trim().toLowerCase();
    if (label.isNotEmpty) tags.add(label);
    for (final e in entries) {
      final t = e.key.toLowerCase();
      if (!tags.contains(t)) tags.add(t);
      if (tags.length >= 3) break;
    }
    if (tags.length < 2 && entries.length > tags.length) {
      for (final e in entries.skip(tags.length)) {
        tags.add(e.key.toLowerCase());
        if (tags.length >= 2) break;
      }
    }

    // Collect spots for selected tags.
    final spots = <TrainingPackSpot>[];
    final used = <String>{};
    for (final tag in tags) {
      final list = await repository.getSpotsByTag(tag);
      for (final s in list.take(5)) {
        if (used.add(s.id)) {
          spots.add(TrainingPackSpot.fromJson(s.toJson()));
          if (spots.length >= spotCount) break;
        }
      }
      if (spots.length >= spotCount) break;
    }

    final positions = <HeroPosition>{for (final s in spots) s.hand.position};
    final now = DateTime.now();
    final tpl = TrainingPackTemplateV2(
      id: _uuid.v4(),
      name: 'Weakness: ${cluster.label}',
      description: 'Auto generated from your weak tags',
      trainingType: TrainingType.pushFold,
      tags: tags,
      spots: spots,
      spotCount: spots.length,
      created: now,
      gameType: GameType.tournament,
      bb: 0,
      positions: [for (final p in positions) p.name],
      meta: const {'schemaVersion': '2.0.0'},
    );
    tpl.trainingType = const TrainingTypeEngine().detectTrainingType(tpl);
    return tpl;
  }
}
