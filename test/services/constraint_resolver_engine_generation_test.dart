import 'package:test/test.dart';
import 'package:poker_analyzer/models/constraint_set.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/constraint_resolver_engine_v2.dart';
import 'package:poker_analyzer/services/inline_theory_linker.dart';

void main() {
  final engine = ConstraintResolverEngine();

  TrainingPackSpot baseSpot() => TrainingPackSpot(
    id: 'base',
    hand: HandData.fromSimpleInput('Ah Kh', HeroPosition.btn, 30),
    tags: ['base'],
    meta: {'a': 1},
  )..theoryLink = InlineTheoryLink(title: 't1', onTap: () {});

  test('merges tags and meta by default', () {
    final base = baseSpot();
    final sets = [
      ConstraintSet(
        overrides: {
          'heroStack': [10],
        },
        tags: ['extra'],
        metadata: {'b': 2},
      ),
    ];
    final spots = engine.apply(base, sets);
    expect(spots, hasLength(1));
    final s = spots.first;
    expect(s.tags.toSet(), {'base', 'extra'});
    expect(s.meta['a'], 1);
    expect(s.meta['b'], 2);
    expect(s.theoryLink?.title, 't1');
  });

  test('override tags and meta', () {
    final base = baseSpot();
    final sets = [
      ConstraintSet(
        overrides: {
          'heroStack': [10],
        },
        tags: ['new'],
        tagMergeMode: MergeMode.override,
        metadata: {'c': 3},
        metaMergeMode: MergeMode.override,
        theoryLink: InlineTheoryLink(title: 't2', onTap: () {}),
      ),
    ];
    final spots = engine.apply(base, sets);
    expect(spots, hasLength(1));
    final s = spots.first;
    expect(s.tags, ['new']);
    expect(s.meta.containsKey('a'), isFalse);
    expect(s.meta['c'], 3);
    expect(s.theoryLink?.title, 't2');
  });
}
