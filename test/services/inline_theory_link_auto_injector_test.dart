import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/hand_data.dart';
import 'package:poker_analyzer/models/inline_theory_entry.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/services/inline_theory_link_auto_injector.dart';

void main() {
  group('InlineTheoryLinkAutoInjector', () {
    test('injects matching theory entry', () {
      final spots = [
        TrainingPackSpot(id: 's1', hand: HandData(), tags: ['openSB']),
      ];
      final model = TrainingPackModel(id: 'p1', title: 'Pack', spots: spots);
      final index = {
        'openSB': const InlineTheoryEntry(
          tag: 'openSB',
          id: 'sb_vs_bb_open_range',
          title: 'SB Opening Range vs BB',
          htmlSnippet: '<p>SB open</p>',
        ),
      };
      const injector = InlineTheoryLinkAutoInjector();

      injector.injectLinks(model, index);

      final entry = spots.first.inlineTheory;
      expect(entry, isNotNull);
      expect(entry!.id, 'sb_vs_bb_open_range');
      expect(entry.title, 'SB Opening Range vs BB');
      expect(entry.tag, 'openSB');
    });

    test('falls back to fuzzy tag matches', () {
      final spots = [
        TrainingPackSpot(id: 's1', hand: HandData(), tags: ['openSBWide']),
      ];
      final model = TrainingPackModel(id: 'p1', title: 'Pack', spots: spots);
      final index = {
        'openSB': const InlineTheoryEntry(
          tag: 'openSB',
          id: 'sb_vs_bb_open_range',
          title: 'SB Opening Range',
          htmlSnippet: '<p>SB open</p>',
        ),
      };
      const injector = InlineTheoryLinkAutoInjector();

      injector.injectLinks(model, index);

      final entry = spots.first.inlineTheory;
      expect(entry, isNotNull);
      expect(entry!.tag, 'openSB');
    });

    test('avoids duplicate theory ids across pack', () {
      final spots = [
        TrainingPackSpot(id: 's1', hand: HandData(), tags: ['openSB']),
        TrainingPackSpot(id: 's2', hand: HandData(), tags: ['openSB']),
      ];
      final model = TrainingPackModel(id: 'p1', title: 'Pack', spots: spots);
      final index = {
        'openSB': const InlineTheoryEntry(
          tag: 'openSB',
          id: 'sb_vs_bb_open_range',
          title: 'SB Opening Range',
          htmlSnippet: '<p>SB open</p>',
        ),
      };
      const injector = InlineTheoryLinkAutoInjector();

      injector.injectLinks(model, index);

      expect(spots[0].inlineTheory, isNotNull);
      expect(spots[1].inlineTheory, isNull);
    });
  });
}
