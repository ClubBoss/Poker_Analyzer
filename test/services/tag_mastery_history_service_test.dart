import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/tag_mastery_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getHistory aggregates daily xp per tag', () async {
    final now = DateTime.now();
    final day1 = DateTime(now.year, now.month, now.day);
    final day2 = day1.subtract(const Duration(days: 1));

    SharedPreferences.setMockInitialValues({
      'tag_xp_test': jsonEncode({
        'total': 30,
        'history': [
          {'date': day1.toIso8601String(), 'xp': 10, 'source': 'a'},
          {
            'date': day1.add(const Duration(hours: 3)).toIso8601String(),
            'xp': 5,
            'source': 'b',
          },
          {'date': day2.toIso8601String(), 'xp': 15, 'source': 'c'},
        ],
      }),
    });

    final service = TagMasteryHistoryService();
    final hist = await service.getHistory();
    expect(hist.containsKey('test'), isTrue);
    final list = hist['test']!;
    expect(list.length, 2);
    expect(list.first.date, day2);
    expect(list.first.xp, 15);
    expect(list.last.date, day1);
    expect(list.last.xp, 15); // 10 + 5
  });
}
