import '../models/weak_cluster_info.dart';
import '../models/player_profile.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'xp_level_engine.dart';

class BoosterInjectionEngine {
  final XPLevelEngine xpEngine;

  const BoosterInjectionEngine({this.xpEngine = XPLevelEngine.instance});

  List<TrainingPackTemplateV2> scheduleBoosters({
    required List<WeakClusterInfo> clusters,
    required List<TrainingPackTemplateV2> boosters,
    required PlayerProfile profile,
    DateTime? now,
  }) {
    if (boosters.isEmpty || clusters.isEmpty) return [];

    final tagCount = <String, int>{};
    for (final c in clusters) {
      for (final t in c.cluster.sharedTags) {
        final tag = t.trim().toLowerCase();
        if (tag.isEmpty) continue;
        tagCount.update(tag, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    final mastered = <String, bool>{};
    profile.tagAccuracy.forEach((k, v) {
      mastered[k.trim().toLowerCase()] = v >= 0.8;
    });

    final recent = {for (final t in profile.tags) t.trim().toLowerCase()};
    final plateau = xpEngine.getProgressToNextLevel(profile.xp) < 0.2;

    final scored = <_ScoredBooster>[];
    for (final b in boosters) {
      final tags = {for (final t in b.tags) t.trim().toLowerCase()}
        ..removeWhere((t) => t.isEmpty);
      if (tags.isEmpty) continue;
      if (tags.every((t) => mastered[t] == true || recent.contains(t))) {
        continue;
      }
      var score = 0;
      if (plateau) score++;
      if (tags.any((t) => (tagCount[t] ?? 0) >= 2)) score++;
      if (tags.every((t) => !recent.contains(t))) score++;
      scored.add(_ScoredBooster(b, score));
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    return [for (final s in scored) s.booster];
  }
}

class _ScoredBooster {
  final TrainingPackTemplateV2 booster;
  final int score;
  const _ScoredBooster(this.booster, this.score);
}
