import 'package:collection/collection.dart';

import '../models/training_attempt.dart';
import '../models/v2/training_pack_template_v2.dart';

class SkillTargetingRecommender {
  SkillTargetingRecommender();

  List<TrainingPackTemplateV2> recommendWeakest({
    required List<TrainingAttempt> attempts,
    required List<TrainingPackTemplateV2> allPacks,
    int maxPacks = 3,
  }) {
    if (attempts.isEmpty) return [];

    final byPack = {for (final p in allPacks) p.id: p};
    final sums = <String, double>{};
    final counts = <String, int>{};

    for (final a in attempts) {
      final pack = byPack[a.packId];
      final spot = pack?.spots.firstWhereOrNull((s) => s.id == a.spotId);
      if (spot == null) continue;
      for (final tag in spot.tags) {
        final key = tag.trim().toLowerCase();
        if (key.isEmpty) continue;
        sums[key] = (sums[key] ?? 0) + a.accuracy;
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    if (sums.isEmpty) return [];

    final mastery = <String, double>{};
    for (final e in sums.entries) {
      final c = counts[e.key]!;
      mastery[e.key] = e.value / c;
    }

    final sortedTags = mastery.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final weakTags = [for (final e in sortedTags.take(5)) e.key];

    final scored = <(TrainingPackTemplateV2, int)>[];
    for (final p in allPacks) {
      final packTags = <String>{
        for (final s in p.spots)
          for (final t in s.tags) t.trim().toLowerCase(),
      };
      final overlap = weakTags.where(packTags.contains).length;
      if (overlap > 0) scored.add((p, overlap));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final e in scored.take(maxPacks)) e.$1];
  }
}
