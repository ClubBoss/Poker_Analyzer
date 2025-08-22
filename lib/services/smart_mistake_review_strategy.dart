import '../models/mistake_insight.dart';
import '../services/mistake_tag_insights_service.dart';
import '../services/skill_loss_feed_engine.dart';
import '../services/tag_insight_reminder_engine.dart';
import '../services/tag_mastery_history_service.dart';
import '../services/training_history_service_v2.dart';
import '../models/training_history_entry_v2.dart';

enum ReviewStrategyType { repeatSameSpots, trainTagPack, recoverCluster }

class ReviewStrategyDecision {
  final ReviewStrategyType type;
  final String reason;
  final String? targetTag;

  ReviewStrategyDecision({
    required this.type,
    required this.reason,
    this.targetTag,
  });
}

class SmartMistakeReviewStrategy {
  final MistakeTagInsightsService insightsService;
  final SkillLossFeedEngine skillLossEngine;
  final TagInsightReminderEngine reminder;

  SmartMistakeReviewStrategy({
    this.insightsService = const MistakeTagInsightsService(),
    this.skillLossEngine = const SkillLossFeedEngine(),
    TagInsightReminderEngine? reminder,
  }) : reminder =
           reminder ??
           TagInsightReminderEngine(history: TagMasteryHistoryService());

  Future<List<SkillLossFeedItem>> _loadFeed() async {
    final losses = await reminder.loadLosses();
    return skillLossEngine.buildFeed(losses);
  }

  Future<ReviewStrategyDecision> decide({
    List<MistakeInsight>? insights,
    List<SkillLossFeedItem>? feed,
    List<TrainingHistoryEntryV2>? history,
  }) async {
    final ins = insights ?? await insightsService.buildInsights();
    final hist =
        history ?? await TrainingHistoryServiceV2.getHistory(limit: 20);
    final skillFeed = feed ?? await _loadFeed();

    final lastTrained = <String, DateTime>{};
    for (final h in hist) {
      for (final t in h.tags) {
        final tag = t.trim().toLowerCase();
        final prev = lastTrained[tag];
        if (prev == null || h.timestamp.isAfter(prev)) {
          lastTrained[tag] = h.timestamp;
        }
      }
    }

    bool recentlyTrained(String tag, {int days = 3}) {
      final last = lastTrained[tag.trim().toLowerCase()];
      if (last == null) return false;
      return DateTime.now().difference(last).inDays < days;
    }

    // Check for repeated spots across insights
    final spotCounts = <String, int>{};
    for (final i in ins) {
      for (final ex in i.examples) {
        final id = ex.spot.id;
        if (id.isEmpty) continue;
        spotCounts.update(id, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    if (spotCounts.values.any((c) => c >= 2)) {
      return const ReviewStrategyDecision(
        type: ReviewStrategyType.repeatSameSpots,
        reason: 'Repeated mistakes on same spots',
      );
    }

    // Determine if a single tag dominates mistakes
    if (ins.isNotEmpty) {
      final total = ins.fold<int>(0, (a, b) => a + b.count);
      final top = ins.first;
      if (total > 0 &&
          top.count / total >= 0.5 &&
          !recentlyTrained(top.tag.label)) {
        return ReviewStrategyDecision(
          type: ReviewStrategyType.trainTagPack,
          reason: 'Tag ${top.tag.label} dominates recent mistakes',
          targetTag: top.tag.label,
        );
      }
    }

    // Skill loss urgent tag
    if (skillFeed.isNotEmpty) {
      skillFeed.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));
      final item = skillFeed.first;
      if (item.urgencyScore >= 1.0 && !recentlyTrained(item.tag)) {
        return ReviewStrategyDecision(
          type: ReviewStrategyType.recoverCluster,
          reason: 'Skill loss detected for ${item.tag}',
          targetTag: item.tag,
        );
      }
    }

    // Fallback
    return const ReviewStrategyDecision(
      type: ReviewStrategyType.repeatSameSpots,
      reason: 'Default repeat mistakes',
    );
  }
}
