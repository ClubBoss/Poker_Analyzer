import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_cluster_summary.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/theory_lesson_progress_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final lessons = <TheoryMiniLessonNode>[
    const TheoryMiniLessonNode(id: 'l1', title: 'L1', content: '', tags: ['a']),
    const TheoryMiniLessonNode(id: 'l2', title: 'L2', content: '', tags: ['b']),
  ];

  test('progressForLessons returns completion ratio', () async {
    final tracker = TheoryLessonProgressTracker();
    await MiniLessonProgressTracker.instance.markCompleted('l1');
    final p = await tracker.progressForLessons(lessons);
    expect(p, 0.5);
  });

  test('progressForCluster filters by tags', () async {
    final tracker = TheoryLessonProgressTracker();
    await MiniLessonProgressTracker.instance.markCompleted('l1');
    final cluster = const TheoryClusterSummary(
      size: 2,
      entryPointIds: [],
      sharedTags: {'a'},
    );
    final map = {for (final l in lessons) l.id: l};
    final p = await tracker.progressForCluster(cluster, map);
    expect(p, 1.0);
  });

  test('computeMasteryGains aggregates tags', () async {
    final tracker = TheoryLessonProgressTracker();
    await MiniLessonProgressTracker.instance.markCompleted('l1');
    final gains = await tracker.computeMasteryGains(lessons, gain: 0.1);
    expect(gains['a'], 0.1);
    expect(gains.containsKey('b'), isFalse);
  });
}
