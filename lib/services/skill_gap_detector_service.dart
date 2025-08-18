import 'mini_lesson_library_service.dart';
import 'tag_mastery_history_service.dart';

/// Detects theory tags that lack reinforcement in user history.
class SkillGapDetectorService {
  final TagMasteryHistoryService history;
  final MiniLessonLibraryService library;

  SkillGapDetectorService({
    TagMasteryHistoryService? history,
    MiniLessonLibraryService? library,
  }) : history = history ?? TagMasteryHistoryService(),
       library = library ?? MiniLessonLibraryService.instance;

  /// Returns tags never reinforced or in the bottom [threshold] fraction
  /// of total XP across all tags.
  Future<List<String>> getMissingTags({double threshold = 0.1}) async {
    if (threshold < 0) threshold = 0;
    await library.loadAll();
    final hist = await history.getHistory();
    final allTags = <String>{};
    for (final l in library.all) {
      for (final t in l.tags) {
        final tag = t.trim().toLowerCase();
        if (tag.isNotEmpty) allTags.add(tag);
      }
    }

    final missing = <String>[];
    final totals = <String, int>{};
    for (final tag in allTags) {
      final entries = hist[tag];
      if (entries == null || entries.isEmpty) {
        missing.add(tag);
      } else {
        final xp = entries.fold<int>(0, (sum, e) => sum + e.xp);
        totals[tag] = xp;
      }
    }

    if (totals.isNotEmpty && threshold > 0) {
      final list = totals.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      var count = (list.length * threshold).ceil();
      if (count <= 0) count = 1;
      for (final e in list.take(count)) {
        if (!missing.contains(e.key)) missing.add(e.key);
      }
    }

    return missing;
  }
}
