import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/hand_data.dart';
import 'package:poker_analyzer/models/inline_theory_entry.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/theory_link_auto_injector.dart';

void main() {
  group('TheoryLinkAutoInjector', () {
    test('injects matching theory metadata', () {
      final spots = [
        TrainingPackSpot(id: 's1', hand: HandData(), tags: ['openSB']),
      ];
      final index = {
        'openSB': const InlineTheoryEntry(
          tag: 'openSB',
          id: 'sb_vs_bb_open_range',
          title: 'SB Opening Range vs BB',
          htmlSnippet: '<p>SB open</p>',
        ),
      };
      const injector = TheoryLinkAutoInjector();

      injector.injectAll(spots, index);

      final meta = spots.first.meta['theory'] as Map<String, dynamic>?;
      expect(meta, isNotNull);
      expect(meta!['id'], 'sb_vs_bb_open_range');
      expect(meta['title'], 'SB Opening Range vs BB');
      expect(meta['tag'], 'openSB');
    });

    test('falls back to fuzzy tag matches', () {
      final spots = [
        TrainingPackSpot(id: 's1', hand: HandData(), tags: ['openSBWide']),
      ];
      final index = {
        'openSB': const InlineTheoryEntry(
          tag: 'openSB',
          id: 'sb_vs_bb_open_range',
          title: 'SB Opening Range',
          htmlSnippet: '<p>SB open</p>',
        ),
      };
      const injector = TheoryLinkAutoInjector();

      injector.injectAll(spots, index);

      final meta = spots.first.meta['theory'] as Map<String, dynamic>?;
      expect(meta, isNotNull);
      expect(meta!['tag'], 'openSB');
    });

    test('avoids duplicate theory ids across pack', () {
      final spots = [
        TrainingPackSpot(id: 's1', hand: HandData(), tags: ['openSB']),
        TrainingPackSpot(id: 's2', hand: HandData(), tags: ['openSB']),
      ];
      final index = {
        'openSB': const InlineTheoryEntry(
          tag: 'openSB',
          id: 'sb_vs_bb_open_range',
          title: 'SB Opening Range',
          htmlSnippet: '<p>SB open</p>',
        ),
      };
      const injector = TheoryLinkAutoInjector();

      injector.injectAll(spots, index);

      final first = spots[0].meta['theory'] as Map<String, dynamic>?;
      final second = spots[1].meta['theory'] as Map<String, dynamic>?;
      expect(first, isNotNull);
      expect(second, isNull);
    });
  });
}

