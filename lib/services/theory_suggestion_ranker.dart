import '../models/theory_mini_lesson_node.dart';
import 'last_viewed_theory_store.dart';

class RankedTheoryLesson {
  final TheoryMiniLessonNode lesson;
  final double score;
  RankedTheoryLesson(this.lesson, this.score);
}

class TheorySuggestionRanker {
  final Map<String, double> userErrorRate;
  final String packId;
  final LastViewedTheoryStore store;

  TheorySuggestionRanker({
    required this.userErrorRate,
    required this.packId,
    LastViewedTheoryStore? store,
  }) : store = store ?? LastViewedTheoryStore.instance;

  Future<List<RankedTheoryLesson>> rank(
      List<TheoryMiniLessonNode> lessons) async {
    final ranked = <RankedTheoryLesson>[];
    for (final l in lessons) {
      double errorRate = 0;
      for (final t in l.tags) {
        final rate = userErrorRate[t.toLowerCase()] ?? 0;
        if (rate > errorRate) errorRate = rate;
      }
      final novelty = await store.contains(packId, l.id) ? 0.0 : 1.0;
      final packLinked = l.linkedPackIds.contains(packId) ? 1.0 : 0.0;
      final score = 0.6 * errorRate + 0.3 * novelty + 0.1 * packLinked;
      ranked.add(RankedTheoryLesson(l, score));
    }
    ranked.sort((a, b) => b.score.compareTo(a.score));
    return ranked;
  }
}
