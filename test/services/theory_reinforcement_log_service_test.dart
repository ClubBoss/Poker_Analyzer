import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_reinforcement_log_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('logInjection stores entry', () async {
    await TheoryReinforcementLogService.instance.logInjection(
      'b1',
      'mini',
      'auto',
    );
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('theory_reinforcement_logs')!;
    final list = jsonDecode(raw) as List;
    expect(list.length, 1);
    final data = list.first as Map<String, dynamic>;
    expect(data['id'], 'b1');
    expect(data['type'], 'mini');
    expect(data['source'], 'auto');
    expect(data['timestamp'], isNotEmpty);
  });

  test('getRecent filters by duration', () async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'theory_reinforcement_logs': jsonEncode([
        {
          'id': 'old',
          'type': 'standard',
          'source': 'manual',
          'timestamp': now.subtract(const Duration(days: 5)).toIso8601String(),
        },
        {
          'id': 'new',
          'type': 'mini',
          'source': 'auto',
          'timestamp': now.subtract(const Duration(hours: 1)).toIso8601String(),
        },
      ]),
    });
    final list = await TheoryReinforcementLogService.instance.getRecent(
      within: const Duration(days: 2),
    );
    expect(list.length, 1);
    expect(list.first.id, 'new');
  });
}
