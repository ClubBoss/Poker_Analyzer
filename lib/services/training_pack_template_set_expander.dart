
import '../models/training_pack_template_set.dart';
import '../models/spot_seed_format.dart';
import 'constraint_resolver_engine_v2.dart';
import 'full_board_generator_service.dart';

/// Expands a [TrainingPackTemplateSet] into a list of concrete
/// [SpotSeedFormat] instances by applying each [ConstraintSet] variant.
class TrainingPackTemplateSetExpander {
  TrainingPackTemplateSetExpander({
    ConstraintResolverEngine? resolver,
    FullBoardGeneratorService? boardGenerator,
  })  : _resolver = resolver ?? ConstraintResolverEngine(),
        _boardGenerator = boardGenerator ?? FullBoardGeneratorService();

  final ConstraintResolverEngine _resolver;
  final FullBoardGeneratorService _boardGenerator;

  /// Generates all spot seeds defined by [set]. Each variant is used to
  /// produce one [SpotSeedFormat] that satisfies the given constraints.
  List<SpotSeedFormat> expand(TrainingPackTemplateSet set) {
    final results = <SpotSeedFormat>[];
    for (final variant in set.variants) {
      final base = set.baseTemplate;
      // Apply overrides from variant where provided.
      final template = SpotSeedFormat(
        player: base.player,
        handGroup:
            variant.handGroup.isNotEmpty ? variant.handGroup : base.handGroup,
        position:
            variant.positions.isNotEmpty ? variant.positions.first : base.position,
        villainActions: variant.villainActions.isNotEmpty
            ? variant.villainActions
            : base.villainActions,
      );

      final street = variant.targetStreet ?? base.currentStreet;
      final stages = _streetToStages(street);

      final boardFilter = variant.boardTags.isNotEmpty
          ? {'boardTexture': variant.boardTags}
          : null;

      final board = _boardGenerator
          .generateBoard(
            FullBoardRequest(
              stages: stages,
              excludedCards: const [],
              boardFilterParams: boardFilter,
            ),
          )
          .cards;

      final candidate = SpotSeedFormat(
        player: template.player,
        handGroup: template.handGroup,
        position: template.position,
        board: board,
        villainActions: template.villainActions,
      );

      if (_resolver.isValid(candidate, variant)) {
        results.add(candidate);
      }
    }
    return results;
  }

  int _streetToStages(String street) {
    switch (street.toLowerCase()) {
      case 'turn':
        return 4;
      case 'river':
        return 5;
      default:
        return 3;
    }
  }
}
