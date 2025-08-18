import '../models/theory_block_model.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'theory_block_library_service.dart';

/// Evaluates review streaks for theory blocks based on recorded tag reviews.
class TheoryBlockReviewStreakEvaluator {
  TheoryBlockReviewStreakEvaluator({
    DecayTagRetentionTrackerService? retention,
    TheoryBlockLibraryService? library,
  }) : retention = retention ?? const DecayTagRetentionTrackerService(),
       library = library ?? TheoryBlockLibraryService.instance;

  final DecayTagRetentionTrackerService retention;
  final TheoryBlockLibraryService library;

  /// Returns all unique UTC dates when any theory tag was reviewed.
  Future<List<DateTime>> getStreakDays() async {
    await library.loadAll();
    final tags = <String>{};
    for (final TheoryBlockModel block in library.all) {
      tags.addAll(block.tags.map((e) => e.toLowerCase()));
    }
    final days = <DateTime>{};
    for (final tag in tags) {
      final last = await retention.getLastTheoryReview(tag);
      if (last != null) {
        final utc = last.toUtc();
        days.add(DateTime.utc(utc.year, utc.month, utc.day));
      }
    }
    final list = days.toList()..sort();
    return list;
  }

  /// Current streak of consecutive days with at least one review.
  Future<int> getCurrentStreak() async {
    final days = await getStreakDays();
    if (days.isEmpty) return 0;
    final set = days.toSet();
    var day = DateTime.now().toUtc();
    day = DateTime.utc(day.year, day.month, day.day);
    var streak = 0;
    while (set.contains(day)) {
      streak += 1;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Historical maximum streak length.
  Future<int> getMaxStreak() async {
    final days = await getStreakDays();
    if (days.isEmpty) return 0;
    var best = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        current += 1;
      } else if (diff > 1) {
        if (current > best) best = current;
        current = 1;
      }
    }
    if (current > best) best = current;
    return best;
  }
}
