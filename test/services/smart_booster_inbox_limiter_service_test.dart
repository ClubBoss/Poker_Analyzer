import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/smart_booster_inbox_limiter_service.dart';
import 'package:poker_analyzer/services/smart_booster_exclusion_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('enforces per-tag cooldown and daily limit', () async {
    final limiter = SmartBoosterInboxLimiterService();

    expect(await limiter.canShow('t1'), isTrue);
    await limiter.recordShown('t1');
    expect(await limiter.canShow('t1'), isFalse); // tag cooldown

    expect(await limiter.canShow('t2'), isTrue);
    await limiter.recordShown('t2');

    // Daily limit reached after two boosters
    expect(await limiter.canShow('t3'), isFalse);
  });

  test('resets daily count on new day and after cooldown', () async {
    final limiter = SmartBoosterInboxLimiterService();
    await limiter.recordShown('t1');

    final prefs = await SharedPreferences.getInstance();
    // Simulate yesterday to reset daily count
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final dateKey =
        '${yesterday.year.toString().padLeft(4, '0')}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    await prefs.setString('booster_inbox_total_date', dateKey);
    await prefs.setInt(
      'booster_inbox_last_t1',
      DateTime.now().subtract(const Duration(hours: 49)).millisecondsSinceEpoch,
    );

    expect(await limiter.getTotalBoostersShownToday(), 0);
    expect(await limiter.canShow('t1'), isTrue);
  });

  test('logs rate limited exclusions', () async {
    final limiter = SmartBoosterInboxLimiterService();
    await limiter.recordShown('t1');
    expect(await limiter.canShow('t1'), isFalse);
    final log = await SmartBoosterExclusionTrackerService().exportLog();
    expect(log.length, 1);
    expect(log.first['tag'], 't1');
    expect(log.first['reason'], 'rateLimited');
  });
}
