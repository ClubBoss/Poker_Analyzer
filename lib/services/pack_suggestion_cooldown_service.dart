import 'package:shared_preferences/shared_preferences.dart';

import 'user_action_logger.dart';

class PackSuggestionCooldownService {
  static bool debugLogging = false;
  static const _prefix = 'cooldown_suggested_';

  static Future<void> markAsSuggested(String packId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$packId', DateTime.now().toIso8601String());

    final cutoff = DateTime.now().subtract(const Duration(days: 60));
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefix)) {
        final raw = prefs.getString(key);
        final time = raw == null ? null : DateTime.tryParse(raw);
        if (time != null && time.isBefore(cutoff)) {
          await prefs.remove(key);
        }
      }
    }
  }

  static Future<bool> isRecentlySuggested(
    String packId, {
    Duration cooldown = const Duration(days: 7),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefix$packId');
    if (raw == null) return false;
    final last = DateTime.tryParse(raw);
    if (last == null) return false;
    final result = DateTime.now().difference(last) < cooldown;
    if (result && debugLogging) {
      await UserActionLogger.instance.log('cooldown.prevented.$packId');
    }
    return result;
  }
}
