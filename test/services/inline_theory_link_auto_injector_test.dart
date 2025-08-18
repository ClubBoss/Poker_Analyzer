import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/hand_data.dart';
import 'package:poker_analyzer/models/inline_theory_entry.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/inline_theory_link_auto_injector.dart';

void main() {
  group('InlineTheoryLinkAutoInjector', () {
    test('scores and selects top theory links', () {
      final spot = TrainingPackSpot(
        id: 's1',
        hand: HandData(),
        tags: ['a', 'b'],
        meta: {
          'boardTextureTags': ['monotone'],
          'clusterIds': ['c1'],
        },
      );
      final index = {
        't1': InlineTheoryEntry(
          tag: 't1',
          id: 't1',
          title: 'T1',
          htmlSnippet: '<p>t1</p>',
          tags: ['a'],
          textureBuckets: ['monotone'],
          clusterIds: ['c1'],
        ),
        't2': InlineTheoryEntry(
          tag: 't2',
          id: 't2',
          title: 'T2',
          htmlSnippet: '<p>t2</p>',
          tags: ['a', 'b'],
        ),
      };
      final injector = InlineTheoryLinkAutoInjector();
      injector.injectAll([spot], index);
      final links = spot.meta['theoryLinks'] as List;
      expect(links.length, 2);
      expect(links.first['id'], 't1');
    });

    test('respects minScore threshold', () {
      final spot = TrainingPackSpot(id: 's1', hand: HandData(), tags: ['x']);
      final index = {
        't1': InlineTheoryEntry(
          tag: 't1',
          id: 't1',
          title: 'T1',
          htmlSnippet: '<p>t1</p>',
          tags: ['y'],
        ),
      };
      final injector = InlineTheoryLinkAutoInjector(minScore: 0.5);
      final result = injector.injectAll([spot], index);
      expect(result.linkedCount, 0);
      expect(result.rejectedLowScore, 1);
    });

    test('idempotent on re-run', () {
      final spot = TrainingPackSpot(id: 's1', hand: HandData(), tags: ['a']);
      final index = {
        't1': InlineTheoryEntry(
          tag: 't1',
          id: 't1',
          title: 'T1',
          htmlSnippet: '<p>t1</p>',
          tags: ['a'],
        ),
      };
      final injector = InlineTheoryLinkAutoInjector();
      injector.injectAll([spot], index);
      final first = spot.meta['theoryLinks'];
      injector.injectAll([spot], index);
      final second = spot.meta['theoryLinks'];
      expect(first, second);
    });
  });
}
