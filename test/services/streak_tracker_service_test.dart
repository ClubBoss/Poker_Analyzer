import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/streak_tracker_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('streak increments on consecutive days', () async {
    SharedPreferences.setMockInitialValues({});
    final service = StreakTrackerService.instance;
    final ctx = TestWidgetsFlutterBinding.instance.renderViewElement!;
    final milestone1 = await service.markActiveToday(ctx);
    var current = await service.getCurrentStreak();
    var best = await service.getBestStreak();
    expect(current, 1);
    expect(best, 1);
    expect(milestone1, false);

    final prefs = await SharedPreferences.getInstance();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await prefs.setString('lastActiveDate', yesterday.toIso8601String());
    await prefs.setInt('currentStreak', 1);
    await prefs.setInt('bestStreak', 3);

    final milestone2 = await service.markActiveToday(ctx);
    current = await service.getCurrentStreak();
    best = await service.getBestStreak();
    expect(current, 2);
    expect(best, 3);
    expect(milestone2, false);

    final old = DateTime.now().subtract(const Duration(days: 3));
    await prefs.setString('lastActiveDate', old.toIso8601String());
    await prefs.setInt('currentStreak', 2);

    current = await service.getCurrentStreak();
    best = await service.getBestStreak();
    expect(current, 0);
    expect(best, 3);
  });

  test('milestone detected correctly', () async {
    SharedPreferences.setMockInitialValues({});
    final service = StreakTrackerService.instance;
    // Day 1
    final ctx = TestWidgetsFlutterBinding.instance.renderViewElement!;
    await service.markActiveToday(ctx);
    final prefs = await SharedPreferences.getInstance();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await prefs.setString('lastActiveDate', yesterday.toIso8601String());
    await prefs.setInt('currentStreak', 1);
    // Day 2
    await service.markActiveToday(ctx);
    final yesterday2 = DateTime.now().subtract(const Duration(days: 1));
    await prefs.setString('lastActiveDate', yesterday2.toIso8601String());
    await prefs.setInt('currentStreak', 2);
    // Day 3 should hit milestone
    final milestone = await service.markActiveToday(ctx);
    expect(milestone, true);
  });

  test('last 30 days map returns correct activity', () async {
    SharedPreferences.setMockInitialValues({
      'streakActiveDays': [
        DateTime.now().toIso8601String().split('T').first,
        DateTime.now()
            .subtract(const Duration(days: 3))
            .toIso8601String()
            .split('T')
            .first,
      ],
    });
    final service = StreakTrackerService.instance;
    final map = await service.getLast30DaysMap();
    final today = DateTime.now();
    final threeAgo = today.subtract(const Duration(days: 3));
    final todayKey = DateTime(today.year, today.month, today.day);
    final threeKey = DateTime(threeAgo.year, threeAgo.month, threeAgo.day);
    expect(map[todayKey], true);
    expect(map[threeKey], true);
    expect(map[todayKey.subtract(const Duration(days: 1))], false);
  });

  testWidgets('missed day uses monthly freeze', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = StreakTrackerService.instance;
    await tester.pumpWidget(Container());
    final ctx = tester.element(find.byType(Container));

    await service.markActiveToday(ctx);
    final prefs = await SharedPreferences.getInstance();
    final twoAgo = DateTime.now().subtract(const Duration(days: 2));
    await prefs.setString('lastActiveDate', twoAgo.toIso8601String());
    await prefs.setInt('currentStreak', 3);

    await tester.runAsync(() async {
      await service.checkAndHandleStreakBreak(ctx);
    });

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final lastStr = prefs.getString('lastActiveDate');
    expect(DateTime.parse(lastStr!).day, yesterday.day);
    expect((prefs.getStringList('usedFreezes') ?? []).isNotEmpty, isTrue);

    await service.markActiveToday(ctx);
    final current = await service.getCurrentStreak();
    expect(current, 4);
  });
}
