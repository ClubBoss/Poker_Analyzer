import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/tag_xp_history_entry.dart';
import 'package:poker_analyzer/services/tag_insight_reminder_engine.dart';
import 'package:poker_analyzer/services/tag_mastery_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHistoryService extends TagMasteryHistoryService {
  final Map<String, List<TagXpHistoryEntry>> data;
  _FakeHistoryService(this.data);
  @override
  Future<Map<String, List<TagXpHistoryEntry>>> getHistory() async => data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadLosses caches results for a day', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day - 2);
    final hist = {
      'a': [
        TagXpHistoryEntry(date: start, xp: 10, source: ''),
        TagXpHistoryEntry(
            date: start.add(const Duration(days: 1)), xp: 8, source: ''),
        TagXpHistoryEntry(
            date: start.add(const Duration(days: 2)), xp: 4, source: ''),
      ],
      'b': [
        TagXpHistoryEntry(date: start, xp: 5, source: ''),
        TagXpHistoryEntry(
            date: start.add(const Duration(days: 1)), xp: 5, source: ''),
        TagXpHistoryEntry(
            date: start.add(const Duration(days: 2)), xp: 5, source: ''),
      ],
    };
    final engine = TagInsightReminderEngine(history: _FakeHistoryService(hist));
    final first = await engine.loadLosses(days: 3);
    expect(first.length, 1);
    expect(first.first.tag, 'a');

    // modify history but results should come from cache
    final engine2 = TagInsightReminderEngine(history: _FakeHistoryService({}));
    final second = await engine2.loadLosses(days: 3);
    expect(second.first.tag, 'a');
  });
}
