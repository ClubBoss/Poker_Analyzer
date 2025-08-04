import 'package:shared_preferences/shared_preferences.dart';

/// Logs when sections within a learning path node are viewed.
class LearningPathNodeAnalyticsLogger {
  const LearningPathNodeAnalyticsLogger();

  static const _storeKey = 'learning_path_group_views';

  /// Records that a group [title] for [nodeId] was viewed at [timestamp].
  Future<void> logGroupViewed(String nodeId, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final events = prefs.getStringList(_storeKey) ?? <String>[];
    final ts = DateTime.now().millisecondsSinceEpoch;
    events.add('$nodeId|$title|$ts');
    await prefs.setStringList(_storeKey, events);
  }
}
