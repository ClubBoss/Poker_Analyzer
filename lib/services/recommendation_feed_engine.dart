import '../models/training_attempt.dart';
import '../models/learning_path_template_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'smart_pack_recommender.dart';
import 'training_pack_stats_service.dart';

class FeedRecommendationCard {
  final String title;
  final String subtitle;
  final String packId;
  final String cta;

  FeedRecommendationCard({
    required this.title,
    required this.subtitle,
    required this.packId,
    required this.cta,
  });
}

class RecommendationFeedEngine {
  final SmartPackRecommender _recommender;

  RecommendationFeedEngine({SmartPackRecommender? recommender})
    : _recommender = recommender ?? const SmartPackRecommender();

  List<FeedRecommendationCard> build({
    required List<TrainingPackTemplateV2> allPacks,
    required Map<String, TrainingPackStat> stats,
    required List<TrainingAttempt> attempts,
    LearningPathTemplateV2? path,
    DateTime? now,
    int count = 3,
  }) {
    final current = now ?? DateTime.now();
    if (allPacks.isEmpty) return [];

    final recs = _recommender.getTopRecommendations(
      allPacks: allPacks,
      stats: stats,
      attempts: attempts,
      path: path,
      now: current,
      count: count,
    );

    final packMap = {for (final p in allPacks) p.id: p};
    final cards = <FeedRecommendationCard>[];

    for (final r in recs) {
      final tpl = packMap[r.packId];
      if (tpl == null) continue;
      final stat = stats[r.packId];
      final acc = stat?.accuracy ?? 0.0;
      final last = stat?.last;

      final accPct = (acc * 100).round();
      final subtitleParts = <String>[];
      if (acc > 0) {
        final label = accPct < 70
            ? 'Low accuracy: $accPct%'
            : 'Accuracy: $accPct%';
        subtitleParts.add(label);
      }
      if (last != null) {
        final days = current.difference(last).inDays;
        subtitleParts.add('Last trained ${days}d ago');
      }
      final subtitle = subtitleParts.join(' · ');

      String title;
      final reason = r.reason.toLowerCase();
      if (reason.startsWith('weakness')) {
        final label = r.reason.substring('Weakness:'.length).trim();
        title = label.isEmpty ? tpl.name : 'Improve $label';
      } else {
        title = tpl.name;
      }

      String cta;
      if (reason.contains('weakness')) {
        cta = 'Review Mistakes';
      } else if (reason.contains('decay')) {
        cta = 'Review';
      } else if (reason.contains('next stage')) {
        cta = 'Continue';
      } else {
        cta = 'Train';
      }

      cards.add(
        FeedRecommendationCard(
          title: title,
          subtitle: subtitle,
          packId: tpl.id,
          cta: cta,
        ),
      );
    }

    return cards;
  }
}
