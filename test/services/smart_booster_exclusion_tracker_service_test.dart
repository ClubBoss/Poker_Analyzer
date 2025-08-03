import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/smart_booster_exclusion_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('logs exclusions and exports them', () async {
    final tracker = SmartBoosterExclusionTrackerService();
    await tracker.logExclusion('t1', 'rateLimited');

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('booster_exclusion_log');
    expect(stored, isNotNull);
    expect(stored!.length, 1);

    final exported = await tracker.exportLog();
    expect(exported.length, 1);
    expect(exported.first['tag'], 't1');
    expect(exported.first['reason'], 'rateLimited');
    expect(exported.first['timestamp'], isNotNull);
  });

  test('keeps only last 100 entries', () async {
    final tracker = SmartBoosterExclusionTrackerService();
    for (var i = 0; i < 105; i++) {
      await tracker.logExclusion('t\$i', 'deduplicated');
    }

    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList('booster_exclusion_log');
    expect(stored, isNotNull);
    expect(stored!.length, 100);

    final exported = await tracker.exportLog();
    expect(exported.first['tag'], 't5');
  });
}
