import 'package:shared_preferences/shared_preferences.dart';

import 'user_action_logger.dart';

/// Records when booster banners are opened or dismissed per tag.
class BoosterInteractionTrackerService {
  BoosterInteractionTrackerService._();
  static final BoosterInteractionTrackerService instance =
      BoosterInteractionTrackerService._();

  static const String _openedPrefix = 'booster_opened_';
  static const String _dismissedPrefix = 'booster_dismissed_';

  Future<void> logOpened(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_openedPrefix$tag',
      DateTime.now().millisecondsSinceEpoch,
    );
    await UserActionLogger.instance.logEvent({
      'event': 'booster_banner.opened',
      'tag': tag,
    });
  }

  Future<void> logDismissed(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_dismissedPrefix$tag',
      DateTime.now().millisecondsSinceEpoch,
    );
    await UserActionLogger.instance.logEvent({
      'event': 'booster_banner.dismissed',
      'tag': tag,
    });
  }

  Future<DateTime?> getLastOpened(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('$_openedPrefix$tag');
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  Future<DateTime?> getLastDismissed(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('$_dismissedPrefix$tag');
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  /// Returns summary analytics keyed by tag with last open/dismiss times.
  Future<Map<String, Map<String, DateTime?>>> getSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, Map<String, DateTime?>>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_openedPrefix)) {
        final tag = key.substring(_openedPrefix.length);
        final ts = prefs.getInt(key);
        final map = result.putIfAbsent(tag, () => {});
        if (ts != null) {
          map['opened'] = DateTime.fromMillisecondsSinceEpoch(ts);
        }
      } else if (key.startsWith(_dismissedPrefix)) {
        final tag = key.substring(_dismissedPrefix.length);
        final ts = prefs.getInt(key);
        final map = result.putIfAbsent(tag, () => {});
        if (ts != null) {
          map['dismissed'] = DateTime.fromMillisecondsSinceEpoch(ts);
        }
      }
    }
    return result;
  }
}

