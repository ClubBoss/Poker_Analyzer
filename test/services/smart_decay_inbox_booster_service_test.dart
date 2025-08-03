import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/smart_decay_inbox_booster_service.dart';
import 'package:poker_analyzer/services/decay_tag_retention_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('builds inbox items for decayed tags', () async {
    final retention = const DecayTagRetentionTrackerService();
    final now = DateTime.now();
    await retention.markBoosterCompleted('alpha',
        time: now.subtract(const Duration(days: 40)));
    await retention.markBoosterCompleted('beta',
        time: now.subtract(const Duration(days: 20)));

    final service = SmartDecayInboxBoosterService(retention: retention);
    final items = await service.getItems(limit: 1);
    expect(items.length, 1);
    expect(items.first.tag, 'alpha');
    expect(items.first.type, 'booster');
    expect(items.first.source, 'decayRecovery');
    expect(items.first.urgency, isNotNull);
  });
}
