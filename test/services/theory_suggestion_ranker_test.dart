import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_suggestion_ranker.dart';
import 'package:poker_analyzer/services/last_viewed_theory_store.dart';

class _FakeStore implements LastViewedTheoryStore {
  final Set<String> seen;
  _FakeStore(this.seen);

  @override
  Future<void> add(String packId, String lessonId) async {
    seen.add('$packId:$lessonId');
  }

  @override
  Future<bool> contains(String packId, String lessonId) async {
    return seen.contains('$packId:$lessonId');
  }
}

void main() {
  test('ranks by error rate and pack linkage', () async {
    final l1 =
        TheoryMiniLessonNode(id: 'l1', title: 'L1', content: 'c', tags: ['a']);
    final l2 = TheoryMiniLessonNode(
        id: 'l2',
        title: 'L2',
        content: 'c',
        tags: ['b'],
        linkedPackIds: ['p1']);
    final ranker = TheorySuggestionRanker(
      userErrorRate: {'a': 0.8, 'b': 0.1},
      packId: 'p1',
      store: _FakeStore({}),
    );
    final ranked = await ranker.rank([l1, l2]);
    expect(ranked.first.lesson.id, 'l1');
  });

  test('applies novelty suppression', () async {
    final l1 =
        TheoryMiniLessonNode(id: 'l1', title: 'L1', content: 'c', tags: ['a']);
    final l2 =
        TheoryMiniLessonNode(id: 'l2', title: 'L2', content: 'c', tags: ['b']);
    final ranker = TheorySuggestionRanker(
      userErrorRate: {'a': 0.2, 'b': 0.2},
      packId: 'p1',
      store: _FakeStore({'p1:l1'}),
    );
    final ranked = await ranker.rank([l1, l2]);
    expect(ranked.first.lesson.id, 'l2');
  });
}
