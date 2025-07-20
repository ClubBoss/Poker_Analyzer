import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/suggested_training_packs_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('log keeps max 100 entries', () async {
    for (var i = 0; i < 120; i++) {
      await SuggestedTrainingPacksHistoryService.logSuggestion(
        packId: 'id$i',
        source: 'test',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('suggested_pack_history')!;
    expect(list.length, 100);
    final first = jsonDecode(list.first) as Map<String, dynamic>;
    final last = jsonDecode(list.last) as Map<String, dynamic>;
    expect(first['id'], 'id119');
    expect(last['id'], 'id20');
  });

  test('getRecentSuggestions filters by age', () async {
    final old = DateTime.now().subtract(const Duration(days: 40));
    final recent = DateTime.now().subtract(const Duration(days: 5));
    SharedPreferences.setMockInitialValues({
      'suggested_pack_history': [
        jsonEncode({'id': 'old', 'source': 's', 'ts': old.toIso8601String()}),
        jsonEncode({'id': 'new', 'source': 's', 'ts': recent.toIso8601String()}),
      ]
    });
    final list = await SuggestedTrainingPacksHistoryService.getRecentSuggestions(
      since: const Duration(days: 30),
    );
    expect(list.length, 1);
    expect(list.first.id, 'new');
  });

  test('clearStaleEntries removes old logs', () async {
    final old = DateTime.now().subtract(const Duration(days: 70));
    final recent = DateTime.now().subtract(const Duration(days: 5));
    SharedPreferences.setMockInitialValues({
      'suggested_pack_history': [
        jsonEncode({'id': 'old', 'source': 's', 'ts': old.toIso8601String()}),
        jsonEncode({'id': 'new', 'source': 's', 'ts': recent.toIso8601String()}),
      ]
    });
    await SuggestedTrainingPacksHistoryService.clearStaleEntries(
      maxAge: const Duration(days: 60),
    );
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('suggested_pack_history')!;
    expect(list.length, 1);
    final data = jsonDecode(list.first) as Map<String, dynamic>;
    expect(data['id'], 'new');
  });
}
