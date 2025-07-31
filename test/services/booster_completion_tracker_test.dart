import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/booster_completion_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BoosterCompletionTracker.instance.resetForTest();
  });

  test('marks and checks completion', () async {
    final tracker = BoosterCompletionTracker.instance;
    expect(await tracker.isBoosterCompleted('b1'), isFalse);
    await tracker.markBoosterCompleted('b1');
    expect(await tracker.isBoosterCompleted('b1'), isTrue);
    final all = await tracker.getAllCompletedBoosters();
    expect(all, {'b1'});
  });
}
