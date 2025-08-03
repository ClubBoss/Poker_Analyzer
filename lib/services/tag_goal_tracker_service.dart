import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';

import '../models/tag_goal_progress.dart';

class TagGoalTrackerService {
  TagGoalTrackerService._();
  static final TagGoalTrackerService instance = TagGoalTrackerService._();

  static const _countPrefix = 'tag_goal_count_';
  static const _streakPrefix = 'tag_goal_streak_';
  static const _lastPrefix = 'tag_goal_last_';
  static const _tagXpPrefix = 'tag_xp_';

  Future<TagGoalProgress> getProgress(String tagId) async {
    final prefs = await PreferencesService.getInstance();
    final tag = tagId.toLowerCase();
    final count = prefs.getInt('$_countPrefix$tag') ?? 0;
    final streak = prefs.getInt('$_streakPrefix$tag') ?? 0;
    final lastStr = prefs.getString('$_lastPrefix$tag');
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;

    int xp = 0;
    final raw = prefs.getString('$_tagXpPrefix$tag');
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        xp = (data['total'] as num?)?.toInt() ?? 0;
      } catch (_) {}
    }

    return TagGoalProgress(
      trainings: count,
      xp: xp,
      streak: streak,
      lastTrainingDate: last,
    );
  }

  Future<void> logTraining(String tagId) async {
    final prefs = await PreferencesService.getInstance();
    final tag = tagId.toLowerCase();
    final countKey = '$_countPrefix$tag';
    final streakKey = '$_streakPrefix$tag';
    final lastKey = '$_lastPrefix$tag';

    await prefs.setInt(countKey, (prefs.getInt(countKey) ?? 0) + 1);

    final now = DateTime.now();
    final lastStr = prefs.getString(lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    int streak = prefs.getInt(streakKey) ?? 0;
    if (last != null) {
      final lastDay = DateTime(last.year, last.month, last.day);
      final diff =
          DateTime(now.year, now.month, now.day).difference(lastDay).inDays;
      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1;
      }
    } else {
      streak = 1;
    }
    await prefs.setInt(streakKey, streak);
    await prefs.setString(lastKey, now.toIso8601String());
  }
}
