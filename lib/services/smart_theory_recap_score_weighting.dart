import '../services/mistake_tag_history_service.dart';
import 'mini_lesson_library_service.dart';

/// Computes dynamic recap scores based on recent mistakes.
class SmartTheoryRecapScoreWeighting {
  final MiniLessonLibraryService library;
  final Duration cacheDuration;

  SmartTheoryRecapScoreWeighting({
    MiniLessonLibraryService? library,
    this.cacheDuration = const Duration(minutes: 30),
  }) : library = library ?? MiniLessonLibraryService.instance;

  static final SmartTheoryRecapScoreWeighting instance =
      SmartTheoryRecapScoreWeighting();

  Map<String, double>? _cache;
  DateTime? _cacheTime;

  Future<Map<String, double>> computeScores(List<String> keys) async {
    final now = DateTime.now();
    if (_cache != null &&
        _cacheTime != null &&
        now.difference(_cacheTime!) < cacheDuration) {
      return {for (final k in keys) k: _cache![k] ?? 0};
    }

    final history = await MistakeTagHistoryService.getRecentHistory(limit: 200);
    final tagWeights = <String, double>{};
    for (final entry in history) {
      final age = now.difference(entry.timestamp);
      final weight = age > const Duration(days: 3) ? 0.5 : 1.0;
      for (final t in entry.tags) {
        tagWeights.update(t.name, (v) => v + weight, ifAbsent: () => weight);
      }
    }

    await library.loadAll();
    final scores = <String, double>{};
    for (final k in keys) {
      if (k.startsWith('tag:')) {
        final tag = k.substring(4);
        scores[k] = tagWeights[tag] ?? 0;
      } else if (k.startsWith('lesson:')) {
        final id = k.substring(7);
        final lesson = library.getById(id);
        double total = 0;
        if (lesson != null) {
          for (final t in lesson.tags) {
            total += tagWeights[t] ?? 0;
          }
        }
        scores[k] = total;
      } else {
        scores[k] = tagWeights[k] ?? 0;
      }
    }

    _cache = scores;
    _cacheTime = now;
    return scores;
  }
}
