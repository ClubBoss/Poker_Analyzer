import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/decay_streak_badge_notifier.dart';
import 'package:poker_analyzer/services/decay_streak_tracker_service.dart';

class _FakeTracker extends DecayStreakTrackerService {
  final int streak;
  const _FakeTracker(this.streak);

  @override
  Future<int> getCurrentStreak() async => streak;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('emits badge when milestone reached', () async {
    final notifier = DecayStreakBadgeNotifier(tracker: const _FakeTracker(3));
    final badge = await notifier.checkForBadge();
    expect(badge?.milestone, 3);
  });

  test('skips when milestone already awarded', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('decay_streak_last_milestone', 3);
    final notifier = DecayStreakBadgeNotifier(tracker: const _FakeTracker(5));
    final badge = await notifier.checkForBadge();
    expect(badge, isNull);
  });

  test('returns next milestone when surpassed', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('decay_streak_last_milestone', 7);
    final notifier = DecayStreakBadgeNotifier(tracker: const _FakeTracker(30));
    final badge = await notifier.checkForBadge();
    expect(badge?.milestone, 14);
  });
}
