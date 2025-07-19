import 'package:shared_preferences/shared_preferences.dart';

import 'session_log_service.dart';
import 'smart_pack_recommendation_engine.dart' show UserProfile;

class TrainingReminderEngine {
  final SessionLogService logs;

  TrainingReminderEngine({required this.logs});

  static const _checkKey = 'lastReminderCheck';

  Future<bool> shouldRemind(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastStr = prefs.getString(_checkKey);
    final lastCheck = lastStr == null ? null : DateTime.tryParse(lastStr);
    if (lastCheck != null && now.difference(lastCheck) < const Duration(days: 1)) {
      return false;
    }
    await prefs.setString(_checkKey, now.toIso8601String());

    await logs.load();
    DateTime? last;
    for (final l in logs.logs) {
      final d = l.completedAt;
      if (last == null || d.isAfter(last)) last = d;
    }
    if (last == null) return true;
    return now.difference(last) > const Duration(days: 3);
  }
}
