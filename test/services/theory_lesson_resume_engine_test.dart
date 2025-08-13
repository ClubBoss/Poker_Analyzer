import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_lesson_resume_engine.dart';
import 'package:poker_analyzer/services/theory_lesson_trail_tracker.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/theory_lesson_tag_clusterer.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> items;
  _FakeLibrary(this.items);

  @override
  List<TheoryMiniLessonNode> get all => items;

  @override
  TheoryMiniLessonNode? getById(String id) =>
      items.firstWhere((e) => e.id == id, orElse: () => null);

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => const [];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await TheoryLessonTrailTracker.instance.clearTrail();
  });

  test('returns first unfinished lesson from trail', () async {
    final lessons = [
      const TheoryMiniLessonNode(id: 'l1', title: 'A', content: ''),
      const TheoryMiniLessonNode(id: 'l2', title: 'B', content: ''),
    ];
    final tracker = TheoryLessonTrailTracker.instance;
    await tracker.recordVisit('l1');
    await tracker.recordVisit('l2');
    await MiniLessonProgressTracker.instance.markCompleted('l1');

    final engine = TheoryLessonResumeEngine(
      library: _FakeLibrary(lessons),
      clusterer: TheoryLessonTagClusterer(library: _FakeLibrary(lessons)),
    );
    final res = await engine.getResumeTarget();
    expect(res?.id, 'l2');
  });

  test('falls back to first incomplete in cluster', () async {
    final lessons = [
      const TheoryMiniLessonNode(
          id: 'l1', title: 'A', content: '', tags: ['x'], nextIds: ['l2']),
      const TheoryMiniLessonNode(
          id: 'l2', title: 'B', content: '', tags: ['x']),
    ];
    final tracker = TheoryLessonTrailTracker.instance;
    await tracker.recordVisit('l1');
    await MiniLessonProgressTracker.instance.markCompleted('l1');

    final library = _FakeLibrary(lessons);
    final engine = TheoryLessonResumeEngine(
      library: library,
      clusterer: TheoryLessonTagClusterer(library: library),
    );
    final res = await engine.getResumeTarget();
    expect(res?.id, 'l2');
  });

  test('returns null when all completed', () async {
    final lessons = [
      const TheoryMiniLessonNode(id: 'l1', title: 'A', content: ''),
    ];
    final tracker = TheoryLessonTrailTracker.instance;
    await tracker.recordVisit('l1');
    await MiniLessonProgressTracker.instance.markCompleted('l1');

    final library = _FakeLibrary(lessons);
    final engine = TheoryLessonResumeEngine(
      library: library,
      clusterer: TheoryLessonTagClusterer(library: library),
    );
    final res = await engine.getResumeTarget();
    expect(res, isNull);
  });
}
