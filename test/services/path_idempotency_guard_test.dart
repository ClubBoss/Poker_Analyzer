import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/plan_idempotency_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('skip within window and inject after expiry', () async {
    final guard = PlanIdempotencyGuard();
    const user = 'u1';
    const sig = 's1';
    expect(await guard.shouldInject(user, sig), isTrue);
    await guard.recordInjected(user, sig);
    expect(await guard.shouldInject(user, sig), isFalse);
    final prefs = await SharedPreferences.getInstance();
    final key = 'planner.injected.$user.$sig';
    final past =
        DateTime.now().subtract(const Duration(hours: 25)).millisecondsSinceEpoch;
    await prefs.setInt(key, past);
    expect(await guard.shouldInject(user, sig), isTrue);
  });
}
