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
    final raw = prefs.getString('suggested_pack_history')!;
    final list = jsonDecode(raw) as List;
    expect(list.length, 100);
    final first = list.first as Map<String, dynamic>;
    final last = list.last as Map<String, dynamic>;
    expect(first['id'], 'id119');
    expect(last['id'], 'id20');
  });

  test('getRecentSuggestions returns entries by recency', () async {
    await SuggestedTrainingPacksHistoryService.logSuggestion(
      packId: 'a',
      source: 't',
    );
    await SuggestedTrainingPacksHistoryService.logSuggestion(
      packId: 'b',
      source: 't',
    );
    await SuggestedTrainingPacksHistoryService.logSuggestion(
      packId: 'c',
      source: 't',
    );

    final list =
        await SuggestedTrainingPacksHistoryService.getRecentSuggestions(
      limit: 2,
    );
    expect(list.length, 2);
    expect(list[0].packId, 'c');
    expect(list[1].packId, 'b');
  });

  test('wasRecentlySuggested respects duration', () async {
    final old = DateTime.now().subtract(const Duration(days: 40));
    final recent = DateTime.now().subtract(const Duration(days: 5));
    SharedPreferences.setMockInitialValues({
      'suggested_pack_history': jsonEncode([
        {'id': 'old', 'source': 's', 'ts': old.toIso8601String()},
        {'id': 'new', 'source': 's', 'ts': recent.toIso8601String()},
      ]),
    });
    final oldRes =
        await SuggestedTrainingPacksHistoryService.wasRecentlySuggested(
      'old',
      within: const Duration(days: 30),
    );
    final newRes =
        await SuggestedTrainingPacksHistoryService.wasRecentlySuggested(
      'new',
      within: const Duration(days: 30),
    );
    expect(oldRes, isFalse);
    expect(newRes, isTrue);
  });

  test('clearStaleEntries removes old logs', () async {
    final old = DateTime.now().subtract(const Duration(days: 70));
    final recent = DateTime.now().subtract(const Duration(days: 5));
    SharedPreferences.setMockInitialValues({
      'suggested_pack_history': jsonEncode([
        {'id': 'old', 'source': 's', 'ts': old.toIso8601String()},
        {'id': 'new', 'source': 's', 'ts': recent.toIso8601String()},
      ]),
    });
    await SuggestedTrainingPacksHistoryService.clearStaleEntries(
      maxAge: const Duration(days: 60),
    );
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('suggested_pack_history')!;
    final list = jsonDecode(raw) as List;
    expect(list.length, 1);
    final data = list.first as Map<String, dynamic>;
    expect(data['id'], 'new');
  });
}
