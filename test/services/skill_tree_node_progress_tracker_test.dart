import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('markCompleted persists and reports completion', () async {
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();

    expect(await tracker.isCompleted('n1'), isFalse);
    await tracker.markCompleted('n1');
    expect(await tracker.isCompleted('n1'), isTrue);
  });

  test('completedNodeIds notifies on updates', () async {
    final tracker = SkillTreeNodeProgressTracker.instance;
    await tracker.resetForTest();

    final changes = <Set<String>>[];
    tracker.completedNodeIds.addListener(() {
      changes.add(tracker.completedNodeIds.value);
    });

    await tracker.markCompleted('a');
    await tracker.markCompleted('b');

    expect(changes.length, 2);
    expect(changes.last.contains('b'), isTrue);
  });
}
