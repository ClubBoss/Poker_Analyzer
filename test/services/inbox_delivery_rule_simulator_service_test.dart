import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/inbox_delivery_rule_simulator_service.dart';
import 'package:poker_analyzer/services/smart_booster_exclusion_tracker_service.dart';
import 'package:poker_analyzer/services/smart_inbox_heuristic_tuning_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns show when no history', () async {
    final sim = InboxDeliveryRuleSimulatorService(
      tuning: SmartInboxHeuristicTuningService(),
      tracker: SmartBoosterExclusionTrackerService(),
    );
    final results = await sim.simulate(['t1']);
    expect(results.single.wouldShow, true);
  });

  test('detects cooldown and rate limit with adjustments', () async {
    final tracker = SmartBoosterExclusionTrackerService();
    final tuning = SmartInboxHeuristicTuningService();
    final sim = InboxDeliveryRuleSimulatorService(tuning: tuning, tracker: tracker);

    // first exclusion triggers cooldown
    await tracker.logExclusion('t1', 'rateLimited');
    var results = await sim.simulate(['t1']);
    expect(results.single.wouldShow, false);
    expect(results.single.reasonIfExcluded, 'cooldown');

    // override cooldown and hit rate limit
    tuning.cooldownOverrides['t1'] = Duration.zero;
    await tracker.logExclusion('t1', 'rateLimited');
    results = await sim.simulate(['t1']);
    expect(results.single.wouldShow, false);
    expect(results.single.reasonIfExcluded, 'rateLimited');

    // increase daily limit so tag would show
    tuning.dailyLimitAdjustments['t1'] = 1;
    results = await sim.simulate(['t1']);
    expect(results.single.wouldShow, true);
  });
}

