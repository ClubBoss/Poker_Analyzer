import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/streak_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('streak increments on consecutive days', () async {
    SharedPreferences.setMockInitialValues({});
    await StreakProgressService.instance.registerDailyActivity();
    var data = await StreakProgressService.instance.getStreak();
    expect(data.currentStreak, 1);
    expect(data.isTodayDone, isTrue);

    final prefs = await SharedPreferences.getInstance();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await prefs.setString('streak_progress_last', yesterday.toIso8601String());

    await StreakProgressService.instance.registerDailyActivity();
    data = await StreakProgressService.instance.getStreak();
    expect(data.currentStreak, 2);
    expect(data.longestStreak, 2);
  });
}
