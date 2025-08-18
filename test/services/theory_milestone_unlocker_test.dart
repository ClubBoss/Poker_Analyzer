import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_cluster_summary.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/theory_milestone_unlocker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('emits events when thresholds reached', () async {
    final lessons = <String, TheoryMiniLessonNode>{
      'l1': const TheoryMiniLessonNode(
        id: 'l1',
        title: 'L1',
        content: '',
        tags: ['a'],
      ),
      'l2': const TheoryMiniLessonNode(
        id: 'l2',
        title: 'L2',
        content: '',
        tags: ['a'],
      ),
      'l3': const TheoryMiniLessonNode(
        id: 'l3',
        title: 'L3',
        content: '',
        tags: ['a'],
      ),
      'l4': const TheoryMiniLessonNode(
        id: 'l4',
        title: 'L4',
        content: '',
        tags: ['a'],
      ),
    };
    const summary = TheoryClusterSummary(
      size: 4,
      entryPointIds: [],
      sharedTags: {'a'},
    );
    final unlocker = TheoryMilestoneUnlocker();
    final events = <TheoryMilestoneEvent>[];
    final sub = unlocker.stream.listen(events.add);

    await unlocker.checkCluster(
      clusterName: 'c',
      summary: summary,
      allLessons: lessons,
    );
    expect(events, isEmpty);

    await MiniLessonProgressTracker.instance.markCompleted('l1');
    await unlocker.checkCluster(
      clusterName: 'c',
      summary: summary,
      allLessons: lessons,
    );
    expect(events.length, 1);
    expect(events.last.type, 'insight');

    await MiniLessonProgressTracker.instance.markCompleted('l2');
    await unlocker.checkCluster(
      clusterName: 'c',
      summary: summary,
      allLessons: lessons,
    );
    expect(events.length, 2);
    expect(events.last.type, 'badge');

    await MiniLessonProgressTracker.instance.markCompleted('l3');
    await MiniLessonProgressTracker.instance.markCompleted('l4');
    await unlocker.checkCluster(
      clusterName: 'c',
      summary: summary,
      allLessons: lessons,
    );
    expect(events.length, 3);
    expect(events.last.type, 'unlock');

    await sub.cancel();
    await unlocker.dispose();
  });
}
