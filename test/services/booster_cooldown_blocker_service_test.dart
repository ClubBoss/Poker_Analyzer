import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/booster_cooldown_blocker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BoosterCooldownBlockerService.instance.resetForTest();
  });

  test('cooldown after dismissal expires', () async {
    final svc = BoosterCooldownBlockerService.instance;
    await svc.markDismissed('recap');
    expect(await svc.isCoolingDown('recap'), isTrue);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('booster_cooldown_blocker');
    final map = jsonDecode(raw!) as Map;
    final rec = Map<String, dynamic>.from(map['recap'] as Map);
    rec['d'] =
        DateTime.now().subtract(const Duration(hours: 4)).toIso8601String();
    map['recap'] = rec;
    await prefs.setString('booster_cooldown_blocker', jsonEncode(map));
    svc.resetForTest();
    expect(await svc.isCoolingDown('recap'), isFalse);
  });

  test('completion also triggers cooldown', () async {
    final svc = BoosterCooldownBlockerService.instance;
    await svc.markCompleted('goal');
    expect(await svc.isCoolingDown('goal'), isTrue);
  });
}
