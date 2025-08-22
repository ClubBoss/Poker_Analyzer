import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';

class UserProfile {
  final Set<String> completedPackIds;
  final List<String> tags;
  final List<String> goals;
  UserProfile({
    this.completedPackIds = const {},
    this.tags = const [],
    this.goals = const [],
  });
}

class SmartPackRecommendationEngine {
  SmartPackRecommendationEngine();

  List<TrainingPackTemplateV2> recommend(
    UserProfile user,
    List<TrainingPackTemplateV2> allPacks, {
    int limit = 10,
  }) {
    const alpha = 0.7;
    const beta = 0.2;
    const gamma = 0.1;
    const delta = 1.0;
    final entries = <MapEntry<TrainingPackTemplateV2, double>>[];
    for (final p in allPacks) {
      final rank = (p.meta['rankScore'] as num?)?.toDouble() ?? 0;
      final rating = (p.meta['rating'] as num?)?.toDouble() ?? 0;
      final base = alpha * rank + (1 - alpha) * (rating / 100);
      final tagMatch = user.tags.where(p.tags.contains).length.toDouble();
      final goalMatch = user.goals.contains(p.goal) ? 1.0 : 0.0;
      final played = user.completedPackIds.contains(p.id) ? 1.0 : 0.0;
      final score = base + beta * tagMatch + gamma * goalMatch - delta * played;
      entries.add(MapEntry(p, score));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    final selected = <TrainingPackTemplateV2>[];
    final types = <TrainingType>{};
    final stacks = <int>{};
    final positions = <String>{};
    for (final e in entries) {
      if (selected.length >= limit) break;
      final pack = e.key;
      final pos = pack.positions.isEmpty ? '' : pack.positions.first;
      final skip =
          types.contains(pack.trainingType) &&
          stacks.contains(pack.bb) &&
          positions.contains(pos);
      if (skip) continue;
      selected.add(pack);
      types.add(pack.trainingType);
      stacks.add(pack.bb);
      positions.add(pos);
    }
    return selected;
  }
}
