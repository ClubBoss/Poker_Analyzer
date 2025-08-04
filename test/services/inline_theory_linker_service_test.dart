import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_lesson_engagement_stats.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/inline_theory_linker_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_engagement_analytics_service.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> lessons;
  _FakeLibrary(this.lessons);

  @override
  List<TheoryMiniLessonNode> get all => lessons;

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  TheoryMiniLessonNode? getById(String id) =>
      lessons.firstWhere((l) => l.id == id, orElse: () => null);

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) {
    final tagSet = tags.toSet();
    final seen = <String>{};
    final result = <TheoryMiniLessonNode>[];
    for (final l in lessons) {
      if (l.tags.any(tagSet.contains)) {
        if (seen.add(l.id)) result.add(l);
      }
    }
    return result;
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());

  @override
  List<String> linkedPacksFor(String lessonId) => const [];
}

class _FakeAnalytics extends TheoryEngagementAnalyticsService {
  final Map<String, double> rates;
  const _FakeAnalytics(this.rates);

  @override
  Future<List<TheoryLessonEngagementStats>> getAllStats() async => [
        for (final e in rates.entries)
          TheoryLessonEngagementStats(
            lessonId: e.key,
            manualOpens: 0,
            reviewViews: 0,
            successRate: e.value,
          )
      ];
}

void main() {
  test('getLinkedLessonIdsForSpot ranks by overlap then success', () async {
    const lessons = [
      TheoryMiniLessonNode(
        id: 'l1',
        title: 'A',
        content: '',
        tags: ['cbet', 'turn'],
      ),
      TheoryMiniLessonNode(
        id: 'l2',
        title: 'B',
        content: '',
        tags: ['cbet'],
      ),
      TheoryMiniLessonNode(
        id: 'l3',
        title: 'C',
        content: '',
        tags: ['turn'],
      ),
      TheoryMiniLessonNode(
        id: 'l4',
        title: 'D',
        content: '',
        tags: ['probe'],
      ),
    ];

    final service = InlineTheoryLinkerService(
      library: _FakeLibrary(lessons),
      analytics: const _FakeAnalytics({
        'l1': 0.9,
        'l2': 0.8,
        'l3': 0.95,
        'l4': 0.7,
      }),
    );

    final spot =
        TrainingPackSpot(id: 's1', hand: HandData(), tags: ['cbet', 'turn']);

    final result = await service.getLinkedLessonIdsForSpot(spot);
    expect(result, ['l1', 'l3', 'l2']);
  });
}
