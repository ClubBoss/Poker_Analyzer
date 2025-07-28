import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_streak_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('current streak computed from logs', () async {
    final now = DateTime.now();
    final logs = [
      {
        'id': 'a',
        'type': 'standard',
        'source': 'auto',
        'timestamp': now.toIso8601String(),
      },
      {
        'id': 'b',
        'type': 'mini',
        'source': 'auto',
        'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'c',
        'type': 'standard',
        'source': 'auto',
        'timestamp': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
    ];
    SharedPreferences.setMockInitialValues({
      'theory_reinforcement_logs': jsonEncode(logs),
    });
    final streak = await TheoryStreakService.instance.getCurrentStreak();
    expect(streak, 3);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('theory_streak_count'), 3);
    expect(prefs.getInt('theory_streak_best'), 3);
  });

  test('streak resets when a day is missed', () async {
    final now = DateTime.now();
    final logs = [
      {
        'id': 'a',
        'type': 'standard',
        'source': 'auto',
        'timestamp': now.toIso8601String(),
      },
      {
        'id': 'b',
        'type': 'mini',
        'source': 'auto',
        'timestamp': now.subtract(const Duration(days: 2)).toIso8601String(),
      },
    ];
    SharedPreferences.setMockInitialValues({
      'theory_reinforcement_logs': jsonEncode(logs),
    });
    final streak = await TheoryStreakService.instance.getCurrentStreak();
    expect(streak, 1);
  });
}
