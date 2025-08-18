import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/smart_inbox_priority_scorer_service.dart';
import 'package:poker_analyzer/services/smart_pinned_block_booster_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('sorts by action priority', () async {
    final service = SmartInboxPriorityScorerService();
    final input = [
      const PinnedBlockBoosterSuggestion(
        blockId: '1',
        blockTitle: 'b1',
        tag: 'a',
        action: 'resumePack',
      ),
      const PinnedBlockBoosterSuggestion(
        blockId: '2',
        blockTitle: 'b2',
        tag: 'b',
        action: 'reviewTheory',
      ),
      const PinnedBlockBoosterSuggestion(
        blockId: '3',
        blockTitle: 'b3',
        tag: 'c',
        action: 'decayBooster',
      ),
    ];
    final result = await service.sort(input);
    expect(result.map((e) => e.blockId).toList(), ['3', '2', '1']);
  });

  test('older last shown wins tie', () async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'booster_inbox_last_a',
      now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
    );
    await prefs.setInt(
      'booster_inbox_last_b',
      now.subtract(const Duration(days: 3)).millisecondsSinceEpoch,
    );

    final service = SmartInboxPriorityScorerService();
    final input = [
      const PinnedBlockBoosterSuggestion(
        blockId: '1',
        blockTitle: 'b1',
        tag: 'a',
        action: 'reviewTheory',
      ),
      const PinnedBlockBoosterSuggestion(
        blockId: '2',
        blockTitle: 'b2',
        tag: 'b',
        action: 'reviewTheory',
      ),
      const PinnedBlockBoosterSuggestion(
        blockId: '3',
        blockTitle: 'b3',
        tag: 'c',
        action: 'reviewTheory',
      ),
    ];
    final result = await service.sort(input);
    expect(result.map((e) => e.blockId).toList(), ['3', '2', '1']);
  });
}
