import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/inbox_booster_tuner_service.dart';
import 'package:poker_analyzer/services/inbox_booster_tracker_service.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';

class _FakeLibrary extends MiniLessonLibraryService {
  final Map<String, TheoryMiniLessonNode> items;
  _FakeLibrary(List<TheoryMiniLessonNode> lessons)
      : items = {for (final l in lessons) l.id: l};

  @override
  Future<void> loadAll() async {}

  @override
  TheoryMiniLessonNode? getById(String id) => items[id];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InboxBoosterTrackerService.instance.resetForTest();
  });

  test('computeTagBoostScores calculates scores', () async {
    final lessons = [
      const TheoryMiniLessonNode(
          id: 'l1', title: 'A', content: '', tags: ['icm']),
      const TheoryMiniLessonNode(
          id: 'l2', title: 'B', content: '', tags: ['call']),
    ];
    final library = _FakeLibrary(lessons);

    for (var i = 0; i < 10; i++) {
      await InboxBoosterTrackerService.instance.markShown('l1');
    }
    for (var i = 0; i < 4; i++) {
      await InboxBoosterTrackerService.instance.markClicked('l1');
    }
    for (var i = 0; i < 6; i++) {
      await InboxBoosterTrackerService.instance.markShown('l2');
    }

    final tuner = InboxBoosterTunerService(
      tracker: InboxBoosterTrackerService.instance,
      library: library,
    );
    final scores = await tuner.computeTagBoostScores();

    expect(scores['icm'], closeTo(1.7, 0.01));
    expect(scores['call'], closeTo(0.9, 0.01));
  });
}
