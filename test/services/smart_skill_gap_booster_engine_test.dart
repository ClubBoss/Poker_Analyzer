import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/smart_skill_gap_booster_engine.dart';
import 'package:poker_analyzer/services/skill_gap_detector_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';

class _FakeDetector extends SkillGapDetectorService {
  final List<String> tags;
  _FakeDetector(this.tags);
  @override
  Future<List<String>> getMissingTags({double threshold = 0.1}) async => tags;
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
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => [
        for (final t in tags) ...lessons.where((l) => l.tags.contains(t)),
      ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('recommend returns lessons covering missing tags', () async {
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
      const TheoryMiniLessonNode(
        id: 'l3',
        title: 'C',
        content: '',
        tags: ['push', 'call'],
      ),
    ];
    final engine = SmartSkillGapBoosterEngine(
      detector: _FakeDetector(['push', 'call']),
      library: _FakeLibrary(lessons),
      progress: MiniLessonProgressTracker.instance,
    );

    final result = await engine.recommend(max: 2);
    expect(result.map((e) => e.id).toList(), ['l3']);
  });

  test('deduplicates by tag and prefers less viewed lessons', () async {
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
      const TheoryMiniLessonNode(
        id: 'l3',
        title: 'C',
        content: '',
        tags: ['push'],
      ),
    ];
    await MiniLessonProgressTracker.instance.markViewed('l1');

    final engine = SmartSkillGapBoosterEngine(
      detector: _FakeDetector(['push', 'call']),
      library: _FakeLibrary(lessons),
      progress: MiniLessonProgressTracker.instance,
    );

    final result = await engine.recommend(max: 2);
    expect(result.map((e) => e.id).toList(), ['l2', 'l3']);
  });
}
