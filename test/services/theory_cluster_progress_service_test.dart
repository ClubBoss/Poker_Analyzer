import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_lesson_cluster.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/theory_cluster_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('computeProgress returns stats for each cluster', () async {
    final a = const TheoryMiniLessonNode(id: 'a', title: 'A', content: '');
    final b = const TheoryMiniLessonNode(id: 'b', title: 'B', content: '');
    final c = const TheoryMiniLessonNode(id: 'c', title: 'C', content: '');
    final cluster1 = TheoryLessonCluster(lessons: [a, b], tags: const {});
    final cluster2 = TheoryLessonCluster(lessons: [c], tags: const {});

    await MiniLessonProgressTracker.instance.markCompleted('a');

    final service = const TheoryClusterProgressService();
    final result = await service.computeProgress([cluster1, cluster2]);

    expect(result.length, 2);
    expect(result[0].completed, 1);
    expect(result[0].total, 2);
    expect(result[0].percent, closeTo(0.5, 0.001));
    expect(result[1].completed, 0);
    expect(result[1].total, 1);
    expect(result[1].percent, 0);
  });
}
