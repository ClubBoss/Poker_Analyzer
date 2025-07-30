import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';
import 'recap_effectiveness_analyzer.dart';

/// Suggests theory mini lessons to reinforce weak recap tags.
class TheoryBoosterSuggestionEngine {
  final RecapEffectivenessAnalyzer recap;
  final MiniLessonLibraryService library;

  TheoryBoosterSuggestionEngine({
    RecapEffectivenessAnalyzer? recap,
    MiniLessonLibraryService? library,
  })  : recap = recap ?? RecapEffectivenessAnalyzer.instance,
        library = library ?? MiniLessonLibraryService.instance;

  static final TheoryBoosterSuggestionEngine instance =
      TheoryBoosterSuggestionEngine();

  /// Returns lessons ordered by urgency based on recap effectiveness.
  Future<List<TheoryMiniLessonNode>> suggestBoosters({int maxCount = 3}) async {
    if (maxCount <= 0) return [];

    await recap.refresh();
    await library.loadAll();

    final suppressed = recap.suppressedTags();
    if (suppressed.isEmpty) return [];

    final nodes = <String, TheoryMiniLessonNode>{};
    final scores = <String, double>{};

    for (final tag in suppressed) {
      final stat = recap.stats[tag];
      if (stat == null) continue;
      final urgency = _urgency(stat);
      final lessons = library.findByTags([tag]);
      for (final l in lessons) {
        nodes[l.id] = l;
        final current = scores[l.id] ?? 0;
        if (urgency > current) scores[l.id] = urgency;
      }
    }

    final ids = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
    return [for (final id in ids.take(maxCount)) nodes[id]!];
  }

  double _urgency(TagEffectiveness s) {
    final countScore = 1 / (s.count + 1);
    final durationScore = 1 / (s.averageDuration.inSeconds + 1);
    final repeatScore = 1 - s.repeatRate;
    return countScore + durationScore + repeatScore;
  }
}
