import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which theory intros have been seen.
class IntroSeenTracker {
  static const _keyPrefix = 'theory_intro_seen_';

  IntroSeenTracker();

  Future<bool> hasSeen(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyPrefix$tag') ?? false;
  }

  Future<void> markSeen(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyPrefix$tag', true);
  }
}
