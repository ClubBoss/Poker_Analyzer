import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_stage_progress_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('completion and mastery persist', () async {
    final tracker = TheoryStageProgressTracker.instance;
    expect(await tracker.isCompleted('stage1'), isFalse);
    expect(await tracker.getMastery('stage1'), 0.0);

    await tracker.updateMastery('stage1', 0.6);
    await tracker.markCompleted('stage1');

    expect(await tracker.isCompleted('stage1'), isTrue);
    expect(await tracker.getMastery('stage1'), 0.6);
  });

  test('getTheoryStageProgressList returns stored entries', () async {
    final tracker = TheoryStageProgressTracker.instance;
    await tracker.updateMastery('s1', 0.7);
    await tracker.updateMastery('s2', 0.4);
    final map = await tracker.getTheoryStageProgressList();
    expect(map['s1'], 0.7);
    expect(map['s2'], 0.4);
  });
}
