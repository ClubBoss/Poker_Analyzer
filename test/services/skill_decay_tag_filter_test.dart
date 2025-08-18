import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/tag_xp_history_entry.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/goal_queue.dart';
import 'package:poker_analyzer/services/recap_booster_queue.dart';
import 'package:poker_analyzer/services/skill_decay_tag_filter.dart';
import 'package:poker_analyzer/services/tag_mastery_history_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';

class _FakeHistoryService extends TagMasteryHistoryService {
  final Map<String, List<TagXpHistoryEntry>> map;
  _FakeHistoryService(this.map);
  @override
  Future<Map<String, List<TagXpHistoryEntry>>> getHistory() async => map;
}

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
    return [
      for (final l in lessons)
        if (l.tags.any((t) => tags.contains(t))) l,
    ];
  }

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) =>
      findByTags(tags.toList());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    RecapBoosterQueue.instance.clear();
    GoalQueue.instance.clear();
  });

  test('filters queued or recently reinforced tags', () async {
    final now = DateTime(2024, 1, 10);
    final lessons = [
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'A',
        content: '',
        tags: ['push'],
      ),
      const TheoryMiniLessonNode(
        id: 'l2',
        title: 'B',
        content: '',
        tags: ['call'],
      ),
    ];

    final history = _FakeHistoryService({
      'push': [
        TagXpHistoryEntry(
          date: now.subtract(const Duration(days: 10)),
          xp: 5,
          source: '',
        ),
      ],
      'call': [
        TagXpHistoryEntry(
          date: now.subtract(const Duration(days: 10)),
          xp: 5,
          source: '',
        ),
      ],
      'fold': [
        TagXpHistoryEntry(
          date: now.subtract(const Duration(days: 2)),
          xp: 5,
          source: '',
        ),
      ],
      'bluff': [
        TagXpHistoryEntry(
          date: now.subtract(const Duration(days: 5)),
          xp: 5,
          source: '',
        ),
      ],
    });

    final filter = SkillDecayTagFilter(
      history: history,
      lessons: _FakeLibrary(lessons),
      recapQueue: RecapBoosterQueue.instance,
      goalQueue: GoalQueue.instance,
    );

    await RecapBoosterQueue.instance.add('l1');
    GoalQueue.instance.push(lessons[1]);

    final result = await filter.filter([
      'push',
      'call',
      'fold',
      'bluff',
    ], now: now);
    expect(result, ['bluff']);
  });
}
