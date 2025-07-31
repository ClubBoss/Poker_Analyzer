import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/booster_inbox_delivery_service.dart';
import 'package:poker_analyzer/services/smart_recall_booster_scheduler.dart';
import 'package:poker_analyzer/models/scheduled_booster_entry.dart';

class _FakeScheduler extends SmartRecallBoosterScheduler {
  final List<ScheduledBoosterEntry> items;
  _FakeScheduler(this.items);

  @override
  Future<List<ScheduledBoosterEntry>> getNextBoosters({int max = 5}) async {
    return items.take(max).toList();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns next deliverable tag', () async {
    final scheduler = _FakeScheduler([
      const ScheduledBoosterEntry(tag: 'a', priorityScore: 2),
      const ScheduledBoosterEntry(tag: 'b', priorityScore: 1),
    ]);
    final service = BoosterInboxDeliveryService(
      scheduler: scheduler,
      cooldown: Duration(hours: 12),
    );

    final tag1 = await service.getNextDeliverableTag();
    expect(tag1, 'a');
    await service.markDelivered(tag1!);

    final tag2 = await service.getNextDeliverableTag();
    expect(tag2, 'b');
  });

  test('respects cooldown window', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'delivered_booster_tags': jsonEncode({'a': now.toIso8601String()}),
    });
    final scheduler = _FakeScheduler([
      const ScheduledBoosterEntry(tag: 'a', priorityScore: 2),
    ]);
    final service = BoosterInboxDeliveryService(
      scheduler: scheduler,
      cooldown: Duration(hours: 12),
    );

    final tag = await service.getNextDeliverableTag();
    expect(tag, isNull);
  });

  test('allows delivery after cooldown expires', () async {
    final old = DateTime.now().subtract(const Duration(hours: 13));
    SharedPreferences.setMockInitialValues({
      'delivered_booster_tags': jsonEncode({'a': old.toIso8601String()}),
    });
    final scheduler = _FakeScheduler([
      const ScheduledBoosterEntry(tag: 'a', priorityScore: 2),
    ]);
    final service = BoosterInboxDeliveryService(
      scheduler: scheduler,
      cooldown: Duration(hours: 12),
    );

    final tag = await service.getNextDeliverableTag();
    expect(tag, 'a');
  });
}
