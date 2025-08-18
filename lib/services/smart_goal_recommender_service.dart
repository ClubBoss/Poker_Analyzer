import '../models/user_goal.dart';
import '../services/pack_library_index_loader.dart';
import '../services/tag_mastery_service.dart';
import '../services/session_log_service.dart';
import '../services/goal_analytics_service.dart';

class SmartGoalRecommenderService {
  final TagMasteryService mastery;
  final SessionLogService logs;

  const SmartGoalRecommenderService({
    required this.mastery,
    required this.logs,
  });

  Future<List<UserGoal>> recommendGoals(UserProfile profile) async {
    await PackLibraryIndexLoader.instance.load();
    await logs.load();
    final masteryMap = await mastery.computeMastery();
    final weak = await mastery.topWeakTags(5);
    final now = DateTime.now();
    final recentCutoff = now.subtract(const Duration(days: 7));
    final recentIds = logs.logs
        .where((l) => l.completedAt.isAfter(recentCutoff))
        .map((l) => l.templateId)
        .toSet();
    final history = await GoalAnalyticsService.instance.getGoalHistory();
    final recentTags = history
        .where((e) => e['tag'] != null)
        .map((e) => e['tag'] as String)
        .toSet();

    final goals = <UserGoal>[];
    final used = <String>{};
    for (final tag in weak) {
      if (!used.add('tag:$tag') || recentTags.contains(tag)) continue;
      final base = (masteryMap[tag] ?? 0.0) * 100;
      goals.add(
        UserGoal(
          id: 'tag_${tag}_${now.millisecondsSinceEpoch}',
          title: 'Фокус на теге $tag до 80%',
          type: 'tagFocus',
          target: 80,
          base: base.round(),
          createdAt: now,
          tag: tag,
          targetAccuracy: 80,
        ),
      );
      if (goals.length >= 3) break;
    }

    if (goals.length < 3) {
      final packs = PackLibraryIndexLoader.instance.library;
      for (final tag in weak) {
        for (final pack in packs.where((p) => p.tags.any((t) => t == tag))) {
          if (profile.completedPackIds.contains(pack.id) ||
              recentIds.contains(pack.id))
            continue;
          if (!used.add('pack:${pack.id}')) continue;
          goals.add(
            UserGoal(
              id: 'pack_${pack.id}_${now.millisecondsSinceEpoch}',
              title: 'Заверши ${pack.name}',
              type: 'completion',
              target: 1,
              base: 0,
              createdAt: now,
              tag: pack.id,
              targetAccuracy: 100,
            ),
          );
          if (goals.length >= 3) break;
        }
        if (goals.length >= 3) break;
      }
    }

    return goals.take(3).toList();
  }
}
