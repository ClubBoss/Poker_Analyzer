import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/recap_auto_repeat_scheduler.dart';
import 'package:poker_analyzer/services/recap_history_tracker.dart';
import 'package:poker_analyzer/services/smart_recap_suggestion_engine.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> items;
  _FakeLibrary(this.items);
  @override
  List<TheoryMiniLessonNode> get all => items;
  @override
  Future<void> loadAll() async {}
  @override
  Future<void> reload() async {}
  @override
  TheoryMiniLessonNode? getById(String id) =>
      items.firstWhere((e) => e.id == id, orElse: () => null);
  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => [];
  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RecapAutoRepeatScheduler.instance.resetForTest();
    RecapHistoryTracker.instance.resetForTest();
  });

  test('nextRecap emits lesson from repeat scheduler', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 't',
      content: '',
    );
    final engine = SmartRecapSuggestionEngine(
      library: _FakeLibrary([lesson]),
      repeats: RecapAutoRepeatScheduler.instance,
    );
    await engine.start(interval: const Duration(milliseconds: 10));
    await RecapAutoRepeatScheduler.instance.scheduleRepeat('l1', Duration.zero);
    final result = await engine.nextRecap.first;
    expect(result.id, 'l1');
    await engine.dispose();
  });
}
