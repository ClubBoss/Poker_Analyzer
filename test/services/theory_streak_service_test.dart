import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_streak_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('recordToday increments consecutive streak', () async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    SharedPreferences.setMockInitialValues({
      'theory_streak_last': yesterday.toIso8601String(),
      'theory_streak_count': 2,
      'theory_streak_best': 4,
    });
    await TheoryStreakService.instance.recordToday();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('theory_streak_count'), 3);
    expect(prefs.getInt('theory_streak_best'), 4);
  });

  test('recordToday resets streak when day missed', () async {
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    SharedPreferences.setMockInitialValues({
      'theory_streak_last': twoDaysAgo.toIso8601String(),
      'theory_streak_count': 5,
      'theory_streak_best': 5,
    });
    await TheoryStreakService.instance.recordToday();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('theory_streak_count'), 1);
    expect(prefs.getInt('theory_streak_best'), 5);
  });
}
