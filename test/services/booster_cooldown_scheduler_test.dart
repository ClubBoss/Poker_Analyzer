import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/booster_cooldown_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BoosterCooldownScheduler.instance.resetForTest();
  });

  test('cooldown after dismissal streak', () async {
    final now = DateTime.now();
    for (var i = 0; i < 3; i++) {
      await BoosterCooldownScheduler.instance
          .recordDismissed('recap', timestamp: now.subtract(Duration(hours: i)));
    }
    expect(await BoosterCooldownScheduler.instance.isCoolingDown('recap'), isTrue);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('booster_cooldown_scheduler');
    final map = jsonDecode(raw!) as Map;
    final list = List<Map<String, dynamic>>.from(map['recap'] as List);
    list[0]['t'] = DateTime.now()
        .subtract(const Duration(hours: 7))
        .toIso8601String();
    map['recap'] = list;
    await prefs.setString('booster_cooldown_scheduler', jsonEncode(map));
    BoosterCooldownScheduler.instance.resetForTest();
    expect(await BoosterCooldownScheduler.instance.isCoolingDown('recap'), isFalse);
  });

  test('overuse triggers cooldown', () async {
    final now = DateTime.now();
    for (var i = 0; i < 5; i++) {
      await BoosterCooldownScheduler.instance
          .recordSuggested('skill', timestamp: now.subtract(Duration(hours: i)));
    }
    expect(await BoosterCooldownScheduler.instance.isCoolingDown('skill'), isTrue);
  });

  test('acceptance clears recent dismissal cooldown', () async {
    await BoosterCooldownScheduler.instance.recordDismissed('goal');
    await BoosterCooldownScheduler.instance.recordAccepted('goal');
    expect(await BoosterCooldownScheduler.instance.isCoolingDown('goal'), isFalse);
  });
});
