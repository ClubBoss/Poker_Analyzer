import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/tag_xp_history_entry.dart';
import 'package:poker_analyzer/services/tag_mastery_trend_service.dart';
import 'package:poker_analyzer/services/tag_mastery_history_service.dart';

class _FakeHistoryService extends TagMasteryHistoryService {
  final Map<String, List<TagXpHistoryEntry>> map;
  _FakeHistoryService(this.map);
  @override
  Future<Map<String, List<TagXpHistoryEntry>>> getHistory() async => map;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('computeTrends detects rising, flat and falling', () async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 13));
    final rising = [
      for (int i = 0; i < 14; i++)
        TagXpHistoryEntry(date: start.add(Duration(days: i)), xp: i, source: '')
    ];
    final falling = [
      for (int i = 0; i < 14; i++)
        TagXpHistoryEntry(
            date: start.add(Duration(days: i)), xp: 13 - i, source: '')
    ];
    final flat = [
      for (int i = 0; i < 14; i++)
        TagXpHistoryEntry(date: start.add(Duration(days: i)), xp: 5, source: '')
    ];

    final service = TagMasteryTrendService(
      history: _FakeHistoryService({
        'r': rising,
        'f': falling,
        'n': flat,
      }),
    );

    final trends = await service.computeTrends(days: 14);
    expect(trends['r'], TagTrend.rising);
    expect(trends['f'], TagTrend.falling);
    expect(trends['n'], TagTrend.flat);
  });
}
