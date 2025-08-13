import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/tag_xp_history_entry.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/skill_gap_detector_service.dart';
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
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [];
  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('detects untrained and low-exposure tags', () async {
    final lessons = [
      const TheoryMiniLessonNode(
          id: 'l1', title: 'A', content: '', tags: ['push']),
      const TheoryMiniLessonNode(
          id: 'l2', title: 'B', content: '', tags: ['call']),
      const TheoryMiniLessonNode(
          id: 'l3', title: 'C', content: '', tags: ['fold']),
    ];

    final history = _FakeHistoryService({
      'push': [TagXpHistoryEntry(date: DateTime.now(), xp: 100, source: '')],
      'call': [TagXpHistoryEntry(date: DateTime.now(), xp: 5, source: '')],
    });

    final service = SkillGapDetectorService(
      history: history,
      library: _FakeLibrary(lessons),
    );

    final result = await service.getMissingTags(threshold: 0.5);
    expect(result, contains('fold')); // never reinforced
    expect(result, contains('call')); // bottom 50%
    expect(result, isNot(contains('push')));
  });
}
