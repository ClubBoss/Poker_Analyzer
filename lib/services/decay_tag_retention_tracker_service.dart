import 'package:shared_preferences/shared_preferences.dart';

/// Tracks reinforcement events for decayed theory tags.
class DecayTagRetentionTrackerService {
  const DecayTagRetentionTrackerService();

  static const String _theoryPrefix = 'retention.theoryReviewed.';
  static const String _boosterPrefix = 'retention.boosterCompleted.';

  Future<void> markTheoryReviewed(String tag, {DateTime? time}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_theoryPrefix${tag.toLowerCase()}',
      (time ?? DateTime.now()).toIso8601String(),
    );
  }

  Future<void> markBoosterCompleted(String tag, {DateTime? time}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_boosterPrefix${tag.toLowerCase()}',
      (time ?? DateTime.now()).toIso8601String(),
    );
  }

  Future<DateTime?> getLastTheoryReview(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('$_theoryPrefix${tag.toLowerCase()}');
    return str != null ? DateTime.tryParse(str) : null;
  }

  Future<DateTime?> getLastBoosterCompletion(String tag) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString('$_boosterPrefix${tag.toLowerCase()}');
    return str != null ? DateTime.tryParse(str) : null;
  }
}
