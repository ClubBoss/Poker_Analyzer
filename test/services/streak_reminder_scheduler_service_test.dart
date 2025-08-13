import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/streak_reminder_scheduler_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shouldNotifyToday prevents duplicate reminders', () async {
    SharedPreferences.setMockInitialValues({});
    final service = StreakReminderSchedulerService();
    await service.init();
    expect(await service.shouldNotifyToday(), isTrue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'streak_reminder_last', DateTime.now().toIso8601String());
    expect(await service.shouldNotifyToday(), isFalse);
    service.dispose();
  });
}
