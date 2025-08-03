import 'dart:math';

import 'package:test/test.dart';
import 'package:poker_analyzer/models/spot_seed_format.dart';
import 'package:poker_analyzer/models/constraint_set.dart';
import 'package:poker_analyzer/models/training_pack_template_set.dart';
import 'package:poker_analyzer/services/training_pack_template_set_expander.dart';
import 'package:poker_analyzer/services/constraint_resolver_engine_v2.dart';
import 'package:poker_analyzer/services/full_board_generator_service.dart';

void main() {
  test('expand generates spots matching variant constraints', () {
    final base = SpotSeedFormat(
      player: 'hero',
      handGroup: const ['broadways'],
      position: 'btn',
      villainActions: const ['check'],
    );

    final set = TrainingPackTemplateSet(
      baseTemplate: base,
      variants: const [
        ConstraintSet(boardTags: ['paired'], positions: ['btn']),
        ConstraintSet(
          boardTags: ['monotone'],
          positions: ['co'],
          villainActions: ['bet'],
        ),
      ],
    );

    final expander = TrainingPackTemplateSetExpander(
      boardGenerator: FullBoardGeneratorService(random: Random(42)),
    );

    final spots = expander.expand(set);
    expect(spots, hasLength(2));

    final engine = ConstraintResolverEngine();
    expect(engine.isValid(spots[0], set.variants[0]), isTrue);
    expect(engine.isValid(spots[1], set.variants[1]), isTrue);
    expect(spots[1].position.toLowerCase(), equals('co'));
    expect(spots[1].villainActions, contains('bet'));
  });
}
