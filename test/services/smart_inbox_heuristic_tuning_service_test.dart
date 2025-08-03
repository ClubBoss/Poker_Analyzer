import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/smart_booster_exclusion_tracker_service.dart';
import 'package:poker_analyzer/services/smart_inbox_heuristic_tuning_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('tunes heuristics based on exclusion analytics', () async {
    final tracker = SmartBoosterExclusionTrackerService();
    // Overused tag with many deduplications.
    for (var i = 0; i < 6; i++) {
      await tracker.logExclusion('t1', 'deduplicated');
    }
    // Underused tag limited by rate limiting.
    for (var i = 0; i < 4; i++) {
      await tracker.logExclusion('t2', 'rateLimited');
    }

    final service = SmartInboxHeuristicTuningService();
    await service.tuneHeuristics();

    expect(service.cooldownOverrides['t1'], isNotNull);
    expect(service.priorityAdjustments['t1'], lessThan(0));
    expect(service.dailyLimitAdjustments['t2'], greaterThan(0));
  });
}
