import 'package:shared_preferences/shared_preferences.dart';

import 'learning_path_summary_cache.dart';
import 'training_history_service_v2.dart';

/// Reminds the user about stalled learning path progress.
class LearningPathReminderEngine {
  LearningPathReminderEngine._(this.cache);

  static LearningPathReminderEngine? _instance;
  final LearningPathSummaryCache cache;

  /// Initializes the singleton with required dependencies.
  factory LearningPathReminderEngine({
    required LearningPathSummaryCache cache,
  }) {
    return _instance ??= LearningPathReminderEngine._(cache);
  }

  static LearningPathReminderEngine get instance => _instance!;

  static const _lastKey = 'learning_path_reminder_last';

  Future<bool> shouldRemindUser() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    if (last != null && now.difference(last) < const Duration(days: 3)) {
      return false;
    }

    await cache.refresh();
    final summary = cache.summary;
    if (summary == null) return false;
    if (summary.remainingPacks <= 0) return false;
    if (summary.avgMastery >= 0.6) return false;

    final history = await TrainingHistoryServiceV2.getHistory(limit: 1);
    if (history.isNotEmpty &&
        now.difference(history.first.timestamp) < const Duration(days: 3)) {
      return false;
    }

    await prefs.setString(_lastKey, now.toIso8601String());
    return true;
  }
}
