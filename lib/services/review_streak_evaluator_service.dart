
import '../models/booster_tag_history.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'pack_recall_stats_service.dart';
import 'booster_path_history_service.dart';

/// Evaluates review streaks for training packs.
///
/// A streak consists of at least two consecutive reviews where each
/// review occurs within [maxGap] of the previous one. The streak is
/// considered active only if the latest review is also within [maxGap]
/// from now.
class ReviewStreakEvaluatorService {
  const ReviewStreakEvaluatorService({this.recallStats});

  /// Service used to read review history. Defaults to
  /// [PackRecallStatsService.instance].
  final PackRecallStatsService? recallStats;

  /// Maximum allowed gap between consecutive reviews to keep a streak.
  static const Duration maxGap = Duration(days: 3);

  PackRecallStatsService get _stats =>
      recallStats ?? PackRecallStatsService.instance;

  /// Returns `true` if [packId] currently has an active review streak.
  Future<bool> isStreakActive(String packId) async {
    final history = await _stats.getReviewHistory(packId);
    if (history.length < 2) return false;
    history.sort();
    var last = history.last;
    var streak = 1;
    for (var i = history.length - 2; i >= 0; i--) {
      final diff = last.difference(history[i]);
      if (diff <= maxGap) {
        streak += 1;
        last = history[i];
      } else {
        break;
      }
    }
    if (streak < 2) return false;
    if (DateTime.now().difference(history.last) > maxGap) return false;
    return true;
  }

  /// Returns the date when the last review streak was broken for [packId].
  /// Returns `null` if the streak is still active or never existed.
  Future<DateTime?> streakBreakDate(String packId) async {
    final history = await _stats.getReviewHistory(packId);
    if (history.length < 2) return null;
    history.sort();
    DateTime? breakDate;
    for (var i = 1; i < history.length; i++) {
      final prev = history[i - 1];
      final diff = history[i].difference(prev);
      if (diff > maxGap) {
        breakDate = prev.add(maxGap);
      }
    }
    final last = history.last;
    if (DateTime.now().difference(last) > maxGap) {
      breakDate = last.add(maxGap);
    }
    return breakDate;
  }

  /// Returns ids of packs with broken review streaks.
  Future<List<String>> packsWithBrokenStreaks() async {
    final prefs = await PreferencesService.getInstance();
    const prefix = 'pack_recall_history.';
    final ids = <String>[];
    for (final key in prefs.getKeys()) {
      if (key.startsWith(prefix)) {
        final id = key.substring(prefix.length);
        if (await streakBreakDate(id) != null) ids.add(id);
      }
    }
    return ids;
  }

  /// Returns booster tag stats from the history service.
  Future<Map<String, BoosterTagHistory>> getTagStats() async {
    return BoosterPathHistoryService.instance.getTagStats();
  }
}
