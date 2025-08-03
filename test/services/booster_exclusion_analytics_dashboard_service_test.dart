import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/booster_exclusion_analytics_dashboard_service.dart';
import 'package:poker_analyzer/services/smart_booster_exclusion_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('aggregates exclusion statistics', () async {
    final tracker = SmartBoosterExclusionTrackerService();
    await tracker.logExclusion('t1', 'reasonA');
    await tracker.logExclusion('t2', 'reasonA');
    await tracker.logExclusion('t1', 'reasonB');

    final service = BoosterExclusionAnalyticsDashboardService();
    final data = await service.getDashboardData();

    expect(data.exclusionsByReason['reasonA'], 2);
    expect(data.exclusionsByReason['reasonB'], 1);

    expect(data.exclusionsByTag['t1'], 2);
    expect(data.exclusionsByTag['t2'], 1);

    expect(data.exclusionsByTagAndReason['t1']?['reasonA'], 1);
    expect(data.exclusionsByTagAndReason['t1']?['reasonB'], 1);
    expect(data.exclusionsByTagAndReason['t2']?['reasonA'], 1);

    await service.printSummary();
  });
}
