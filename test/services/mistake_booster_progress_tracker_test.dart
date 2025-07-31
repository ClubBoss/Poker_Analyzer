import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/mistake_booster_progress_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tracks repetitions and detects completed tags', () async {
    final tracker = MistakeBoosterProgressTracker.instance;
    await tracker.resetForTest();

    await tracker.recordProgress({'push': 0.05});
    await tracker.recordProgress({'push': 0.04});
    await tracker.recordProgress({'push': 0.03});

    final completed = await tracker.getCompletedTags();
    expect(completed.length, 1);
    final status = completed.first;
    expect(status.tag, 'push');
    expect(status.repetitions, 3);
    expect(status.totalDelta, closeTo(0.12, 1e-6));
  });
}
