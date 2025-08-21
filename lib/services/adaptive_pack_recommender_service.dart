import 'dart:math';

import '../models/v2/training_pack_template_v2.dart';
import '../models/mistake_tag.dart';
import '../core/training/library/training_pack_library_v2.dart';
import 'tag_decay_forecast_service.dart';
import 'tag_mastery_service.dart';
import 'mistake_tag_history_service.dart';
import 'training_pack_stats_service.dart';

class AdaptivePackRecommendation {
  final TrainingPackTemplateV2 pack;
  final double score;

  const AdaptivePackRecommendation({required this.pack, required this.score});
}

class AdaptivePackRecommenderService {
  final TagDecayForecastService decayService;
  final TagMasteryService masteryService;
  final MistakeTagHistoryService? mistakeHistory;

  const AdaptivePackRecommenderService({
    this.decayService = const TagDecayForecastService(),
    required this.masteryService,
    this.mistakeHistory,
  });

  Future<List<AdaptivePackRecommendation>> recommend({
    int count = 3,
    DateTime? now,
  }) async {
    if (count <= 0) return const [];
    final current = now ?? DateTime.now();
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final library = TrainingPackLibraryV2.instance.packs;

    final decay = await decayService.summarize(now: current);
    final mastery = await masteryService.computeMastery();
    final mistakeFreq = mistakeHistory == null
        ? <MistakeTag, int>{}
        : await mistakeHistory!.getTagsByFrequency();
    final maxMistakes =
        mistakeFreq.values.isEmpty ? 0 : mistakeFreq.values.reduce(max);

    final recommendations = <AdaptivePackRecommendation>[];

    for (final pack in library) {
      double score = 0;

      // Decay overlap
      for (final tag in pack.tags) {
        final stat = decay[tag.toLowerCase()];
        if (stat != null) {
          final days = stat.timeSinceLast.inDays;
          final interval = stat.averageInterval.inDays + 1;
          score += (days / interval).clamp(0.0, 1.0) * 2;
        }
      }

      // Weak tag mastery
      for (final tag in pack.tags) {
        final m = mastery[tag.toLowerCase()];
        if (m != null) score += (1 - m);
      }

      // Novelty
      final stat = await TrainingPackStatsService.getStats(pack.id);
      if (stat == null) {
        score += 1.0;
      } else {
        final days = current.difference(stat.last).inDays;
        score += (days / 7).clamp(0.0, 1.0);
      }

      // Mistake patterns
      for (final entry in mistakeFreq.entries) {
        final label = entry.key.label.toLowerCase();
        if (pack.tags.any((t) => t.toLowerCase() == label)) {
          final weight = maxMistakes > 0 ? entry.value / maxMistakes : 0;
          score += weight * 1.5;
        }
      }

      if (score > 0) {
        recommendations.add(
          AdaptivePackRecommendation(pack: pack, score: score),
        );
      }
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(count).toList();
  }
}
