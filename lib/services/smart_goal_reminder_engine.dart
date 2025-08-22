import '../models/goal_progress.dart';
import '../models/goal_engagement.dart';
import 'goal_completion_engine.dart';

/// Returns tags of goals that have not been interacted with for [staleDays].
class SmartGoalReminderEngine {
  SmartGoalReminderEngine();

  Future<List<String>> getStaleGoalTags({
    int staleDays = 5,
    required List<GoalProgress> allGoals,
    required List<GoalEngagement> engagementLog,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: staleDays));

    // Determine last relevant engagement for each tag.
    final lastActivity = <String, DateTime?>{};
    for (final e in engagementLog) {
      if (e.action != 'start' && e.action != 'dismiss') continue;
      final tag = e.tag.trim().toLowerCase();
      final existing = lastActivity[tag];
      if (existing == null || e.timestamp.isAfter(existing)) {
        lastActivity[tag] = e.timestamp;
      }
    }

    final staleEntries = <MapEntry<String, DateTime?>>[];
    for (final g in allGoals) {
      final tag = g.tag.trim().toLowerCase();
      if (GoalCompletionEngine.instance.isGoalCompleted(g)) continue;
      final last = lastActivity[tag];
      if (last == null || last.isBefore(cutoff)) {
        staleEntries.add(MapEntry(tag, last));
      }
    }

    staleEntries.sort((a, b) {
      final ta = a.value;
      final tb = b.value;
      if (ta == null && tb == null) return 0;
      if (ta == null) return -1;
      if (tb == null) return 1;
      return ta.compareTo(tb);
    });

    return [for (final e in staleEntries) e.key];
  }
}
