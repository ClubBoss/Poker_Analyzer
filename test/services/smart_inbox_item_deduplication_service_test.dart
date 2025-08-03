import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/smart_inbox_item_deduplication_service.dart';
import 'package:poker_analyzer/services/smart_pinned_block_booster_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('keeps booster not shown recently for same tag', () async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('booster_opened_a',
        now.subtract(const Duration(days: 1)).millisecondsSinceEpoch);

    final service = SmartInboxItemDeduplicationService();
    final input = [
      const PinnedBlockBoosterSuggestion(
          blockId: '1',
          blockTitle: 'b1',
          tag: 'a',
          action: 'reviewTheory'),
      const PinnedBlockBoosterSuggestion(
          blockId: '2',
          blockTitle: 'b2',
          tag: 'a',
          action: 'reviewTheory'),
    ];
    final result = await service.deduplicate(input);
    expect(result.length, 1);
    expect(result.first.blockId, '2');
  });

  test('prefers resumePack for same block', () async {
    final service = SmartInboxItemDeduplicationService();
    final input = [
      const PinnedBlockBoosterSuggestion(
          blockId: '1',
          blockTitle: 'b1',
          tag: 'a',
          action: 'reviewTheory'),
      const PinnedBlockBoosterSuggestion(
          blockId: '1',
          blockTitle: 'b1',
          tag: 'b',
          action: 'resumePack'),
    ];
    final result = await service.deduplicate(input);
    expect(result.length, 1);
    expect(result.first.tag, 'b');
  });
}
