import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/adaptive_spot_scheduler.dart';
import 'package:poker_analyzer/services/user_error_rate_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';

TrainingPackSpot _spot(String id, String tag) =>
    TrainingPackSpot(id: id, tags: [tag], hand: HandData());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await UserErrorRateService.instance.reset();
  });

  test('deterministic with seed', () async {
    final pool = [_spot('a', 'x'), _spot('b', 'y')];
    final s1 = AdaptiveSpotScheduler(seed: 42);
    final p1 = await s1.next(packId: 'p', pool: pool, recentSpotIds: []);
    final s2 = AdaptiveSpotScheduler(seed: 42);
    final p2 = await s2.next(packId: 'p', pool: pool, recentSpotIds: []);
    expect(p1.id, p2.id);
  });

  test('higher tag error increases selection probability', () async {
    final now = DateTime.now();
    final svc = UserErrorRateService.instance;
    for (int i = 0; i < 5; i++) {
      await svc.recordAttempt(
          packId: 'p', tags: {'hi'}, isCorrect: false, ts: now);
      await svc.recordAttempt(
          packId: 'p', tags: {'lo'}, isCorrect: true, ts: now);
    }
    final pool = [_spot('s1', 'hi'), _spot('s2', 'lo')];
    int hi = 0;
    const trials = 200;
    for (int i = 0; i < trials; i++) {
      final sched = AdaptiveSpotScheduler(seed: i);
      final pick = await sched.next(packId: 'p', pool: pool, recentSpotIds: []);
      if (pick.id == 's1') hi++;
    }
    expect(hi, greaterThan(trials / 2));
  });

  test('respects no-repeat window', () async {
    final pool = [_spot('a', 'x'), _spot('b', 'y'), _spot('c', 'z')];
    final sched = AdaptiveSpotScheduler(seed: 1);
    final recent = <String>[];
    final first =
        await sched.next(packId: 'p', pool: pool, recentSpotIds: recent);
    recent.add(first.id);
    final second =
        await sched.next(packId: 'p', pool: pool, recentSpotIds: recent);
    expect(second.id, isNot(first.id));
  });

  test('exploration roughly matches epsilon', () async {
    final now = DateTime.now();
    final svc = UserErrorRateService.instance;
    for (int i = 0; i < 5; i++) {
      await svc.recordAttempt(
          packId: 'p', tags: {'x'}, isCorrect: false, ts: now);
    }
    final pool = [_spot('a', 'x'), _spot('b', 'y')];
    int low = 0;
    const trials = 200;
    const eps = 0.5;
    for (int i = 0; i < trials; i++) {
      final sched = AdaptiveSpotScheduler(seed: i);
      final pick = await sched.next(
          packId: 'p', pool: pool, recentSpotIds: [], epsilon: eps);
      if (pick.id == 'b') low++;
    }
    // Expect around 50 selections of the lower-weight spot with epsilon=0.5.
    expect(low, inInclusiveRange(30, 70));
  });
}
