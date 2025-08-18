import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/decay_booster_injector_scheduler.dart';
import 'package:poker_analyzer/services/decay_booster_spot_injector.dart';

class _FakeInjector extends DecayBoosterSpotInjector {
  int calls = 0;
  _FakeInjector() : super();
  @override
  Future<void> inject({DateTime? now}) async {
    calls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('injects when day passed', () async {
    final injector = _FakeInjector();
    final sched = DecayBoosterInjectorScheduler(injector: injector);
    await sched.maybeInject(now: DateTime(2024, 1, 1));
    expect(injector.calls, 1);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('decay_booster_inject_last'), isNotNull);
  });

  test('skips when recent', () async {
    final now = DateTime(2024, 1, 2, 10);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'decay_booster_inject_last',
      now.subtract(const Duration(hours: 2)).toIso8601String(),
    );
    final injector = _FakeInjector();
    final sched = DecayBoosterInjectorScheduler(injector: injector);
    await sched.maybeInject(now: now);
    expect(injector.calls, 0);
  });
}
