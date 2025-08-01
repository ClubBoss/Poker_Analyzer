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

  /// Returns days since last review or booster completion for [tag].
  Future<double> getDecayScore(String tag, {DateTime? now}) async {
    final review = await getLastTheoryReview(tag);
    final booster = await getLastBoosterCompletion(tag);
    DateTime? last;
    if (review != null && booster != null) {
      last = review.isAfter(booster) ? review : booster;
    } else {
      last = review ?? booster;
    }
    if (last == null) return 9999.0;
    final current = now ?? DateTime.now();
    return current.difference(last).inDays.toDouble();
  }

  /// Returns normalized decay scores for all tracked tags.
  Future<Map<String, double>> getAllDecayScores({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final tags = <String>{};
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_theoryPrefix)) {
        tags.add(key.substring(_theoryPrefix.length));
      } else if (key.startsWith(_boosterPrefix)) {
        tags.add(key.substring(_boosterPrefix.length));
      }
    }

    final current = now ?? DateTime.now();
    final result = <String, double>{};
    for (final tag in tags) {
      final reviewStr = prefs.getString('$_theoryPrefix$tag');
      final boosterStr = prefs.getString('$_boosterPrefix$tag');
      final review = reviewStr != null ? DateTime.tryParse(reviewStr) : null;
      final booster = boosterStr != null ? DateTime.tryParse(boosterStr) : null;
      DateTime? last;
      if (review != null && booster != null) {
        last = review.isAfter(booster) ? review : booster;
      } else {
        last = review ?? booster;
      }
      if (last == null) {
        result[tag] = 1.0;
      } else {
        final days = current.difference(last).inDays.toDouble();
        result[tag] = (days / 100).clamp(0.0, 1.0);
      }
    }
    return result;
  }
}
