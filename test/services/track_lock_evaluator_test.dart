import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/track_lock_evaluator.dart';
import 'package:poker_analyzer/services/skill_tree_node_progress_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final tracker = SkillTreeNodeProgressTracker.instance;

  setUp(() async {
    await tracker.resetForTest();
  });

  test('detects locked tracks based on prerequisites', () async {
    final eval = TrackLockEvaluator(prerequisites: const {'b': 'a'});
    expect(await eval.isLocked('a'), isFalse);
    expect(await eval.isLocked('b'), isTrue);
    await tracker.markTrackCompleted('a');
    expect(await eval.isLocked('b'), isFalse);
  });

  test('getUnlockedTracks returns only unlocked ids', () async {
    final eval = TrackLockEvaluator(prerequisites: const {'b': 'a', 'c': 'b'});
    await tracker.markTrackCompleted('a');
    final unlocked = await eval.getUnlockedTracks();
    expect(unlocked.contains('a'), isTrue);
    expect(unlocked.contains('b'), isTrue);
    expect(unlocked.contains('c'), isFalse);
  });
}
