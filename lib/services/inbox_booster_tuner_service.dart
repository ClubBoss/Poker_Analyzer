import 'inbox_booster_tracker_service.dart';
import 'mini_lesson_library_service.dart';

/// Adjusts booster tag priority weights based on inbox banner engagement.
class InboxBoosterTunerService {
  final InboxBoosterTrackerService tracker;
  final MiniLessonLibraryService library;

  InboxBoosterTunerService({
    InboxBoosterTrackerService? tracker,
    MiniLessonLibraryService? library,
  })  : tracker = tracker ?? InboxBoosterTrackerService.instance,
        library = library ?? MiniLessonLibraryService.instance;

  static final InboxBoosterTunerService instance = InboxBoosterTunerService();

  /// Returns boost scores per tag derived from historical interactions.
  Future<Map<String, double>> computeTagBoostScores({
    DateTime? now,
    int recencyDays = 3,
  }) async {
    final data = await tracker.getInteractionStats();
    await library.loadAll();
    final map = <String, _MutableTagStats>{};

    for (final entry in data.entries) {
      final lesson = library.getById(entry.key);
      if (lesson == null) continue;
      final tags = lesson.tags;
      if (tags.isEmpty) continue;

      final shows = (entry.value['shows'] as num?)?.toInt() ?? 0;
      final clicks = (entry.value['clicks'] as num?)?.toInt() ?? 0;
      final lastShown = DateTime.tryParse(
        entry.value['lastShown'] as String? ?? '',
      );
      final lastClicked = DateTime.tryParse(
        entry.value['lastClicked'] as String? ?? '',
      );

      for (final t in tags) {
        final key = t.toLowerCase();
        final stat = map.putIfAbsent(key, () => _MutableTagStats());
        stat.shownCount += shows;
        stat.clickCount += clicks;
        if (lastShown != null &&
            (stat.lastShown == null || lastShown.isAfter(stat.lastShown!))) {
          stat.lastShown = lastShown;
        }
        if (lastClicked != null &&
            (stat.lastClicked == null ||
                lastClicked.isAfter(stat.lastClicked!))) {
          stat.lastClicked = lastClicked;
        }
      }
    }

    final result = <String, double>{};
    final cutoff = (now ?? DateTime.now()).subtract(
      Duration(days: recencyDays),
    );
    map.forEach((tag, stat) {
      final rate =
          stat.shownCount > 0 ? stat.clickCount / stat.shownCount : 0.0;
      var score = 1.0;
      if (rate > 0.3) score += 0.5;
      if (stat.shownCount > 5 && stat.clickCount < 1) score -= 0.3;
      final recent = stat.lastClicked ?? stat.lastShown;
      if (recent != null && recent.isAfter(cutoff)) score += 0.2;
      result[tag] = score;
    });

    return result;
  }
}

class _MutableTagStats {
  int shownCount = 0;
  int clickCount = 0;
  DateTime? lastShown;
  DateTime? lastClicked;
}
