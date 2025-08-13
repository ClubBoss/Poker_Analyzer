import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/inbox_booster_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    InboxBoosterTrackerService.instance.resetForTest();
  });

  test('markShown records timestamp and count', () async {
    await InboxBoosterTrackerService.instance.markShown('l1');
    final recent =
        await InboxBoosterTrackerService.instance.wasRecentlyShown('l1');
    expect(recent, isTrue);
    final stats =
        await InboxBoosterTrackerService.instance.getInteractionStats();
    expect(stats['l1']?['shows'], 1);
  });

  test('markClicked increments clicks', () async {
    await InboxBoosterTrackerService.instance.markClicked('l2');
    await InboxBoosterTrackerService.instance.markClicked('l2');
    final stats =
        await InboxBoosterTrackerService.instance.getInteractionStats();
    expect(stats['l2']?['clicks'], 2);
  });
}
