import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/player_profile.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/adaptive_theory_scheduler.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/tag_mastery_service.dart';
import 'package:poker_analyzer/services/session_log_service.dart';
import 'package:poker_analyzer/services/training_session_service.dart';

class _StubLibrary extends MiniLessonLibraryService {
  final List<TheoryMiniLessonNode> items;
  _StubLibrary(this.items) : super._();

  @override
  List<TheoryMiniLessonNode> get all => items;

  @override
  Future<void> loadAll() async {}

  @override
  Future<void> reload() async {}
}

class _FakeMastery extends TagMasteryService {
  final Map<String, double> values;
  _FakeMastery(this.values)
    : super(logs: SessionLogService(sessions: TrainingSessionService()));

  @override
  Future<Map<String, double>> computeMastery({bool force = false}) async =>
      values;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('recommendNextLesson prefers weak tag lessons', () async {
    final lessons = [
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'L1',
        content: '',
        tags: ['a'],
        nextIds: ['l2'],
      ),
      const TheoryMiniLessonNode(
        id: 'l2',
        title: 'L2',
        content: '',
        tags: ['b'],
      ),
      const TheoryMiniLessonNode(
        id: 'l3',
        title: 'L3',
        content: '',
        tags: ['c'],
      ),
    ];
    final library = _StubLibrary(lessons);
    final scheduler = AdaptiveTheoryScheduler(
      library: library,
      mastery: _FakeMastery({'b': 0.2, 'c': 0.8}),
    );
    final profile = PlayerProfile(completedLessonIds: {'l1'});

    final next = await scheduler.recommendNextLesson(profile);
    expect(next?.id, 'l2');
  });

  test('recommendNextLesson falls back to unlocked lesson', () async {
    final lessons = [
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'L1',
        content: '',
        tags: ['a'],
      ),
      const TheoryMiniLessonNode(
        id: 'l2',
        title: 'L2',
        content: '',
        tags: ['b'],
      ),
    ];
    final library = _StubLibrary(lessons);
    final scheduler = AdaptiveTheoryScheduler(
      library: library,
      mastery: _FakeMastery({'x': 0.1}),
    );
    final profile = PlayerProfile();

    final next = await scheduler.recommendNextLesson(profile);
    expect(next, isNotNull);
    expect(['l1', 'l2'], contains(next!.id));
  });
}
