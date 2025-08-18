import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/theory_booster_recall_engine.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/theory_prompt_dismiss_tracker.dart';

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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TheoryBoosterRecallEngine.instance.resetForTest();
    TheoryPromptDismissTracker.instance.resetForTest();
  });

  test('recalls suggestions after cooldown', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 'L1',
      content: '',
      tags: [],
    );
    final engine = TheoryBoosterRecallEngine(library: _FakeLibrary([lesson]));
    final old = DateTime.now().subtract(const Duration(days: 4));
    await engine.recordSuggestion('l1', timestamp: old);
    final rec = await engine.recallUnlaunched(after: const Duration(days: 3));
    expect(rec.map((e) => e.id), ['l1']);
  });

  test('launched lessons are not recalled', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l2',
      title: 'L2',
      content: '',
      tags: [],
    );
    final engine = TheoryBoosterRecallEngine(library: _FakeLibrary([lesson]));
    final old = DateTime.now().subtract(const Duration(days: 4));
    await engine.recordSuggestion('l2', timestamp: old);
    await engine.recordLaunch('l2');
    final rec = await engine.recallUnlaunched(after: const Duration(days: 3));
    expect(rec, isEmpty);
  });

  test('recallDismissedUnlaunched returns dismissed lessons', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l3',
      title: 'L3',
      content: '',
      tags: [],
    );
    final engine = TheoryBoosterRecallEngine(library: _FakeLibrary([lesson]));
    final old = DateTime.now().subtract(const Duration(days: 4));
    await engine.recordSuggestion('l3', timestamp: old);
    await TheoryPromptDismissTracker.instance.markDismissed(
      'l3',
      timestamp: old,
    );
    final rec = await engine.recallDismissedUnlaunched(
      since: const Duration(days: 3),
    );
    expect(rec.map((e) => e.id), ['l3']);
  });
}
