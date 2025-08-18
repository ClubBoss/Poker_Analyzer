import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/xp_guided_goal.dart';
import 'package:poker_analyzer/services/goal_to_training_launcher.dart';
import 'package:poker_analyzer/services/mini_lesson_library_service.dart';
import 'package:poker_analyzer/services/training_session_launcher.dart';

class _FakeLibrary implements MiniLessonLibraryService {
  final Map<String, TheoryMiniLessonNode> lessons;
  int loadCount = 0;
  _FakeLibrary(List<TheoryMiniLessonNode> items)
    : lessons = {for (final l in items) l.id: l};

  @override
  List<TheoryMiniLessonNode> get all => lessons.values.toList();

  @override
  TheoryMiniLessonNode? getById(String id) => lessons[id];

  @override
  Future<void> loadAll() async {
    loadCount++;
  }

  @override
  Future<void> reload() async {}

  @override
  List<TheoryMiniLessonNode> findByTags(List<String> tags) => const [];

  @override
  List<TheoryMiniLessonNode> getByTags(Set<String> tags) => const [];
}

class _FakeLauncher extends TrainingSessionLauncher {
  TheoryMiniLessonNode? lesson;
  int count = 0;
  const _FakeLauncher();

  @override
  Future<void> launchForMiniLesson(
    TheoryMiniLessonNode l, {
    List<String>? sessionTags,
  }) async {
    lesson = l;
    count++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('launchFromGoal starts lesson and marks complete', () async {
    final lesson = const TheoryMiniLessonNode(
      id: 'l1',
      title: 'Title',
      content: '',
    );
    var complete = 0;
    final goal = XPGuidedGoal(
      id: 'l1',
      label: 'Goal',
      xp: 10,
      source: 't',
      onComplete: () => complete++,
    );
    final library = _FakeLibrary([lesson]);
    const launcher = _FakeLauncher();
    final service = GoalToTrainingLauncher(
      library: library,
      launcher: launcher,
    );
    await service.launchFromGoal(goal);
    expect(library.loadCount, 1);
    expect(launcher.lesson?.id, 'l1');
    expect(complete, 1);
    expect(launcher.count, 1);
  });

  test('launchFromGoal does nothing when lesson missing', () async {
    final library = _FakeLibrary(const []);
    const launcher = _FakeLauncher();
    var complete = 0;
    final goal = XPGuidedGoal(
      id: 'x',
      label: 'Goal',
      xp: 10,
      source: 't',
      onComplete: () => complete++,
    );
    final service = GoalToTrainingLauncher(
      library: library,
      launcher: launcher,
    );
    await service.launchFromGoal(goal);
    expect(library.loadCount, 1);
    expect(launcher.lesson, isNull);
    expect(complete, 0);
    expect(launcher.count, 0);
  });
}
